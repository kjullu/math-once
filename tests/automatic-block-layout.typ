#import "../math-once.typ": calculation-builder, text-unit

#let eq = calculation-builder(key: "automatic-block-layout")

// Typst records compact math as inline and spaced/multiline math as block.
#let inline = eq($1 + 1$)
#let spaced = eq($ 1 + 1 $)
#let multiline = eq($
  1 + 1
$)

#assert(inline.block == false)
#assert(spaced.block == true)
#assert(multiline.block == true)

// Raw and string input have no layout metadata and retain centered output.
#assert(eq(`1 + 1`).block == true)
#assert(eq("1 + 1").block == true)
#assert(eq(`1 + 1`, block: false).block == false)

// Content embedded in the output unit must not make a spaced source compact.
#assert(eq(
  $ 1 / "distance" $,
  unit: $#text-unit("lines") / m$,
).block == true)

// Builder and per-call booleans remain explicit overrides.
#let forced-inline = calculation-builder(
  key: "forced-inline-layout",
  block: false,
)
#assert(forced-inline($ 1 + 1 $).block == false)
#assert(forced-inline($ 1 + 1 $, block: true).block == true)
#assert(eq($1 + 1$, block: true).block == true)
#assert(eq($ 1 + 1 $, block: false).block == false)

// Render representative inline and centered forms for visual regression.
Inline before #eq($2 + 2$) inline after.

#eq($ 2 + 2 $)

// A compact unit argument does not pull a spaced source out of block layout.
#eq($ 1 / (0.5 "mm") $, unit: $#text-unit("lines") / m$)
