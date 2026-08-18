# `reset`

Clears the complete state of a [`calculation-builder`](calculation-builder.md).
It takes effect at its position in the document and renders no visible output.

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
reset(key: "math-once-calculation") -> content
```

## Example

The default `key` matches a builder created without an explicit key:

```typ
#let eq = calculation-builder(initial-state: (factor: 2))
#eq(`height := factor * 5 m`)

#reset()
// values, functions, initial-state, unloads, and aliases are all cleared;
// the standard e and pi constants are restored
```

Use the matching `key` for a custom builder:

```typ
#let eq = calculation-builder(key: "geometry")
#eq(`height := 10 m`)

#reset(key: "geometry")
```

`reset` deliberately accepts no positional names. This keeps it unambiguous:
it always clears the complete matching builder state. To migrate an older
selective call, use the operation matching what should be removed:

| Older call | Replacement |
| --- | --- |
| `reset("x")` for a stored value | `reset-variables("x")` |
| `reset("f")` for a stored function | `reset-functions("f")` |
| `reset("m")` for an unloaded unit | `restore-units("m")` |
| `reset("v")` for a unit alias | `reset-unit-aliases("v")` |

## Parameters

### `key`

`str` — optional, named — default: `"math-once-calculation"`

Must match the `key` passed to the associated builder.
