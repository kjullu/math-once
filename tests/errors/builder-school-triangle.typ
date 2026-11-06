#import "../../math-once.typ": calculation-builder
#let eq = calculation-builder(key: "builder-school-triangle", strict: true)
#eq(`triangle(a = 1, b = 2, c = 5)`)
