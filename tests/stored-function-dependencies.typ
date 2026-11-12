#import "../math-once.typ": calculation-builder, unload

// Stored functions read the variables their bodies name, including through
// other functions, at the time of each call.
#let eq = calculation-builder(strict: true)
#unload("a", "b")
#eq(`x := 100`)
#eq(`f_1(x) := x + a`)
#eq(`f_2(y) := f_1(y) * b`)
#eq(`a := 2`)
#eq(`b := 3`)
#eq(`z := f_2(4)`)
#context assert(eq().z.exact == 18)

// Redefining a dependency changes later calls. The parameter `x` shadows the
// stored `x`.
#eq(`a := 7`)
#eq(`w := f_2(4)`)
#context assert(eq().w.exact == 33)
#context assert(eq().x.exact == 100)

// Redefining a nested function must affect later calls without changing old
// results. Unrelated state must survive the narrowed evaluation scope.
#eq(`f_1(x) := x * a`)
#eq(`latest := f_2(4)`, hidden: true)
#context {
  assert(eq().latest.exact == 84)
  assert(eq().z.exact == 18)
  assert(eq().w.exact == 33)
  assert(eq().x.exact == 100)
  assert(eq().b.exact == 3)
  assert("display" in eq().latest)
}
