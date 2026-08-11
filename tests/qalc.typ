#import "../math-once.typ": qalc, qalc-builder

// Automatic conversion during addition: 1 km/t = 0.2777... m/s.
#let speed = qalc(`10 m/s + 1 km/t`)
#assert(calc.abs(speed.exact - 10.277777777777779) < 0.000000000001)
#assert(speed.value == 10.2778)
#assert(speed.unit == "m/s")

// Explicit output conversion.
#let converted = qalc(`10 m/s to km/t`, digits: 2)
#assert(converted.value == 36.0)
#assert(converted.unit == "km/t")

// The named `unit` argument is an alternative to writing `to`.
#let requested-unit = qalc(`(1 m/s + 2 m/s)`, unit: `km/h`, digits: 1)
#assert(requested-unit.value == 10.8)
#assert(requested-unit.unit == "km/h")
#assert(calc.abs(requested-unit.si-value - 3.0) < 0.000000000001)

// A prior result is a dimensioned variable, not just a displayed number.
#let distance = qalc(`v * 2 s`, scope: (v: speed), digits: 3)
#assert(calc.abs(distance.exact - 20.555555555555557) < 0.000000000001)
#assert(distance.unit == "m")

// Parentheses, derived units, exponents, prefixes, and implicit products.
#let energy = qalc(`2 N * 3 m`)
#assert(energy.value == 6.0)
#assert(energy.unit == "J")

#let area = qalc(`(2 m + 30 cm)^2`, digits: 2)
#assert(area.value == 5.29)
#assert(area.unit == "m^2")

#let volume = qalc(`500 mL + 1 L to L`, digits: 1)
#assert(volume.value == 1.5)
#assert(volume.unit == "L")

// Operator precedence and right-associative powers.
#assert(qalc(`1 m + 2 * 3 m`).value == 7.0)
#assert(qalc(`2^3^2`).value == 512.0)
#assert(qalc(`-2^2`).value == -4.0)
#assert(qalc(`(-2)^2`).value == 4.0)

// Negative unit powers and numeric scope values.
#let frequency = qalc(`1 s^-1 to Hz`)
#assert(frequency.value == 1.0)
#assert(qalc(`x cm + 1 m to cm`, scope: (x: 50)).value == 150.0)

#speed.display \
#converted.display \
#requested-unit.display \
#distance.display \
#energy.display \
#area.display \
#volume.display

// Stateful, eqrun-style variables.
#let run = qalc-builder()
#run(`v = 10 m/s + 1 km/t`)
#run(`d = v * 2 s`, digits: 3)
#context {
  let variables = run()
  assert(variables.v.value == 10.2778)
  assert(variables.v.unit == "m/s")
  assert(calc.abs(variables.d.exact - 20.555555555555557) < 0.000000000001)
  assert(variables.d.unit == "m")
}
