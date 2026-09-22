#import "../math-once.typ": calculation-builder, reset, unload, rename-unit

#let eq = calculation-builder(
  key: "unified-reset",
  initial-state: (factor: 2),
)

#unload("a", key: "unified-reset")
#rename-unit($m$, $v$, key: "unified-reset")
#eq($a := 3$)
#eq(`x := factor * a`)
#eq($f(t) := t + 1$)
#eq(`distance := 4 v`)

// Values can be cleared without changing functions or unit configuration.
#reset(variables: ("x",), key: "unified-reset")
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
#reset(variables: true, key: "unified-reset")
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
#reset(functions: ("factor",), key: "unified-reset")
#context assert(eq().factor == 2)
#reset(functions: true, key: "unified-reset")
#context assert("f" not in eq())

// Restoring an unloaded catalog name also removes a variable using that name.
#reset(units: ("a",), key: "unified-reset")
#context assert("a" not in eq())
#eq($a := 4$) // red error: a is the are unit again
#context assert("a" not in eq())

// Aliases survive value resets but can be reset separately.
#reset(aliases: ("v",), key: "unified-reset")
#eq($m := 2$) // red error: m is metre again
#eq(`alias_result := 2 v`) // red error: v is no longer an alias
#context {
  assert("m" not in eq())
  assert("alias_result" not in eq())
  assert(eq().factor == 2)
}

// true affects every item in only its own category.
#unload("b", key: "unified-reset")
#reset(units: true, key: "unified-reset")
#rename-unit($s$, $z$, key: "unified-reset")
#reset(aliases: true, key: "unified-reset")
#reset(key: "unified-reset")
#context assert(eq().len() == 0)

// Explicit empty/false selections must never become a full reset.
#let other = calculation-builder(key: "untouched", initial-state: (sentinel: 17))
#other(`x := 11`)
#eq(`x := 5`)
#reset(variables: (), functions: false, units: (), aliases: false, key: "unified-reset")
#reset(variables: false, key: "unified-reset")
#context assert(eq().x.exact == 5)
#reset(variables: ("missing",), key: "unified-reset")
#context assert(eq().x.exact == 5)

// Select multiple categories with strings, raw text, and math names.
#unload("a", "b", "e", "pi", key: "unified-reset")
#eq(`a := 3`)
#eq(`b := 4`)
#eq(`e := 7`)
#eq(`pi := 8`)
#eq(`f(t) := t + 1`)
#eq(`helper(t) := t + 2`)
#rename-unit($m$, $v$, key: "unified-reset")
#rename-unit($s$, $z$, key: "unified-reset")
#eq(`m := 6`)
#reset(units: ("m",), key: "unified-reset")
#context assert(eq().m.exact == 6)
#reset(variables: ($x$,), functions: (`f`,), units: ("a", "pi"), aliases: ($m$,), key: "unified-reset")
#context {
  let values = eq()
  assert("x" not in values and "f" not in values)
  assert("a" not in values and "m" not in values)
  assert(values.b.exact == 4)
  assert(values.helper.function)
}
#eq(`restored := 2 m + 1 m`)
#eq(`aliased := 2 z`)
#eq(`constant := pi`)
#eq(`remaining_constant := e`)
#context {
  assert(eq().restored.si-value == 3)
  assert(eq().aliased.si-value == 2)
  assert(eq().constant.exact == calc.pi)
  assert(eq().remaining_constant.exact == 7)
}
#reset(variables: true, functions: true, units: true, aliases: true, key: "unified-reset")
#context {
  assert(eq().len() == 0)
  assert(other().x.exact == 11 and other().sentinel == 17)
}
#eq(`constants := e + pi`)
#context assert(calc.abs(eq().constants.exact - (calc.e + calc.pi)) < 1e-12)

// Combined focused reset keeps initial values; full reset discards them.
#let seeded = calculation-builder(key: "seeded", initial-state: (factor: 2))
#seeded(`factor := 9`)
#reset(variables: true, functions: true, units: true, aliases: true, key: "seeded")
#context assert(seeded().factor == 2)
#reset(key: "seeded")
#reset(variables: true, key: "seeded")
#context assert(seeded().len() == 0)

// Named selections use the default builder key when key is omitted.
#let default = calculation-builder()
#default(`x := 3`)
#default(`y := 4`)
#reset(variables: ("x",))
#context {
  assert("x" not in default())
  assert(default().y.exact == 4)
}
