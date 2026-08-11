#import "../math-once.typ": calculate, calculation-builder

#let eq = calculation-builder(key: "trigonometry-test", digits: 9)

#eq($lambda = 530 "nm"$)
#eq($n = 1$)
#eq($o = 15.0$)
#eq($d = (n * lambda) / (sin(o))$)

#context {
  let variables = eq()
  assert(variables.n.value == 1.0)
  assert(variables.d.unit == "µm")
  assert(calc.abs(variables.d.value - 2.047762752) < 0.000000001)
}

// Unit symbols remain units in a builder expression.
#let lengths = calculation-builder(key: "reserved-unit-name-test", digits: 2)
#lengths($x = 1 m + 25 "cm"$, unit: $m$)
#context assert(lengths().x.value == 1.25)

#assert(calculate(`sin(30)`).value == 0.5)
#assert(calculate(`cos(60)`).value == 0.5)
#assert(calculate(`tan(45)`).value == 1.0)
