#import "../math-once.typ": calculate

#let tonne = calculate(`1 t to kg`)
#assert(tonne.exact == 1000.0)
#assert(tonne.dimensions.mass == 1)
#assert(tonne.dimensions.time == 0)

#let danish-hours = calculate(`1 timer to h`)
#assert(danish-hours.exact == 1.0)
#assert(danish-hours.dimensions.time == 1)
