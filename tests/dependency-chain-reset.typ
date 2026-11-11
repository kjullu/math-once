#import "../math-once.typ": calculation-builder, reset

// A long chain of dependent assignments settles to the right values, before
// and after selective and full resets.
#let eq = calculation-builder()
#eq(`step_0 := 1`, hidden: true)
#for i in range(1, 26) {
  eq("step_" + str(i) + " := step_" + str(i - 1) + " + 1", hidden: true)
}
#context assert(eq().step_25.exact == 26)

#reset(variables: ("step_5",))
#eq(`x := step_25 + 1`)
#context assert(eq().x.exact == 27)

#reset()
#eq(`step_0 := 2`, hidden: true)
#for i in range(1, 26) {
  eq("step_" + str(i) + " := step_" + str(i - 1) + " + 1", hidden: true)
}
#context assert(eq().step_25.exact == 27)
