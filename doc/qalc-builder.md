# `qalc-builder`

Creates a stateful, eqrun-style calculator. Assignments store their complete
unit-aware results, and later equations visibly substitute stored values.

## Example

```typ
#import "math-once.typ": qalc-builder

#let eq = qalc-builder(digits: 2)

#eq($v = 902 / 3.6$)
// v = 902/3.6 = 250.56

#eq($a = v * 2$)
// a = v ⋅ 2 = 250.56 ⋅ 2 = 501.11
```

Calculations use the unrounded stored value. This avoids accumulating rounding
errors even though the substituted step shows the rounded value.

## Signature

```typ
qalc-builder(
  initial-state: (:),
  key: "math-once-qalc",
  digits: 4,
  block: true,
) -> function
```

## Parameters

### `initial-state`

`dictionary` — optional, named — default: `(:)`

Numbers or existing `qalc` results available before the first equation.

```typ
#let eq = qalc-builder(
  initial-state: (factor: 2),
  key: "initial-state-example",
)
#eq(`a = factor * 3`)
```

### `key`

`str` — optional, named — default: `"math-once-qalc"`

The key used for Typst state. Give each independent runner a unique key.

```typ
#let first = qalc-builder(key: "first-calculator")
#let second = qalc-builder(key: "second-calculator")
```

### `digits`

`int` — optional, named — default: `4`

The default number of displayed decimal places for runner calls. A call can
override it.

```typ
#let eq = qalc-builder(key: "rounding-example", digits: 2)
#eq(`x = 1 / 3`)
#eq(`y = x * 2`, digits: 4)
```

### `block`

`bool` — optional, named — default: `true`

Whether runner output is a centered block equation by default. A call can
override it with `block: false`.

```typ
#let eq = qalc-builder(key: "inline-example", block: false)
Inline: #eq(`x = 2 + 2`).
```

## Returned runner

`qalc-builder` returns a function with this interface:

```typ
runner(
  [source],
  digits: builder-digits,
  unit: none,
  block: builder-block,
) -> content or dictionary
```

### `source`

`str` or `raw` or math `content` — optional, positional

An expression or assignment. A top-level `name = expression` stores the
result under `name`. A call without an assignment calculates and displays a
result without storing a new variable.

```typ
#let eq = qalc-builder(key: "source-example")
#eq($v = 10 m/s$)
#eq($d = v * 2 s$)
#eq(`1 m/s to km/h`)
```

Multi-letter names inside Typst math must be quoted. Raw input does not need
the quotes.

```typ
#eq(`speed = 10 m/s`)
#eq($"speed" = 10 m/s$)
```

### `digits`

`int` — optional, named

Overrides the builder's `digits` value for this call.

### `unit`

`str` or `raw` or `none` — optional, named — default: `none`

Requests an output unit for this call. It behaves like the `unit` parameter of
[`qalc`](qalc.md#unit).

```typ
#let eq = qalc-builder(key: "unit-example")
#eq(`v = 10 m/s`, unit: `km/h`, digits: 1)
// v = 10 m/s = 36 km/h
```

### `block`

`bool` — optional, named

Overrides the builder's `block` value for this call.

## Reading stored variables

Call the runner without `source` inside a `context` block to retrieve the
state dictionary. Each assigned value is a complete [`qalc`](qalc.md) result
with an additional `variable` field.

```typ
#let eq = qalc-builder(key: "state-example", digits: 2)
#eq($v = 902 / 3.6$)

#context {
  let variables = eq()
  [Rounded: #variables.v.value]
  [Exact: #variables.v.exact]
}
```

Stored dimensioned variables include their unit in the visible substitution:

```typ
#let eq = qalc-builder(key: "dimensioned-example", digits: 2)
#eq($v = 10 m/s + 1 "km"/h$)
#eq($d = v * 2 s$, digits: 3)
// d = v ⋅ 2 s = 10.28 m/s ⋅ 2 s = 20.556 m
```
