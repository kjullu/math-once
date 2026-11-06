#import "../../math-once.typ": calculation-builder
#let eq = calculation-builder(key: "builder-school-singular", strict: true)
#eq(`inv(mat(1, 2; 2, 4))`)
