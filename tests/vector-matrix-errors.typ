#import "../math-once.typ": calculation-builder, matrix

#let eq = calculation-builder(key: "vector-matrix-errors")

#eq($arrow(v) := vec(1, 2)$)
#eq($arrow(w) := vec(3, 4)$)
#eq($X := matrix(1, 2; 3, 4)$)

// These should render focused errors without storing an invalid result.
#eq($arrow(q) := arrow(v) arrow(w)$)
#eq($Y := matrix(1, 2, 3; 4, 5, 6) X$)
#eq($Z := matrix(1, 2; 3)$)
#eq($X$, unit: $m$)

#context {
  let state = eq()
  assert("arrow_q" not in state)
  assert("Y" not in state)
  assert("Z" not in state)
}
