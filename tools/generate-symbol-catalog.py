#!/usr/bin/env python3
"""Generate math-once's pinned Typst symbol catalog and exhaustive fixture.

The input is the `sym.txt` file from the `codex` version used by the Typst
compiler we support. For Typst 0.14.2 that is codex 0.2.0.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path


CATALOG_START = "// BEGIN GENERATED TYPST SYMBOL CATALOG"
CATALOG_END = "// END GENERATED TYPST SYMBOL CATALOG"
MATH_SECTIONS = {
    "Arithmetic",
    "Relations",
    "Set theory",
    "Calculus",
    "Logic",
    "Function and category theory",
    "Game theory",
    "Number theory",
    "Algebra",
    "Geometry",
}


@dataclass(frozen=True)
class Symbol:
    path: str
    value: str
    section: str
    deprecated: bool


def decode_value(source: str) -> str:
    source = re.sub(
        r"\\u\{([0-9A-Fa-f]+)\}",
        lambda match: chr(int(match.group(1), 16)),
        source,
    )
    def variation_selector(match: re.Match[str]) -> str:
        selector = match.group(1)
        number = {"text": 15, "emoji": 16}.get(selector)
        if number is None:
            number = int(selector)
        return chr(0xFE00 + number - 1)

    return re.sub(r"\\vs\{([^}]+)\}", variation_selector, source)


def parse_catalog(source: str) -> list[Symbol]:
    records: list[Symbol] = []
    section = ""
    base: str | None = None
    base_deprecated = False
    module: str | None = None
    deprecated = False

    for line in source.splitlines():
        section_match = re.fullmatch(r"// (.+)\.", line)
        if section_match:
            section = section_match.group(1)
            continue
        if line.lstrip().startswith("@deprecated:"):
            deprecated = True
            continue
        if not line or line.startswith("//"):
            continue
        if line == "}":
            module = None
            base = None
            base_deprecated = False
            continue
        module_match = re.fullmatch(r"([a-z][a-z0-9]*) \{", line)
        if module_match:
            module = module_match.group(1)
            base = None
            base_deprecated = False
            continue

        if module is not None:
            binding = re.fullmatch(r"  ([a-z][a-z0-9]*) (.+)", line)
            modifier = re.fullmatch(r"    (\.[a-z0-9.]+) (.+)", line)
            if binding:
                base = module + "." + binding.group(1)
                base_deprecated = deprecated
                records.append(Symbol(base, decode_value(binding.group(2)), section, deprecated))
                deprecated = False
            elif modifier and base is not None:
                records.append(Symbol(base + modifier.group(1), decode_value(modifier.group(2)), section, deprecated or base_deprecated))
                deprecated = False
            continue

        binding = re.fullmatch(r"([a-zA-Z][a-zA-Z0-9]*) ?(.*)", line)
        modifier = re.fullmatch(r"  (\.[a-z0-9.]+) (.+)", line)
        if binding:
            base = binding.group(1)
            base_deprecated = deprecated
            if binding.group(2):
                records.append(Symbol(base, decode_value(binding.group(2)), section, deprecated))
                deprecated = False
        elif modifier and base is not None:
            value = decode_value(modifier.group(2))
            records.append(Symbol(base + modifier.group(1), value, section, deprecated or base_deprecated))
            deprecated = False

    return records


def typst_string(value: str) -> str:
    # Keep NBSP distinct from an ordinary source-code space. Some Typst
    # versions normalize the literal glyph while parsing dictionary keys and
    # then report the reverse symbol table as containing a duplicate key.
    return json.dumps(value, ensure_ascii=False).replace("\u00a0", r"\u{a0}")


def generated_catalog(records: list[Symbol]) -> str:
    canonical = [record for record in records if not record.deprecated]
    rows = "\n".join(
        f"  {typst_string(record.path)}: {typst_string(record.value)},"
        for record in canonical
    )
    values: dict[str, str] = {}
    for record in canonical:
        values.setdefault(record.value, record.path)
    value_rows = "\n".join(
        f"  {typst_string(value)}: {typst_string(name)},"
        for value, name in values.items()
    )
    return (
        f"{CATALOG_START}\n"
        "// Generated from codex 0.2.0's sym.txt for Typst 0.14.2.\n"
        f"// {len(canonical)} canonical named paths; regenerate with tools/generate-symbol-catalog.py.\n"
        "let typst-symbol-catalog = (\n"
        f"{rows}\n"
        ")\n"
        "let typst-symbol-values = (\n"
        f"{value_rows}\n"
        ")\n"
        f"{CATALOG_END}"
    )


def generated_test(records: list[Symbol]) -> str:
    math = [
        record
        for record in records
        if not record.deprecated and record.section in MATH_SECTIONS
    ]
    rows = "\n".join(
        f"  ({typst_string(record.path)}, {typst_string(record.value)}),"
        for record in math
    )
    return f'''// Generated from codex 0.2.0's mathematical symbol sections.
// Regenerate with tools/generate-symbol-catalog.py; do not edit by hand.
#import "../math-once.typ": calculation-builder

#let eq = calculation-builder(key: "all-mathematical-symbols")
#let symbols = (
{rows}
)

// Every canonical name must resolve to the expected glyph in this Typst
// version and pass through math-once in both named raw and Typst-math input.
#for (name, expected) in symbols {{
  let resolved = eval(name, mode: "math").body
  assert(resolved.text == expected, message: name)
  if name not in ("plus", "minus", "div", "times", "eq") {{
    eq("x = " + name)
    if expected not in ("+", "−", "×", "⋅", "∗", "÷", "=") {{
      eq("x = " + expected)
      eq($x = #resolved$)
    }}
  }}
}}

// The five ordinary arithmetic/relation glyphs retain evaluator semantics.
#eq(`1 plus 2`)
#eq(`3 minus 2`)
#eq(`6 div 2`)
#eq(`2 times 3`)
#eq($1 + 2$)
#eq($3 - 2$)
#eq($6 div 2$)
#eq($2 times 3$)
#eq($x = 1$)

// Display-only symbols must never create a stored numeric result.
#eq(`ambiguous := infinity`)
#context assert("ambiguous" not in eq())
'''


def replace_generated(path: Path, generated: str) -> None:
    source = path.read_text()
    start = source.index(CATALOG_START)
    end = source.index(CATALOG_END, start) + len(CATALOG_END)
    path.write_text(source[:start] + generated + source[end:])


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()

    records = parse_catalog(args.input.read_text())
    canonical = sum(not record.deprecated for record in records)
    deprecated = len(records) - canonical
    math = sum(not record.deprecated and record.section in MATH_SECTIONS for record in records)
    # Seven `sect.*` variants inherit their base binding's deprecation. This
    # leaves 1100 warning-free paths and 312 in the mathematical sections.
    if (canonical, deprecated, math) != (1100, 66, 312):
        raise SystemExit(
            "unexpected codex catalog counts: "
            f"canonical={canonical}, deprecated={deprecated}, math={math}"
        )

    math_once = args.root / "math-once.typ"
    replace_generated(math_once, generated_catalog(records))
    (args.root / "tests" / "all-mathematical-symbols.typ").write_text(generated_test(records))


if __name__ == "__main__":
    main()
