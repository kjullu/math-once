#import "../lib.typ": calculate

#let a = calculate(`902 / 3.6`, unit: `m/s`)
#assert(a.value == 251.0)
#assert(calc.abs(a.exact - 250.55555555555554) < 0.000000000001)
#assert(a.source == "902 / 3.6")
#assert(a.unit.text == "m/s")

#let b = calculate(`a * 2`, scope: (a: a), unit: a.unit, digits: 1)
#assert(b.value == 501.1)
#assert(calc.abs(b.exact - 501.1111111111111) < 0.000000000001)

#let precise = calculate(`1.0 / 8`, digits: 3, block: true)
#assert(precise.value == 0.125)

#a.display
#b.display
#precise.display
