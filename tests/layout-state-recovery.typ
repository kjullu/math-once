#import "../math-once.typ": calculation-builder, unload, reset

#let eq = calculation-builder()

// The unload and the assignment must reach the state sequence together.
#unload("m")
#eq(`m := 5 "kg"`)
#eq(`x := 2*m`)
#eq(`y := x+3 "kg"`)
#context {
  assert(eq().m.unloaded)
  assert(eq().y.si-value == 13)
  assert(eq().m.display.func() == math.equation)
}

#context eq().m.display

#reset()
// Errors must not write values, including when an unload follows the error.
#eq(`m := 5`)
#eq(`e := 3`)
#context {
  assert("m" not in eq())
  assert("e" not in eq())
}
#unload("m")
#eq(`x := 2*m`)
#context assert("x" not in eq())
#eq(`m := 2 ± 1`)
#context assert("m" not in eq())

#reset()
// A missing absolute-value input must recover without changing its display.
#eq(`x := 3`)
#eq(`y := |x|`)
#eq(`z := y+1`)
#context assert(eq().z.exact == 4)
