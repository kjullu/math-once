#import "../math-once.typ": calculate, calculation-builder

// abs(...) always calculates an absolute value.
#assert(calculate(`abs(-3)`).exact == 3)
#assert(calculate(`abs(-3 cm)`).exact == 3)
#assert(calculate(`abs(-3 cm)`).unit == "cm")

// Balanced scalar bars work in raw and Typst math input.
#assert(calculate(`|-3|`).exact == 3)
#assert(calculate($|-3|$).exact == 3)
#assert(calculate($abs(-3)$).exact == 3)
#assert(calculate(`|-3| + |-4|`).exact == 7)
#assert(calculate(`||-3||`).exact == 3)

#let eq = calculation-builder(key: "absolute-value", digits: 2)
#eq($T_0 := 286.15 K$)
#eq($T_3 := 316.15 K$)
#eq($T_Delta := |T_0 - T_3|$)
#eq(`length := abs(-3 cm)`)

#context {
  let values = eq()
  assert(values.at("T_Delta").exact == 30)
  assert(values.at("T_Delta").unit == "K")
  assert(values.length.exact == 3)
  assert(values.length.unit == "cm")
}

// Infix bars are not treated as absolute value and remain display-only.
#eq($a | b$)
#eq($|q|$)
#eq($"not_numeric" := |q|$)
#context assert("not_numeric" not in eq())
