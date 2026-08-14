# `reset`

Clears the complete or selected parts of a
[`calculation-builder`](calculation-builder.md) state. It changes the builder
state at its position in the document and renders no visible output.

> You may want one of the focused operations instead: use
> [`reset-variables`](reset-variables.md) to keep functions and unit
> configuration, [`reset-functions`](reset-functions.md) for stored functions,
> [`restore-units`](restore-units.md) to undo `unload`, or
> [`reset-unit-aliases`](reset-unit-aliases.md) to undo `rename-unit`.

## Import

```typ
#import "math-once.typ": calculation-builder, reset
```

## Signature

```typ
reset(..names, key: "math-once-calculation") -> content
```

## Examples

The default `key` matches a builder created without an explicit key:

```typ
#let eq = calculation-builder()
#eq(`height := 10 m`)
#eq(`width := 5 m`)

#reset("height")
// width remains stored

#reset()
// all remaining variables are cleared
```

Reset several selected variables by passing their names separately:

```typ
#reset("height", "width")
#reset(`height`, `width`)
```

Single-letter and supported mathematical names can also use math content:

```typ
#reset($x$, $theta_1$)
```

Bare `#reset(height, width)` is not valid unless `height` and `width` are
already Typst values, because Typst evaluates function arguments before
calling `reset`. Strings or raw names preserve the variable names instead.

## Parameters

### `names`

Zero or more `str`, raw, or math-content positional arguments.

- With no names, every value, function, unloaded-unit setting, alias, and
  `initial-state` value in the selected state is removed.
- With names, matching values or functions are removed. Matching unloaded unit
  names are restored, and matching aliases have their complete relationship
  removed.
- Unknown names do nothing.
- Names may contain letters and an optional underscore subscript containing
  letters or digits, matching builder variable names.

### `key`

`str` — optional, named — default: `"math-once-calculation"`

Must match the `key` passed to the associated builder:

```typ
#let eq = calculation-builder(key: "geometry")
#eq(`height := 10 m`)
#eq(`width := 5 m`)

#reset("height", key: "geometry")
#reset(key: "geometry")
```

An empty reset also removes values originally supplied through
`initial-state`. A selective reset preserves initial and calculated variables
whose names were not supplied.

Reset also restores names temporarily made available as variables by
[`unload`](unload.md). A selective reset restores the supplied names; an empty
reset restores every unloaded unit.

For [`rename-unit`](rename-unit.md), resetting either the original spelling or
its current alias restores the original unit and removes the complete alias
relationship. Other stored variables remain unchanged.
