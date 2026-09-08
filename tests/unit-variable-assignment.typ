#import "../math-once.typ": calculation-builder, unload

#let eq = calculation-builder(key: "unit-variable-assignment-message")

// This renders a red message and must not store `m` as a variable.
#eq($m := 1$)
#eq($x := 1 m + 25 "cm"$, unit: $m$)

#context {
  let variables = eq()
  assert("m" not in variables)
  assert(variables.x.value == 1.25)
  assert(variables.x.unit == "m")
}

// Results derived from an unloaded unit-name variable must still be stored.
#unload("d", "R", "r", "A", key: "unit-variable-assignment-message")
#eq($ d := 4 "m" $)
#eq($ R := d / 2 $)
#eq($ r := R - 20 "cm" $)
#eq($ rho := 2700 "kg" / m^3 $)
#eq($ A_s := pi * R^2 $)
#eq($ A_l := pi * r^2 $)
#eq($ A_l $)
#eq($ A := (A_s - A_l) * 10 m $)
#eq($ M := A * rho $)
#eq($ I := 1 / 2 * M * (r^2 + R^2) $, unit: $"kg" * m^2$, digits: 3)
#eq($ I $, result-only: true)

#context {
  let values = eq()
  assert(calc.abs(values.at("A_s").exact - calc.pi * 2 * 2) < 0.0000001)
  assert(calc.abs(values.at("A_l").exact - calc.pi * 1.8 * 1.8) < 0.0000001)
  assert(values.at("A_l").unit == "m^2")
  let expected-I = calc.pi * (2 * 2 - 1.8 * 1.8) * 10 * 2700 * (1.8 * 1.8 + 2 * 2) / 2
  assert(calc.abs(values.I.exact - expected-I) < 0.0000001)
  assert(values.I.unit == "kg*m^(2)")
}
