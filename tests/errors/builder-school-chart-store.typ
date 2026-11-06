#import "../../math-once.typ": calculation-builder
#let eq = calculation-builder(key: "builder-school-chart-store", strict: true)
#eq(`graph := plot(x^2, x, 0, 1)`)
