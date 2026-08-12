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
