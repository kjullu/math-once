# `unload`

Temporarily makes reserved unit or built-in constant names available as variables in a
[`calculation-builder`](calculation-builder.md). The setting is stored with the
builder state and lasts until [`restore-units`](restore-units.md) or
[`reset`](reset.md) restores it.

## Import

```typ
#import "math-once.typ": calculation-builder, reset, restore-units, unload
```

## Signature

```typ
unload(..names, key: "math-once-calculation") -> content
```

## Example

Qalculate defines `a` as are and `b` as barn, so they are normally reserved
unit names. Unload them before assigning variables with those names:

```typ
#let eq = calculation-builder()

#unload($a$, $b$)
#eq($a := 2$)
#eq($b := 3$)
#eq($x := a + b$)
// x = a + b

#eq($x$)
// x = 5
```

Strings and raw names work too:

```typ
#unload("a", "b")
#unload(`a`, `b`)
```

Bare `#unload(a, b)` is not generally valid because Typst evaluates `a` and
`b` before calling the function. Single-letter math arguments such as `$a$`
are the closest equivalent without quoting.

The built-in constants `e` and `pi` are reserved in the same way. Unload them
before deliberately replacing either value:

```typ
#unload("e", "pi")
#eq($e := 3$)
#eq($pi := 4$)
```

## Restoring units

Restore one catalog name without changing other builder state:

```typ
#restore-units("a")
#eq($a := 4$)
// red message: a is a unit name again
```

A focused call can restore every unloaded unit without clearing unrelated
values or functions:

```typ
#restore-units()
```

A complete reset also restores every unloaded unit, but clears the rest of the
builder state as well:

```typ
#reset()
```

Other selectively restored names do not affect an unloaded unit. If `b` is
unloaded, `restore-units("a")` leaves `b` available as a variable.

## Parameters

### `names`

One or more `str`, raw, or math-content positional arguments.

- Known unit names and the built-in constants `e` and `pi` are unloaded until
  restored or reset.
- Names that are neither units nor built-in constants are harmless no-ops
  because they are already available as variables.
- Calling `unload()` without a name reports an error.

An unloaded spelling is interpreted as the variable in calculation
expressions while it is unloaded. Longer aliases remain available. For
example, after `unload("a")`, use `are` when the area unit itself is needed.
An explicit output request such as `unit: "a"` still selects the unit.

### `key`

`str` — optional, named — default: `"math-once-calculation"`

Must match the associated builder and any reset calls:

```typ
#let eq = calculation-builder(key: "custom")
#unload("m", key: "custom")
#eq($m := 1$)

#restore-units("m", key: "custom")
```
