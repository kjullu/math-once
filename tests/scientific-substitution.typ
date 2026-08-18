#import "../math-once.typ": calculation-builder

// Large and small stored values stay compact when substituted into a later
// equation. This is also a page-width regression fixture.
#let eq = calculation-builder(key: "scientific-substitution", digits: 4)

#eq($M_S := 1.989 * 10^(30) "kg"$, show-result: false)
#eq($m_J := 5.976 * 10^(24) "kg"$, show-result: false)
#eq($G := 6.6726 * 10^(-11) m^3 / ("kg" s^2)$)
#eq($r := 149600000 "km"$)
#eq($F_g := G * (m_J * M_S) / (r)^2$, size: $10^22$)

#context {
  let variables = eq()
  assert(variables.G.exact == 6.6726e-11)
  assert(calc.abs(variables.F_g.exact - 3.543865869) < 0.000000001)
  assert(variables.F_g.unit == "10^(22) N")
}
