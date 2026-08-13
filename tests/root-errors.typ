#import "../math-once.typ": calculation-builder

#let eq = calculation-builder(key: "root-errors")

#eq($sqrt(-1)$)
#eq($root(0, 5)$)
#eq($root(2.5, 5)$)
#eq($sqrt(2 m)$)
