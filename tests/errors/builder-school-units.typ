#import "../../math-once.typ": calculation-builder
#let eq = calculation-builder(key: "builder-school-units", strict: true)
#eq(`mean(vec(2 m, 3 m))`)
