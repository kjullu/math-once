#import "../math-once.typ": calculate, calculation-builder

#let eq = calculation-builder(key: "roots-test", digits: 6)

#eq($sqrt(5)$)
#eq($root(5, 3)$)

#eq($x_1 := sqrt(25)$)
#eq($x_2 := root(3, 8)$)
#eq($x_3 := sqrt(9 m^2)$)

#context {
  assert(eq().x_1.value == 5.0)
  assert(eq().x_2.value == 2.0)
  assert(eq().x_3.value == 3.0)
  assert(eq().x_3.unit == "m")
}

#let raw-square-root = calculate(`sqrt(81)`)
#let raw-cube-root = calculate(`root(3, 27)`)
#assert(raw-square-root.value == 9.0)
#assert(raw-cube-root.value == 3.0)
