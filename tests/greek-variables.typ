#import "../math-once.typ": calculation-builder

#let eq = calculation-builder(key: "greek-variable-test")

// Typst math names are stored under their readable ASCII names and retain
// their mathematical symbols in the rendered equations.
#eq($lambda := 530 m$)
#eq($z := 2 lambda$)
#eq($theta := 2$)
#eq($x := theta + 1$)

// Raw input uses the same names and storage keys.
#eq(`omega := 3`)
#eq(`y := omega * 2`)

#context {
  let variables = eq()
  assert(variables.lambda.value == 530.0)
  assert(variables.lambda.unit == "m")
  assert(variables.z.value == 1060.0)
  assert(variables.theta.value == 2.0)
  assert(variables.x.value == 3.0)
  assert(variables.omega.value == 3.0)
  assert(variables.y.value == 6.0)
}
