# math-once

`math-once` is a small, pure Typst package for writing a calculation once,
showing the calculation and its result, and reusing the result later.

```typ
#import "@local/math-once:0.1.0": calculate

#let a = calculate(`902 / 3.6`, unit: `m/s`)
#a.display

// Pass the whole result; math-once uses its exact value internally.
#let b = calculate(`a * 2`, scope: (a: a), unit: a.unit, digits: 1)
#b.display
```

This renders the equivalents of $902 / 3.6 = 251 m/s$ and
$a times 2 = 501.1 m/s$.
The expression in each call is written only once.

## API

```typ
#let result = calculate(
  `902 / 3.6`,
  digits: 0,
  scope: (:),
  unit: none,
  block: false,
)
```

The result is a dictionary:

- `result.display` is the visible equation.
- `result.value` is the rounded number displayed by the equation.
- `result.exact` is the value before rounding.
- `result.source` is the original expression as a string.
- `result.unit` is the supplied unit, so it can be reused later.

Use `digits: 2` for two decimals and `block: true` for a displayed equation.
Variables used in a later expression must be explicitly supplied in `scope`.
A complete earlier result can be supplied directly; its exact value is then
used automatically, so intermediate display rounding does not accumulate.
Single-letter variable names such as `a`, `b`, and `x` render best in Typst's
math mode.

The `unit` option accepts a string, raw text, or math content. It is rendered
and retained with the result. Units are intentionally not guessed from an
arbitrary source string: when multiplying or dividing unlike quantities, pass
the resulting unit explicitly. This prevents silently incorrect dimensional
algebra.

`calculate` uses Typst's `eval` function so the same source can be evaluated as
code and rendered as mathematics. Only pass trusted expressions; do not pass
untrusted user or external input.

## Local development

Compile the example and tests with:

```sh
typst compile --root . examples/basic.typ build/basic.pdf
typst compile --root . tests/test.typ build/test.pdf
```

Ordinary Typst packages are written in Typst itself. TypeScript is not needed,
and this package does not need a WebAssembly plugin.

