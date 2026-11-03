#import "../../math-once.typ": calculation-builder
#let eq = calculation-builder(key: "builder-school-pole", strict: true, angles: "radians")
#eq(`integrate(1/cos(x), x, 3, 5)`)
