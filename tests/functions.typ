#import "../math-once.typ": calculation-builder

#let eq = calculation-builder(key: "functions", digits: 2)

// Ordinary equals remains display-only.
#eq($g(x) = x + 2$)

// := stores scalar functions and supports later numeric calls.
#eq($f(x) := x + 1$)
#eq($f(2)$)
#eq($u(x) := x * 2 m$)
#eq($u(3)$)
#eq($h(x, y) := x * y + 1$)
#eq($h(3, 4)$)

// Arrow names and vectors are accepted and stored symbolically.
#eq($arrow(s)(t) := vec(t^3 - 3t^2 - 4t + 12, t^2 - 4)$)
#eq($arrow(s)(2)$)

#context {
  let state = eq()
  assert("g" not in state)
  assert(state.f.function)
  assert(state.f.parameters == ("x",))
  assert(state.h.parameters == ("x", "y"))
  assert(state.u.function)
  assert(state.arrow_s.function)
  assert(state.arrow_s.vector)
}
