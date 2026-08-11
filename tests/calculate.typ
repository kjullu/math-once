#import "../math-once.typ": calculate, calculation-builder

// Automatic conversion during addition: 1 km/t = 0.2777... m/s.
#let speed = calculate(`10 m/s + 1 km/t`)
#assert(calc.abs(speed.exact - 10.277777777777779) < 0.000000000001)
#assert(speed.value == 10.2778)
#assert(speed.unit == "m/s")
#assert(speed.display.block == true)
#assert(calculate(`1 m`, block: false).display.block == false)

// Explicit output conversion.
#let converted = calculate(`10 m/s to km/t`, digits: 2)
#assert(converted.value == 36.0)
#assert(converted.unit == "km/t")

// The named `unit` argument is an alternative to writing `to`.
#let requested-unit = calculate(`(1 m/s + 2 m/s)`, unit: `km/h`, digits: 1)
#assert(requested-unit.value == 10.8)

// `size` accepts wrapped math and keeps the exact SI value.
#let sized-length = calculate(`2047.762752 nm`, size: $10^(-6)$, digits: 9)
#assert(sized-length.value == 2.047762752)
#assert(sized-length.unit == "µm")
#assert(sized-length.size == 0.000001)
#assert(calc.abs(sized-length.si-value - 0.000002047762752) < 0.000000000000001)
#let twice-sized = calculate(`x * 2`, scope: (x: sized-length), digits: 9)
#assert(twice-sized.value == 4.095525504)
#assert(twice-sized.unit == "µm")
#assert(calculate(`1000 nm`, size: `10^(-6)`).value == 1.0)
#assert(calculate(`1000 nm`, size: "10^(-6)").value == 1.0)
#assert(calculate(`1000 nm`, size: calc.pow(10, -6)).value == 1.0)
#assert(requested-unit.unit == "km/h")
#assert(calc.abs(requested-unit.si-value - 3.0) < 0.000000000001)

// `unit` assigns dimensions to a plain number and accepts Typst math content.
#let labelled-number = calculate($902 / 3.6$, unit: $m/s$, digits: 2)
#assert(labelled-number.value == 250.56)
#assert(labelled-number.unit == "m/s")
#assert(labelled-number.dimensions == speed.dimensions)
#assert(calc.abs(labelled-number.si-value - 250.55555555555554) < 0.000000000001)

// A prior result is a dimensioned variable, not just a displayed number.
#let distance = calculate(`v * 2 s`, scope: (v: speed), digits: 3)
#assert(calc.abs(distance.exact - 20.555555555555557) < 0.000000000001)
#assert(distance.unit == "m")

// Parentheses, derived units, exponents, prefixes, and implicit products.
#let energy = calculate(`2 N * 3 m`)
#assert(energy.value == 6.0)
#assert(energy.unit == "J")

#let area = calculate(`(2 m + 30 cm)^2`, digits: 2)
#assert(area.value == 5.29)
#assert(area.unit == "m^2")

#let volume = calculate(`500 mL + 1 L to L`, digits: 1)
#assert(volume.value == 1.5)
#assert(volume.unit == "L")

// Operator precedence and right-associative powers.
#assert(calculate(`1 m + 2 * 3 m`).value == 7.0)
#assert(calculate(`2^3^2`).value == 512.0)
#assert(calculate(`-2^2`).value == -4.0)
#assert(calculate(`(-2)^2`).value == 4.0)

// Negative unit powers and numeric scope values.
#let frequency = calculate(`1 s^-1 to Hz`)
#assert(frequency.value == 1.0)
#assert(calculate(`x cm + 1 m to cm`, scope: (x: 50)).value == 150.0)

#speed.display \
#converted.display \
#requested-unit.display \
#distance.display \
#energy.display \
#area.display \
#volume.display

// Stateful reusable variables.
#let run = calculation-builder()
#run(`v = 10 m/s + 1 km/t`)
#run(`d = v * 2 s`, digits: 3)
#context {
  let variables = run()
  assert(variables.v.value == 10.2778)
  assert(variables.v.unit == "m/s")
  assert(calc.abs(variables.d.exact - 20.555555555555557) < 0.000000000001)
  assert(variables.d.unit == "m")
  assert(variables.d.display.block == true)
}

// Typst math input and visible variable substitution.
#let eq = calculation-builder(key: "math-equation-runner", digits: 2)
#eq($v = 902 / 3.6$)
#eq($a = v * 2$)
#eq($b = 902 / 3.6$, unit: $m/s$)
#eq($c = b * 2$)
#eq($u = 10 m/s + 1 "km"/h$)
#eq($d = u * 2 s$, digits: 3)
#context {
  let variables = eq()
  assert(variables.v.value == 250.56)
  assert(variables.a.value == 501.11)
  assert(variables.b.unit == "m/s")
  assert(variables.c.unit == "m/s")
  assert(variables.c.value == 501.11)
  assert(variables.u.unit == "m/s")
  assert(variables.d.unit == "m")
  assert(calc.abs(variables.a.exact - 501.1111111111111) < 0.000000000001)
}
