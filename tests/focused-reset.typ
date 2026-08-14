#import "../math-once.typ": calculation-builder, reset, reset-variables, reset-functions, restore-units, reset-unit-aliases, unload, rename-unit

#let eq = calculation-builder(
  key: "focused-reset",
  initial-state: (factor: 2),
)

#unload("a", key: "focused-reset")
#rename-unit($m$, $v$, key: "focused-reset")
#eq($a := 3$)
#eq(`x := factor * a`)
#eq($f(t) := t + 1$)
#eq(`distance := 4 v`)

// Values can be cleared without changing functions or unit configuration.
#reset-variables("x", key: "focused-reset")
#context {
  let values = eq()
  assert("x" not in values)
  assert(values.a.value == 3.0)
  assert(values.factor == 2)
  assert(values.f.function)
}
#eq(`another := 5 v`)
#context assert(eq().another.si-value == 5.0)

// Clearing all values restores initial-state and retains unloaded names.
#eq(`factor := 9`)
#reset-variables(key: "focused-reset")
#context {
  let values = eq()
  assert(values.factor == 2)
  assert(values.f.function)
  assert("a" not in values)
  assert("distance" not in values)
  assert("another" not in values)
}
#eq($a := 7$)
#context assert(eq().a.value == 7.0)

// Functions are independent, and an overwritten initial value is restored.
#eq(`factor(t) := t * 2`)
#reset-functions("factor", key: "focused-reset")
#context assert(eq().factor == 2)
#reset-functions(key: "focused-reset")
#context assert("f" not in eq())

// Restoring an unloaded catalog name also removes a variable using that name.
#restore-units("a", key: "focused-reset")
#context assert("a" not in eq())
#eq($a := 4$) // red error: a is the are unit again
#context assert("a" not in eq())

// Aliases survive value resets but can be reset separately.
#reset-unit-aliases("v", key: "focused-reset")
#eq($m := 2$) // red error: m is metre again
#eq(`alias_result := 2 v`) // red error: v is no longer an alias
#context {
  assert("m" not in eq())
  assert("alias_result" not in eq())
  assert(eq().factor == 2)
}

// Empty focused calls affect every item in only their own category.
#unload("b", key: "focused-reset")
#restore-units(key: "focused-reset")
#rename-unit($s$, $z$, key: "focused-reset")
#reset-unit-aliases(key: "focused-reset")
#reset(key: "focused-reset")
#context assert(eq().len() == 0)
