#import "../math-once.typ": qalc

// Every SI prefix is resolved generically.
#let prefix-cases = (
  ("Y", 1e24), ("Z", 1e21), ("E", 1e18), ("P", 1e15),
  ("T", 1e12), ("G", 1e9), ("M", 1e6), ("k", 1e3),
  ("h", 1e2), ("da", 1e1), ("d", 1e-1), ("c", 1e-2),
  ("m", 1e-3), ("u", 1e-6), ("n", 1e-9), ("p", 1e-12),
  ("f", 1e-15), ("a", 1e-18), ("z", 1e-21), ("y", 1e-24),
)
#for (prefix, factor) in prefix-cases {
  assert(qalc("1 " + prefix + "m to m").exact == factor)
}

// All accepted micro spellings are equivalent.
#assert(qalc(`1 µm to nm`).value == 1000.0)
#assert(qalc(`1 μm to nm`).value == 1000.0)
#assert(qalc(`1 um to nm`).value == 1000.0)

// Prefixes work on derived units too.
#assert(qalc(`1 MHz to Hz`).value == 1000000.0)
#assert(qalc(`1 kPa to Pa`).value == 1000.0)
#assert(qalc(`1 mV * 1 A`, unit: `mW`).value == 1.0)
#assert(calc.abs(qalc(`1 MJ to kWh`).exact - 0.2777777777777778) < 0.000000000001)

// Common accepted non-SI units.
#assert(qalc(`1 bar to kPa`).value == 100.0)
#assert(qalc(`1 atm to Pa`).value == 101325.0)
#assert(qalc(`1 day to h`).value == 24.0)
#assert(qalc(`1 week to day`).value == 7.0)
#assert(qalc(`1 inch to cm`).value == 2.54)
#assert(qalc(`1 ft to inch`).value == 12.0)
#assert(qalc(`1 mi to km`, digits: 6).value == 1.609344)
#assert(qalc(`1 mph to km/h`, digits: 6).value == 1.609344)
#assert(qalc(`180 deg to rad`, digits: 12).value == calc.round(calc.pi, digits: 12))
#assert(qalc(`180 ° to rad`, digits: 12).value == calc.round(calc.pi, digits: 12))
#assert(qalc(`1 kΩ`, unit: `ohm`).value == 1000.0)
#assert(qalc(`1 ml to mL`).value == 1.0)

// Derived-unit identities.
#assert(qalc(`1 V * 1 A`, unit: `W`).value == 1.0)
#assert(qalc(`1 C / (1 s)`, unit: `A`).value == 1.0)
#assert(qalc(`1 W * 1 h`, unit: `Wh`).value == 1.0)

#qalc(`1 m/s + 1 m/s = km/s`).display
#qalc(`1 mV * 1 A`, unit: `mW`).display
#qalc(`1 mi to km`).display
