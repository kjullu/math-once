#import "../math-once.typ": calculation-builder

#set page(width: auto, height: auto, margin: 12pt)

// `arrow(A B)` names one vector between two points.
#let eq = calculation-builder(key: "point-vectors", strict: true, block: true)
#eq($arrow(A B) := vec(1, 2, 3)$)
#eq($arrow(A D) := vec(0, 1, 4)$)
#eq($arrow(n) := arrow(A B) times arrow(A D)$)
#eq($p := arrow(A B) bullet arrow(A D)$)
#context {
  let values = eq()
  assert("arrow_AB" in values)
  assert(values.arrow_n.values == (5.0, -4.0, 1.0))
  assert(values.p.value == 14)
}
