# `number-labelled-equations`

Numbers block equations only when they have a label. Labelled equations can be
referenced normally with Typst's `@label` syntax; unlabelled equations have no
number and do not advance the equation counter.

## Example

```typ
#import "math-once.typ": equation, number-labelled-equations

#show: number-labelled-equations.with(supplement: [Ligning])

// No label: no name or number.
$ 1 + 1 = 2 $

// Label: receives number (1) and can have a per-equation caption.
#equation(
  $ E = m c^2 $,
  caption: [Sammenhængen mellem masse og energi],
) <energy>

// Visible caption: Ligning 1: Sammenhængen mellem masse og energi

Som vist i @energy kan masse omdannes til energi.
// Som vist i Ligning 1 ...
```

The function styles the original equation elements instead of replacing them.
This is important because replacing a labelled equation in a show rule can
break Typst's reference target.

It also works with equations returned by `calculate` and `calculation-builder`:

```typ
#import "math-once.typ": calculation-builder, number-labelled-equations

#show: number-labelled-equations.with(supplement: [Ligning])
#let eq = calculation-builder(digits: 2)

#eq(
  $ v := 902 / 3.6 $,
  unit: $m/s$,
  caption: [Den beregnede hastighed],
) <speed>
#eq($x := v * 2$)

Hastigheden er beregnet i @speed.
```

Only the first equation is numbered because only it has a label. Its caption is
declared beside that equation, in the same style as Typst's `figure` calls.
`calculation-builder` also accepts `label: <speed>` as an alternative to the
postfix label.

## Signature

```typ
number-labelled-equations(
  body,
  numbering: "(1)",
  supplement: auto,
  captions: (:),
) -> content
```

## Parameters

### `body`

`content` — required, positional

The document content transformed by the show rule. Typst supplies this
parameter automatically when the function is used with `#show:`.

```typ
#show: number-labelled-equations
```

### `numbering`

`str` or `function` — optional, named — default: `"(1)"`

The numbering pattern or function used for labelled equations. It follows
Typst's normal equation-numbering rules.

```typ
#show: number-labelled-equations.with(numbering: "1.1")
```

### `supplement`

`auto` or `content` or `function` or `none` — optional, named — default: `auto`

The name placed before the number when the equation is referenced. `auto`
uses Typst's localized equation supplement. Set explicit Danish text with:

```typ
#show: number-labelled-equations.with(supplement: [Ligning])
```

### `captions`

`dictionary` — optional, named — default: `(:)`

Compatibility alternative for documents written before per-equation captions
were added. Maps label names to caption content. Write dictionary keys without
angle brackets. A caption is centered below its equation and prefixed with the
equation's localized reference name and number.

```typ
#show: number-labelled-equations.with(
  supplement: [Ligning],
  captions: (
    pythagoras: [Pythagoras' læresætning],
    energy: [Sammenhængen mellem masse og energi],
  ),
)

$ a^2 + b^2 = c^2 $ <pythagoras>
$ E = m c^2 $ <energy>
```

Captions require a label because the label connects the caption, number, and
reference target. Labels without a matching dictionary entry are still
numbered normally but receive no caption.

For new documents, prefer [`equation(..., caption: ...)`](equation.md) for
native equations and `#eq(..., caption: ...)` for calculation-builder output.
This keeps each caption beside the equation it describes.

## Equation outline

Use [`equation-outline`](equation-outline.md) to create a list of labelled,
captioned equations with dot leaders and page numbers:

```typ
#import "math-once.typ": equation-outline

#equation-outline(title: [Ligningsoversigt])
```

## Labels and references

Place the label directly after the equation in markup mode. Then reference it
with `@` followed by the label name.

```typ
$ a^2 + b^2 = c^2 $ <pythagoras>

Fra @pythagoras følger trekantens sidelængde.
```

The rule applies to block equations. Inline equations remain unnumbered.
