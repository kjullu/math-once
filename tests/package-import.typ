#import "@local/math-once:0.7.0": evaluate-code, calculate, calculation-builder, equation, equation-outline

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
#run(`v = 10 m/s`)
#run(`d = v * 2 s`)
#context {
  let variables = run()
  assert(variables.d.value == 20.0)
  assert(variables.d.unit == "m")
}
