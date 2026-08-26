#import "../math-once.typ": calculate, calculation-builder

#let celsius-difference = calculate(`30 celsius - 20 celsius`, digits: 2)
#assert(celsius-difference.si-value == 10.0)
#assert(celsius-difference.exact == 10.0)
#assert(celsius-difference.unit == "celsius")
#assert(celsius-difference.affine-kind == "difference")
#celsius-difference.display

#let fahrenheit-difference = calculate(`86 fahrenheit - 68 fahrenheit`, digits: 2)
#assert(calc.abs(fahrenheit-difference.si-value - 10.0) < 0.0000001)
#assert(calc.abs(fahrenheit-difference.exact - 18.0) < 0.0000001)
#assert(fahrenheit-difference.unit == "fahrenheit")
#assert(fahrenheit-difference.affine-kind == "difference")
#fahrenheit-difference.display

#let converted-difference = calculate(`30 celsius - 20 celsius`, unit: `fahrenheit`, digits: 2)
#assert(calc.abs(converted-difference.exact - 18.0) < 0.0000001)
#converted-difference.display

#let rounded-difference = calculate(`round(30.4 celsius - 20 celsius)`, digits: 2)
#assert(rounded-difference.exact == 10.0)
#rounded-difference.display

#let eq = calculation-builder(key: "affine-temperatures", digits: 2)
#eq(`T_1 := 30 celsius`)
#eq(`T_2 := 20 celsius`)
#eq(`Delta_T := T_1 - T_2`)
#eq(`Delta_T`, result-only: true)
#context {
  let values = eq()
  assert(values.Delta_T.si-value == 10.0)
  assert(values.Delta_T.exact == 10.0)
  assert(values.Delta_T.affine-kind == "difference")
}
