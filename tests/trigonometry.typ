#import "../math-once.typ": calculate, calculation-builder

#let eq = calculation-builder(key: "trigonometry-test", digits: 9)

#eq($lambda = 530 "nm"$)
#eq($n = 1$)
#eq($theta_1 = 15.0 degree$)
#eq($x = (n * lambda) / (sin(theta_1))$, size: $10^(-6)$)

#context {
  let variables = eq()
  assert(variables.n.value == 1.0)
  assert(variables.x.unit == "µm")
  assert(variables.x.size == 0.000001)
  assert(calc.abs(variables.x.value - 2.047762752) < 0.000000001)
}

// Unit symbols remain units in a builder expression.
#let lengths = calculation-builder(key: "reserved-unit-name-test", digits: 2)
#lengths($x = 1 m + 25 "cm"$, unit: $m$)
#context assert(lengths().x.value == 1.25)

#assert(calculate(`sin(30)`).value == 0.5)
#assert(calculate(`cos(60)`).value == 0.5)
#assert(calculate(`tan(45)`).value == 1.0)
