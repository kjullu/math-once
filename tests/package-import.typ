#import "@local/math-once:0.1.0": calculate

#let result = calculate(`6 * 7`, unit: `kg`)
#assert(result.value == 42)
#assert(result.exact == 42)
#result.display
