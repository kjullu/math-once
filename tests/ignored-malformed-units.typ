#import "../math-once.typ": calculation-builder

// A unit is parsed only when a calculation evaluates. These calls never read
// their unit, so one that cannot be parsed must not stop compilation.
#let eq = calculation-builder()

// A missing variable leaves the equation as written.
#eq(`x = y`, unit: $m_(1+2)$)

// Function definitions have no result to convert.
#eq(`f(x) := x + 1`, unit: $m_(1+2)$)
#eq(`f(2)`)

// Symbolic calls report their own unit error first.
#eq(`diff(x^2, x)`, unit: $m_(1+2)$)
