#import "../math-once.typ": calculate, calculation-builder, rename-unit

#let tonne = calculate(`1 t to kg`)
#assert(tonne.exact == 1000.0)
#assert(tonne.dimensions.mass == 1)
#assert(tonne.dimensions.time == 0)

// Non-English spellings are opt-in builder aliases instead of catalog units.
#let time = calculation-builder(key: "translated-hour-alias")
#rename-unit($h$, $"timer"$, key: "translated-hour-alias")
#time(`duration := 1 timer`)
#context {
  assert(time().duration.si-value == 3600.0)
  assert(time().duration.dimensions.time == 1)
}
