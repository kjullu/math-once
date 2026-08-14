# `rename-unit`

Moves an active physical unit spelling to a different name within one
[`calculation-builder`](calculation-builder.md) state. The new spelling keeps
the original unit's dimensions and conversion factor. The old spelling is
then free for use as a variable until [`reset`](reset.md).

## Import

```typ
#import "math-once.typ": calculation-builder, rename-unit, reset, unload
```

## Signature

```typ
rename-unit(from, to, key: "math-once-calculation") -> content
```

## Example

```typ
#let eq = calculation-builder()

#rename-unit($m$, $v$)
#eq($m := 2$)       // m is now a variable
#eq($d := 3 v$)     // v means metre; d = 3 m

#reset()
```

Aliases may be moved again. Quote multi-letter names in Typst math:

```typ
#rename-unit($m$, $v$)
#rename-unit($v$, $"vme"$)
#eq($d := 4 "vme"$)
```

Successful calls render no visible output. Calls take effect at their position
in the document because the alias is stored in Typst state.

## Parameters

### `from`

`str`, raw, or math content — required, positional

An active catalog unit spelling or an alias previously created by
`rename-unit`. It must be a single supported state name. After the call, this
spelling no longer denotes the unit and can be assigned with `:=`.

### `to`

`str`, raw, or math content — required, positional

The new unit spelling. It must not already be an active catalog unit, alias, or
stored variable. A catalog spelling explicitly made available with `unload`
can be reused as the destination. Names contain letters and may have one
underscore subscript containing letters or digits.

```typ
#let eq = calculation-builder()
#unload("T", "t")
#rename-unit($h$, $t$)
#eq($T := 8t + 30 "min"$) // T = 8.5 t
```

### `key`

`str` — optional, named — default: `"math-once-calculation"`

Must match the associated builder:

```typ
#let eq = calculation-builder(key: "physics")
#rename-unit($m$, $v$, key: "physics")
#eq($d := 3 v$)
```

## Reset

`reset()` clears every variable and restores all original unit spellings.
Selective reset accepts either side of a rename and removes that complete
relationship:

```typ
#reset($v$) // restores m and removes v as its alias
```

Unrelated variables remain stored after a selective reset.

## Errors

The call shows a centered red error in the document if the source is not an
active unit or alias, the source and destination are identical, or the
destination collides with an active catalog unit, alias, or stored variable.
The rename is not applied, so the existing unit and variables remain intact.
