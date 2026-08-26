#import "../../math-once.typ": calculation-builder

#let eq = calculation-builder(key: "strict-builder-error", strict: true)
#eq(`x := 1 / 0`)
