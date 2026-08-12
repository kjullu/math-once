# `calculation-builder`

Creates a stateful equation calculator. Definitions written with `:=` store
their complete unit-aware results. A plain `=` only displays an equation, and
later expressions visibly substitute values stored by `:=`.

## Example

```typ
#import "math-once.typ": calculation-builder, text-unit

#let eq = calculation-builder(digits: 2)

#eq($v := 902 / 3.6$)
// v = 902/3.6 = 250.56

#eq($v * 2$)
// v ⋅ 2 = 250.56 ⋅ 2 = 501.11
```

Calculations use the unrounded stored value. This avoids accumulating rounding
errors even though the substituted step shows the rounded value.

A direct definition is not repeated when its right-hand side already equals
the calculated result. Calculated definitions show their useful result while
also storing the exact value:

```typ
#eq($v := 10 m/s$)
// v = 10 m/s

#eq($x := v * 2$)
// x = v ⋅ 2 = 10 m/s ⋅ 2 = 20 m/s

#eq($y := 1 + 1$)
// y = 1 + 1 = 2
```

Use a plain equals sign for a display-only equation. It neither evaluates nor
stores its left-hand name:

```typ
#eq($x = 1 + 1$)
// x = 1 + 1

#eq($x + 1$)
// red: math-once: x is not set.
```

## Signature

```typ
calculation-builder(
  initial-state: (:),
  key: "math-once-calculation",
  digits: 4,
  block: true,
  supplement: auto,
) -> function
```

## Parameters

### `initial-state`

`dictionary` — optional, named — default: `(:)`

Numbers or existing `calculate` results available before the first equation.
Unit names are reserved and cannot be used as keys.

```typ
#let eq = calculation-builder(
  initial-state: (factor: 2),
  key: "initial-state-example",
)
#eq(`x := factor * 3`)
```

### `key`

`str` — optional, named — default: `"math-once-calculation"`

The key used for Typst state. Give each independent runner a unique key.

```typ
#let first = calculation-builder(key: "first-calculator")
#let second = calculation-builder(key: "second-calculator")
```

### `digits`

`int` — optional, named — default: `4`

The default number of displayed decimal places for runner calls. A call can
override it.

```typ
#let eq = calculation-builder(key: "rounding-example", digits: 2)
#eq(`x := 1 / 3`)
#eq(`y := x * 2`, digits: 4)
```

### `block`

`bool` — optional, named — default: `true`

Whether runner output is a centered block equation by default. A call can
override it with `block: false`.

```typ
#let eq = calculation-builder(key: "inline-example", block: false)
Inline: #eq(`x := 2 + 2`).
```

### `supplement`

`auto` or `content` or `function` or `none` — optional, named — default: `auto`

Sets the name placed before references and captions created by this builder.
`auto` inherits the active equation supplement. This is useful for changing
language or giving one family of calculations its own name.

```typ
#let eq = calculation-builder(
  key: "english-equations",
  supplement: [Equation],
)
```

## Returned runner

`calculation-builder` returns a function with this interface:

```typ
runner(
  [source],
  digits: builder-digits,
  unit: none,
  size: none,
  show-result: true,
  block: builder-block,
  label: none,
  caption: none,
  gap: 0.65em,
  supplement: builder-supplement,
) -> content or dictionary
```

### `source`

`str` or `raw` or math `content` — optional, positional

An expression, display equation, or stored definition. A top-level
`name := expression` stores the result under `name`; `name = expression` only
renders the equation. A call without either form calculates and displays a
result without storing a new variable. Unset variables produce a red message.

### `show-result`

`bool` — optional, named — default: `true`

Controls whether a stored `:=` definition also shows substituted values and
its calculated result. With `false`, the exact value is still calculated,
stored, and available to later equations; only the written definition is
shown.

```typ
#let eq = calculation-builder(key: "quiet-definition", digits: 12)
#eq($lambda := 530 * 10^(-9)$, show-result: false)
// λ = 530 ⋅ 10^(-9)

#eq($lambda * 2$)
// λ ⋅ 2 = 0.00000053 ⋅ 2 = 0.00000106
```

```typ
#let eq = calculation-builder(key: "source-example")
#eq($v := 10 m/s$)
#eq($x := v * 2 s$)
#eq(`1 m/s to km/h`)
```

Multi-letter names inside Typst math must be quoted. Raw input does not need
the quotes.

```typ
#eq(`speed := 10 m/s`)
#eq($"speed" := 10 m/s$)
```

Greek mathematical names are supported directly. Typst displays the symbol,
while the stored dictionary uses its readable ASCII name:

```typ
#let eq = calculation-builder(key: "greek-variable-example")

#eq($lambda := 530 m$)
// λ = 530 m

#eq($x := 2 lambda$)
// x = 2λ

#eq($x$)
// x = 1060 m

#context {
  let variables = eq()
  [Wavelength: #variables.lambda.value #variables.lambda.unit]
}
```

The common lowercase Greek names are available, along with the distinct
uppercase Greek symbols. Examples include `alpha`, `beta`, `theta`, `lambda`,
`pi`, `sigma`, `phi`, `psi`, and `omega`.

Variables can also have letter or number subscripts. The complete name,
including its underscore, becomes the state dictionary key:

```typ
#let eq = calculation-builder(key: "subscript-example")

#eq($theta_m := 15$)
#eq($lambda_0 := 530 m$)
#eq($x := 2 lambda_0$)

#context {
  let variables = eq()
  [#variables.at("theta_m").value]
  [#variables.at("lambda_0").value]
}
```

Raw input uses the same underscore syntax, for example
`` `speed_max := 20 m/s` ``. Subscripts are intentionally limited to letters
and digits so they remain unambiguous reusable variable names.

`degree` can be used with a subscripted angle and is displayed as `°` in Typst
math:

```typ
#eq($theta_m := 15.0 degree$)
// θ_m = 15.0°

#eq($x := theta_m * 2$)
// x = θ_m ⋅ 2
```

Unit names are reserved and cannot be assigned as variables. This keeps an
expression such as `1 m + 25 cm` unambiguous. For example, `#eq($m := 1$)`
prints a red, centered message and does not store the variable because `m` is
the metre unit. Choose another name such as `n` or use `order` in raw input.

## Trigonometric calculations

`sin`, `cos`, and `tan` accept parenthesized angles. Bare numbers are treated
as degrees, matching the common calculator convention. Explicit `deg`, `°`,
`degree`, and `rad` units are also supported.

```typ
#let eq = calculation-builder(key: "diffraction", digits: 9)

#eq($lambda := 530 "nm"$)
#eq($n := 1$)
#eq($theta_1 := 15.0$)
#eq($x := (n * lambda) / (sin(theta_1))$)
// x = (n ⋅ λ) / sin(θ_1)

#eq($x$)
// x = 2.047762752 µm
```

Typst math requires quotes around multi-letter units such as `"nm"`. Raw input
can instead be written without quotes: `` `lambda := 530 nm` ``.

Microscopic SI lengths automatically select a readable engineering prefix, so
a result of roughly `2047.76 nm` is displayed as roughly `2.04776 µm`.

### `digits`

`int` — optional, named

Overrides the builder's `digits` value for this call.

### `unit`

`str` or `raw` or math `content` or `none` — optional, named — default: `none`

Requests an output unit for this call. It behaves like the `unit` parameter of
[`calculate`](calculate.md#unit).

```typ
#let eq = calculation-builder(key: "unit-example")
#eq(`v := 10 m/s`, unit: `km/h`, digits: 1)
// v = 10 m/s; the stored value is 36 km/h

#eq($x := 902 / 3.6$, unit: $m/s$, digits: 2)
// x = 902/3.6; the stored value is 250.56 m/s
```

Use `text-unit` inside a math unit for symbolic count labels,
for example `unit: $#text-unit("linjer")/m$`. Known quoted unit names retain their catalog
meaning. See [Custom output labels](units.md#custom-output-labels).

### `size`

`int` or `float` or `decimal` or string/raw/math `content` or `none` — optional,
named — default: `none`

Selects the SI scale used for the displayed result. Wrap exponent notation in
Typst math, so `$10^(-6)$` requests millionths of the SI unit. For lengths,
familiar scales use their normal prefix.

```typ
#let eq = calculation-builder(key: "size-example", digits: 9)
#eq($lambda := 530 "nm"$)
#eq($n := 1$)
#eq($theta_1 := 15 degree$)
#eq($x := (n * lambda) / sin(theta_1)$, size: $10^(-6)$)
// x = (n ⋅ λ) / sin(θ_1); the stored value is 2.047762752 µm
```

The exact `si-value` is unchanged and is used by later calculations. `size`
must be positive. It can be combined with the named `unit:` parameter; in that
case it scales the requested unit:

```typ
#eq($"distance" := 1 "cm" + 2 "cm"$, unit: $m$, size: 0.01)
// distance = 1 cm + 2 cm; the stored value is 3 cm

#eq($"distance"$, unit: $m$, size: 1)
// distance = 0.03 m
```

Use `unit:` when combining both controls. `size:` cannot be combined with
`to` or an output `=` inside the expression, and it cannot scale affine output
units such as Celsius.
Bare `10^(-6)` is not valid in Typst code; use `$10^(-6)$`, `` `10^(-6)` ``,
`"10^(-6)"`, or `calc.pow(10, -6)`.

### `block`

`bool` — optional, named

Overrides the builder's `block` value for this call.

### `label`

`label` or `none` — optional, named — default: `none`

Attaches a Typst label directly to the generated equation so it can be
referenced. It is an alternative to the more natural postfix syntax.

```typ
#import "math-once.typ": calculation-builder, number-labelled-equations

#show: number-labelled-equations.with(supplement: [Ligning])
#let eq = calculation-builder(key: "label-example")

#eq($v := 10 m/s$) <speed>

// Equivalent:
#eq($x := 20 m/s$, label: <other-speed>)

Se @speed.
```

### `caption`

`content` or `str` or `none` — optional, named — default: `none`

Places a caption directly below this calculation, like the named `caption`
argument of a Typst figure. The calculation must be a block equation. A postfix
label still attaches to the generated equation and can be referenced normally.

```typ
#import "math-once.typ": calculation-builder, number-labelled-equations

#show: number-labelled-equations.with(supplement: [Ligning])
#let eq = calculation-builder(key: "caption-example")

#eq(
  $v := 10 m/s$,
  caption: [Den valgte begyndelseshastighed],
) <speed>

Se @speed.
```

The older central [`captions` dictionary](number-labelled-equations.md#captions)
is retained for compatibility.

### `gap`

`relative` — optional, named — default: `0.65em`

Controls the vertical distance between this calculation and its caption.

```typ
#let eq = calculation-builder(key: "caption-gap-example")
#eq(`x := 2 + 2`, caption: [A compact caption], gap: 0.3em)
```

### `supplement` override

`auto` or `content` or `function` or `none` — optional, named

Overrides the builder's `supplement` for one calculation.

```typ
#let eq = calculation-builder(key: "mixed-supplements")
#eq(
  `x = 2 + 2`,
  caption: [A named formula],
  supplement: [Formula],
) <formula>
```

## Reading stored variables

Call the runner without `source` inside a `context` block to retrieve the
state dictionary. Each assigned value is a complete [`calculate`](calculate.md) result
with an additional `variable` field.

```typ
#let eq = calculation-builder(key: "state-example", digits: 2)
#eq($v := 902 / 3.6$)

#context {
  let variables = eq()
  [Rounded: #variables.v.value]
  [Exact: #variables.v.exact]
}
```

Stored dimensioned variables include their unit in the visible substitution:

```typ
#let eq = calculation-builder(key: "dimensioned-example", digits: 2)
#eq($v := 10 m/s + 1 "km"/h$)
#eq($x := v * 2 s$, digits: 3)
#eq($x$)
// x = 20.556 m
```

Use [`reset`](reset.md) with the same state `key` to remove selected variables
or clear the complete builder state.

Use [`unload`](unload.md) before a definition when a reserved unit spelling
must temporarily be used as a variable name.

## Error feedback

Common calculation errors are rendered as centered red messages without
stopping the rest of the document. These include unset variables, reserved
variable names, incompatible addition and conversion, division by zero,
invalid trigonometric arguments or unit powers, common `size` mistakes,
conflicting output options, and unbalanced parentheses.

```typ
#let eq = calculation-builder(key: "error-example")

#eq(`1 m + 2 s`)
// red: math-once: cannot add length and time.

#eq(`1 / 0`)
// red: math-once: cannot divide by zero.
```

A failed `:=` definition is not stored. A later expression that uses its name
therefore reports that the variable is not set. Direct [`calculate`](calculate.md)
calls remain strict and panic on invalid input, which is useful when their
return values are consumed programmatically.
