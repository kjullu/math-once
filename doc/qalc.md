# `qalc`

Evaluates one dimensional expression and returns both rendered equation
content and a reusable result.

## Example

```typ
#import "math-once.typ": qalc

#let speed = qalc(`10 m/s + 1 km/h`)
#speed.display
// 10 m/s + 1 km/h = 10.2778 m/s

#let distance = qalc(`v * 2 s`, scope: (v: speed), digits: 3)
#distance.display
// v ⋅ 2 s = 20.556 m
```

## Signature

```typ
qalc(
  source,
  digits: 4,
  scope: (:),
  unit: none,
  block: true,
) -> dictionary
```

## Parameters

### `source`

`str` or `raw` or math `content` — required, positional

The expression to evaluate. It can contain numbers, variables, units,
parentheses, and the operators `+`, `-`, `*`, `/`, and `^`.

```typ
#qalc(`1 m + 25 cm`).display
#qalc("1 m + 25 cm").display
#qalc($1 m + 25 "cm"$).display
```

Input `*` is rendered as the multiplication dot `⋅`. Adjacent values imply
multiplication, as in `2 N` or `10 m`.

### `digits`

`int` — optional, named — default: `4`

The number of decimal places used for `result.value` and the rendered result.
The unrounded value remains available through `result.exact` and
`result.si-value`.

```typ
#qalc(`1 m / 3`, digits: 2).display
// 1 m / 3 = 0.33 m
```

### `scope`

`dictionary` — optional, named — default: `(:)`

Numbers and earlier `qalc` results made available as variables. A reused
`qalc` result keeps its exact SI value and physical dimensions.

```typ
#let speed = qalc(`10 m/s`)
#qalc(
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
#qalc(`3 m/s`, unit: `km/h`, digits: 1).display
// 3 m/s = 10.8 km/h

#qalc($902 / 3.6$, unit: $m/s$, digits: 2).display
// 902/3.6 = 250.56 m/s
```

Typst evaluates function arguments before calling the function, so bare
`unit: m/s` treats `m` and `s` as code variables and does not work. Wrap the
unit in math, raw text, or a string: `unit: $m/s$`, ``unit: `m/s` ``, or
`unit: "m/s"`.

Writing `to` or `=` in `source` performs the same conversion. Use only one of
the three forms in a call.

```typ
#qalc(`3 m/s to km/h`, digits: 1).display
#qalc(`3 m/s = km/h`, digits: 1).display
```

### `block`

`bool` — optional, named — default: `true`

Controls whether `result.display` is a centered block equation. Set it to
`false` for an inline equation.

```typ
Inline: #qalc(`100 cm to m`, block: false).display.
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
| `source` | `str` | The normalized source expression. |

Use `display` to show the equation and pass the full result through `scope`
when another calculation needs it:

```typ
#let length = qalc(`250 cm to m`)
#length.display

#let area = qalc(`x^2`, scope: (x: length))
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
