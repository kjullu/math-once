#import "../math-once.typ": calculation-builder, unload
#let eq = calculation-builder(key: "function-errors")
#eq($f(x) := x + 1$)
#eq($f(1, 2)$) // red error: expects one argument

// Unit names are callable; built-in constants still require explicit unloading.
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
  assert(values.m.function)
  assert("e" not in values)
}

// Deliberately unloaded names follow the same opt-in rule as scalar variables.
#let unloaded = calculation-builder(key: "unloaded-function-names")
#unload("m", "e", key: "unloaded-function-names")
#unloaded(`m(x) := x + 1`)
#unloaded(`e(x) := x + 2`)
#unloaded(`result := m(1) + e(1)`)
#context assert(unloaded().result.exact == 5.0)
#eq("bad(x) := x+")
#eq("diff(bad(x),x)")
#eq("solve(x^2 = 4,x)")
// Rejected definitions must never fall back to constants or physical units.
#eq("e(2)")
#eq("bad(2)")
#eq("bad(x) := x^2")
#eq("recovered := bad(2)")
#context assert(eq().recovered.exact == 4)
#let degree = calculation-builder(key:"degree-calculus")
#degree("f(x) := sin(x)")
#degree("value1 := f(90)")
#context assert(calc.abs(degree().value1.exact - 1) < 1e-8)
#degree("df(x) := diff(f(x),x)")
#degree("df(90)") // requires radians builder, not a misleading zero
#eq("F(x) := integrate(exp(x^2),x)")
#eq("F(2)") // rejected integral must not become a farad quantity
