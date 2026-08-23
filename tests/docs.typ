#import "../math-once.typ": calculate, calculation-builder, reset, reset-variables, reset-functions, restore-units, reset-unit-aliases, unload, rename-unit, text-unit, equation, equation-outline, evaluate-code, number-labelled-equations

// calculate documentation examples.
#calculate(`1 m + 25 cm`).display
#calculate("1 m + 25 cm").display
#calculate($1 m + 25 "cm"$).display
#calculate(`1 m / 3`, digits: 2).display

#let speed = calculate(`10 m/s`)
#calculate(
  `factor * v * 2 s`,
  scope: (factor: 2, v: speed),
).display
#calculate(`3 m/s`, unit: `km/h`, digits: 1).display
#calculate($902 / 3.6$, unit: $m/s$, digits: 2).display
#calculate(`2047.762752 nm`, size: $10^(-6)$, digits: 9).display
#calculate(`3 m/s to km/h`, digits: 1).display
#calculate(`3 m/s = km/h`, digits: 1).display
#calculate(`floor(3.7 cm)`).display
#calculate(`ceil(-3.2)`).display
#calculate(`round(3.5)`).display
#calculate(`abs(-3 cm)`).display
#calculate($|-3 "cm"|$).display
Inline: #calculate(`100 cm to m`, block: false).display.

#let length = calculate(`250 cm to m`)
#let area = calculate(`x^2`, scope: (x: length))
#assert(area.value == 6.25)

// calculation-builder documentation examples.
#let initial = calculation-builder(
  initial-state: (factor: 2),
  key: "docs-initial-state",
)
#initial(`x := factor * 3`)

#let rounding = calculation-builder(key: "docs-rounding", digits: 2)
#rounding(`x := 1 / 3`)
#rounding(`y := x * 2`, digits: 4)

#let inline = calculation-builder(key: "docs-inline", block: false)
Inline: #inline(`x := 2 + 2`).

#let automatic = calculation-builder(key: "docs-automatic-layout")
Inline: #automatic($1 + 1$).
#automatic($ 1 + 1 $)

#let source = calculation-builder(key: "docs-source")
#source($v := 10 m/s$)
#source($x := v * 2 s$)
#source(`1 m/s to km/h`)
#source(`speed := 10 m/s`)
#source($"other" := 10 m/s$)

#let converted = calculation-builder(key: "docs-unit")
#converted(`v := 10 m/s`, unit: `km/h`, digits: 1)
#converted($x := 902 / 3.6$, unit: $m/s$, digits: 2)

#let sized = calculation-builder(key: "docs-size", digits: 9)
#sized($lambda := 530 "nm"$)
#sized($n := 1$)
#sized($theta_1 := 15 degree$)
#sized($x := (n * lambda) / sin(theta_1)$, size: $10^(-6)$)

#let stored = calculation-builder(key: "docs-state", digits: 2)
#stored($v := 902 / 3.6$)
#context {
  let variables = stored()
  assert(variables.v.value == 250.56)
}

#let dimensioned = calculation-builder(key: "docs-dimensioned", digits: 2)
#dimensioned($v := 10 m/s + 1 "km"/h$)
#dimensioned($x := v * 2 s$, digits: 3)

#let text-subscript = calculation-builder(key: "docs-text-subscript")
#unload("d", key: "docs-text-subscript")
#text-subscript($d := 10 "mm"$)
#text-subscript($lambda := 2 "mm"$)
#text-subscript($n_"maks" := d / lambda$)
#context assert(text-subscript().at("n_maks").exact == 5)

// Symbolic calculation-builder documentation examples.
#let symbolic = calculation-builder(key: "docs-symbolic")
#symbolic(`f := simplify(x^2 + 2*x + 1)`)
#symbolic(`df := diff(f, x)`)
#symbolic(`roots := solve(x^2 - 4, x)`)
#context {
  assert(symbolic().f.symbolic-kind == "expression")
  assert(symbolic().df.operation == "diff")
  assert(symbolic().roots.symbolic-kind == "roots")
}

// reset documentation examples.
#let resettable = calculation-builder(key: "docs-reset")
#resettable(`height := 10 m`)
#resettable(`width := 5 m`)
#reset-variables("height", key: "docs-reset")
#context assert("height" not in resettable() and "width" in resettable())
#reset(key: "docs-reset")
#context assert(resettable().len() == 0)

// Focused reset documentation examples.
#let focused = calculation-builder(key: "docs-focused-reset", initial-state: (factor: 2))
#unload("a", key: "docs-focused-reset")
#rename-unit($m$, $v$, key: "docs-focused-reset")
#focused($a := 3$)
#focused($f(x) := x + 1$)
#focused(`distance := factor * a`)
#reset-variables(key: "docs-focused-reset")
#context assert(focused().factor == 2 and focused().f.function)
#reset-functions("f", key: "docs-focused-reset")
#restore-units("a", key: "docs-focused-reset")
#reset-unit-aliases("v", key: "docs-focused-reset")
#context assert(focused().factor == 2)

// unload documentation examples.
#unload($a$, $b$, key: "docs-reset")
#resettable($a := 2$)
#resettable($b := 3$)
#resettable($x := a + b$)
#context assert(resettable().x.value == 5.0)
#reset(key: "docs-reset")

// rename-unit documentation examples.
#rename-unit($m$, $v$, key: "docs-reset")
#resettable($m := 2$)
#resettable($x := 3 v$)
#context assert(resettable().m.value == 2.0 and resettable().x.si-value == 3.0)
#reset(key: "docs-reset")

// Per-equation caption examples.
#show: number-labelled-equations
#equation-outline(title: [List of Equations])
#equation($ E = m c^2 $, caption: [Mass-energy equivalence]) <docs-energy>
#dimensioned(
  $ p := 2 m * 3 m $,
  caption: [Calculated area],
  supplement: [Formula],
) <docs-area>
See @docs-energy and @docs-area.

// evaluate-code documentation examples.
#evaluate-code(`902 / 3.6`, digits: 2, unit: `m/s`).display
#evaluate-code(`902 / 3.6`).display
#evaluate-code("81 / 9").display
#evaluate-code(`1 / 3`, digits: 3).display

#let first = evaluate-code(`902 / 3.6`, digits: 2)
#let second = evaluate-code(`a * 2`, scope: (a: first), digits: 2)
#assert(second.value == 501.11)

#evaluate-code(`250`, unit: `m/s`).display
#evaluate-code(`250`, unit: $m/s$).display
#evaluate-code(`2 + 2`, block: true).display
Inline: #evaluate-code(`2 + 2`, block: false).display.

// Units documentation examples.
#calculate(`1 µm to nm`).display
#calculate(`1 MHz to Hz`).display
#calculate(`1 mV * 1 A`, unit: `mW`).display
#calculate(`1 MJ to kWh`).display
#calculate(`1 mph to km/h`).display
#calculate(`1 s^-1 to Hz`).display
