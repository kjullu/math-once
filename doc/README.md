# math-once documentation

`math-once` evaluates numerical expressions, renders the equation and result,
and returns the value for later calculations. Unit-aware values are stored
internally in SI base units, so compatible units can be combined safely.

## Functions

Start with one of these two functions. Both understand physical dimensions and reject incompatible operations such as `10 m + 2 s`.

| Function | Use it for |
| --- | --- |
| [`calculate`](calculate.md) | One unit-aware calculation with a reusable result. |
| [`calculation-builder`](calculation-builder.md) | A sequence of equations with stored variables and visible substitution. |

### Builder state and calculations

- [Symbolic calculations](symbolic-calculations.md): simplify, differentiate, solve, and reuse expressions through the builder.
- [`reset`](reset.md): reset all state or select variables, functions, unloaded names, and aliases.
- [Vectors and matrices](calculation-builder.md#vectors-arrow-names-and-matrices): use Typst's `vec` and `mat` syntax.

### Units

- [Units and prefixes](units.md) and the [supported units](supported-units.md).
- [`text-unit`](units.md#custom-output-labels): add a display label that is not a physical unit.
- Advanced unit management: [`unload`](unload.md) frees a reserved name; [`rename-unit`](rename-unit.md) moves a unit to an alias.

### Equation layout

- [`number-labelled-equations`](number-labelled-equations.md): number and reference labelled equations.
- [`equation`](equation.md): add a caption to an equation.
- [`equation-outline`](equation-outline.md): list captioned equations with page numbers.

Use a postfix label such as `#eq($x := 2$) <result>` and put `caption:` on the equation itself. The builder's `label:` parameter remains useful for programmatic calls.

### Advanced helpers and compatibility

[`evaluate-code`](evaluate-code.md) evaluates trusted Typst code, with units used only as display labels. Use it when you need Typst code evaluation; use `calculate` for mathematical expressions with physical units.

The focused reset functions remain supported: [`reset-variables`](reset-variables.md), [`reset-functions`](reset-functions.md), [`restore-units`](restore-units.md), and [`reset-unit-aliases`](reset-unit-aliases.md). New documents should use [`reset` selections](reset.md#compatibility).

The `matrix` alias and central [`captions` dictionary](number-labelled-equations.md#captions) remain supported for existing documents. Prefer native `mat` and per-equation `caption:` in new code.

## Basic usage

```typ
#import "math-once.typ": calculate, calculation-builder

#calculate(`10 m/s + 1 km/h`).display
// 10 m/s + 1 km/h = 10.2778 m/s

#let eq = calculation-builder(digits: 2)
#eq($v := 902 / 3.6$)
#eq($x := v * 2$)
```

In a calculation builder, `:=` calculates and stores a variable. A simple
`name = expression` calculates and displays the result without storing it.
Top-level CAS calls use the same rules; see
[Symbolic calculations](symbolic-calculations.md).

## Input forms

Expressions can normally be written as raw text, strings, or Typst math:

```typ
#calculate(`10 m/s + 1 km/h`).display
#calculate("10 m/s + 1 km/h").display
#calculate($10 m/s + 1 "km"/h$).display
```

In Typst math, quote multi-letter names such as `"km"`. Raw text is usually
the simplest form for unit-heavy expressions.

See [Units and prefixes](units.md) for the supported unit system and see [all Supported units](supported-units.md) for a list of all units.
