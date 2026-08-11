#import "../math-once.typ": calculate, calculation-builder, unload

#let custom = calculate($1 / (0.5 "mm")$, unit: $"linjer" / m$, digits: 0)
#assert(custom.value == 2000.0)
#assert(custom.exact == 2000.0)
#assert(custom.unit == "linjer/m")
#assert(custom.dimensions.length == -1)
#custom.display

// Quoting a known unit keeps its physical meaning.
#let known = calculate($10 "cm" / s$, unit: $"km" / h$, digits: 3)
#assert(known.value == 0.36)
#known.display

#let eq = calculation-builder(key: "custom-output-unit", digits: 0)
#unload($d$, key: "custom-output-unit")
#eq($d := 0.5 "mm"$)
#eq($1 / d$, unit: $"linjer" / m$)
