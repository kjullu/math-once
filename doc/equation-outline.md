# `equation-outline`

Creates a linked list of labelled, captioned equations. Each entry contains the
equation's supplement and number, its caption, dot leaders, and its page number,
similar to Typst's list of tables.

Only equations created with a per-equation `caption:` and followed by a label
are included. Unlabelled equations, ordinary intermediate equations, and
equations without captions are omitted.

## Example

```typ
#import "math-once.typ": equation, equation-outline, number-labelled-equations

#show: number-labelled-equations.with(supplement: [Ligning])

#equation-outline(title: [Ligningsoversigt])

#equation(
  $ E = m c^2 $,
  caption: [Sammenhængen mellem masse og energi],
) <energy>
```

The outline entry is rendered like:

```text
Ligning 1  Sammenhængen mellem masse og energi ........ 1
```

## Signature

```typ
equation-outline(
  title: [List of Equations],
  indent: auto,
) -> content
```

## Parameters

### `title`

`auto` or `content` or `none` — optional, named — default: `[List of Equations]`

The heading displayed above the equation list. Set it to `none` to omit the
heading.

```typ
#equation-outline(title: [Ligningsoversigt])
#equation-outline(title: none)
```

### `indent`

`auto` or `relative` or `function` — optional, named — default: `auto`

Controls entry indentation using Typst's normal outline indentation rules.

```typ
#equation-outline(indent: 1em)
```

## Builder equations

The outline also includes labelled captions made by `calculation-builder`.

```typ
#import "math-once.typ": calculation-builder, equation-outline, number-labelled-equations

#show: number-labelled-equations
#equation-outline(title: [List of Equations])

#let eq = calculation-builder(
  key: "outline-example",
  supplement: [Equation],
)

#eq(
  $v = 10 m/s$,
  caption: [Initial velocity],
) <speed>
```

The supplement shown in the list comes from each equation. This means one list
can contain names such as `Ligning`, `Equation`, and `Formula` when desired.
