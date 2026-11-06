#import "../../math-once.typ": calculation-builder
#let eq = calculation-builder(key: "builder-school-chi2-zero", strict: true)
#eq(`chi2gof(vec(0, 0), vec(0.5, 0.5))`)
