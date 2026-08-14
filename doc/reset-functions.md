# `reset-functions`

Clears stored scalar or vector function definitions without changing stored
values or unit configuration.

## Import

```typ
#import "math-once.typ": calculation-builder, reset-functions
```

## Signature

```typ
reset-functions(..names, key: "math-once-calculation") -> content
```

## Example

```typ
#let eq = calculation-builder()
#eq($f(x) := x + 1$)
#eq($g(x) := x * 2$)

#reset-functions("f")
// g remains stored

#reset-functions()
// every stored function is removed
```

With selected names, only matching functions are removed. With no names, all
stored functions are removed. Values, unloaded unit names, and aliases remain
unchanged. If a function replaced a name from `initial-state`, removing that
function restores the initial value.

The optional `key` must match the associated builder.
