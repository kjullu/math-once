#import "../math-once.typ": calculate, calculation-builder, text-unit

// Strict unit lookup remains opt-in and accepts catalog units and text labels.
#assert(calculate(`2 cm`, strict-units: true).unit == "cm")
#assert(calculate(`2 / m`, unit: $#text-unit("lines") / m$, strict-units: true).unit == "lines/m")

#let eq = calculation-builder(key: "builder-options", digits: 0)
#eq(`x := 3`)

// Hide the substituted middle expression but retain the source and result.
#eq(`y := x * 2`, show-substitution: false)

Before. #eq(`hidden_value := y + 1`, hidden: true)After: #eq(`hidden_value`, result-only: true).

#context {
  let values = eq()
  assert(values.y.exact == 6.0)
  assert(values.hidden_value.exact == 7.0)
}
