#import "../../math-once.typ": calculation-builder
// A tiny factor must not hide the pole from the convergence check.
#let eq = calculation-builder(key: "builder-school-scaled-pole", strict: true, angles: "radians")
#eq(`integrate(0.000000000001*exp(x)/(x-0.1234)^2, x, 0, 1)`)
