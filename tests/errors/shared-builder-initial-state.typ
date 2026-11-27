#import "../../math-once.typ": calculation-builder

// A second builder inherits the first builder's initial values when sharing
// a key. Overwriting one must still validate the inherited initial scope.
#let first = calculation-builder(initial-state: (factor: "bad"))
#let second = calculation-builder()
#first(`f(x) := x + 1`)
#second(`factor := 3`)
