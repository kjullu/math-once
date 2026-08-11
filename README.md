# math-once

`math-once` is a pure Typst calculator that evaluates qalc-like expressions
with physical units, renders the calculation, and lets later calculations
reuse the dimensioned result.

## Public API

The file exports exactly three supported functions:

| Function | Purpose |
| --- | --- |
| `qalc` | Evaluate one dimensional expression and return its result. |
| `qalc-builder` | Create a stateful runner with eqrun-style variables. |
| `calculate` | Evaluate unrestricted Typst code with an optional unit label. |

Every function and argument is documented below. A single compilable document
covering all of them is available in
[`examples/all-functions.typ`](examples/all-functions.typ).

## Quick start

Copy [`math-once.typ`](math-once.typ) into your Typst project and import it
directly. No installation or additional files are required:

```typ
#import "math-once.typ": qalc, qalc-builder, calculate

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
#import "@local/math-once:0.1.0": qalc, qalc-builder, calculate
```

The expression in each call is written only once. Values are stored internally
in SI base units, so compatible units are converted before addition or
subtraction. Multiplication, division, and powers combine dimensions.

## `qalc`

Evaluates one constrained qalc-style expression. Unlike `calculate`, `qalc`
tracks dimensions and converts compatible units automatically.

```typ
#let result = qalc(
  `10 m/s + 1 km/t`,
  digits: 4,
  scope: (:),
  unit: none,
  block: true,
)
```

| Argument | Accepted value | Default | Description |
| --- | --- | --- | --- |
| `source` | string or raw block | required | Expression to evaluate. |
| `digits` | integer | `4` | Decimal places in the displayed value. |
| `scope` | dictionary | empty | Numbers and earlier qalc results available as variables. |
| `unit` | string, raw block, or `none` | `none` | Requested output unit; alternative to `to`. |
| `block` | boolean | `true` | Center as a block equation when true. |

The result is a dictionary:

| Field | Description |
| --- | --- |
| `result.display` | Rendered equation content. |
| `result.value` | Rounded number in `result.unit`. |
| `result.exact` | Unrounded number in `result.unit`. |
| `result.si-value` | Unrounded value in SI base units, used for reuse. |
| `result.dimensions` | Dictionary of physical base-dimension exponents. |
| `result.unit` | Displayed output unit, or `none` if dimensionless. |
| `result.source` | Original expression as a string. |

Examples of every argument:

```typ
// `source` as raw text; defaults to four digits and centered output.
#qalc(`10 m/s + 1 km/t`).display

// A string source and explicit rounding.
#qalc("1 m / 3", digits: 2).display

// Ordinary numbers and earlier qalc results in `scope`.
#let speed = qalc(`10 m/s`)
#qalc(
  `factor * v * 2 s`,
  scope: (factor: 2, v: speed),
).display

// Requested output unit.
#qalc(`3 m/s`, unit: `km/h`, digits: 1).display

// Inline instead of centered.
Inline: #qalc(`100 cm to m`, block: false).display.
```

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

Calculations are block equations and centered by default. Pass `block: false`
to `qalc` or `qalc-builder` when an inline equation is wanted instead.

## Stateful variables

`qalc-builder` provides eqrun-style variables. A name on the left side of `=`
stores the complete result, including its exact SI value and dimensions. Later
calls automatically have access to all earlier variables:

```typ
#let run = qalc-builder(
  initial-state: (:),
  key: "math-once-qalc",
  digits: 4,
  block: true,
)
```

| Builder argument | Accepted value | Default | Description |
| --- | --- | --- | --- |
| `initial-state` | dictionary | empty | Initial numbers or qalc results. |
| `key` | string | `"math-once-qalc"` | Typst state key; it must be unique per independent runner. |
| `digits` | integer | `4` | Default decimal places for runner calls. |
| `block` | boolean | `true` | Center runner equations by default. |

The returned runner accepts zero or one positional expression. Each expression
call also accepts `digits`, `unit`, and `block`, which override the builder
defaults for that call. Calling it without an expression retrieves the state
and therefore requires `context`.

```typ
#import "math-once.typ": qalc-builder

#let run = qalc-builder(
  initial-state: (factor: 2),
  key: "worked-example",
  digits: 2,
  block: true,
)

#run(`v = 10 m/s + 1 km/t`)
// v = 10 m/s + 1 km/t = 10.2778 m/s

#run(`d = factor * v * 2 s`, unit: `m`, digits: 3)
// d = factor * v * 2 s = 41.111 m

// No assignment: calculate without storing a new variable.
Inline: #run(`1 m/s`, unit: `km/h`, digits: 1, block: false).

#context {
  let variables = run()
  [Distance: #variables.d.value #variables.d.unit]
}
```

Different runners should receive different state keys:

```typ
#let first = qalc-builder(key: "first-calculator")
#let second = qalc-builder(key: "second-calculator")
```

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
#let result = calculate(
  `902 / 3.6`,
  digits: 0,
  scope: (:),
  unit: none,
  block: false,
)
```

| Argument | Accepted value | Default | Description |
| --- | --- | --- | --- |
| `source` | string or raw block | required | Trusted Typst code expression. |
| `digits` | integer | `0` | Decimal places in the displayed value. |
| `scope` | dictionary | empty | Values made available during evaluation. |
| `unit` | string, raw block, math, content, or `none` | `none` | Display-only unit label retained in the result. |
| `block` | boolean | `false` | Center as a block equation when true. |

The returned dictionary contains `display`, rounded `value`, unrounded
`exact`, normalized `source`, and the original `unit` value.

Examples of every argument:

```typ
#import "@local/math-once:0.1.0": calculate

// Raw source and an inline result.
#let a = calculate(`902 / 3.6`, unit: `m/s`)
#a.display

// String source, exact-result reuse through `scope`, rounding, unit, and block.
#let b = calculate(
  "a * 2",
  scope: (a: a),
  digits: 1,
  unit: a.unit,
  block: true,
)
#b.display
```

`calculate` uses Typst's unrestricted `eval` function. Only pass trusted
expressions to it. `qalc` instead accepts only its documented numerical and
unit syntax.

## Local development

Compile the example and tests with:

```sh
typst compile --root . examples/basic.typ build/basic.pdf
typst compile --root . examples/all-functions.typ build/all-functions.pdf
typst compile --root . tests/test.typ build/test.pdf
typst compile --root . tests/qalc.typ build/qalc.pdf
typst compile --root . tests/public-api.typ build/public-api.pdf
```

Ordinary Typst packages are written in Typst itself. TypeScript is not needed,
and this package does not need a WebAssembly plugin.
