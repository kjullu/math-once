# `equation`

Adds a caption directly to an ordinary Typst equation. Its call shape follows
Typst's `figure` function: the body is positional and `caption` is named.

The wrapper returns a real `math.equation`, not a figure. This lets native and
calculated equations share the same equation counter and keeps postfix labels
referenceable.

## Example

```typ
#import "math-once.typ": equation, number-labelled-equations

#show: number-labelled-equations.with(supplement: [Ligning])

#equation(
  $ E = m c^2 $,
  caption: [Sammenhængen mellem masse og energi],
) <energy>

Som vist i @energy kan masse omdannes til energi.
```

The equation is numbered because it has a label. Without `<energy>`, it still
has its caption but receives no number under `number-labelled-equations`.

## Signature

```typ
equation(
  body,
  caption: none,
  gap: 0.65em,
) -> content
```

## Parameters

### `body`

math `content` — required, positional

The native Typst equation to display. Pass `$ ... $`, including the dollar
signs, as the first argument.

```typ
#import "math-once.typ": equation

#equation($ a^2 + b^2 = c^2 $)
```

### `caption`

`content` or `str` or `none` — optional, named — default: `none`

Caption content centered below the equation in normal text style. Captions
require a block equation.

```typ
#equation(
  $ F = m a $,
  caption: [Newtons anden lov],
)
```

### `gap`

`relative` — optional, named — default: `0.65em`

The vertical distance between the formula and caption.

```typ
#equation(
  $ p = m v $,
  caption: [Definitionen af impuls],
  gap: 0.3em,
)
```

## Labels and references

Write the label after the complete function call, just as a label is written
after a native equation. Use `@label` to reference it.

```typ
#import "math-once.typ": equation, number-labelled-equations
#show: number-labelled-equations

#equation($ E_k = 1/2 m v^2 $, caption: [Kinetisk energi]) <kinetic>

Se @kinetic.
```

For stateful calculations, use the same `caption:` and `gap:` arguments
directly on a [`calculation-builder`](calculation-builder.md#caption) runner.
