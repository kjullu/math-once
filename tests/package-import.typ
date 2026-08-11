#import "@local/math-once:0.1.0": calculate, qalc, qalc-builder

#let result = calculate(`6 * 7`, unit: `kg`)
#assert(result.value == 42)
#assert(result.exact == 42)
#result.display

#let speed = qalc(`10 m/s + 1 km/t`)
#assert(speed.value == 10.2778)
#assert(speed.unit == "m/s")
#speed.display

#let run = qalc-builder(key: "package-import-runner")
#run(`v = 10 m/s`)
#run(`d = v * 2 s`)
#context {
  let variables = run()
  assert(variables.d.value == 20.0)
  assert(variables.d.unit == "m")
}
