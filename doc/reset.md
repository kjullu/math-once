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

## Compilation checkpoints

A full `reset()` also starts a separate calculation state sequence. Put it between independent exercises or sections to keep their calculation histories separate. Existing calls use this automatically, including custom `key` values.

```typ
#let eq = calculation-builder()
#eq(`distance := 100 m`)
#eq(`speed := distance / (5 s)`)

#reset()
#eq(`mass := 2 kg`)
#eq(`force := mass * (3 m/s^2)`)
```

Changing the distance can reuse the force section's cached calculation state. This does not freeze the PDF layout. Page breaks, equation numbering, references, and Typst's own cache decisions can still require work elsewhere in the document. Adding or removing a reset changes section identities from that point onward. Inserting equations can also make Typst resolve document locations again, so a checkpoint does not guarantee that compilation visits only one section.

Focused operations such as `reset-variables()` preserve part of the old state, so they do not create independent checkpoints. Within one section, calculations still read the accumulated state, including stored functions and unit settings. Use separate builder keys for independent calculations that should coexist without clearing each other.

For a local incremental benchmark, run `python3 tools/benchmark-incremental.py --output build/benchmark-current`. This uses one persistent compiler process and measures edits and insertions, including edits in the first and last sections. Local timings do not measure the typst.app editor or its compiler service.
