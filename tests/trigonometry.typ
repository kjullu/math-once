#import "../math-once.typ": calculate, calculation-builder

#let eq = calculation-builder(key: "trigonometry-test", digits: 9)

#eq($l = 530 "nm"$)
#eq($m = 1$)
#eq($o = 15.0$)
#eq($d = (m * l) / (sin(o))$)

#context {
  let variables = eq()
  assert(variables.m.value == 1.0)
  assert(variables.d.unit == "µm")
  assert(calc.abs(variables.d.value - 2.047762752) < 0.000000001)
}

#assert(calculate(`sin(30)`).value == 0.5)
#assert(calculate(`cos(60)`).value == 0.5)
#assert(calculate(`tan(45)`).value == 1.0)
