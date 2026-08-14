#import "../math-once.typ": calculation-builder

// Large and small stored values stay compact when substituted into a later
// equation. This is also a page-width regression fixture.
#let eq = calculation-builder(key: "scientific-substitution", digits: 4)

#eq($pi := 3.1415926536$, show-result: false)
#eq($M_S := 1.989 * 10^(30) "kg"$, show-result: false)
#eq($m_J := 5.976 * 10^(24) "kg"$, show-result: false)
#eq($G := 6.6726 * 10^(-11)$)
#eq($r := 149600000 "km"$)
#eq($F_g := G * (m_J * M_S) / (r)^2$, size: $2 * 10^(3)$)

#context {
  let variables = eq()
  assert(variables.G.exact == 6.6726e-11)
  assert(variables.F_g.exact > 1.771e19)
}
