#import "../math-once.typ": evaluate-code, calculate, calculation-builder, number-labelled-equations

#set text(lang: "en")

= `evaluate-code`

// Raw source, default integer rounding, and inline output.
#let plain = evaluate-code(`902 / 3.6`)
#plain.display

// String source, decimal rounding, a scope variable, a unit label, and a
// centered block equation exercise every evaluate-code argument.
#let labelled = evaluate-code(
  "x / 3.6",
  digits: 2,
  scope: (x: 902),
  unit: `m/s`,
  block: true,
)
#labelled.display

// A previous evaluate-code result is automatically unwrapped to its exact value.
#let reused = evaluate-code(`a * 2`, scope: (a: labelled), digits: 1)
#reused.display

#assert(plain.value == 251.0)
#assert(labelled.value == 250.56)
#assert(calc.abs(labelled.exact - 250.55555555555554) < 0.000000000001)
#assert(labelled.source == "x / 3.6")
#assert(labelled.unit.text == "m/s")

= `calculate`

// Automatic compatible-unit conversion and centered output.
#let speed = calculate(`10 m/s + 1 km/t`)
#speed.display

// `unit` selects the output unit; `digits` controls display rounding.
#let converted = calculate(`(1 m/s + 2 m/s)`, unit: `km/h`, digits: 1)
#converted.display

// `to` is an alternative output-unit syntax.
#calculate(`10 m/s to km/h`, digits: 2).display

// `=` is another equivalent output-unit syntax.
#calculate(`1 m/s + 1 m/s = km/s`).display

// Both ordinary numbers and complete calculate results can be scope variables.
#let distance = calculate(
  `factor * v * 2 s`,
  scope: (factor: 2, v: speed),
  unit: `m`,
  digits: 3,
)
#distance.display

// Inline output remains available.
Inline: #calculate(`100 cm to m`, block: false).display.

#assert(speed.value == 10.2778)
#assert(converted.value == 10.8)
#assert(distance.unit == "m")
#assert(type(distance.si-value) == float)
#assert(type(distance.dimensions) == dictionary)
#assert(distance.source == "factor * v * 2 s")

= `calculation-builder`

// Builder defaults: initial state, unique state key, rounding, and layout.
#let run = calculation-builder(
  initial-state: (factor: 2),
  key: "all-functions-example",
  digits: 2,
  block: true,
)

// Assignments store full dimensioned results for later calls.
#run(`v = 10 m/s + 1 km/t`)
#run(`d = factor * v * 2 s`, unit: `m`, digits: 3)

// A call without assignment calculates without adding a variable. Per-call
// `block`, `digits`, and `unit` override the builder defaults.
Inline runner result: #run(`1 m/s`, unit: `km/h`, digits: 1, block: false).

// Calling the runner without an expression retrieves all stored variables.
#context {
  let variables = run()
  assert(variables.factor == 2)
  assert(variables.v.unit == "m/s")
  assert(variables.d.unit == "m")
  [Stored distance: #variables.d.value #variables.d.unit]
}

// Normal Typst math input visibly substitutes stored
// variables before showing the final result.
#let eq = calculation-builder(key: "math-input-example", digits: 2)
#eq($v = 902 / 3.6$)
#eq($a = v * 2$)

= `number-labelled-equations`

// Only labelled block equations receive a number and a reference name.
#show: number-labelled-equations.with(supplement: [Equation])

$ 1 + 1 = 2 $
$ E = m c^2 $ <energy-equation>

See @energy-equation.
