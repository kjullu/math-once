# `number-labelled-equations`

Numbers block equations only when they have a label. Labelled equations can be
referenced normally with Typst's `@label` syntax; unlabelled equations have no
number and do not advance the equation counter.

## Example

```typ
#import "math-once.typ": number-labelled-equations

#show: number-labelled-equations.with(supplement: [Ligning])

// No label: no name or number.
$ 1 + 1 = 2 $

// Label: receives number (1).
$ E = m c^2 $ <energy>

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

#eq($v = 902 / 3.6$, unit: $m/s$, label: <speed>)
#eq($a = v * 2$)

Hastigheden er beregnet i @speed.
```

Only the first equation is numbered because only it has a label. Use the
runner's `label:` parameter for `calculation-builder`: placing `<speed>` after the
function call would label Typst's contextual state wrapper rather than the
equation inside it.

## Signature

```typ
number-labelled-equations(
  body,
  numbering: "(1)",
  supplement: auto,
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

## Labels and references

Place the label directly after the equation in markup mode. Then reference it
with `@` followed by the label name.

```typ
$ a^2 + b^2 = c^2 $ <pythagoras>

Fra @pythagoras følger trekantens sidelængde.
```

The rule applies to block equations. Inline equations remain unnumbered.
