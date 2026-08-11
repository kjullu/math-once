#import "../math-once.typ": calculation-builder, reset, unload

#let eq = calculation-builder()

// Single-letter math names are convenient for unit aliases. `c` is already
// available as a variable and is therefore a harmless no-op.
#unload($a$, $b$, $c$)
#context assert(eq().len() == 0)
#eq($a := 2$)
#eq($b := 3$)
#eq($c := a + b$)
#eq($x := c * 2 m$)

#context {
  let variables = eq()
  assert(variables.a.value == 2.0)
  assert(variables.b.value == 3.0)
  assert(variables.c.value == 5.0)
  assert(variables.x.value == 10.0)
  assert(variables.x.unit == "m")
}

// Selective reset restores only that unit name.
#reset("a")
#eq($a := 4$) // red error: `a` is the are unit again
#context {
  let variables = eq()
  assert("a" not in variables)
  assert(variables.b.value == 3.0)
  assert(variables.c.value == 5.0)
}

// A full reset clears variables and restores every unloaded unit.
#reset()
#context assert(eq().len() == 0)

// Custom builders use the same key for unload and reset.
#let custom = calculation-builder(key: "unload-custom-key")
#unload("m", key: "unload-custom-key")
#custom($m := 1$)
#custom($x := m * 2$)
#context assert(custom().x.value == 2.0)
#reset(key: "unload-custom-key")
#context assert(custom().len() == 0)
