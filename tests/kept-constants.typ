#import "../math-once.typ": calculation-builder, unload

// Built-in constants stay symbols in the substitution step by default.
#let eq = calculation-builder(key: "kept-constants", digits: 4)
#eq($r := 2 "cm"$)
#eq($a_1 := pi r^2$)
#eq($r pi$)
#eq($e^2 r$)

// substitute-constants: true restores the numeric substitution.
#let eq2 = calculation-builder(key: "kept-constants-numeric", digits: 4, substitute-constants: true)
#eq2($r := 2 "cm"$)
#eq2($a_1 := pi r^2$)

// An unloaded and reassigned name is an ordinary variable again.
#let eq3 = calculation-builder(key: "kept-constants-unloaded", digits: 4)
#unload("pi", key: "kept-constants-unloaded")
#eq3($pi := 3$)
#eq3($"c" := 2 pi$)

#context {
  assert(calc.abs(eq().a_1.exact - calc.pi * 4e-4) < 1e-12)
  assert(calc.abs(eq2().a_1.exact - calc.pi * 4e-4) < 1e-12)
  assert(eq3().c.exact == 6)
}
