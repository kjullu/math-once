# math-once

`math-once` is a pure Typst calculator that evaluates qalc-like expressions
with physical units, renders the calculation, and lets later calculations
reuse the dimensioned result.

## Quick start

Copy [`math-once.typ`](math-once.typ) into your Typst project and import it
directly. No installation or additional files are required:

```typ
#import "math-once.typ": qalc, calculate

#let speed = qalc(`10 m/s + 1 km/t`)
#speed.display
// 10 m/s + 1 km/t = 10.2778 m/s

#qalc(`10 m/s to km/t`, digits: 2).display
// 10 m/s = 36 km/t

#qalc(`(1 m/s + 2 m/s)`, unit: `km/h`, digits: 1).display
// 1 m/s + 2 m/s = 10.8 km/h

#let distance = qalc(`v * 2 s`, scope: (v: speed), digits: 3)
#distance.display
// v * 2 s = 20.556 m
```

If it is installed as a local Typst package, this import works too:

```typ
#import "@local/math-once:0.1.0": qalc, calculate
```

The expression in each call is written only once. Values are stored internally
in SI base units, so compatible units are converted before addition or
subtraction. Multiplication, division, and powers combine dimensions.

## `qalc`

```typ
#let result = qalc(
  `10 m/s + 1 km/t`,
  digits: 4,
  scope: (:),
  unit: none,
  block: false,
)
```

The result is a dictionary:

- `result.display` is the visible equation.
- `result.value` is the displayed, rounded number in `result.unit`.
- `result.exact` is the unrounded number in `result.unit`.
- `result.si-value` is the unrounded value in SI base units.
- `result.dimensions` contains its physical dimensions.
- `result.unit` is the displayed unit.
- `result.source` is the original expression as a string.

Supported syntax:

- Operators: `+`, `-`, `*`, `/`, and `^`
- Parentheses and implicit multiplication, such as `10 m` and `2 N`
- Scientific notation, such as `1.2e3`
- Explicit conversion with `to`, such as `10 m/s to km/t`
- An output unit with `unit:`, for example the raw value `km/h`
- Previous results and ordinary numbers supplied through `scope`

`to` and `unit:` are equivalent ways to choose the output unit. Use only one
of them in a calculation. Without either, the result uses the first compatible
input unit where possible, otherwise a canonical SI unit.

Supported units:

| Dimension | Units |
| --- | --- |
| Length | `mm`, `cm`, `m`, `km` |
| Time | `s`, `min`, `h`, `t` (`t` is Danish *timer*) |
| Mass | `g`, `kg` |
| Volume | `mL`, `L`, plus derived `m^3` |
| Derived SI | `Hz`, `N`, `Pa`, `J`, `W` |
| Other SI bases | `A`, `K`, `mol`, `cd` |

Unit names are reserved and take precedence over equally named scope
variables. Affine temperature units such as Celsius and Fahrenheit are not yet
supported; `K` is supported.

Incompatible operations fail clearly. For example, the expression
`10 m + 2 s` reports that length and time cannot be added, while `10 m to s`
rejects the conversion.

## Simple source evaluation

The original `calculate` API remains available for ordinary Typst numerical
expressions where units only need to be retained as a label:

```typ
#import "@local/math-once:0.1.0": calculate

#let a = calculate(`902 / 3.6`, unit: `m/s`)
#a.display

// Pass the complete result to reuse its exact value.
#let b = calculate(`a * 2`, scope: (a: a), unit: a.unit, digits: 1)
#b.display
```

`calculate` uses Typst's unrestricted `eval` function. Only pass trusted
expressions to it. `qalc` instead accepts only its documented numerical and
unit syntax.

## Local development

Compile the example and tests with:

```sh
typst compile --root . examples/basic.typ build/basic.pdf
typst compile --root . tests/test.typ build/test.pdf
typst compile --root . tests/qalc.typ build/qalc.pdf
```

Ordinary Typst packages are written in Typst itself. TypeScript is not needed,
and this package does not need a WebAssembly plugin.
