# math-once

Write a calculation once, show the equation, and reuse its exact result.
`math-once` is a single-file Typst calculator with physical units, automatic
conversion, and stateful equation variables.

Unknown quoted unit names also work as opaque custom units. They support
ordinary arithmetic with matching custom units, without physical conversion.

```typ
#import "math-once.typ": calculation-builder, text-unit

#let eq = calculation-builder(digits: 2)

#eq($v := 902 / 3.6$)
// v = 902/3.6 = 250.56

#eq($v * 2$)
// v ⋅ 2 = 250.56 ⋅ 2 = 501.11

#eq($distance := 0.5 "mm"$)
#eq($1 / distance$, unit: $#text-unit("lines") / m$)
// 1/distance = 1/(0.5 mm) = 2000 lines/m
```

## Acknowledgements and alternatives

- [Qalculate!](https://github.com/Qalculate/libqalculate) is a powerful
  calculator. Its unit handling *inspired* math-once. (Terminal and GUI tool)
- [eqrun](https://github.com/snlxnet/eqrun) is a well-designed calculator for
  Typst and the original inspiration for this project. (Typst plugin)

## Install

Copy [`math-once.typ`](math-once.typ) into your project and import the
[functions](doc/README.md#functions) you need:

```typ
#import "math-once.typ": calculate, calculation-builder, reset, unload, rename-unit, text-unit, equation, equation-outline, evaluate-code, number-labelled-equations
```

When installed as a local Typst package, use:

```typ
#import "@local/math-once:0.22.0": calculate, calculation-builder, reset, unload, rename-unit, text-unit, equation, equation-outline, evaluate-code, number-labelled-equations
```

The package is implemented entirely in Typst and has no runtime dependencies.

Common calculation mistakes passed through `calculation-builder` are shown as
centered red messages in the document instead of stopping compilation. Direct
`calculate(...)` calls still panic, making failures observable in Typst code.

## Documentation

- [Documentation overview](doc/README.md)
- [`calculate`](doc/calculate.md) — evaluate one unit-aware expression
- [`calculation-builder`](doc/calculation-builder.md) — store and reuse equation variables
- [`reset`](doc/reset.md) — clear all or selected stored variables
- [`unload`](doc/unload.md) — temporarily use unit names as variables
- [`rename-unit`](doc/rename-unit.md) — move a unit spelling to a custom alias
- [`equation`](doc/equation.md) — add a caption directly to an equation
- [`equation-outline`](doc/equation-outline.md) — list captioned equations with page numbers
- [`evaluate-code`](doc/evaluate-code.md) — evaluate trusted Typst code
- [`number-labelled-equations`](doc/number-labelled-equations.md) — number and reference only labelled equations
- [Units and prefixes](doc/units.md)

A compilable example covering the complete public API is available in
[`examples/all-functions.typ`](examples/all-functions.typ).

You can find all the supported units [here](doc/supported-units.md)

See the [changelog](CHANGELOG.md) when upgrading from `0.1.x`.

## License

MIT
