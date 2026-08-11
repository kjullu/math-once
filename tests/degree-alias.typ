#import "../math-once.typ": calculate, calculation-builder

#let eq = calculation-builder(key: "degree-alias-test", digits: 2)

// Typst math converts `degree` to the degree symbol.
#eq($theta_m = 15.0 degree$)
#eq($d = theta_m * 2$)

// Raw and string expressions accept the readable alias too.
#eq(`theta_0 = 10 degree`)
#eq(`a = 2 * theta_0`)

#let converted = calculate(`180 degree to rad`, digits: 12)
#assert(converted.value == calc.round(calc.pi, digits: 12))

#context {
  let variables = eq()
  assert(variables.at("theta_m").value == 15.0)
  assert(variables.at("theta_m").unit == "°")
  assert(variables.d.value == 30.0)
  assert(variables.d.unit == "°")
  assert(variables.at("theta_0").value == 10.0)
  assert(variables.at("theta_0").unit == "degree")
  assert(variables.a.value == 20.0)
  assert(variables.a.unit == "degree")
}
