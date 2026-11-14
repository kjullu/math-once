#import "../math-once.typ": calculate, calculation-builder

// A vector written as the whole expression, numerator, or exponent is still a
// vector. Its components used to be read as a product, so `vec(1, 2)` was 2.
#let eq = calculation-builder(key: "standalone-structures")

#eq($ vec(1, 2) $)
#eq($ vec(3 "m", 4 "m") $)
#eq($ mat(1, 2; 3, 4) $)
#eq($ |vec(3, 4)| $)
#eq($ abs(vec(3, 4)) $)
#eq($ vec(1, 2) / 2 $)
#eq($ vec(1, 2) / vec(1, 2) $)
#eq($ 2^vec(1, 2) $)
#eq($ 3 / vec(1, 2) $)

#eq($ arrow(a) := vec(2, 4) / 2 $)
#context {
  let state = eq()
  assert(state.arrow_a.values == (1.0, 2.0))
}
