#import "@local/math-once:0.16.1": evaluate-code, calculate, calculation-builder, reset, unload, equation, equation-outline

#let result = evaluate-code(`6 * 7`, unit: `kg`)
#assert(result.value == 42)
#assert(result.exact == 42)
#result.display

#let speed = calculate(`10 m/s + 1 km/t`)
#assert(speed.value == 10.2778)
#assert(speed.unit == "m/s")
#speed.display

#let run = calculation-builder(key: "package-import-runner")
#assert(type(equation) == function)
#assert(type(equation-outline) == function)
#run(`v := 10 m/s`)
#run(`x := v * 2 s`)
#context {
  let variables = run()
  assert(variables.x.value == 20.0)
  assert(variables.x.unit == "m")
}
#reset("x", key: "package-import-runner")
#context assert("x" not in run())
#unload("a", key: "package-import-runner")
#run($a := 2$)
#context assert(run().a.value == 2.0)
#reset(key: "package-import-runner")
