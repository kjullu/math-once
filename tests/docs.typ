#import "../math-once.typ": qalc, qalc-builder, calculate

// qalc documentation examples.
#qalc(`1 m + 25 cm`).display
#qalc("1 m + 25 cm").display
#qalc($1 m + 25 "cm"$).display
#qalc(`1 m / 3`, digits: 2).display

#let speed = qalc(`10 m/s`)
#qalc(
  `factor * v * 2 s`,
  scope: (factor: 2, v: speed),
).display
#qalc(`3 m/s`, unit: `km/h`, digits: 1).display
#qalc($902 / 3.6$, unit: $m/s$, digits: 2).display
#qalc(`3 m/s to km/h`, digits: 1).display
#qalc(`3 m/s = km/h`, digits: 1).display
Inline: #qalc(`100 cm to m`, block: false).display.

#let length = qalc(`250 cm to m`)
#let area = qalc(`x^2`, scope: (x: length))
#assert(area.value == 6.25)

// qalc-builder documentation examples.
#let initial = qalc-builder(
  initial-state: (factor: 2),
  key: "docs-initial-state",
)
#initial(`a = factor * 3`)

#let rounding = qalc-builder(key: "docs-rounding", digits: 2)
#rounding(`x = 1 / 3`)
#rounding(`y = x * 2`, digits: 4)

#let inline = qalc-builder(key: "docs-inline", block: false)
Inline: #inline(`x = 2 + 2`).

#let source = qalc-builder(key: "docs-source")
#source($v = 10 m/s$)
#source($d = v * 2 s$)
#source(`1 m/s to km/h`)
#source(`speed = 10 m/s`)
#source($"other" = 10 m/s$)

#let converted = qalc-builder(key: "docs-unit")
#converted(`v = 10 m/s`, unit: `km/h`, digits: 1)
#converted($u = 902 / 3.6$, unit: $m/s$, digits: 2)

#let stored = qalc-builder(key: "docs-state", digits: 2)
#stored($v = 902 / 3.6$)
#context {
  let variables = stored()
  assert(variables.v.value == 250.56)
}

#let dimensioned = qalc-builder(key: "docs-dimensioned", digits: 2)
#dimensioned($v = 10 m/s + 1 "km"/h$)
#dimensioned($d = v * 2 s$, digits: 3)

// calculate documentation examples.
#calculate(`902 / 3.6`, digits: 2, unit: `m/s`).display
#calculate(`902 / 3.6`).display
#calculate("81 / 9").display
#calculate(`1 / 3`, digits: 3).display

#let first = calculate(`902 / 3.6`, digits: 2)
#let second = calculate(`a * 2`, scope: (a: first), digits: 2)
#assert(second.value == 501.11)

#calculate(`250`, unit: `m/s`).display
#calculate(`250`, unit: $m/s$).display
#calculate(`2 + 2`, block: true).display
Inline: #calculate(`2 + 2`, block: false).display.

// Units documentation examples.
#qalc(`1 µm to nm`).display
#qalc(`1 MHz to Hz`).display
#qalc(`1 mV * 1 A`, unit: `mW`).display
#qalc(`1 MJ to kWh`).display
#qalc(`1 mph to km/h`).display
#qalc(`1 s^-1 to Hz`).display
