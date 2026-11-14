#import "../../math-once.typ": calculation-builder
#let eq = calculation-builder()
#eq($L := 2 "m"$)
#eq($L$, result-only: true, unit: false)
