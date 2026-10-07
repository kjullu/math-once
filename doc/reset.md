# `reset`

Reset a [`calculation-builder`](calculation-builder.md) at the current position in the document. The call renders no output. Use `reset()` to clear everything, or select the categories and names to reset.

## Import

```typ
#import "math-once.typ": calculation-builder, reset
```

## Signature

```typ
reset(
  key: "math-once-calculation",
  variables: auto,
  functions: auto,
  units: auto,
  aliases: auto,
) -> content
```

## Selections

| Option | Effect |
| --- | --- |
| `variables: true` | Clear stored values and restore values from `initial-state`. Keep functions and unit configuration. |
| `functions: true` | Remove stored functions. If a function replaced an initial value, restore that value. |
| `units: true` | Undo `unload` for catalog unit names and the built-in constants `e` and `pi`. Remove variables using those names. Keep renamed units and aliases. |
| `aliases: true` | Undo `rename-unit`, restoring original unit spellings and removing their aliases and any variables using the original spellings. |

Each option accepts `true` for the whole category or an array of names for selected items. Names may be strings, raw text, or Typst math. Unknown names do nothing. For aliases, pass either the original unit spelling or its current alias.

For a single name, include the trailing comma: `("x",)` is a one-item array, while `("x")` is just a string. Wrap math names in `$...$`. Subscripted variables can be selected using their math form or their stored name:

```typ
#let eq = calculation-builder()
#eq($v_"max" := 30 m/s$)

#reset(variables: ($v_"max"$,))
// Remove the stored maximum speed.
// The equivalent string form is:
// #reset(variables: ("v_max",))
```

See the [calculation-builder documentation](calculation-builder.md) for how math names map to stored names.

`false` and empty arrays select nothing. `auto` is the default for omitted options. If every option is `auto`, the call clears the complete state, including `initial-state`, functions, unloaded names, and aliases, and restores the standard constants. Otherwise, only explicit selections take effect. Thus `reset(variables: ())` and `reset(variables: false)` leave everything unchanged.

Multiple selections run in this order: variables, functions, units, aliases. Restoring a unit name takes precedence over preserving a variable under that name. Focused resets retain the builder's initial values for later variable resets; only a full reset discards them.

`key` must match the associated builder. Its default matches a builder created without an explicit key. Positional names such as `reset("x")` are not accepted; select a category explicitly.

## Example

```typ
#let eq = calculation-builder(initial-state: (factor: 2))
#eq(`x := factor * 5 m`)
#eq(`factor := 9`)

#reset(variables: ("x",))
// x is removed; factor is still 9

#reset(variables: true)
// factor returns to 2; functions and unit settings remain

#reset(functions: ("f",), units: ("m", "pi"))
// remove f and restore unloaded m and pi, if present

#reset()
// also discard initial-state and restore all unit settings
```

Use a matching key for a custom builder:

```typ
#let eq = calculation-builder(key: "geometry")
#eq(`height := 10 m`)
#reset(variables: ("height",), key: "geometry")
```

## Migration from the old API

The focused reset functions have been removed. Replace them with explicit selections:

| Existing call | Recommended call |
| --- | --- |
| `reset-variables()` | `reset(variables: true)` |
| `reset-variables("x", "y")` | `reset(variables: ("x", "y"))` |
| `reset-functions("f")` | `reset(functions: ("f",))` |
| `restore-units("m", "pi")` | `reset(units: ("m", "pi"))` |
| `reset-unit-aliases("v")` | `reset(aliases: ("v",))` |

An old focused call with no names resets its whole category, so use `true`, not an empty array, when migrating it. Pass the same `key` to either form.
