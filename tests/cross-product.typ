#import "../math-once.typ": calculation-builder

#set page(width: auto, height: auto, margin: 12pt)

#let eq = calculation-builder(key: "cross-product", strict: true)
#eq($arrow(a) := vec(1, 2, 3)$)
#eq($arrow(b) := vec(4, 5, 6)$)
#eq($arrow(c) := arrow(a) times arrow(b)$)
#eq($p := arrow(c) bullet arrow(a)$)
#eq($arrow(k) := 2 times arrow(a)$)
#eq($arrow(l) := arrow(a) times 2$)
#eq($q := 2 times 3$)
#eq($arrow(r) := vec(0 "m", 2 "m", 0 "m")$)
#eq($arrow(F) := vec(3 "N", 0 "N", 0 "N")$)
#eq($arrow(tau) := arrow(r) times arrow(F)$, unit: "N m")
#context {
  let values = eq()
  assert(values.arrow_c.values == (-3.0, 6.0, -3.0))
  assert(values.p.value == 0)
  assert(values.arrow_k.values == (2.0, 4.0, 6.0))
  assert(values.arrow_l.values == (2.0, 4.0, 6.0))
  assert(values.q.value == 6)
  assert(values.arrow_tau.values == (0.0, 0.0, -6.0))
}

// Non-strict builders render cross product misuse inline.
#let soft = calculation-builder(key: "cross-product-errors")
#soft($vec(1, 2) times vec(3, 4)$)
#soft($mat(1, 0; 0, 1) times vec(1, 2)$)
