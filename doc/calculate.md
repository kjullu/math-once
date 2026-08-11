# `calculate`

Evaluates one dimensional expression and returns both rendered equation
content and a reusable result.

## Example

```typ
#import "math-once.typ": calculate

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
parentheses, and the operators `+`, `-`, `*`, `/`, and `^`.

```typ
#calculate(`1 m + 25 cm`).display
#calculate("1 m + 25 cm").display
#calculate($1 m + 25 "cm"$).display
```

Input `*` is rendered as the multiplication dot `⋅`. Adjacent values imply
multiplication, as in `2 N` or `10 m`.

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

Inside a math unit, an unknown quoted name is a symbolic count label. Known
parts of the unit are still converted and dimension-checked:

```typ
#calculate($1 / (0.5 "mm")$, unit: $"linjer" / m$, digits: 0).display
// 1/(0.5 mm) = 2000 linjer/m
```

Use this explicit math form for custom labels. An unquoted unknown name remains
an error, and a quoted catalog name such as `"cm"` remains centimetres. See
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

The result keeps its unchanged `si-value` for later calculations. `size`
cannot be combined with `unit`, `to`, or an output `=` and requires a result
with physical dimensions. Bare `10^(-6)` is invalid Typst code; equivalent
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

Use `display` to show the equation and pass the full result through `scope`
when another calculation needs it:

```typ
#let length = calculate(`250 cm to m`)
#length.display

#let area = calculate(`x^2`, scope: (x: length))
#area.display
#area.value
```

## Supported syntax

- Decimal and scientific notation, such as `1.2e3`.
- `+`, `-`, `*`, `/`, and right-associative `^`.
- Parentheses and implicit multiplication.
- Unit products, quotients, prefixes, and integer powers.
- Output conversion through `to`, `=`, or `unit:`.

See [Units and prefixes](units.md) for unit names and limitations.
