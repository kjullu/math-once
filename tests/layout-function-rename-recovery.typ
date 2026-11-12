#import "../math-once.typ": calculation-builder, unload, rename-unit, reset

#let eq = calculation-builder()
#unload("m")
#eq(`m(x) := x+1`)
#eq(`y := m(3)`)
#eq(`z := 2*y`)
#context assert(eq().z.exact == 8)

#reset()
// A reserved function definition remains an error and cannot write state.
#eq(`m(x) := x+1`)
#context assert("m" not in eq())

#reset()
// Rename depends on both an earlier unload and an earlier alias.
#unload("t")
#rename-unit("h", "t")
#rename-unit("t", "hour")
#eq(`x := 2 "hour"`)
#context assert(eq().x.si-value == 7200)

#reset()
// A failed rename must not replace a stored variable or unload its source.
#eq(`foo := 3`)
#rename-unit("m", "foo")
#context {
  assert(eq().foo.exact == 3)
  assert("m" not in eq())
}
