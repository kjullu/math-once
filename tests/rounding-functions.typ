#import "../math-once.typ": calculate, calculation-builder

// Rounding functions use the same evaluator in calculate and the builder.
#assert(calculate(`floor(3.7)`).exact == 3)
#assert(calculate(`ceil(3.2)`).exact == 4)
#assert(calculate(`round(3.5)`).exact == 4)
#assert(calculate(`floor(-3.2)`).exact == -4)
#assert(calculate(`ceil(-3.2)`).exact == -3)

// Typst converts math-mode names to floor and ceiling delimiters before the
// package sees them. Reconstruct the function from those delimiters.
#assert(calculate($floor(3.7)$).exact == 3)
#assert(calculate($ceil(3.2)$).exact == 4)
#assert(calculate($round(3.5)$).exact == 4)
#assert(calculate($floor(-3.2)$).exact == -4)

// Round in the input's preferred unit and preserve that unit when stored.
#let centimetres = calculate(`floor(3.7 cm)`)
#assert(centimetres.exact == 3)
#assert(centimetres.si-value == 0.03)
#assert(centimetres.unit == "cm")
#let custom = calculate(`ceil(3.2 "widgets")`)
#assert(custom.exact == 4)
#assert(custom.unit == "widgets")

#let eq = calculation-builder(key: "rounding-functions", digits: 2)
#eq(`down := floor(3.7)`)
#eq(`up := ceil(3.2)`)
#eq(`nearest := round(3.5)`)
#eq(`length := floor(3.7 cm)`)
#eq(`reused := length * 2`)
#eq(`bucket(x) := floor(x)`)
#eq(`bucketed := bucket(8.9)`)

#context {
  let values = eq()
  assert(values.down.exact == 3)
  assert(values.up.exact == 4)
  assert(values.nearest.exact == 4)
  assert(values.length.exact == 3)
  assert(values.length.si-value == 0.03)
  assert(values.length.unit == "cm")
  assert(values.reused.exact == 6)
  assert(values.reused.unit == "cm")
  assert(values.bucket.function)
  assert(values.bucketed.exact == 8)
}

// Render positive, negative, and unit-aware examples for visual regression.
#eq($ floor(3.7) $)
#eq($ ceil(-3.2) $)
#eq($ round(3.5) $)
#eq($ floor(3.7 "cm") $)
