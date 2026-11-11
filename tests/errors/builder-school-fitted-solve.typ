#import "../../math-once.typ": calculation-builder
#let eq = calculation-builder(key: "builder-school-fitted-solve", strict: true)
#eq(`xd := vec(1, 2, 3, 4)`)
#eq(`yw := vec(3, 0, 1, 2)`)
#eq(`fit := linreg(xd, yw)`)
#eq(`solve(fit(x) = 2, x)`)
