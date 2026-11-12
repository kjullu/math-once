#!/usr/bin/env python3
"""Time full compiles of generated documents, with and without math-once.

Each document size is written twice: once with math-once calculations, and once
as plain Typst math showing the same equations with precomputed results. The
difference is the compile time math-once adds. Generated sources, PDFs, and
results.json stay in the output folder.
"""

import argparse
import json
import math
from pathlib import Path
import shutil
import statistics
import subprocess
import sys
import time

# Builder calls per section: nine equations and one inline result.
CALLS_PER_SECTION = 10


def number(value):
    """Format like math-once with digits: 2, without trailing zeros."""
    return f"{round(value, 2):.2f}".rstrip("0").rstrip(".")


def section_values(index):
    mass = 10 + (index % 7) * 1.5
    acceleration = 2 + (index % 5) * 0.4
    distance = 3 + (index % 4) * 0.5
    duration = 2 + (index % 3) * 0.5
    force = mass * acceleration
    work = force * distance
    return {
        "m": mass, "a": acceleration, "s": distance, "t": duration,
        "F": force, "W": work, "P": work / duration,
        "x": math.sqrt(3**2 + 4**2) + 2 * math.pi + index,
        "E": 0.5 * mass * (acceleration * duration) ** 2,
    }


def prose(index):
    return (
        f"= Exercise {index}\n"
        "A cart is pushed along a level track. The mass, acceleration, distance,\n"
        "and time are measured, and the force, work, and power follow from them.\n\n"
    )


def math_once_section(index):
    v, i = section_values(index), f"({index})"
    return prose(index) + "".join(line + "\n" for line in (
        f'#eq($ m_{i} := {number(v["m"])} "kg" $)',
        f'#eq($ a_{i} := {number(v["a"])} m / s^2 $)',
        f'#eq($ F_{i} := m_{i} * a_{i} $, unit: $N$)',
        f'#eq($ s_{i} := {number(v["s"])} m $)',
        f'#eq($ W_{i} := F_{i} * s_{i} $, unit: $J$)',
        f'#eq($ t_{i} := {number(v["t"])} s $)',
        f'#eq($ P_{i} := W_{i} / t_{i} $, unit: $W$)',
        f'The power is #eq($P_{i}$, result-only: true).',
        f'#eq($ x_{i} := sqrt(3^2 + 4^2) + 2 pi + {index} $)',
        f'#eq($ E_{i} := 0.5 * m_{i} * (a_{i} * t_{i})^2 $, unit: $J$)',
        "",
    ))


def plain_section(index):
    v, i = section_values(index), f"({index})"
    n = {name: number(value) for name, value in v.items()}
    return prose(index) + "".join(line + "\n" for line in (
        f'$ m_{i} = {n["m"]} "kg" $',
        f'$ a_{i} = {n["a"]} "m" / "s"^2 $',
        f'$ F_{i} = m_{i} dot a_{i} = {n["m"]} "kg" dot {n["a"]} "m" / "s"^2 = {n["F"]} "N" $',
        f'$ s_{i} = {n["s"]} "m" $',
        f'$ W_{i} = F_{i} dot s_{i} = {n["F"]} "N" dot {n["s"]} "m" = {n["W"]} "J" $',
        f'$ t_{i} = {n["t"]} "s" $',
        f'$ P_{i} = W_{i} / t_{i} = ({n["W"]} "J") / ({n["t"]} "s") = {n["P"]} "W" $',
        f'The power is ${n["P"]} "W"$.',
        f'$ x_{i} = sqrt(3^2 + 4^2) + 2 pi + {index} = sqrt(3^2 + 4^2) + 2 dot 3.141592653589793 + {index} = {n["x"]} $',
        f'$ E_{i} = 0.5 dot m_{i} dot (a_{i} dot t_{i})^2 = 0.5 dot {n["m"]} "kg" dot ({n["a"]} "m" / "s"^2 dot {n["t"]} "s")^2 = {n["E"]} "J" $',
        "",
    ))


def mixed_section(index, plain=False):
    """Stored vector-valued functions and matrix products supplement scalars."""
    if plain:
        return "\n".join((
            f'$ f_({index})(x) = vec(x, 2) $',
            f'$ "vector"_({index}) = f_({index})({index}) = vec({index}, 2) $',
            f'$ "matrix"_({index}) = mat(1, 2; 3, 4) $',
            f'$ "product"_({index}) = "matrix"_({index}) "vector"_({index}) = vec({index + 4}, {3 * index + 8}) $',
            "",
        ))
    return "\n".join((
        f'#eq(`f_{index}(x) := vec(x, 2)`)',
        f'#eq(`vector_{index} := f_{index}({index})`)',
        f'#eq(`matrix_{index} := mat(1, 2; 3, 4)`)',
        f'#eq(`product_{index} := matrix_{index} * vector_{index}`)',
        '#context {',
        '  let stored = eq()',
        f'  assert(stored.at("product_{index}").values == ({index + 4}.0, {3 * index + 8}.0))',
        '}',
        "",
    ))


def math_once_header(import_path, initial_values=0):
    initial = ""
    if initial_values:
        initial = (", initial-state: { let values = (:); for i in range(" + str(initial_values)
                   + ') { values.insert("seed_" + str(i), i) }; values }')
    return f'#import "{import_path}": calculation-builder\n#let eq = calculation-builder(digits: 2{initial})\n\n'


def time_compile(compiler, root, source, timeout):
    """Return seconds for one cold compile, or None on timeout."""
    command = [compiler, "compile", "--root", str(root), str(source), str(source.with_suffix(".pdf"))]
    started = time.perf_counter()
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return None
    elapsed = time.perf_counter() - started
    if result.returncode != 0:
        raise RuntimeError(f"{source.name} failed to compile:\n{result.stderr}")
    return elapsed


def seconds(value):
    return "timeout" if value is None else f"{value:.2f} s"


def change(before, after):
    """Describe the current time relative to the baseline, such as '10.0x faster'."""
    if before is None or after is None:
        return "unknown"
    if after <= before:
        return f"{before / after:.1f}x faster"
    return f"{after / before:.1f}x slower"


def markdown_summary(results, limit):
    baseline = results["baseline"] is not None
    controls_timed_out = (results["empty_seconds"] is None or results["import_only_seconds"] is None
                          or any(entry["plain_seconds"] is None for entry in results["documents"]))
    too_slow = [entry for entry in results["documents"] if entry["over_limit"]]
    lines = ["## math-once compile speed", ""]
    if too_slow:
        sizes = ", ".join(f"{entry['calls']} calculations ({seconds(entry['math_once_seconds'])})" for entry in too_slow)
        description = "a compile timed out" if limit is None else f"the limit is {limit:g} s per document"
        lines += [f"**Too slow:** {description}. Affected documents: {sizes}.", ""]
    elif limit is not None and not controls_timed_out:
        lines += [f"Every document compiled within the {limit:g} s limit.", ""]
    if controls_timed_out:
        lines += ["**Incomplete:** a control document timed out; ratios or per-calculation costs may be unavailable.", ""]
    header = ["Calculations", "Plain Typst"] + (["Before", "After", "Change"] if baseline else ["math-once"])
    header += ["Slower than plain", "Per calculation"] + (["Limit"] if limit is not None else [])
    lines += ["| " + " | ".join(header) + " |", "|" + "---:|" * len(header)]
    for entry in results["documents"]:
        plain, after = entry["plain_seconds"], entry["math_once_seconds"]
        row = [str(entry["calls"]), seconds(plain)]
        if baseline:
            row += [seconds(entry["baseline_seconds"]), seconds(after), change(entry["baseline_seconds"], after)]
        else:
            row.append(seconds(after))
        if after is None:
            row += ["", ""]
        else:
            imported = results["import_only_seconds"]
            per_call = "" if imported is None else f"{(after - imported) / entry['calls'] * 1000:.1f} ms"
            row += ["" if plain is None else f"{after / plain:.1f}x", per_call]
        if limit is not None:
            row.append("**too slow**" if entry["over_limit"] else "ok")
        lines.append("| " + " | ".join(row) + " |")
    notes = [f"Median of {results['runs']} cold compiles each with `{results['compiler']}`."]
    notes.append(f"Workload: {results['workload']}; initial variables: {results['initial_values']}.")
    if baseline:
        notes.append(f"Before is `{results['baseline']}`; After is this change.")
    notes.append(f"Importing math-once without using it: {seconds(results['import_only_seconds'])}; "
                 f"empty document: {seconds(results['empty_seconds'])}. 'Per calculation' excludes the import.")
    return "\n".join(lines + ["", " ".join(notes), ""]) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sections", type=int, nargs="+", default=[1, 5, 20, 50],
                        help="Document sizes; each section has 10 scalar calls, or 14 mixed calls")
    parser.add_argument("--runs", type=int, default=3, help="Compiles per document; the median is reported")
    parser.add_argument("--timeout", type=float, default=300, help="Seconds per compile")
    parser.add_argument("--output", type=Path, default=None, help="Default: build/speed-test")
    parser.add_argument("--typst", default="typst", help="Typst executable")
    parser.add_argument("--baseline", type=Path, default=None,
                        help="An earlier math-once.typ to time as 'before', next to the current one")
    parser.add_argument("--baseline-label", default=None, help="Name shown for the baseline, such as a branch")
    parser.add_argument("--max-seconds", type=float, default=None,
                        help="Exit with status 1 when a math-once document takes longer than this")
    parser.add_argument("--summary", type=Path, default=None,
                        help="Also append the results as a Markdown table to this file, such as $GITHUB_STEP_SUMMARY")
    parser.add_argument("--workload", choices=("scalar", "mixed"), default="scalar",
                        help="Mixed adds stored functions, vectors, and matrices")
    parser.add_argument("--initial-values", type=int, default=0, help="Seed the builder with this many unused initial variables")
    args = parser.parse_args()
    if args.runs < 1 or any(size < 1 for size in args.sections):
        parser.error("sections and runs must be positive")
    if args.initial_values < 0:
        parser.error("initial-values must be nonnegative")
    if not math.isfinite(args.timeout) or args.timeout <= 0:
        parser.error("timeout must be finite and positive")
    if args.max_seconds is not None and (not math.isfinite(args.max_seconds) or args.max_seconds <= 0):
        parser.error("max-seconds must be finite and positive")
    compiler = shutil.which(args.typst)
    if compiler is None:
        parser.error(f"Typst executable not found: {args.typst}")
    root = Path(__file__).resolve().parent.parent
    output = (args.output or root / "build/speed-test").resolve()
    if root not in output.parents:
        parser.error("--output must be inside the repository, so documents can import math-once.typ")
    output.mkdir(parents=True, exist_ok=True)
    current_header = math_once_header("/math-once.typ", args.initial_values)
    baseline_header = None
    if args.baseline is not None:
        if not args.baseline.is_file():
            parser.error(f"Baseline not found: {args.baseline}")
        # Typst can only import files inside the project root.
        copied = output / "baseline-math-once.typ"
        if args.baseline.resolve() != copied:
            shutil.copyfile(args.baseline, copied)
        baseline_header = math_once_header("/" + copied.relative_to(root).as_posix(), args.initial_values)

    samples = {}

    def measure(name, text):
        source = output / f"{name}.typ"
        source.write_text(text)
        times = samples[name] = []
        for _ in range(args.runs):
            elapsed = time_compile(compiler, root, source, args.timeout)
            times.append(elapsed)
            if elapsed is None:
                return None
        return statistics.median(times)

    # Importing math-once has a fixed cost that is paid once per document,
    # however many calculations follow.
    empty = measure("empty", "Nothing here.\n")
    import_only = measure("import-only", current_header + "Nothing here.\n")
    print(f"Empty document: {seconds(empty)}. Importing math-once without using it: {seconds(import_only)}.\n")
    columns = f"{'calls':>6} {'plain':>9}" + (f" {'before':>9}" if baseline_header else "")
    print(columns + f" {'math-once':>10} {'slower':>8} {'per call':>10}" + (f" {'change':>14}" if baseline_header else ""))
    results = {"compiler": subprocess.check_output([compiler, "--version"], text=True).strip(),
               "runs": args.runs, "initial_values": args.initial_values, "workload": args.workload, "empty_seconds": empty, "import_only_seconds": import_only,
               "baseline": (args.baseline_label or str(args.baseline)) if baseline_header else None,
               "max_seconds": args.max_seconds, "samples_seconds": samples, "documents": []}
    # A baseline that times out is not timed again at larger sizes.
    baseline_alive = baseline_header is not None
    for size in sorted(set(args.sections)):
        indexes = range(1, size + 1)
        calls = size * (CALLS_PER_SECTION + (4 if args.workload == "mixed" else 0))
        body = "".join(math_once_section(index) + (mixed_section(index) if args.workload == "mixed" else "") for index in indexes)
        plain = measure(f"plain-{size}", "".join(plain_section(index) + (mixed_section(index, plain=True) if args.workload == "mixed" else "") for index in indexes))
        before = measure(f"baseline-{size}", baseline_header + body) if baseline_alive else None
        baseline_alive = before is not None
        with_package = measure(f"math-once-{size}", current_header + body)
        over_limit = with_package is None or (args.max_seconds is not None and with_package > args.max_seconds)
        results["documents"].append({"sections": size, "calls": calls, "plain_seconds": plain,
                                     "baseline_seconds": before, "math_once_seconds": with_package,
                                     "over_limit": over_limit})
        row = f"{calls:>6} {seconds(plain):>9}" + (f" {seconds(before):>9}" if baseline_header else "")
        if with_package is None:
            print(row + f" {'timeout':>10}", flush=True)
            print(f"\nStopped: math-once took longer than {args.timeout:g} s. Larger documents were skipped.")
            break
        per_call = "unknown" if import_only is None else f"{(with_package - import_only) / calls * 1000:.1f} ms"
        ratio = "unknown" if plain is None else f"{with_package / plain:.1f}x"
        row += f" {seconds(with_package):>10} {ratio:>8} {per_call:>10}"
        print(row + (f" {change(before, with_package):>14}" if baseline_header else ""), flush=True)
    (output / "results.json").write_text(json.dumps(results, indent=2) + "\n")
    if args.summary is not None:
        with args.summary.open("a") as summary:
            summary.write(markdown_summary(results, args.max_seconds))
    print(f"\nMedian of {args.runs} cold compiles each. 'per call' excludes the import cost.")
    print(f"Documents and results.json: {output}")
    too_slow = [entry["calls"] for entry in results["documents"] if entry["over_limit"]]
    if too_slow:
        limit = f"{args.max_seconds:g} s limit" if args.max_seconds is not None else f"{args.timeout:g} s timeout"
        print(f"Too slow: the documents with {', '.join(map(str, too_slow))} calculations exceeded the {limit}.")
        return 1
    if empty is None or import_only is None or any(entry["plain_seconds"] is None for entry in results["documents"]):
        print("Incomplete benchmark: a control document timed out.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
