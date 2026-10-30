#import "../../math-once.typ": calculation-builder
#let eq = calculation-builder(strict: true)
#eq(`vv := vec(1, 2)`)
#eq(`vv * vv`)
