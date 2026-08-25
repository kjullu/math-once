# `calculation-builder`

Creates a stateful equation calculator. Definitions written with `:=` store
their complete unit-aware results. A simple `name = expression` calculates and
displays its result without storing `name`, and later expressions visibly
substitute values stored by `:=`.

## Example

```typ
#import "math-once.typ": calculation-builder, unload, text-unit

#let eq = calculation-builder(digits: 2)

#eq($v := 902 / 3.6$)
// v = 902/3.6 = 250.56

#eq($v * 2$)
// v ⋅ 2 = 250.56 ⋅ 2 = 501.11
```

Calculations use the unrounded stored value. This avoids accumulating rounding
errors even though the substituted step shows the rounded value.

Euler's number `e` and the circle constant `pi` are available by default and
use Typst's `calc.e` and `calc.pi` values:

```typ
#eq($"growth" := e^2$)
#eq($"circumference" := 2 pi r$)
```

Their names are reserved so they cannot be replaced accidentally. To reuse
either spelling as an ordinary variable, unload it first:

```typ
#unload("e", "pi")
#eq($e := 3$)
#eq($pi := 4$)
```

[`restore-units`](restore-units.md) restores their standard values, as does a
complete [`reset`](reset.md). Built-in constants are omitted from the
dictionary returned by `eq()` so it continues to contain user results only.

Very large values (`>= 10^9`) and very small nonzero values (`< 10^(-4)`) are
shown in scientific notation when substituted or rendered as results. Their
stored exact values are unchanged. For example, a stored mass of
`1.989 * 10^30 kg` is substituted as $1.989 dot 10^30 "kg"$ instead of a long
decimal expansion.

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

Use a plain equals sign to calculate without storing the left-hand name:

```typ
#eq($x = 1 + 1$)
// x = 1 + 1 = 2

#eq($x + 1$)
// red: math-once: x is not set.
```

Only a simple variable name on the left enables this calculation. General
symbolic equations such as `$f(x) = x + 1$` remain display-only. A simple
equation whose right-hand side contains unknown names also remains symbolic
instead of producing an unset-variable error.

## Symbolic calculations

For the complete guide, see
[Symbolic calculations](symbolic-calculations.md). The short version is that
CAS calls use the same `:=` storage and `=` non-storage rules as numeric
calculations.

The builder recognizes these top-level CAS operations:

```text
simplify(expression)
diff(expression, variable)
integrate(expression, variable)
solve(expression, variable)
solve(left, right, variable)
factor(expression[, variable])
limit(expression, variable, target)
taylor(expression, variable, center, order)
```

They are powered by the pinned MIT-licensed
[typCAS](https://github.com/sihooleebd/typCAS) package. Use `:=` to store the
symbolic result just like a numeric result. The stored expression tree can be
passed to a later operation:

```typ
#let eq = calculation-builder(key: "symbolic-example")

#eq(`f := simplify(x^2 + 2*x + 1)`)
// f = simplify(x² + 2x + 1) = x² + 2x + 1

#eq(`df := diff(f, x)`)
// df = diff(f, x) = 2x + 2

#eq(`roots := solve(x^2 - 4, x)`)
// roots = solve(x² - 4, x) = 2, -2
```

Unknown names such as `x` stay symbolic. Existing stored, dimensionless
numeric values are substituted before the CAS operation. Values with physical
or custom units remain the responsibility of the unit-aware evaluator and
produce a red inline error if referenced by a CAS operation. `unit:` and
`size:` are therefore not accepted for symbolic calls.

A solved root set is stored with `symbolic-kind: "roots"`; it cannot be reused
where one expression is required. Other operations store
`symbolic-kind: "expression"` and an `expression` AST. Advanced code can use
that AST with typCAS directly:

```typ
#import "@preview/typcas:0.2.3": cas

#context {
  let derivative = eq().df.expression
  let evaluated = cas.eval(derivative, bindings: (x: 2))
  assert(cas.value-of(evaluated) == 6)
}
```

Plain `$...$` CAS input with unquoted multi-letter names does not work because
Typst evaluates those identifiers before the builder receives the content.
Use raw input or a string instead:

```typ
#eq(`identity := simplify(sin(x)^2 + cos(x)^2)`)
#eq("identity := simplify(sin(x)^2 + cos(x)^2)")
```

Alternatively, `$...$` works when both multi-letter variable names and CAS
operation names are quoted:

```typ
#eq($"identity" := "simplify"(sin(x)^2 + cos(x)^2)$)
```

## Paired plus/minus signs

Typst's `plus.minus` ($plus.minus$) and `minus.plus` ($minus.plus$) symbols are
evaluated as two correlated branches when their operands are known:

```typ
#eq($10 plus.minus 2$)
// 10 ± 2 = 12 ∨ 8

#eq($x = 10 plus.minus 2$)
// x = 10 ± 2 = 12 ∨ 8

#eq(`result = alpha plus.minus beta minus.plus gamma`)
// remains symbolic because alpha, beta, and gamma are unknown
```

Raw and string input accept both the spelled forms and the Unicode `±` and `∓`
characters. The signs remain paired: the upper branch of
`alpha ± beta ∓ gamma` is `alpha + beta - gamma`, and the lower branch is
`alpha - beta + gamma`.

The two calculated values are separated by Typst's logical-or symbol `∨`.
Units, conversions, precedence, and stored scalar operands are applied to both
branches independently. Expressions with unknown operands remain symbolic.

The result cannot be stored with `:=`, because an ordinary math-once variable
contains one scalar value. Use a plain `=` when you want a label without
storing it.

## Other mathematical symbols

The builder also preserves Typst's other mathematical symbols in display-only
equations. This covers relations, set operators, calculus, logic, geometry,
arrows, and symbol variants:

```typ
#eq($A subset.eq B$)
#eq($f: A arrow.r B$)
#eq(`x eq.not infinity`)
#eq("p = q arrow.r r")
```

Named symbols, their Unicode characters, and symbols already parsed inside
`$...$` are accepted. Ordinary `+`, `-`, multiplication, division, and powers
keep their numeric meaning. Other symbols are deliberately display-only:
math-once can typeset `x ∈ A` or `f → g`, but does not pretend that a relation,
integral sign, or arrow is one number that can be stored with `:=`.

Typst resolves `$...$` symbol names to glyphs before math-once receives them.
When two names share the same glyph, that original distinction is therefore
unavailable. In particular, `ast.op` and `convolve` both resolve to `∗`, which
math-once already accepts as multiplication in `$...$`. Use raw or string input
to preserve the display-only `convolve` name:

```typ
#eq(`f = a convolve b`)
```

## Signature

```typ
calculation-builder(
  initial-state: (:),
  key: "math-once-calculation",
  digits: 4,
  block: auto,
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

`auto` or `bool` — optional, named — default: `auto`

With `auto`, the runner follows Typst's own math layout: compact `$1 + 1$`
input produces an inline equation, while spaced `$ 1 + 1 $` input or math
delimiters on separate lines produce a centered block equation. Raw and string
input remain centered by default because they do not carry Typst layout
metadata.

Content in other arguments does not affect that choice. For example,
`unit: $#text-unit("lines") / m$` can be compact while a spaced source such as
`$ 1 / d $` remains a centered block equation.

Set a boolean on the builder to force one layout by default. An individual
call can still override it:

```typ
#let eq = calculation-builder(key: "inline-example", block: false)
Inline: #eq(`x := 2 + 2`).

#let automatic = calculation-builder(key: "automatic-layout")
Inline: #automatic($1 + 1$).

#automatic($ 1 + 1 $)
// centered, like Typst's own spaced math syntax

Inline CAS: #automatic(`diff(f, x)`, block: false)
// raw input has no $...$ metadata, so use an explicit override for inline CAS
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
  result-only: false,
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
`name := expression` stores the result under `name`; a simple
`name = expression` calculates without storing it. A call without either form
calculates and displays a result without storing a new variable. Unset
variables produce a red message.

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

### `result-only`

`bool` — optional, named — default: `false`

Shows only the final calculated value, without repeating the variable or the
expression. The calculation still uses the stored exact value, units,
conversion, rounding, and scientific-notation rules:

```typ
#let eq = calculation-builder(key: "conclusion-example", digits: 4)
#eq($v_0 := 11.1822 "km"/s$)

The minimum evasion velocity is: #eq($v_0$, result-only: true)
// The minimum evasion velocity is: 11.1822 km/s
```

`result-only: true` is inline by default because it is intended for inserting
a result into prose. This also makes raw/CAS results compact even though raw
input has no `$...$` layout metadata. Pass `block: true` explicitly to center
the result instead.

It also works for an expression or a paired result:

```typ
#eq($v_0 * 2$, result-only: true)
// 22.3644 km/s

#eq($10 plus.minus 2$, result-only: true)
// 12 ∨ 8
```

An unset or display-only symbolic expression has no calculated result and
therefore produces a focused inline error with `result-only: true`.

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

Unknown quoted names are stored as opaque custom units. Matching custom units
support ordinary arithmetic, but they cannot be converted to catalog units.
See [Custom units](units.md#custom-units).

## Functions

Use `:=` to store a function. An ordinary `=` only displays it:

```typ
#let eq = calculation-builder(key: "function-example", digits: 2)

#eq($f(x) := x + 1$)
#eq($f(2)$)
// f(2) = ((2) + 1) = 3

#eq($h(x, y) := x * y + 1$)
#eq($h(3, 4)$)
// h(3, 4) = ((3) ⋅ (4) + 1) = 13
```

Function bodies use the same arithmetic, units, variables, trigonometric
functions, and rounding functions as other builder expressions. `floor`
rounds down, `ceil` rounds up, and `round` selects the nearest integer. They
preserve the input unit:

```typ
#eq(`down := floor(3.7)`)
// down = floor(3.7) = 3

#eq(`up := ceil(3.2)`)
// up = ceil(3.2) = 4

#eq(`length := floor(3.7 cm)`)
// length = floor(3.7 cm) = 3 cm
```

The same functions work inside `$...$` math:

```typ
#eq($floor(3.7)$) // ⌊3.7⌋ = 3
#eq($ceil(3.2)$)  // ⌈3.2⌉ = 4
#eq($round(3.5)$) // ⌊3.5⌉ = 4
```

`abs(expression)` and balanced scalar bars calculate absolute values while
preserving units:

```typ
#eq($T_0 := 286.15 K$)
#eq($T_3 := 316.15 K$)
#eq($T_Delta := |T_0 - T_3|$)
// T_Δ = |T_0 - T_3| = 30 K

#eq(`length := abs(-3 cm)`)
// length = |-3 cm| = 3 cm
```

Other uses of `|`, including infix and non-numeric notation, remain
display-only.

Arguments to stored functions are substituted before the normal unit-aware
calculation:

```typ
#eq($u(x) := x * 2 m$)
#eq($u(3)$)
// u(3) = ((3) ⋅ 2 m) = 6 m
```

## Vectors, arrow names, and matrices

Import `matrix` with `calculation-builder` when you want the readable `matrix(...)` spelling. It is an alias for Typst's built-in `mat(...)`, and math-once understands both forms:

```typ
#import "math-once.typ": calculation-builder, matrix

#let eq = calculation-builder()

#eq($arrow(v) := vec(1, 2)$)
#eq($arrow(w) := vec(3, 4)$)
#eq($arrow(q) := arrow(v) + arrow(w)$)
// q⃗ = v⃗ + w⃗ = vec(4, 6)

#eq($X := matrix(1, 2; 3, 4)$)
#eq($Y := mat(5, 6; 7, 8)$)
#eq($Z := X + Y$)
// Z = X + Y = mat(6, 8; 10, 12)

#eq($X arrow(v)$)
// Xv⃗ = vec(5, 11)

#eq($X Y$)
// XY = mat(19, 22; 43, 50)
```

`arrow(v)` changes how the stored name is drawn; its state key is `arrow_v`. `vec(...)` creates the vector value. Matrix rows are separated by semicolons and cells by commas, matching Typst's native matrix syntax.

The builder supports vector or matrix addition and subtraction with matching shapes, scalar multiplication, division of a vector or matrix by a scalar, matrix multiplication, matrix–vector multiplication, and row-vector–matrix multiplication. `vector * vector` is rejected because it is ambiguous between a dot product, an outer product, and component-wise multiplication.

Components and cells are calculated independently and may contain compatible physical or custom units. A whole vector or matrix cannot receive one `unit:` or `size:` option; put units in the individual component or cell expressions.

Stored functions may return either structure:

```typ
#eq($arrow(s)(t) := vec(t^3 - 3t^2 - 4t + 12, t^2 - 4)$)
#eq($arrow(s)(2)$)
// s⃗(2) = vec(0, 0)

#eq($D(t) := matrix(t, 0; 0, t)$)
#eq($D(3)$)
// D(3) = mat(3, 0; 0, 3)
```

Calling a function with the wrong number of arguments produces a red inline error.

Built-in square and indexed roots can be calculated and stored in the same
way. The indexed form follows Typst's `root(index, radicand)` order:

```typ
#eq($sqrt(5)$)
// √5 = 2.2361

#eq($root(5, 3)$)
// ⁵√3 = 1.2457

#eq($x := sqrt(9 m^2)$)
// x = √(9 m²) = 3 m
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
`` `speed_max := 20 m/s` ``. Typst text subscripts work too. Quotes let a
multi-letter subscript stay upright in math while the stored key remains
plain:

```typ
#unload("d") // d is the day unit until unloaded
#eq($d := 10 "mm"$)
#eq($lambda := 2 "mm"$)
#eq($n_"maks" := d / lambda$)

#context assert(eq().at("n_maks").exact == 5)
```

Subscripts are intentionally limited to letters and digits so they remain
unambiguous reusable variable names.

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

Power-of-ten scales remain scientific with either automatic or requested
units. A compound scale preserves its written factor while still being
evaluated numerically:

```typ
#eq($force := 3.5439 * 10^22 N$, size: $10^22$)
// force = 3.5439 ⋅ 10²² N

#eq($other := 6000 N$, size: $2 * 10^3$)
// other = 3 ⋅ (2 ⋅ 10³) N
```

Use `unit:` when combining both controls. `size:` cannot be combined with
`to` or an output `=` inside the expression, and it cannot scale affine output
units such as Celsius.
Bare `10^(-6)` is not valid in Typst code; use `$10^(-6)$`, `` `10^(-6)` ``,
`"10^(-6)"`, or `calc.pow(10, -6)`.

### `block`

`auto` or `bool` — optional, named

Overrides the builder's `block` value for this call. `auto` follows math input
layout and centers raw/string input; `true` and `false` force block or inline
layout.

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
  $ v := 10 m/s $,
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
