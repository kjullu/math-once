#import "../math-once.typ": calculate, calculation-builder

#set page(width: 16cm, height: auto, margin: 1cm)

#let least = calculate(`1.2 + 3.456`, digits: auto)
#assert(least.digits == 1)
#assert(least.value == 4.7)
#assert(calc.abs(least.exact - 4.656) < 1e-12)
#least.display

#assert(calculate($1.2 + 3.456$, digits: auto).value == 4.7)
#assert(calculate(`1 + 3.456`, digits: auto).digits == 0)
#assert(calculate(`-1.20 * 3.456`, digits: auto).value == -4.15)
#assert(calculate(`1.20 / 3.456`, digits: auto).value == 0.35)
#assert(calculate(`1.20e-2`, digits: auto).digits == 4)
#assert(calculate(`1.20e+2`, digits: auto).digits == 0)
#assert(calculate(`1.20E-2`, digits: auto).digits == 4)
#assert(calculate(`.120 + .1234`, digits: auto).digits == 3)

#let original = calculate(`1.20`, digits: auto)
#let reused = calculate(`x + 3.456`, scope: (x: original, unused: 1), digits: auto)
#assert(reused.digits == 2)
#assert(reused.value == 4.66)
#reused.display
#assert(calculate(`x + 3.456`, scope: (x: 1.2, unused: 1), digits: auto).digits == 1)
#let fixed = calculate(`1.20`)
#assert(calculate(`x + 3.456`, scope: (x: fixed), digits: auto).digits == 2)
#assert(calculate(`1.234 + 2.345`, digits: 1).value == 3.6)
#assert(calculate(`1.234 + 2.345`).digits == 4)

#let converted = calculate(`1.20 m to cm`, digits: auto)
#assert(converted.digits == 2)
#assert(converted.value == 120)
#converted.display
#let sized = calculate(`1.234 m`, unit: `m`, size: 0.01, digits: auto)
#assert(sized.digits == 3)
#assert(sized.value == 123.4)
#let paired = calculate(`1.20 ± 0.345`, digits: auto)
#assert(paired.branches.all(branch => branch.digits == 2))
#paired.display

#let eq = calculation-builder(key: "auto-digits", digits: auto)
#eq(`x := 1.20`)
#eq(`y := x + 3.456`)
#eq(`z := y / 2.00`)
#eq(`override := x / 3`, digits: 3)
#eq(`v := vec(1.20, 3.456)`)
#eq(`w := v * 2.00`)
#eq(`f(t) := t + 1.20`)
#eq(`fromfunction := f(3.456)`)
#context {
  let values = eq()
  assert(values.x.digits == 2)
  assert(values.y.value == 4.66)
  assert(values.z.digits == 2)
  assert(values.z.value == 2.33)
  assert(values.override.digits == 3)
  assert(values.w.components.all(item => item.digits == 2))
  assert(values.fromfunction.digits == 2)
}

#let override = calculation-builder(key: "auto-digits-override")
#override(`x := 1.2 + 3.456`, digits: auto)
#context { assert(override().x.value == 4.7) }
