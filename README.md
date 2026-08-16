# math-once

Write a calculation once, show the equation, and reuse its exact result.
`math-once` is a Typst calculator with physical units, automatic conversion,
stateful equation variables, and symbolic calculations through
[typCAS](https://github.com/sihooleebd/typCAS).

Unknown quoted unit names also work as opaque custom units. They support
ordinary arithmetic with matching custom units, without physical conversion.

```typ
#import "math-once.typ": calculation-builder, text-unit

#let eq = calculation-builder(digits: 2)

#eq($v := 902 / 3.6$)
// v = 902/3.6 = 250.56

#eq($v * 2$)
// v ⋅ 2 = 250.56 ⋅ 2 = 501.11

#eq($10 plus.minus 2$)
// 10 ± 2 = 12 ∨ 8

#eq($distance := 0.5 "mm"$)
#eq($1 / distance$, unit: $#text-unit("lines") / m$)
// 1/distance = 1/(0.5 mm) = 2000 lines/m

// Use raw backticks for CAS input. Plain $...$ only works when
// multi-letter names are quoted.
#eq(`f := simplify(x^2 + 2*x + 1)`)
#eq(`df := diff(f, x)`)
// df = diff(f, x) = 2x + 2

// Alternatively, quote multi-letter variables and CAS operations in $...$:
#eq($"identity" := "simplify"(sin(x)^2 + cos(x)^2)$)
```

## Acknowledgements and alternatives

- [Qalculate!](https://github.com/Qalculate/libqalculate) is a powerful
  calculator. Its unit handling *inspired* math-once. (Terminal and GUI tool)
- [eqrun](https://github.com/snlxnet/eqrun) is a well-designed calculator for
  Typst and the original inspiration for this project. (Typst plugin)
- [typcas](https://github.com/sihooleebd/typCAS) For the cas functions, as we integrate them into math-one (Typst plugin)

## Install

Copy [`math-once.typ`](math-once.typ) into your project and import the
[functions](doc/README.md#functions) you need:

```typ
#import "math-once.typ": calculate, calculation-builder, reset, reset-variables, reset-functions, restore-units, reset-unit-aliases, unload, rename-unit, text-unit, equation, equation-outline, evaluate-code, number-labelled-equations
```

When installed as a local Typst package, use:

```typ
#import "@local/math-once:0.30.0": calculate, calculation-builder, reset, reset-variables, reset-functions, restore-units, reset-unit-aliases, unload, rename-unit, text-unit, equation, equation-outline, evaluate-code, number-labelled-equations
```

The package is implemented entirely in Typst. Symbolic builder operations use
the pinned `@preview/typcas:0.2.3` dependency, which Typst downloads and caches
through the normal package system. See [third-party notices](THIRD-PARTY.md).

Common calculation mistakes passed through `calculation-builder` are shown as
centered red messages in the document instead of stopping compilation. Direct
`calculate(...)` calls still panic, making failures observable in Typst code.

## Documentation

- [Documentation overview](doc/README.md)
- [`calculate`](doc/calculate.md) — evaluate one unit-aware expression
- [`calculation-builder`](doc/calculation-builder.md) — store and reuse equation variables
- [Symbolic calculations](doc/symbolic-calculations.md) — simplify, differentiate, solve, and reuse CAS results
- [`reset`](doc/reset.md) — clear the complete builder state
- [`reset-variables`](doc/reset-variables.md) — clear values while keeping builder configuration
- [`reset-functions`](doc/reset-functions.md) — clear stored function definitions
- [`restore-units`](doc/restore-units.md) — undo `unload` without resetting other state
- [`reset-unit-aliases`](doc/reset-unit-aliases.md) — undo `rename-unit` relationships
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

See the [changelog](CHANGELOG.md) when upgrading.

## Why is it called `math-once`?
The plugin originally started as just `typst-math` (still the name of the folder on my pc).

But was later renamed, by codex, to `math-once`, idk why. My guess is because my first prompt for this plugin was something along the lines of: "*make a typst plugin like [eqrun](https://github.com/snlxnet/eqrun), but where I can save variabels, so I only have to do the math once*", and when I asked it to then create a little README.md for the docs and so I could share it with my friends, the name `math-once` was in the header (you can look at the blame and see it).

And it is still the name today because I have gotten to used to typing (autocompleteing) `github.com/kjullu/math-once` in the adresses bare in my browser (and I don't have a better name).

## License

MIT
