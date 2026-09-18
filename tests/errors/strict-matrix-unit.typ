#import "../../math-once.typ": calculation-builder
#let eq = calculation-builder(strict: true, strict-units: true)
#eq(`bad := mat(1 "meterrs", 2)`)
