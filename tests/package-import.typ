#import "@local/math-once:0.1.0": calculate, qalc

#let result = calculate(`6 * 7`, unit: `kg`)
#assert(result.value == 42)
#assert(result.exact == 42)
#result.display

#let speed = qalc(`10 m/s + 1 km/t`)
#assert(speed.value == 10.2778)
#assert(speed.unit == "m/s")
#speed.display
