#import "../math-once.typ": calculation-builder, unload

#let eq = calculation-builder(key: "direct-assignment-test", digits: 2)

// Definitions store direct values and aliases.
#eq($v := 10 m/s$)
#eq($w := v$)

// Arithmetic, conversions, and rounding retain their exact stored result.
#eq($x := v * 2$)
#eq($y := 10 "km"/h$)
#eq($"rounded" := 1.23456 m$)

// A calculated definition displays substitution and its useful result.
#eq($lambda := 530 "nm"$)
#eq($n := 1$)
#eq($theta_1 := 15 degree$)
#eq($"distance" := (n * lambda) / sin(theta_1)$, digits: 5)

#context {
  let variables = eq()
  assert(variables.v.value == 10.0)
  assert(variables.w.value == 10.0)
  assert(variables.x.value == 20.0)
  assert(variables.y.unit == "m/s")
  assert(variables.rounded.value == 1.23)
  assert(variables.distance.value == 2.04776)
  assert(variables.distance.unit == "µm")
}

// Regression: unloaded unit spellings can be variables, and a calculated
// definition must show and store its result on the same line.
#let diffraction = calculation-builder(key: "definition-result-regression")
#unload($m$, key: "definition-result-regression")
#diffraction($lambda := 530 "nm"$)
#diffraction($m := 1$)
#diffraction($theta_1 := 15 degree$)
#unload($d$, key: "definition-result-regression")
#diffraction($d := (m * lambda) / sin(theta_1)$, digits: 5)
#context {
  let variables = diffraction()
  assert(variables.d.value == 2.04776)
  assert(variables.d.unit == "µm")
}
