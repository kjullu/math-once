# `calculate`

Evaluates a trusted Typst numerical expression and optionally appends a
display-only unit label. Use [`qalc`](qalc.md) when units must participate in
the calculation.

> **Security:** `calculate` uses unrestricted Typst `eval`. Only pass source
> that you trust.

## Example

```typ
#import "math-once.typ": calculate

#let result = calculate(`902 / 3.6`, digits: 2, unit: `m/s`)
#result.display
// 902/3.6 = 250.56 m/s

The exact value is #result.exact.
```

## Signature

```typ
calculate(
  source,
  digits: 0,
  scope: (:),
  unit: none,
  block: false,
) -> dictionary
```

## Parameters

### `source`

`str` or `raw` — required, positional

A trusted Typst code expression that evaluates to an integer, float, or
decimal.

```typ
#calculate(`902 / 3.6`).display
#calculate("81 / 9").display
```

### `digits`

`int` — optional, named — default: `0`

The number of decimal places used for `result.value` and the rendered result.
It does not change `result.exact`.

```typ
#calculate(`1 / 3`, digits: 3).display
// 1/3 = 0.333
```

### `scope`

`dictionary` — optional, named — default: `(:)`

Values available to the evaluated expression. Earlier `calculate` results are
automatically unwrapped to their exact value.

```typ
#let a = calculate(`902 / 3.6`, digits: 2)
#let b = calculate(`a * 2`, scope: (a: a), digits: 2)
#b.display
```

### `unit`

`str` or `raw` or math `content` or `content` or `none` — optional, named —
default: `none`

A label appended to the visible result. It is not parsed, converted, or used
in the calculation.

```typ
#calculate(`250`, unit: `m/s`).display
#calculate(`250`, unit: $m/s$).display
```

### `block`

`bool` — optional, named — default: `false`

Whether `result.display` is a centered block equation.

```typ
#calculate(`2 + 2`, block: true).display
Inline: #calculate(`2 + 2`, block: false).display.
```

## Result

Returns a dictionary with these fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `display` | math content | The rendered expression and result. |
| `value` | number | The rounded result. |
| `exact` | number | The unrounded result used when reused through `scope`. |
| `source` | `str` | The normalized Typst source expression. |
| `unit` | any accepted unit value | The original display-only unit value. |

Unlike `qalc`, `calculate` does not store dimensions. For example, a label of
`m/s` is carried to the output but has no mathematical meaning to the
evaluator.
