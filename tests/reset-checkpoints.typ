#import "../math-once.typ": calculation-builder, reset, reset-variables, reset-functions, unload, restore-units, rename-unit, reset-unit-aliases

// Reused content follows placement order, including repeated reset content.
#let eq = calculation-builder(initial-state: (factor: 2))
#let other = calculation-builder(key: "checkpoint-other", initial-state: (factor: 3))
#let clear = reset()
#let assignment = eq(`value := 7`, hidden: true)
#eq(`length := factor * 3 m`)
#other(`length := factor * 4 m`)
#context assert(eq().length.exact == 6)
#clear
#context {
  assert(eq().len() == 0)
  assert(other().length.exact == 12)
}
#assignment
#context assert(eq().value.exact == 7)
#clear
#context assert(eq().len() == 0)

// Empty consecutive checkpoints and readers with the same key agree.
#reset()
#let same = calculation-builder(initial-state: (ignored: 99))
#context assert(same().len() == 0)
#assignment
#context assert(same().value.exact == 7)

// Every configuration writer must address the active checkpoint.
#eq(`f(x) := x * 2`)
#eq(`answer := f(value)`)
#context assert(eq().answer.exact == 14)
#reset-variables("value")
#reset-functions("f")
#context {
  assert("value" not in eq())
  assert("f" not in eq())
  assert(eq().answer.exact == 14)
}
#unload("m")
#eq(`m := 4`)
#restore-units("m")
#context assert("m" not in eq())
#rename-unit("m", "checkpointmetre")
#eq(`distance := 2 checkpointmetre`)
#reset-unit-aliases()
#eq(`distance := 3 m`)
#context assert(eq().distance.exact == 3)

// A full reset removes initial values, functions, unloads, and aliases.
#unload("pi")
#eq(`pi := 3`)
#rename-unit("s", "checkpointsecond")
#reset()
#context assert(eq().len() == 0)
#eq(`circle := pi * 2`)
#eq(`duration := 2 s`)
#context {
  assert(calc.abs(eq().circle.exact - 2 * calc.pi) < 0.000000001)
  assert(eq().duration.exact == 2)
  assert(other().length.exact == 12)
}
#reset(key: "checkpoint-other")
#context assert(other().len() == 0)

// Long dependency chains must still converge after a reset, including
// assignments that produce no visible output.
#let chain = calculation-builder(key: "checkpoint-chain")
#reset(key: "checkpoint-chain")
#chain(`step_0 := 1`, hidden: true)
#for index in range(1, 20) {
  chain("step_" + str(index) + " := step_" + str(index - 1) + " + 1", hidden: true)
}
#context assert(chain().at("step_19").exact == 20)

#let checked = calculation-builder(key: "checkpoint-strict", strict: true)
#reset(key: "checkpoint-strict")
#checked(`value := 5`, hidden: true)
#context assert(checked().value.exact == 5)

// Even keys that look like an internal state name remain independent.
#let unusual-key = "math-once-checkpoint-state:" + repr(("checkpoint-strict", 1))
#let unusual = calculation-builder(key: unusual-key)
#unusual(`value := 9`, hidden: true)
#context {
  assert(unusual().value.exact == 9)
  assert(checked().value.exact == 5)
}

// Selective reset options and legacy helpers share each active checkpoint.
#let mixed = calculation-builder(key: "checkpoint-mixed", initial-state: (seed: 2))
#reset(key: "checkpoint-mixed")
#mixed(`x := 7`)
#mixed(`f(t) := t + 1`)
#reset(variables: ("x",), key: "checkpoint-mixed")
#context assert("x" not in mixed() and mixed().f.function)
#mixed(`x := 9`)
#reset-functions("f", key: "checkpoint-mixed")
#context assert(mixed().x.exact == 9 and "f" not in mixed())
#rename-unit("m", "mixedmetre", key: "checkpoint-mixed")
#mixed(`m := 4`)
#reset(units: ("m",), key: "checkpoint-mixed")
#context assert(mixed().m.exact == 4)
#reset-unit-aliases("m", key: "checkpoint-mixed")
#mixed(`distance := 2 m`)
#context assert("m" not in mixed() and mixed().distance.exact == 2)
#reset(key: "checkpoint-mixed")
#context assert(mixed().len() == 0)
