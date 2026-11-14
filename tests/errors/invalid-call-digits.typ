#import "../../math-once.typ": calculation-builder
#let eq = calculation-builder(key: "invalid-call-digits")
#eq(`1 / 3`, digits: 2.5)
