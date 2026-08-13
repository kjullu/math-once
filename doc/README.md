# math-once documentation

`math-once` evaluates numerical expressions, renders the equation and result,
and returns the value for later calculations. Unit-aware values are stored
internally in SI base units, so compatible units can be combined safely.

## Functions

| Function | Use it for |
| --- | --- |
| [`calculate`](calculate.md) | One unit-aware calculation with a reusable result. |
| [`calculation-builder`](calculation-builder.md) | A sequence of equations with stored variables and visible substitution. |
| [`reset`](reset.md) | Clear all or selected variables from a calculation-builder state. |
| [`unload`](unload.md) | Temporarily use reserved unit names as builder variables. |
| [`rename-unit`](rename-unit.md) | Move an active unit spelling to a custom alias. |
| [`text-unit`](units.md#custom-output-labels) | Create an explicit symbolic output-unit label. |
| [`equation`](equation.md) | A figure-like wrapper for per-equation captions. |
| [`equation-outline`](equation-outline.md) | A linked list of labelled, captioned equations. |
| [`evaluate-code`](evaluate-code.md) | Trusted Typst code where a unit is only a display label. |
| [`number-labelled-equations`](number-labelled-equations.md) | Number only labelled equations and make them referenceable. |

For most documents, use `calculate` or `calculation-builder`. They understand physical
dimensions and reject incompatible operations such as `10 m + 2 s`.
`evaluate-code` uses unrestricted Typst evaluation and does not interpret units.

## Basic usage

```typ
#import "math-once.typ": calculate, calculation-builder

#calculate(`10 m/s + 1 km/h`).display
// 10 m/s + 1 km/h = 10.2778 m/s

#let eq = calculation-builder(digits: 2)
#eq($v := 902 / 3.6$)
#eq($x := v * 2$)
```

In a calculation builder, `:=` stores a variable while an ordinary `=` only
displays the written equation.

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
