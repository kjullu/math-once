#import "../math-once.typ": evaluate-code, calculate, calculation-builder, reset, reset-variables, reset-functions, restore-units, reset-unit-aliases, unload, rename-unit, text-unit, equation, equation-outline, number-labelled-equations

#calculate($1 / m$, unit: $#text-unit("lines") / m$).display

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
#let speed = calculate(`10 m/s + 1 km/h`)
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

// Definitions store full dimensioned results for later calls.
#run(`v := 10 m/s + 1 km/h`)
#run(`x := factor * v * 2 s`, unit: `m`, digits: 3)

// A call without a definition calculates without adding a variable. Per-call
// `block`, `digits`, and `unit` override the builder defaults.
Inline runner result: #run(`1 m/s`, unit: `km/h`, digits: 1, block: false).

// Calling the runner without an expression retrieves all stored variables.
#context {
  let variables = run()
  assert(variables.factor == 2)
  assert(variables.v.unit == "m/s")
  assert(variables.x.unit == "m")
  [Stored distance: #variables.x.value #variables.x.unit]
}

// Normal Typst math input visibly substitutes stored
// variables before showing the final result.
#let eq = calculation-builder(key: "math-input-example", digits: 2)
#eq($v := 902 / 3.6$)
#eq($x := v * 2$)

= Symbolic builder operations

// CAS expressions use the same := storage and can feed later CAS calls.
#let symbolic = calculation-builder(key: "all-functions-symbolic")
#symbolic(`f := simplify(x^2 + 2*x + 1)`)
#symbolic(`df := diff(f, x)`)
#symbolic(`roots := solve(x^2 - 4, x)`)
#context {
  assert(symbolic().df.symbolic-kind == "expression")
  assert(symbolic().roots.symbolic-kind == "roots")
}

= `reset`

`reset()` is the broad operation. The focused reset functions in the following
section preserve unrelated builder state.

// Reset clears the entire matching state, including initial values.
#reset(key: "all-functions-example")
#context assert(run().len() == 0)

= Focused resets

#let focused = calculation-builder(
  key: "all-functions-focused-reset",
  initial-state: (factor: 2),
)
#unload("a", key: "all-functions-focused-reset")
#rename-unit($m$, $v$, key: "all-functions-focused-reset")
#focused($a := 3$)
#focused($f(x) := x + 1$)
#focused(`distance := factor * a`)

// Clear calculated values while restoring initial-state and retaining the
// stored function, unloaded name, and unit alias.
#reset-variables(key: "all-functions-focused-reset")
#context assert(focused().factor == 2 and focused().f.function)

// Each remaining category can be reset independently.
#reset-functions("f", key: "all-functions-focused-reset")
#restore-units("a", key: "all-functions-focused-reset")
#reset-unit-aliases("v", key: "all-functions-focused-reset")
#context assert(focused().factor == 2)

= `unload`

// Reserved unit names can temporarily become variables in the same state.
#unload($a$, $b$, key: "all-functions-example")
#run($a := 2$)
#run($b := 3$)
#run($x := a + b$)
#context assert(run().x.value == 5.0)

// Reset clears the variables and restores the unit meanings.
#reset(key: "all-functions-example")

= `rename-unit`

// Move metre to v, leaving m available as a variable until reset.
#rename-unit($m$, $v$, key: "all-functions-example")
#run($m := 2$)
#run($x := 3 v$)
#context assert(run().m.value == 2.0 and run().x.si-value == 3.0)
#reset(key: "all-functions-example")

= `number-labelled-equations`

// Only labelled block equations receive a number and a reference name.
#show: number-labelled-equations.with(
  supplement: [Equation],
  captions: (energy: [Mass-energy equivalence]),
)

#equation-outline(title: [List of Equations])

$ 1 + 1 = 2 $
$ E = m c^2 $ <energy>

= `equation`

// The figure-like caption stays attached to a native equation and its label.
#equation(
  $ p = m v $,
  caption: [Momentum as mass times velocity],
  gap: 0.4em,
) <momentum>

// Calculated equations accept the same per-call caption style.
#eq(
  $ y := x / 2 $,
  caption: [The recovered speed],
  supplement: [Formula],
) <recovered-speed>

See @energy.
See also @momentum.
See also @recovered-speed.
