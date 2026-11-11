#import "../../math-once.typ": calculation-builder
// The first invalid initial value is reported, not the one the expression uses.
#let eq = calculation-builder(initial-state: (alpha: "bad", beta: "bad"))
#eq(`beta + 1`)
