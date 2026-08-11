#import "../math-once.typ": calculation-builder

#let eq = calculation-builder(key: "direct-assignment-test", digits: 2)

// Direct values and aliases must not repeat an identical final result.
#eq($v = 10 m/s$)
#eq($w = v$)

// Actual arithmetic and conversions must retain their result step.
#eq($x = v * 2$)
#eq($y = 10 "km"/h$)
#eq($"rounded" = 1.23456 m$)

#context {
  let variables = eq()
  assert(variables.v.value == 10.0)
  assert(variables.w.value == 10.0)
  assert(variables.x.value == 20.0)
  assert(variables.y.unit == "m/s")
  assert(variables.rounded.value == 1.23)
}
