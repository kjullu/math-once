#import "../math-once.typ": calculation-builder

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
