#import "../math-once.typ": calculation-builder

#set page(width: auto, height: auto, margin: 12pt)
#let eq = calculation-builder(key: "negative-structure-display", strict: true)

// Literal negative components should not add an identical result.
#eq($arrow(a) := vec(2, -3, 0)$)
#eq($arrow(b) := vec(-1, -2, 1)$)
#eq($X := mat(-1, 2; 3, -4)$)
#eq(`vv := vec(-1, -2, 1)`)
// Calculated and rounded components must still show their results.
#eq($arrow(c) := vec(2 - 3, -2 * 3, 1)$)
#eq($arrow(d) := vec(-1.234, 2, 3)$, digits: 1)
#context {
  let values = eq()
  assert(values.arrow_a.values == (2.0, -3.0, 0.0))
  assert(values.arrow_c.values == (-1.0, -6.0, 1.0))
}
