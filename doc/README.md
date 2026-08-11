# math-once documentation

`math-once` evaluates numerical expressions, renders the equation and result,
and returns the value for later calculations. Unit-aware values are stored
internally in SI base units, so compatible units can be combined safely.

## Functions

| Function | Use it for |
| --- | --- |
| [`qalc`](qalc.md) | One unit-aware calculation with a reusable result. |
| [`qalc-builder`](qalc-builder.md) | A sequence of equations with stored variables and visible substitution. |
| [`calculate`](calculate.md) | Trusted Typst code where a unit is only a display label. |
| [`number-labelled-equations`](number-labelled-equations.md) | Number only labelled equations and make them referenceable. |

For most documents, use `qalc` or `qalc-builder`. They understand physical
dimensions and reject incompatible operations such as `10 m + 2 s`.
`calculate` uses unrestricted Typst evaluation and does not interpret units.

## Basic usage

```typ
#import "math-once.typ": qalc, qalc-builder

#qalc(`10 m/s + 1 km/h`).display
// 10 m/s + 1 km/h = 10.2778 m/s

#let eq = qalc-builder(digits: 2)
#eq($v = 902 / 3.6$)
#eq($a = v * 2$)
```

## Input forms

Expressions can normally be written as raw text, strings, or Typst math:

```typ
#qalc(`10 m/s + 1 km/h`).display
#qalc("10 m/s + 1 km/h").display
#qalc($10 m/s + 1 "km"/h$).display
```

In Typst math, quote multi-letter names such as `"km"`. Raw text is usually
the simplest form for unit-heavy expressions.

See [Units and prefixes](units.md) for the supported unit system.
