#import "../math-once.typ": calculation-builder, unload

#let eq = calculation-builder(key: "store-syntax-test")

// A simple `=` calculation shows its result but does not create state.
#eq($x = 1 + 1$)
#context assert(eq().len() == 0)

// An unknown variable renders a red message instead of panicking.
#eq($x + 1$)
#context assert(eq().len() == 0)

// `:=` stores the exact result but is rendered as an ordinary equality.
#eq($x := 1 + 1$)
#context {
  let variables = eq()
  assert(variables.x.value == 2.0)
  assert(variables.x.exact == 2.0)
}

// Typst represents a fraction's unit factors with redundant parentheses.
// They must not make a direct value repeat as `G = value = value`.
#eq($G := 9.81 m/s^2$)
#context {
  let gravity = eq().G
  assert(gravity.value == 9.81)
  assert(repr(gravity.display.body).matches(regex("\\[=\\]")).len() == 1)
}

// Meaningful arithmetic parentheses still keep the calculated result visible.
#eq($"computed_gravity" := (4 + 5.81) m/s^2$)
#context {
  let gravity = eq().computed_gravity
  assert(gravity.value == 9.81)
  assert(repr(gravity.display.body).matches(regex("\\[=\\]")).len() == 2)
}

// Later expressions visibly substitute and calculate the stored value.
#eq($x + 1$)

// Reserved unit spellings still require unload before either storage form.
#let units = calculation-builder(key: "store-syntax-unit-test")
#unload($a$, key: "store-syntax-unit-test")
#units($a = 1 + 1$)
#context assert(units().len() == 0)
#units($a + 1$)

#units($a := 1 + 1$)
#context assert(units().a.value == 2.0)
#units($a + 1$)

// A calculated equals expression substitutes stored variables without storing
// its own left-hand name.
#let display = calculation-builder(key: "calculated-equals")
#unload($d$, key: "calculated-equals")
#display($d := 5262 "km"$)
#display($r = d / 2$)
#context {
  assert(display().d.value == 5262.0)
  assert("r" not in display())
}

// A symbolic equation with unknown right-hand names remains display-only.
#display($E = q z$)
#context assert("E" not in display())
