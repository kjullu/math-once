# math-once

Write a calculation once, show the equation, and reuse its exact result.
`math-once` is a single-file Typst calculator with physical units, automatic
conversion, and eqrun-style variables.

```typ
#import "math-once.typ": qalc-builder

#let eq = qalc-builder(digits: 2)

#eq($v = 902 / 3.6$)
// v = 902/3.6 = 250.56

#eq($a = v * 2$)
// a = v ⋅ 2 = 250.56 ⋅ 2 = 501.11
```

## Install

Copy [`math-once.typ`](math-once.typ) into your project and import the
functions you need:

```typ
#import "math-once.typ": qalc, qalc-builder, calculate, number-labelled-equations
```

When installed as a local Typst package, use:

```typ
#import "@local/math-once:0.1.0": qalc, qalc-builder, calculate, number-labelled-equations
```

The package is implemented entirely in Typst and has no runtime dependencies.

## Documentation

- [Documentation overview](doc/README.md)
- [`qalc`](doc/qalc.md) — evaluate one unit-aware expression
- [`qalc-builder`](doc/qalc-builder.md) — store and reuse equation variables
- [`calculate`](doc/calculate.md) — evaluate trusted Typst code
- [`number-labelled-equations`](doc/number-labelled-equations.md) — number and reference only labelled equations
- [Units and prefixes](doc/units.md)

A compilable example covering the complete public API is available in
[`examples/all-functions.typ`](examples/all-functions.typ).

## License

MIT
