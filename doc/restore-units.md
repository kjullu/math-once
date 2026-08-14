# `restore-units`

Restores catalog unit names previously made available as variables with
[`unload`](unload.md), without resetting unrelated builder state.

## Import

```typ
#import "math-once.typ": calculation-builder, unload, restore-units
```

## Signature

```typ
restore-units(..names, key: "math-once-calculation") -> content
```

## Example

```typ
#let eq = calculation-builder()
#unload("a", "b")
#eq($a := 2$)
#eq($b := 3$)

#restore-units("a")
// a is the are unit again; b remains available as a variable

#restore-units()
// every remaining unloaded catalog name is restored
```

Restoring a catalog name removes a stored variable using that name because the
name cannot simultaneously be a builder variable and an active unit. Unit
aliases are separate configuration; use
[`reset-unit-aliases`](reset-unit-aliases.md) to remove them.

The optional `key` must match the associated builder.
