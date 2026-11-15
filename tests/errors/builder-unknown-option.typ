#import "../../math-once.typ": *
#let eq = calculation-builder()
#eq($x := 2 "m"$)
#eq($x$, show-units: false)
