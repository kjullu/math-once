# `unload`

Temporarily makes unit names available as variables in a
[`calculation-builder`](calculation-builder.md). The setting is stored with the
builder state and lasts until [`reset`](reset.md) restores it.

## Import

```typ
#import "math-once.typ": calculation-builder, reset, unload
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
#eq($a = 2$)
#eq($b = 3$)
#eq($x = a + b$)
// x = a + b = 2 + 3 = 5
```

Strings and raw names work too:

```typ
#unload("a", "b")
#unload(`a`, `b`)
```

Bare `#unload(a, b)` is not generally valid because Typst evaluates `a` and
`b` before calling the function. Single-letter math arguments such as `$a$`
are the closest equivalent without quoting.

## Restoring units

Resetting one variable also restores that unit name:

```typ
#reset("a")
#eq($a = 4$)
// red message: a is a unit name again
```

A complete reset clears all variables and restores every unloaded unit:

```typ
#reset()
```

Other selectively reset names do not affect an unloaded unit. If `b` is
unloaded, `reset("a")` leaves `b` available as a variable.

## Parameters

### `names`

One or more `str`, raw, or math-content positional arguments.

- Known unit names are unloaded until reset.
- Names that are not units are harmless no-ops because they are already
  available as variables.
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
#eq($m = 1$)

#reset(key: "custom")
```
