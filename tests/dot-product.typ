#import "../math-once.typ": calculation-builder

#set page(width: auto, height: auto, margin: 12pt)

#let eq = calculation-builder(key: "dot-product", strict: true)
#eq($arrow(a) := vec(1, 2, 3)$)
#eq($arrow(b) := vec(4, 5, 6)$)
#eq($c := arrow(a) bullet arrow(b)$)
#eq($x := vec(1, 2) bullet vec(3, 4) + 1$)
#eq($y := 2 arrow(a) bullet arrow(b)$)
#eq($z := arrow(a) bullet arrow(b) / 2$)
#eq($arrow(F) := vec(2 "N", 3 "N")$)
#eq($arrow(s) := vec(4 "m", 1 "m")$)
#eq($w_F := arrow(F) bullet arrow(s)$, unit: "J")
#context {
  let values = eq()
  assert(values.c.value == 32)
  assert(values.x.value == 12)
  assert(values.y.value == 64)
  assert(values.z.value == 16)
  assert(values.w_F.value == 11)
}

// Non-strict builders render dot product misuse inline.
#let soft = calculation-builder(key: "dot-product-errors")
#soft($arrow(u) := vec(1, 2)$)
#soft($arrow(v) := vec(1, 2, 3)$)
#soft($arrow(u) bullet arrow(v)$)
#soft($2 bullet 3$)
#soft($arrow(u) * arrow(u)$)
#soft($-(arrow(u) bullet arrow(u))$)
