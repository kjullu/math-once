# `calculate`

Evaluates one dimensional expression and returns both rendered equation
content and a reusable result.

## Example

```typ
#import "math-once.typ": calculate, text-unit

#let speed = calculate(`10 m/s + 1 km/h`)
#speed.display
// 10 m/s + 1 km/h = 10.2778 m/s

#let distance = calculate(`v * 2 s`, scope: (v: speed), digits: 3)
#distance.display
// v ⋅ 2 s = 20.556 m
```

## Signature

```typ
calculate(
  source,
  digits: 4,
  scope: (:),
  unit: none,
  size: none,
  block: true,
) -> dictionary
```

## Parameters

### `source`

`str` or `raw` or math `content` — required, positional

The expression to evaluate. It can contain numbers, variables, units,
parentheses, and the operators `+`, `-`, `*`, `/`, `^`, `±`, and `∓`.

```typ
#calculate(`1 m + 25 cm`).display
#calculate("1 m + 25 cm").display
#calculate($1 m + 25 "cm"$).display
```

Input `*` is rendered as the multiplication dot `⋅`. Adjacent values imply
multiplication, as in `2 N` or `10 m`.

Paired `plus.minus` (`±`) and `minus.plus` (`∓`) signs evaluate both
correlated branches and display them with `∨` between the results:

```typ
#let alternatives = calculate(`10 plus.minus 3 minus.plus 1`)
#alternatives.display
// 10 ± 3 ∓ 1 = 12 ∨ 8
#assert(alternatives.values == (12.0, 8.0))
```

For every paired sign, the first branch selects the upper operator and the
second selects the lower operator. See [Result](#result) for the returned
multi-value fields.

An unknown quoted name such as `"widget"` is an opaque custom unit. Matching
custom units support normal arithmetic but cannot be converted to physical
catalog units. See [Custom units](units.md#custom-units).

### `digits`

`int` — optional, named — default: `4`

The number of decimal places used for `result.value` and the rendered result.
The unrounded value remains available through `result.exact` and
`result.si-value`.

```typ
#calculate(`1 m / 3`, digits: 2).display
// 1 m / 3 = 0.33 m
```

### `scope`

`dictionary` — optional, named — default: `(:)`

Numbers and earlier `calculate` results made available as variables. A reused
`calculate` result keeps its exact SI value and physical dimensions.

```typ
#let speed = calculate(`10 m/s`)
#calculate(
  `factor * v * 2 s`,
  scope: (factor: 2, v: speed),
).display
// factor ⋅ v ⋅ 2 s = 40 m
```

Unit names are reserved and take precedence over scope variable names.

### `unit`

`str` or `raw` or math `content` or `none` — optional, named — default: `none`

Requests the unit used for the returned and displayed value. The requested
unit normally has the same physical dimensions as the result. When the
expression is a plain number, `unit` assigns that physical unit to the value.

```typ
#calculate(`3 m/s`, unit: `km/h`, digits: 1).display
// 3 m/s = 10.8 km/h

#calculate($902 / 3.6$, unit: $m/s$, digits: 2).display
// 902/3.6 = 250.56 m/s
```

Typst evaluates function arguments before calling the function, so bare
`unit: m/s` treats `m` and `s` as code variables and does not work. Wrap the
unit in math, raw text, or a string: `unit: $m/s$`, ``unit: `m/s` ``, or
`unit: "m/s"`.

Use `text-unit` for a symbolic label with no physical dimension or conversion
factor. Known parts of the unit are still converted and dimension-checked:

```typ
#calculate($1 / (0.5 "mm")$, unit: $#text-unit("linjer") / m$, digits: 0).display
// 1/(0.5 mm) = 2000 linjer/m
```

This also removes ambiguity: `"cm"` remains centimetres, while
`text-unit("cm")` is only the literal label `cm`. An unquoted unknown name
remains an error. See
[Custom output labels](units.md#custom-output-labels).

Writing `to` or `=` in `source` performs the same conversion. Use only one of
the three forms in a call.

```typ
#calculate(`3 m/s to km/h`, digits: 1).display
#calculate(`3 m/s = km/h`, digits: 1).display
```

### `size`

`int` or `float` or `decimal` or string/raw/math `content` or `none` — optional,
named — default: `none`

Displays the result in multiples of a positive SI scale. Wrap exponent
notation in Typst math: `$10^(-6)$` selects millionths of the SI unit. Known
length scales are written with their normal prefix.

```typ
#calculate(`2047.762752 nm`, size: $10^(-6)$, digits: 9).display
// 2047.762752 nm = 2.047762752 µm
```

The result keeps its unchanged `si-value` for later calculations. When `unit:`
and `size:` are supplied together, `unit:` chooses the output unit and `size:`
scales it. Familiar length scales use their normal SI symbols:

```typ
#calculate(`1 cm + 2 cm`, unit: $m$, size: 0.01, digits: 2).display
// 1 cm + 2 cm = 3 cm

#calculate(`1 cm + 2 cm`, unit: $m$, size: 1, digits: 2).display
// 1 cm + 2 cm = 0.03 m
```

For example, `unit: $m/s$, size: 0.1` means tenths of a metre per second.
Scales without a familiar symbol are displayed explicitly. `size:` requires a
physical result and cannot scale affine output units such as Celsius.

Power-of-ten scales are displayed as scientific notation with both automatic
and explicitly requested output units. Compound scientific scales retain their
written form instead of expanding to a decimal number:

```typ
#calculate(
  $1 / (2.05 * 10^(-6))$,
  unit: $"linjer" / m$,
  size: $10^(5)$,
  digits: 2,
).display
// 1/(2.05 ⋅ 10⁻⁶) = 4.88 ⋅ 10⁵ linjer/m

#calculate(`6000 N`, size: $2 * 10^3$, digits: 2).display
// 6000 N = 3 ⋅ (2 ⋅ 10³) N
```

Combine `size:` with the named `unit:` parameter, not with `to` or an output
`=` inside the expression. Bare `10^(-6)` is invalid Typst code; equivalent
accepted forms are `$10^(-6)$`, `` `10^(-6)` ``, `"10^(-6)"`, and
`calc.pow(10, -6)`.

### Trigonometric functions

`sin`, `cos`, and `tan` accept a parenthesized angle. A bare number is treated
as degrees. Add `rad`, `deg`, `degree`, or `°` to select an explicit angle unit.

```typ
#calculate(`sin(30)`).display
// sin(30) = 0.5

#calculate(`cos(60 degree)`).display
// cos(60°) = 0.5

#calculate(`tan(0.7853981634 rad)`, digits: 6).display
// approximately 1
```

### Roots

`sqrt(x)` calculates a square root. `root(n, x)` calculates the `n`th root
of `x`, matching Typst's index-first math syntax:

```typ
#calculate($sqrt(5)$, digits: 6).display
// √5 = 2.236068

#calculate($root(5, 3)$, digits: 6).display
// ⁵√3 = 1.245731
```

Roots preserve physical dimensions when every unit exponent is divisible by
the root index. For example, `sqrt(9 m^2)` returns `3 m`. A non-integer or
zero index, an even root of a negative value, or incompatible unit exponents
produces an error.

### Rounding functions

`floor(x)` rounds down, `ceil(x)` rounds up, and `round(x)` rounds to the
nearest integer:

```typ
#calculate(`floor(3.7)`).display
// floor(3.7) = 3

#calculate(`ceil(3.2)`).display
// ceil(3.2) = 4

#calculate(`round(3.5)`).display
// round(3.5) = 4
```

Down and up refer to the number line. This matters for negative values:

```typ
#calculate(`floor(-3.2)`).display // -4
#calculate(`ceil(-3.2)`).display  // -3
```

The functions preserve units and round in the input's preferred unit:

```typ
#calculate(`floor(3.7 cm)`).display
// floor(3.7 cm) = 3 cm
```

### `block`

`bool` — optional, named — default: `true`

Controls whether `result.display` is a centered block equation. Set it to
`false` for an inline equation.

```typ
Inline: #calculate(`100 cm to m`, block: false).display.
```

## Result

Returns a dictionary with these fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `display` | math content | The rendered expression and result. |
| `value` | number | The rounded value expressed in `unit`. |
| `exact` | number | The unrounded value expressed in `unit`. |
| `si-value` | `float` | The unrounded value in SI base units. |
| `dimensions` | dictionary | Exponents for the seven SI base dimensions. |
| `unit` | `str` or `none` | The displayed output unit. |
| `size` | number or `none` | The requested SI display scale. |
| `source` | `str` | The normalized source expression. |

A paired `±`/`∓` calculation instead returns `alternatives: true`, `display`,
and these tuple fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `branches` | tuple of dictionaries | The two complete scalar calculation results. |
| `values` | tuple of numbers | The two rounded displayed values. |
| `exacts` | tuple of numbers | The two unrounded values in their output units. |
| `si-values` | tuple of floats | The two unrounded SI values. |
| `units` | tuple | The displayed unit of each branch. |

It deliberately has no singular `value`: use `values.first()`,
`values.last()`, or one of the complete `branches` explicitly.

Use `display` to show the equation. A normal scalar result can be passed
through `scope` when another calculation needs it:

```typ
#let length = calculate(`250 cm to m`)
#length.display

#let area = calculate(`x^2`, scope: (x: length))
#area.display
#area.value
```

## Supported syntax

- Decimal and scientific notation, such as `1.2e3`.
- `+`, `-`, `*`, `/`, right-associative `^`, and paired `±`/`∓`.
- Parentheses and implicit multiplication.
- Unit products, quotients, prefixes, and integer powers.
- Output conversion through `to`, `=`, or `unit:`.

See [Units and prefixes](units.md) for unit names and limitations.
