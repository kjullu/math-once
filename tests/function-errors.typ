#import "../math-once.typ": calculation-builder
#let eq = calculation-builder(key: "function-errors")
#eq($f(x) := x + 1$)
#eq($f(1, 2)$) // red error: expects one argument
