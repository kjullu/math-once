#import "../math-once.typ": calculate, calculation-builder, unload

#let direct = calculate($1 "widget" + 2 "widget"$)
#assert(direct.value == 3.0)
#assert(direct.unit == "widget")
#assert(direct.custom-units == (widget: 1))

#let scaled = calculate($3 "widget" * 2$)
#assert(scaled.value == 6.0)
#assert(scaled.unit == "widget")

#let squared = calculate($(2 "widget")^2$)
#assert(squared.value == 4.0)
#assert(squared.unit == "widget^2")
#assert(squared.custom-units == (widget: 2))

#let eq = calculation-builder(key: "opaque-units")
#unload($d$, key: "opaque-units")
#eq($d := 1 "micrometer"$)
#eq($x := d * 2$)
#eq($d + 3 "micrometer"$)
#context {
  assert(eq().d.value == 1.0)
  assert(eq().d.unit == "micrometer")
  assert(eq().x.value == 2.0)
  assert(eq().x.custom-units == (micrometer: 1))
}

// Quoted custom units named after Typst symbols use the same glyph in the
// source expression and result. Known quoted units remain upright text.
#let symbols = calculation-builder(key: "opaque-symbol-units")
#symbols($M := 53 * 10^(-3) "Omega"$)
#symbols($x := 2 "alpha"$)
#symbols($y := 2 "ohm"$)
#context {
  assert(symbols().M.unit == "Omega")
  assert(symbols().x.unit == "alpha")
  assert(symbols().y.unit == "ohm")
}

// An explicit unit: replaces opaque input units while preserving arithmetic.
#let overridden = calculate($1 "micrometer" + 1$, unit: $m$)
#assert(overridden.value == 2.0)
#assert(overridden.unit == "m")
#assert(overridden.dimensions.length == 1)
#assert(overridden.custom-units.len() == 0)

#let override-builder = calculation-builder(key: "opaque-unit-override")
#unload($d$, key: "opaque-unit-override")
#override-builder($d := 1 "micrometer" + 1$, unit: $m$)
#context {
  assert(override-builder().d.value == 2.0)
  assert(override-builder().d.unit == "m")
  assert(override-builder().d.dimensions.length == 1)
}

// Mixed custom and physical dimensions retain both parts in their output unit.
#let tariff = calculate(`2.35 "DKK"/kWh`, digits: 12)
#assert(tariff.unit == "DKK/J")
#assert(tariff.custom-units == (DKK: 1))
#assert(tariff.dimensions.length == -2)
#assert(tariff.dimensions.mass == -1)
#assert(tariff.dimensions.time == 2)
#tariff.display

#let prices = calculation-builder(key: "mixed-opaque-physical", digits: 4)
#prices(`tariff := 2.35 "DKK"/kWh`)
#prices(`cost := 1.4 kWh * tariff`)
#prices(`tariff`, result-only: true)
#prices(`cost`, result-only: true)
#context {
  let values = prices()
  assert(values.tariff.unit == "DKK/J")
  assert(values.cost.unit == "DKK")
  assert(calc.abs(values.cost.exact - 3.29) < 0.0000001)
}
