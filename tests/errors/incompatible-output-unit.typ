#import "../../math-once.typ": qalc-builder

#let eq = qalc-builder(key: "incompatible-output-unit")

// This file must fail: speed cannot be converted to power.
#eq(`v = 1 m/s + 1 m/s = W`)
