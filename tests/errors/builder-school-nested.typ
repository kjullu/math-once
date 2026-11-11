#import "../../math-once.typ": calculation-builder
#let eq = calculation-builder(key: "builder-school-nested", strict: true)
#eq(`1 - binomcdf(10, 0.5, 3)`)
