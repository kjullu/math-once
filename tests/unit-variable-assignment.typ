#import "../math-once.typ": calculation-builder

#let eq = calculation-builder(key: "unit-variable-assignment-message")

// This renders a red message and must not store `m` as a variable.
#eq($m = 1$)
#eq($x = 1 m + 25 "cm"$, unit: $m$)

#context {
  let variables = eq()
  assert("m" not in variables)
  assert(variables.x.value == 1.25)
  assert(variables.x.unit == "m")
}
