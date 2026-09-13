#import "../math-once.typ": calculate, calculation-builder

// Automatic conversion during addition: 1 km/h = 0.2777... m/s.
#let speed = calculate(`10 m/s + 1 km/h`)
#assert(calc.abs(speed.exact - 10.277777777777779) < 0.000000000001)
#assert(speed.value == 10.2778)
#assert(speed.unit == "m/s")
#assert(speed.display.block == true)
#assert(calculate(`1 m`, block: false).display.block == false)

// Explicit output conversion.
#let converted = calculate(`10 m/s to km/h`, digits: 2)
#assert(converted.value == 36.0)
#assert(converted.unit == "km/h")

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

// `unit` chooses the target and `size` scales that target.
#let centimetres = calculate(`1 cm + 2 cm`, unit: `m`, size: 0.01, digits: 2)
#assert(centimetres.value == 3.0)
#assert(centimetres.exact == 3.0)
#assert(centimetres.unit == "cm")
#let metres = calculate(`1 cm + 2 cm`, unit: `m`, size: 1, digits: 2)
#assert(metres.value == 0.03)
#assert(metres.unit == "m")
#let scaled-speed = calculate(`36 km/h`, unit: `m/s`, size: 0.1, digits: 2)
#assert(scaled-speed.value == 100.0)
#assert(scaled-speed.unit == "10^(-1) m/s")
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
#let energy = calculate(`2 N * 3 m`, unit: `J`)
#assert(energy.value == 6.0)
#assert(energy.unit == "J")

// Electrical resistance prefers Ω, and Typst's Omega symbol spelling is a
// valid explicit output unit without reserving Omega as a general unit name.
#let voltage = calculate(`0.366 V`)
#let current = calculate(`6.11 A`)
#let resistance = calculate(`V_1 / A_1`, scope: (V_1: voltage, A_1: current), digits: 4)
#assert(resistance.value == 0.0599)
#assert(resistance.unit == "Ω")
#let omega-resistance = calculate(
  $V_1 / A_1$,
  scope: (V_1: voltage, A_1: current),
  unit: $Omega$,
  digits: 4,
)
#assert(omega-resistance.value == 0.0599)
#assert(omega-resistance.unit == "Ω")

// Unambiguous coherent SI dimensions use their derived-unit symbols.
#let derived-unit-cases = (
  (`1 A * 1 s`, "C"),
  (`1 W / (1 A)`, "V"),
  (`1 C / (1 V)`, "F"),
  (`1 A / (1 V)`, "S"),
  (`1 V * 1 s`, "Wb"),
  (`1 Wb / (1 m)^2`, "T"),
  (`1 Wb / (1 A)`, "H"),
  (`1 cd / (1 m)^2`, "lx"),
  (`1 mol / (1 s)`, "kat"),
)
#for (source, expected) in derived-unit-cases {
  assert(calculate(source).unit == expected, message: "wrong derived unit for " + source.text)
}

// Common Typst math spellings remain single physical output units.
#let celsius-output = calculate($20$, unit: $degree C$)
#assert(celsius-output.unit == "°C")
#assert(celsius-output.exact == 20.0)
#assert(celsius-output.si-value == 293.15)
#let fahrenheit-output = calculate($68$, unit: $degree F$)
#assert(fahrenheit-output.unit == "°F")
#assert(calc.abs(fahrenheit-output.exact - 68.0) < 0.000000000001)
#assert(calc.abs(fahrenheit-output.si-value - 293.15) < 0.000000000001)
#let rankine-output = calculate($491.67$, unit: $degree R$)
#assert(rankine-output.unit == "°R")
#assert(calc.abs(rankine-output.si-value - 273.15) < 0.000000001)
#let micrometre-output = calculate($1$, unit: $mu m$)
#assert(micrometre-output.unit == "µm")
#assert(micrometre-output.si-value == 0.000001)
#let microfarad-output = calculate($1$, unit: $mu F$)
#assert(microfarad-output.unit == "µF")
#assert(microfarad-output.si-value == 0.000001)
#let celsius-conversion = calculate($293.15 K = degree C$, digits: 2)
#assert(celsius-conversion.unit == "°C")
#assert(celsius-conversion.value == 20.0)
#let omega-conversion = calculate($1 "ohm" = Omega$)
#assert(omega-conversion.unit == "Ω")
#let micrometre-conversion = calculate($1 m = mu m$)
#assert(micrometre-conversion.unit == "µm")
#assert(micrometre-conversion.value == 1000000.0)

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
#resistance.display \
#omega-resistance.display \
#celsius-output.display \
#fahrenheit-output.display \
#rankine-output.display \
#micrometre-output.display \
#microfarad-output.display \
#area.display \
#volume.display

// Stateful reusable variables.
#let run = calculation-builder()
#run(`v := 10 m/s + 1 km/h`)
#run(`x := v * 2 s`, digits: 3)
#context {
  let variables = run()
  assert(variables.v.value == 10.2778)
  assert(variables.v.unit == "m/s")
  assert(calc.abs(variables.x.exact - 20.555555555555557) < 0.000000000001)
  assert(variables.x.unit == "m")
  assert(variables.x.display.block == true)
}

// Typst math input and visible variable substitution.
#let eq = calculation-builder(key: "math-equation-runner", digits: 2)
#eq($v := 902 / 3.6$)
#eq($x := v * 2$)
#eq($y := 902 / 3.6$, unit: $m/s$)
#eq($z := y * 2$)
#eq($p := 10 m/s + 1 "km"/h$)
#eq($q := p * 2 s$, digits: 3)
#context {
  let variables = eq()
  assert(variables.v.value == 250.56)
  assert(variables.x.value == 501.11)
  assert(variables.y.unit == "m/s")
  assert(variables.z.unit == "m/s")
  assert(variables.z.value == 501.11)
  assert(variables.p.unit == "m/s")
  assert(variables.q.unit == "m")
  assert(calc.abs(variables.x.exact - 501.1111111111111) < 0.000000000001)
}

// Stored volts divided by stored amperes infer electrical resistance.
#let electrical = calculation-builder(key: "electrical-resistance", digits: 4)
#electrical($V_1 := 0.366 V$)
#electrical($A_1 := 6.11 A$)
#electrical($R_A := V_1 / A_1$)
#context {
  let variables = electrical()
  assert(variables.R_A.value == 0.0599)
  assert(variables.R_A.unit == "Ω")
}
