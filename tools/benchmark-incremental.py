#!/usr/bin/env python3
"""Measure real edits in one persistent Typst watch process.

Pass --implementation to compare a saved math-once.typ with the current file.
Generated sources, logs, and compiler traces stay in the selected output folder.
"""

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import statistics
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--implementation", type=Path, default=Path("math-once.typ"))
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--sections", type=int, default=8)
    parser.add_argument("--equations", type=int, default=30)
    parser.add_argument("--timings", action="store_true", help="Also retain compiler traces, which add overhead")
    parser.add_argument("--runs", type=int, default=3, help="Fresh watch processes; report median edit times")
    parser.add_argument("--workload", choices=("independent", "chain"), default="independent")
    parser.add_argument("--result-only", action="store_true", help="Render only results, including stored assignments")
    args = parser.parse_args()
    if args.sections < 1 or args.equations < 1 or args.runs < 1:
        parser.error("sections, equations, and runs must be positive")
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    runs = [benchmark(args, output / f"run-{run + 1}") for run in range(args.runs)]
    results = []
    for index, entry in enumerate(runs[0]):
        samples = [run[index]["seconds"] for run in runs]
        results.append({"edit": entry["edit"], "median_seconds": statistics.median(samples),
                        "samples_seconds": samples})
    (output / "results.json").write_text(json.dumps(results, indent=2) + "\n")
    print(json.dumps(results, indent=2))


def benchmark(args, output):
    output.mkdir(parents=True, exist_ok=True)
    implementation = args.implementation.resolve()
    copied = output / "math-once.typ"
    if implementation != copied:
        shutil.copyfile(implementation, copied)
    source = output / "main.typ"
    header = '#import "math-once.typ": calculation-builder, reset\n#let eq = calculation-builder()\n'

    def section_source(section, first=1, extra=False):
        multiplier = section + 2
        values = [first, *range(2, args.equations + 1)]
        body = "#reset()\n"
        if extra:
            body += '#eq(`extra := 99`)\n'
        expected = []
        for index, value in enumerate(values):
            if args.workload == "chain" and index > 0:
                expression = f"v_{index - 1} + {multiplier}"
                expected.append(expected[-1] + multiplier)
            else:
                expression = f"{value} * {multiplier}"
                expected.append(value * multiplier)
            options = ", result-only: true" if args.result_only else ""
            body += f'#eq(`v_{index} := {expression}`{options})\n'

        # Validate section routing during each edit, as well as measuring it.
        body += "#context {\n  let stored = eq()\n"
        body += f"  assert(stored.len() == {args.equations + int(extra)})\n"
        body += "".join(
            f'  assert(stored.at("v_{index}").exact == {value})\n'
            for index, value in enumerate(expected)
        )
        return body + "}\n"

    sections = [section_source(section) for section in range(args.sections)]
    original = header + "".join(sections)
    source.write_text(original)
    log_path = output / "watch.log"
    results = []
    with log_path.open("w") as log:
        process = subprocess.Popen(
            ["typst", "watch", "--root", str(output),
             *(["--timings", str(output / "trace-{n}.json")] if args.timings else []),
             str(source), str(output / "main.pdf")],
            stdout=log, stderr=log,
        )
        try:
            def wait_for_compile(count):
                deadline = time.monotonic() + 120
                while time.monotonic() < deadline:
                    text = log_path.read_text()
                    timings = re.findall(r"compiled successfully in ([^\r\n\x1b]+)", text)
                    if len(timings) >= count:
                        # Watch registers dependencies after reporting success and
                        # exporting the optional trace. Do not race that setup.
                        if args.timings:
                            trace = output / f"trace-{count - 1}.json"
                            previous = -1
                            while time.monotonic() < deadline:
                                size = trace.stat().st_size if trace.exists() else 0
                                if size > 0 and size == previous:
                                    break
                                previous = size
                                time.sleep(0.2)
                        time.sleep(0.3)
                        return timings[-1].strip()
                    if process.poll() is not None or "error:" in text or "layout did not converge" in text:
                        raise RuntimeError(text)
                    time.sleep(0.05)
                raise TimeoutError(log_path.read_text())

            results.append({"edit": "cold", "time": wait_for_compile(1)})
            edits = [
                ("change first section", header + section_source(0, first=7) + "".join(sections[1:])),
                ("restore first section", original),
                ("insert first section", header + section_source(0, extra=True) + "".join(sections[1:])),
                ("remove inserted equation", original),
                ("change last section", header + "".join(sections[:-1]) + section_source(args.sections - 1, first=7)),
            ]
            for count, (name, changed) in enumerate(edits, start=2):
                source.write_text(changed)
                result = {"edit": name, "time": wait_for_compile(count)}
                results.append(result)
                print(json.dumps(result), flush=True)
        finally:
            process.terminate()
            process.wait(timeout=10)
    for result in results:
        match = re.fullmatch(r"([0-9.]+)\s*(ns|µs|μs|us|ms|s)", result["time"])
        if match is None:
            raise ValueError(f"Unrecognized Typst duration: {result['time']}")
        result["seconds"] = float(match[1]) * {"ns": 1e-9, "µs": 1e-6, "μs": 1e-6,
                                               "us": 1e-6, "ms": 1e-3, "s": 1}[match[2]]
    (output / "results.json").write_text(json.dumps(results, indent=2) + "\n")
    (output / "environment.json").write_text(json.dumps({
        "compiler": subprocess.check_output(["typst", "--version"], text=True).strip(),
        "implementation_sha256": hashlib.sha256(copied.read_bytes()).hexdigest(),
        "sections": args.sections,
        "equations_per_section": args.equations,
        "traces": args.timings,
        "workload": args.workload,
        "result_only": args.result_only,
    }, indent=2) + "\n")
    return results


if __name__ == "__main__":
    main()
