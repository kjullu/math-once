# `reset-unit-aliases`

Removes relationships created by [`rename-unit`](rename-unit.md) and restores
their original catalog spellings without clearing unrelated builder state.

## Import

```typ
#import "math-once.typ": calculation-builder, rename-unit, reset-unit-aliases
```

## Signature

```typ
reset-unit-aliases(..names, key: "math-once-calculation") -> content
```

## Example

```typ
#let eq = calculation-builder()
#rename-unit($m$, $v$)
#eq($m := 2$)

#reset-unit-aliases($v$)
// m means metre again and v is no longer its alias
```

Pass either the original catalog spelling or its current alias. With no names,
every unit-alias relationship in the matching builder state is removed.
Variables stored under an original spelling are removed when that spelling
becomes an active unit again. Unrelated values and functions remain stored.

The optional `key` must match the associated builder.
