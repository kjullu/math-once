#import "../math-once.typ": calculation-builder, unload
#let eq = calculation-builder(key: "function-errors")
#eq($f(x) := x + 1$)
#eq($f(1, 2)$) // red error: expects one argument

// Catalog units and built-in constants cannot be stored as function names.
#eq(`m(x) := x + 1`)
#eq(`e(x) := x + 1`)

// Direct and indirect recursive calls report focused errors.
#eq(`recur(x) := recur(x)`)
#eq(`recur(1)`)
#eq(`cycle_a(x) := cycle_b(x)`)
#eq(`cycle_b(x) := cycle_a(x)`)
#eq(`cycle_a(1)`)

#context {
  let values = eq()
  assert("m" not in values)
  assert("e" not in values)
}

// Deliberately unloaded names follow the same opt-in rule as scalar variables.
#let unloaded = calculation-builder(key: "unloaded-function-names")
#unload("m", "e", key: "unloaded-function-names")
#unloaded(`m(x) := x + 1`)
#unloaded(`e(x) := x + 2`)
#unloaded(`result := m(1) + e(1)`)
#context assert(unloaded().result.exact == 5.0)
