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


MATH_ONCE_HEADER = '#import "/math-once.typ": calculation-builder\n#let eq = calculation-builder(digits: 2)\n\n'


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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sections", type=int, nargs="+", default=[1, 5, 20, 50],
                        help=f"Document sizes; each section has {CALLS_PER_SECTION} math-once calls")
    parser.add_argument("--runs", type=int, default=3, help="Compiles per document; the median is reported")
    parser.add_argument("--timeout", type=float, default=300, help="Seconds per compile")
    parser.add_argument("--output", type=Path, default=None, help="Default: build/speed-test")
    parser.add_argument("--typst", default="typst", help="Typst executable")
    parser.add_argument("--summary", type=Path, default=None,
                        help="Also append the results as a Markdown table to this file, such as $GITHUB_STEP_SUMMARY")
    args = parser.parse_args()
    if args.runs < 1 or any(size < 1 for size in args.sections):
        parser.error("sections and runs must be positive")
    compiler = shutil.which(args.typst)
    if compiler is None:
        parser.error(f"Typst executable not found: {args.typst}")
    root = Path(__file__).resolve().parent.parent
    output = (args.output or root / "build/speed-test").resolve()
    if root not in output.parents:
        parser.error("--output must be inside the repository, so documents can import math-once.typ")
    output.mkdir(parents=True, exist_ok=True)

    def measure(name, text):
        source = output / f"{name}.typ"
        source.write_text(text)
        times = []
        for _ in range(args.runs):
            elapsed = time_compile(compiler, root, source, args.timeout)
            if elapsed is None:
                return None
            times.append(elapsed)
        return statistics.median(times)

    # Importing math-once has a fixed cost that is paid once per document,
    # however many calculations follow.
    empty = measure("empty", "Nothing here.\n")
    import_only = measure("import-only", MATH_ONCE_HEADER + "Nothing here.\n")
    print(f"Empty document: {empty:.2f} s. Importing math-once without using it: {import_only:.2f} s.\n")
    print(f"{'calls':>6} {'plain':>9} {'math-once':>10} {'slower':>8} {'per call':>10}")
    results = {"compiler": subprocess.check_output([compiler, "--version"], text=True).strip(),
               "runs": args.runs, "empty_seconds": empty, "import_only_seconds": import_only, "documents": []}
    for size in sorted(set(args.sections)):
        indexes = range(1, size + 1)
        calls = size * CALLS_PER_SECTION
        plain = measure(f"plain-{size}", "".join(plain_section(index) for index in indexes))
        with_package = measure(f"math-once-{size}", MATH_ONCE_HEADER + "".join(math_once_section(index) for index in indexes))
        entry = {"sections": size, "calls": calls, "plain_seconds": plain, "math_once_seconds": with_package}
        results["documents"].append(entry)
        if with_package is None:
            print(f"{calls:>6} {plain:>7.2f} s {'timeout':>10}", flush=True)
            print(f"\nStopped: math-once took longer than {args.timeout:g} s. Larger documents were skipped.")
            break
        per_call = (with_package - import_only) / calls * 1000
        print(f"{calls:>6} {plain:>7.2f} s {with_package:>8.2f} s {with_package / plain:>7.1f}x {per_call:>7.1f} ms", flush=True)
    (output / "results.json").write_text(json.dumps(results, indent=2) + "\n")
    if args.summary is not None:
        lines = ["## math-once compile speed", "",
                 "| Calculations | Plain Typst | math-once | Slower | Per calculation |", "|---:|---:|---:|---:|---:|"]
        for entry in results["documents"]:
            plain, with_package = entry["plain_seconds"], entry["math_once_seconds"]
            if with_package is None:
                lines.append(f"| {entry['calls']} | {plain:.2f} s | timeout | | |")
            else:
                per_call = (with_package - import_only) / entry["calls"] * 1000
                lines.append(f"| {entry['calls']} | {plain:.2f} s | {with_package:.2f} s | {with_package / plain:.1f}x | {per_call:.1f} ms |")
        lines += ["", f"Median of {args.runs} cold compiles each with `{results['compiler']}`. "
                  f"Importing math-once without using it: {import_only:.2f} s; an empty document: {empty:.2f} s. "
                  "'Per calculation' excludes the import cost.", ""]
        with args.summary.open("a") as summary:
            summary.write("\n".join(lines) + "\n")
    print(f"\nMedian of {args.runs} cold compiles each. 'per call' excludes the import cost.")
    print(f"Documents and results.json: {output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
