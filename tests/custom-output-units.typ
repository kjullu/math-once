#import "../math-once.typ": calculate, calculation-builder, unload, text-unit

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

// text-unit always creates a symbolic label, even when the spelling is also a
// known physical unit. A quoted "cm" above remains centimetres.
#let symbolic-known = calculate($2 / (0.5 m)$, unit: $#text-unit("cm") / m$, digits: 0)
#assert(symbolic-known.value == 4.0)
#assert(symbolic-known.unit == "cm/m")
#assert(symbolic-known.dimensions.length == -1)
#symbolic-known.display

#let symbolic-lines = calculate($1 / (0.5 "mm")$, unit: $#text-unit("linjer") / m$, digits: 0)
#assert(symbolic-lines.value == 2000.0)
#assert(symbolic-lines.unit == "linjer/m")
#symbolic-lines.display

#let eq = calculation-builder(key: "custom-output-unit", digits: 0)
#unload($d$, key: "custom-output-unit")
#eq($d := 0.5 "mm"$)
#eq($1 / d$, unit: $"linjer" / m$)
