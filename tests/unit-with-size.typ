#import "../math-once.typ": calculate, calculation-builder

#let eq = calculation-builder(key: "unit-with-size", digits: 5)

#eq($"distance" := 1 "cm" + 2 "cm"$, unit: $m$, size: 0.01)
#eq($"distance"$, unit: $m$, size: 1)

#context {
  let variables = eq()
  assert(variables.distance.value == 3.0)
  assert(variables.distance.exact == 3.0)
  assert(variables.distance.si-value == 0.03)
  assert(variables.distance.unit == "cm")
}

#let density = calculation-builder(key: "scientific-unit-size")
#density(
  $x := 1 / (2.05 * 10^(-6))$,
  unit: $"linjer" / m$,
  size: $10^(5)$,
  digits: 2,
)
#context {
  assert(density().x.value == 4.88)
  assert(density().x.unit == "10^(5) linjer/m")
}

// Scientific size notation is preserved with automatic and requested units.
#let automatic-power = calculate(`3.5439 * 10^22 N`, size: $10^22$, digits: 4)
#let automatic-factor = calculate(`6000 N`, size: $2 * 10^3$, digits: 2)
#let requested-factor = calculate(
  `0.0009 N`,
  unit: $N$,
  size: $3 * 10^(-4)$,
  digits: 2,
)

#automatic-power.display
#automatic-factor.display
#requested-factor.display

#assert(automatic-power.value == 3.5439)
#assert(automatic-power.unit == "10^(22) N")
#assert(automatic-factor.value == 3.0)
#assert(automatic-factor.unit == "(2*10^(3)) N")
#assert(requested-factor.value == 3.0)
#assert(requested-factor.unit == "(3*10^(-4)) N")
