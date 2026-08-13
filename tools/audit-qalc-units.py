#!/usr/bin/env python3
"""Audit Qalculate's built-in units and emit their SI scale/dimensions.

This is a development helper only. The generated Typst table has no runtime
dependency on Qalculate.
"""

from concurrent.futures import ThreadPoolExecutor
import argparse
import json
import re
import subprocess


BASE_DIMS = {
    "m": {"length": 1},
    "g": {"mass": 1},
    "s": {"time": 1},
    "A": {"current": 1},
    "K": {"temperature": 1},
    "mol": {"amount": 1},
    "cd": {"luminosity": 1},
    "bit": {"information": 1},
    "Np": {"logratio": 1},
}

PREFIXES = {
    "Y": 1e24, "Z": 1e21, "E": 1e18, "P": 1e15, "T": 1e12,
    "G": 1e9, "M": 1e6, "k": 1e3, "h": 1e2, "da": 1e1,
    "d": 1e-1, "c": 1e-2, "m": 1e-3, "μ": 1e-6,
    "µ": 1e-6, "u": 1e-6, "n": 1e-9, "p": 1e-12,
    "f": 1e-15, "a": 1e-18, "z": 1e-21, "y": 1e-24,
}

# These are not linear scale conversions. Rankine is linear and is retained.
NONLINEAR = {"celsius", "oC", "°C", "℃", "centigrade", "fahrenheit", "oF", "°F", "℉", "dBW", "dBm"}

SPECIALS = {
    "ElectronUnit": (9.1093837139e-31, {"mass": 1}),
    "GregorianYear": (31556952.0, {"time": 1}),
    "OctalDigit": (3.0, {"information": 1}),
    "PlanckLength": (1.616255e-35, {"length": 1}),
    "PlanckTemperature": (1.416784e32, {"temperature": 1}),
    "PlanckTime": (5.391247e-44, {"time": 1}),
    "PlanckUnit": (1.054571817e-34, {"mass": 1, "length": 2, "time": -1}),
    "SolarMass": (1.98847e30, {"mass": 1}),
    "TropicalYear": (31556925.216, {"time": 1}),
    "becquerel": (1.0, {"time": -1}),
    "byte": (8.0, {"information": 1}),
    "curie": (3.7e10, {"time": -1}),
    "day": (86400.0, {"time": 1}),
    "debye": (3.33564095198152e-30, {"current": 1, "length": 1, "time": 1}),
    "declet": (10.0, {"information": 1}),
    "fortnight": (1209600.0, {"time": 1}),
    "hartley": (3.32192809488736, {"information": 1}),
    "hertz": (1.0, {"time": -1}),
    "hour": (3600.0, {"time": 1}),
    "kayser": (100.0, {"length": -1}),
    "minute": (60.0, {"time": 1}),
    "mpg": (425143.707430272, {"length": -2}),
    "nat": (1.44269504088896, {"information": 1}),
    "nibble": (4.0, {"information": 1}),
    "nonet": (9.0, {"information": 1}),
    "parsec": (3.08567758149137e16, {"length": 1}),
    "rutherford": (1e6, {"time": -1}),
    "tribble": (12.0, {"information": 1}),
    "trit": (1.58496250072116, {"information": 1}),
    "week": (604800.0, {"time": 1}),
    "word": (16.0, {"information": 1}),
    "year": (31557600.0, {"time": 1}),
}

AFFINE = {
    "celsius": (1.0, 273.15, {"temperature": 1}),
    "fahrenheit": (5 / 9, 255.3722222222222, {"temperature": 1}),
}


def list_units():
    output = subprocess.check_output(["qalc", "--list-units"], text=True)
    rows = []
    for line in output.splitlines():
        if not line or line.startswith("For more"):
            continue
        names = [part.strip() for part in line.split(" / ")]
        rows.append(names)
    return rows


def qalc_base(name):
    command = [
        "qalc", "-t", "--color=0",
        "-s", "decimal comma off",
        "-s", "approximation approximate",
        "-s", "precision 15",
        f"1 {name} to base",
    ]
    result = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return name, result.stdout.strip(), result.stderr.strip()


def parse_factor_and_dims(output):
    # Mixed-unit calendar output is Qalculate's display choice, not a nonlinear
    # unit definition. Resolve the sole case emitted by the current catalog.
    if output == "30 d + 10 h + 30 min":
        return 2629800.0, {"time": 1}

    match = re.fullmatch(r"([+\-]?[0-9.]+(?:E[+\-]?[0-9]+)?)\s*(.*)", output)
    if not match:
        raise ValueError(f"unparsed result: {output!r}")
    factor = float(match.group(1))
    expression = match.group(2).strip()
    if not expression:
        return factor, {}

    # Turn qalc's base-unit product into signed factors. Parentheses only occur
    # around denominator products in the terse base output.
    expression = expression.replace("(", "").replace(")", "")
    dims = {}
    sides = expression.split("/", 1)
    terms = []
    for side_index, side in enumerate(sides):
        sign = 1 if side_index == 0 else -1
        for term in side.split("·"):
            term = term.strip()
            if not term or term == "1":
                continue
            exponent = sign
            superscripts = str.maketrans("⁰¹²³⁴⁵⁶⁷⁸⁹⁻", "0123456789-")
            unit_match = re.fullmatch(r"(.+?)([⁰¹²³⁴⁵⁶⁷⁸⁹⁻]+)?", term)
            symbol = unit_match.group(1)
            if unit_match.group(2):
                exponent *= int(unit_match.group(2).translate(superscripts))

            base = symbol
            prefix_factor = 1.0
            if symbol not in BASE_DIMS:
                for prefix in sorted(PREFIXES, key=len, reverse=True):
                    candidate = symbol[len(prefix):] if symbol.startswith(prefix) else ""
                    if candidate in BASE_DIMS:
                        base = candidate
                        prefix_factor = PREFIXES[prefix]
                        break
            if base not in BASE_DIMS:
                raise ValueError(f"unknown base symbol {symbol!r} in {output!r}")
            # Qalculate's mass base is grams; math-once's is kilograms.
            if base == "g":
                prefix_factor *= 1e-3
            factor *= prefix_factor ** exponent
            for dim_name, dim_exponent in BASE_DIMS[base].items():
                dims[dim_name] = dims.get(dim_name, 0) + exponent * dim_exponent
    return factor, {name: exponent for name, exponent in dims.items() if exponent}


def collect():
    rows = list_units()
    with ThreadPoolExecutor(max_workers=16) as pool:
        results = dict((name, (output, error)) for name, output, error in pool.map(qalc_base, (row[0] for row in rows)))

    successes = []
    failures = []
    for names in rows:
        canonical = names[0]
        output, error = results[canonical]
        if canonical in SPECIALS:
            scale, dims = SPECIALS[canonical]
            successes.append((names, scale, dims, 0.0))
            continue
        if canonical in AFFINE:
            scale, offset, dims = AFFINE[canonical]
            successes.append((names, scale, dims, offset))
            continue
        if any(name in NONLINEAR for name in names):
            failures.append((canonical, "nonlinear/affine", output))
            continue
        try:
            scale, dims = parse_factor_and_dims(output)
            successes.append((names, scale, dims, 0.0))
        except ValueError as exc:
            failures.append((canonical, str(exc), output))

    return successes, failures


def typst_number(value):
    return format(value, ".15g").replace("e+", "e")


def emit_typst(successes, failures):
    print("// Generated from Qalculate 5.10's built-in unit catalog; see")
    print("// tools/audit-qalc-units.py. Runtime use remains dependency-free.")
    print("let qalc-unit-definitions = (")
    for names, scale, dims, offset in successes:
        # Add Qalculate's `t` tonne alias explicitly with the compatibility
        # aliases below, rather than duplicating it in the generated catalog.
        names = [name for name in names if name != "t"]
        quoted = ", ".join(repr(name).replace("'", '"') for name in names)
        if len(names) == 1:
            quoted += ","
        dim_args = ", ".join(f"{name}: {exponent}" for name, exponent in dims.items())
        tail = f", offset: {typst_number(offset)}" if offset else ""
        print(f"  (names: ({quoted}), scale: {typst_number(scale)}, dims: dim({dim_args}){tail}),")
    print(")")
    print("")
    print("for definition in qalc-unit-definitions {")
    print("  let item = (scale: definition.scale, dims: definition.dims,")
    print('    offset: definition.at("offset", default: 0.0))')
    print("  for name in definition.names { units.insert(name, item) }")
    print("}")
    print("")
    print("// Project-specific compatibility aliases and named composites.")
    print('units.insert("t", units.tonne)')
    print('units.insert("timer", units.hour)')
    print('units.insert("kn", units.knot)')
    print('units.insert("Nm", (scale: 1.0, dims: dim(length: 2, mass: 1, time: -2)))')
    print('units.insert("Ncm", (scale: 0.01, dims: units.Nm.dims))')
    print('units.insert("Nmm", (scale: 0.001, dims: units.Nm.dims))')
    print('units.insert("Wh", (scale: 3600.0, dims: dim(length: 2, mass: 1, time: -2)))')
    if failures:
        print("// Not representable as linear or affine units: " + ", ".join(row[0] for row in failures))


def emit_tests(successes):
    print('#import "../math-once.typ": calculate')
    print("")
    print("// Generated catalog smoke tests: every qalc spelling accepted by")
    print("// math-once must parse and retain its audited SI value.")
    print("#let qalc-unit-cases = (")
    for names, scale, _dims, offset in successes:
        for name in names:
            expected = scale + offset
            print(f"  ({json.dumps(name, ensure_ascii=False)}, {typst_number(expected)}),")
    print(")")
    print("")
    print("#for (name, expected) in qalc-unit-cases {")
    print('  let actual = calculate("1 " + name).si-value')
    print("  let tolerance = calc.max(calc.abs(expected) * 1e-10, 1e-55)")
    print('  assert(calc.abs(actual - expected) <= tolerance, message: "qalc unit failed: " + name)')
    print("}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--typst", action="store_true")
    parser.add_argument("--tests", action="store_true")
    args = parser.parse_args()
    successes, failures = collect()
    if args.typst:
        emit_typst(successes, failures)
        return
    if args.tests:
        emit_tests(successes)
        return
    print(f"successes={len(successes)} failures={len(failures)}")
    for names, scale, dims, offset in successes:
        print("OK\t" + "|".join(names) + f"\t{scale:.15g}\t" + ",".join(f"{key}:{value}" for key, value in dims.items()) + f"\toffset:{offset:.15g}")
    for canonical, reason, output in failures:
        print(f"FAIL\t{canonical}\t{reason}\t{output}")


if __name__ == "__main__":
    main()
