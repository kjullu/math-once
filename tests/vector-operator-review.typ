#import "../math-once.typ": calculation-builder
#set page(width: auto, height: auto, margin: 12pt)
#let eq = calculation-builder(key: "vector-operator-review", strict: true, block: true)

// Regressions from the PR #18 review: matrix `times`, units through
// intermediate vector results, and powers of vector-derived scalars.
#eq($M := mat(1, 2; 3, 4)$)
#eq($r_1 := M times vec(1, 2)$)
#eq($R_2 := M times 2$)
#eq($r_3 := vec(1 "m", 2 "m") bullet vec(3 "N", 4 "N") + 1 "J"$, unit: "J")
#eq($r_4 := (vec(1 "m", 2 "m") bullet vec(3 "N", 4 "N")) / 2$, unit: "J")
#eq($arrow(r_5) := 2 (vec(1 "m", 0 "m", 0 "m") times vec(0 "N", 1 "N", 0 "N"))$, unit: "N m")
#eq($r_6 := abs(vec(3, 4))^2$)
#eq($r_7 := (vec(1, 2) bullet vec(3, 4))^2$)
#eq($r_8 := 2^3^2$)
#eq($arrow(v) := vec(1, 2)$)
#eq($arrow(w) := arrow(v) + vec(1, 1)$)
#eq($r_9 := abs(arrow(v) - arrow(w))^2 + 1$)
#context {
  let v = eq()
  assert(v.r_1.values == (5.0, 11.0))
  assert(v.R_2.values == ((2.0, 4.0), (6.0, 8.0)))
  assert(v.r_3.value == 12)
  assert(v.r_4.value == 5.5)
  assert(v.arrow_r_5.values == (0.0, 0.0, 2.0))
  assert(v.r_6.value == 25)
  assert(v.r_7.value == 121)
  assert(v.r_8.value == 512)
  assert(calc.abs(v.r_9.value - 3) < 1e-9)
}
#let soft = calculation-builder(key: "vector-operator-review-soft")
#soft($vec(1, 2)^2$)
#soft($vec(1 "m", 2 "m") bullet vec(3 "N", 4 "N")$)
