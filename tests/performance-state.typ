#import "../math-once.typ": calculation-builder, reset, unload

#set page(width: 19cm, height: auto)

// Quoted variable reads must not be mistaken for an unused assignment target.
#let eq = calculation-builder(key: "performance-state", digits: 2)
#eq(`"velocity" := 1.25 m/s`)
#eq(`"velocity" := 2 * "velocity"`)
#context {
  let result = eq().velocity
  assert(result.exact == 2.5)
  assert(result.unit == "m/s")
  assert(result.display.func() == math.equation)
  assert(result.keys().position(key => key == "display") < result.keys().position(key => key == "variable"))
}

// Direct rendering preserves subscripts and fraction/power content too.
#eq(`component_003 := 7`)
#eq(`component_alpha := component_003^2`)
#eq(`ratio := component_003 / component_alpha`)
#context { assert(eq().ratio.exact == 1 / 7) }
#eq(`x := 2`)
#eq(`y_2 := 3`)
#eq(`power := x^y_2`)
#context { assert(eq().power.exact == 8) }

// An identical call can succeed, then fail after a dependency is removed.
// The failed call shows an error while preserving the earlier stored value.
#eq(`seed := 4`)
#eq(`x := seed + 1`)
#reset(key: "performance-state", variables: ("seed",))
#eq(`x := seed + 1`)
#context { assert(eq().x.exact == 5) }

// Repeated, hidden, and self-dependent writes retain public result displays.
#eq(`x := 7`, show-result: false)
#eq(`x := 7`, hidden: true)
#eq(`x := x + 1`)
#context {
  let result = eq().x
  assert(result.exact == 8)
  assert(result.display.body != [])
}
#reset(key: "performance-state")
#context { assert(eq().len() == 0) }

// A failed overwrite after restoring a unit must not read a stale success.
#let units = calculation-builder(key: "performance-unit-state")
#unload("m", key: "performance-unit-state")
#units(`m := 3 "kg"`, hidden: true)
#reset(key: "performance-unit-state", units: true)
#units(`m := 3 "kg"`)
#context { assert(units().len() == 0) }
