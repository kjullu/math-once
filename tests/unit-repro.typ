#import "../math-once.typ": calculate, calculation-builder

#let result = calculate(`1 m/s + 1 m/s`, unit: `km/s`)
#assert(result.value == 0.002)
#assert(result.unit == "km/s")
#assert(result.si-value == 2.0)
#result.display

#let equals-result = calculate(`1 m/s + 1 m/s = km/s`)
#assert(equals-result.value == 0.002)
#assert(equals-result.unit == "km/s")
#equals-result.display

// In a stateful runner, the first `=` assigns and the second selects a unit.
#let run = calculation-builder(key: "equals-unit-repro")
#run(`v = 1 m/s + 1 m/s = km/s`)
#context {
  let variables = run()
  assert(variables.v.value == 0.002)
  assert(variables.v.unit == "km/s")
}
