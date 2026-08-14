# `reset-variables`

Clears stored calculation values while preserving stored functions, unloaded
unit names, and unit aliases. Values configured through `initial-state` are
restored to their original values instead of being removed.

## Import

```typ
#import "math-once.typ": calculation-builder, reset-variables
```

## Signature

```typ
reset-variables(..names, key: "math-once-calculation") -> content
```

## Example

```typ
#let eq = calculation-builder(initial-state: (factor: 2))
#eq(`x := factor * 3`)
#eq(`factor := 9`)

#reset-variables("x")
// x is removed; factor is still 9

#reset-variables()
// all calculated values are removed; factor is restored to 2
```

With selected names, only matching stored values are cleared. With no names,
all stored values are cleared. Unknown names do nothing.

If a value uses a name made available by [`unload`](unload.md), clearing the
value keeps that name unloaded. Likewise, clearing a value using the original
spelling of a renamed unit keeps the [`rename-unit`](rename-unit.md)
relationship active.

The optional `key` must match the associated builder.
