#import "../math-once.typ": calculate, calculation-builder

#let eq = calculation-builder(key: "trigonometry-test", digits: 9)

#eq($lambda := 530 "nm"$)
#eq($n := 1$)
#eq($theta_1 := 15.0 degree$)
#eq($x := (n * lambda) / (sin(theta_1))$, size: $10^(-6)$)

#context {
  let variables = eq()
  assert(variables.n.value == 1.0)
  assert(variables.x.unit == "µm")
  assert(variables.x.size == 0.000001)
  assert(calc.abs(variables.x.value - 2.047762752) < 0.000000001)
}

// Unit symbols remain units in a builder expression.
#let lengths = calculation-builder(key: "reserved-unit-name-test", digits: 2)
#lengths($x := 1 m + 25 "cm"$, unit: $m$)
#context assert(lengths().x.value == 1.25)

#assert(calculate(`sin(30)`).value == 0.5)
#assert(calculate(`cos(60)`).value == 0.5)
#assert(calculate(`tan(45)`).value == 1.0)
#assert(calculate(`asin(0.5)`).value == 30.0)
#assert(calculate(`acos(0.5)`).value == 60.0)
#assert(calculate(`atan(1)`).value == 45.0)
#assert(calculate(`arcsin(0.5)`).value == 30.0)
#assert(calculate(`arccos(0.5)`).value == 60.0)
#assert(calculate(`arctan(1)`).value == 45.0)
#assert(calculate(`atan2(1, 1)`).value == 45.0)
#assert(calculate(`atan2(1 m, -1 m)`).value == 135.0)
#assert(calc.abs(calculate(`acos(0) to rad`, digits: 9).value - calc.pi / 2) < 0.000000001)

#let inverse = calculation-builder(key: "inverse-trigonometry-test", digits: 2)
#inverse($theta := "acos"(0.5)$)
#inverse($alpha := arccos(0.5)$)
#inverse($beta := arcsin(0.5)$)
#inverse($gamma := arctan(1)$)
#context {
  let variables = inverse()
  assert(variables.theta.value == 60.0)
  assert(variables.theta.unit == "degree")
  assert(variables.alpha.value == 60.0)
  assert(variables.beta.value == 30.0)
  assert(variables.gamma.value == 45.0)
}
