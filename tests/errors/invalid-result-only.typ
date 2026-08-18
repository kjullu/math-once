#import "../../math-once.typ": calculation-builder

#let eq = calculation-builder(key: "invalid-result-only")

// The display option must be a boolean.
#eq($1 + 1$, result-only: "yes")
