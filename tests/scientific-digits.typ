#import "../math-once.typ": calculate, calculation-builder, unload

// Check the rendered coefficient, rather than only the rounded result.value.
#let check(source, digits, coefficient) = {
  let result = calculate(source, digits: digits)
  let rendered-result = repr(result.display.body).split("[=]").last()
  assert("[" + coefficient + "]" in rendered-result)
  result.display
}

#check(`128 / 100000000`, 1, "1.3")
#check(`128 / 100000000`, 9, "1.280000000")
#check(`128 / 100000000`, 8, "1.28000000")
#check(`-128 / 100000000`, 1, "1.3")
#check(`123456789123 / 100000000000000000`, 9, "1.234567891")
#check(`123456789123`, 2, "1.23")
#check(`-123456789123`, 2, "1.23")
#check(`12001 / 10000000000`, 3, "1.200")
#check(`99996 / 10000000000`, 3, "1.000")
#check(`9999600000`, 3, "1.000")
#check(`128 / 100000000`, 0, "1")
#check(`0`, 3, "0")
#check(`128 / 100`, 1, "1.3")

// The reported inertia example uses stored, unit-bearing results and inline
// result-only overrides. Rounding their display must not change later math.
#let eq = calculation-builder(key: "scientific-digits")
#unload($L$, $m$, key: "scientific-digits")
#eq($L := 4 "cm"$)
#eq($m := L dot 0.120 g/"cm"$, unit: "g", digits: 3)
#eq($I_"ver" := 1/3 dot m dot L^2$)
#eq($I_"hor" := m dot L^2$)
One decimal: #eq($2 dot I_"ver" + I_"hor"$, result-only: true, digits: 1).
Nine decimals: #eq($2 dot I_"ver" + I_"hor"$, result-only: true, digits: 9).
Eight decimals: #eq($2 dot I_"ver" + I_"hor"$, result-only: true, digits: 8).
#context {
  let result = calculate($2 dot I_"ver" + I_"hor"$, scope: eq(), digits: 1)
  assert("[1.3]" in repr(result.display.body).split("[=]").last())
  assert(calc.abs(result.exact - 1.28e-6) < 1e-20)
  assert(calc.abs(eq().I_ver.exact - 2.56e-7) < 1e-20)
  assert(calc.abs(eq().I_hor.exact - 7.68e-7) < 1e-20)
}
