#import "../math-once.typ": calculation-builder

#let eq = calculation-builder(key: "functions", digits: 2)

// Ordinary equals remains display-only.
#eq($g(x) = x + 2$)

// := stores scalar functions and supports later numeric calls.
#eq($f(x) := x + 1$)
#eq($f(2)$)
#eq($f_2(x) := x * 2 m$)
#eq($f_2(3)$)
#eq($f_3(x, y) := x * y + 1$)
#eq($f_3(3, 4)$)

// Arrow names and vectors are accepted and stored symbolically.
#eq($arrow(s)(t) := vec(t^3 - 3t^2 - 4t + 12, t^2 - 4)$)
#eq($arrow(s)(2)$)

// Stored calls expand until no stored function calls remain.
#eq(`f_4(x) := x + 1`)
#eq(`f_5(x) := f_4(x) + 1`)
#eq(`f_6(x) := f_5(x) + 1`)
#eq(`f_7(x) := f_6(x) + 1`)
#eq(`deep := f_7(1)`)

#context {
  let state = eq()
  assert("g" not in state)
  assert(state.f.function)
  assert(state.f.parameters == ("x",))
  assert(state.f_3.parameters == ("x", "y"))
  assert(state.f_2.function)
  assert(state.arrow_s.function)
  assert(state.arrow_s.vector)
  assert(state.deep.exact == 5.0)
}
