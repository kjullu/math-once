#import "../math-once.typ": calculation-builder, reset

// The default reset key matches the default builder key.
#let eq = calculation-builder()
#eq(`height := 10 m`)
#eq(`width := 5 m`)
#eq(`depth := 2 m`)

// Reset clears the entire state.
#reset()
#context assert(eq().len() == 0)

// A custom builder is reset through the matching key.
#let custom = calculation-builder(
  key: "reset-custom-key",
  initial-state: (factor: 2),
)
#custom(`length := factor * 3 m`)
#reset(key: "reset-custom-key")
#context assert(custom().len() == 0)
