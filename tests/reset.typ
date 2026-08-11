#import "../math-once.typ": calculation-builder, reset

// The default reset key matches the default builder key.
#let eq = calculation-builder()
#eq(`height := 10 m`)
#eq(`width := 5 m`)
#eq(`depth := 2 m`)

// Selective reset accepts strings and raw names.
#reset("height", `width`)
#context {
  let variables = eq()
  assert("height" not in variables)
  assert("width" not in variables)
  assert(variables.depth.value == 2.0)
}

// Math names, including subscripts, are accepted too.
#eq($theta_1 := 15 degree$)
#reset($theta_1$)
#context assert("theta_1" not in eq())

// No names clears the entire state.
#reset()
#context assert(eq().len() == 0)

// A custom builder is reset through the matching key.
#let custom = calculation-builder(
  key: "reset-custom-key",
  initial-state: (factor: 2),
)
#custom(`length := factor * 3 m`)
#reset("length", key: "reset-custom-key")
#context {
  let variables = custom()
  assert(variables.factor == 2)
  assert("length" not in variables)
}
#reset(key: "reset-custom-key")
#context assert(custom().len() == 0)
