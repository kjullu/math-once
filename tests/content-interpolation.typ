#import "../math-once.typ": calculation-builder

#let eq = calculation-builder(key: "content-interpolation")
#let characters = "309"

// Typst values interpolated into math are parsed as part of the expression.
#eq($ #characters/2400 $)
#eq($ x := #characters/2400 $)

#context {
  assert(eq().x.exact == 309 / 2400)
  assert(eq().x.value == 0.1288)
}
