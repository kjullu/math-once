#import "../math-once.typ": calculate, calculation-builder

#let eq = calculation-builder(key: "review-structures", strict: true)
#eq(`vv := vec(1, 2)`)
#eq(`ww := vec(3, 4)`)
#eq(`sum := -vv + ww`)
#eq(`difference := -vv - ww`)
#eq(`grouped := -(vv + ww)`)
#eq(`scaled := -vv * 2 + ww`)
#eq(`literal := vec(1, 2) + vec(3, 4)`)
#eq(`nested := vec((1), (2))`)
#eq(`matrices := mat(1, 2; 3, 4) + mat(5, 6; 7, 8)`)
#eq(`product := mat(1, 2; 3, 4) * vec(3, 4)`)
#eq(`negative := -mat(1, 2; 3, 4) + mat(5, 6; 7, 8)`)
#context {
  let values = eq()
  assert(values.sum.values == (2.0, 2.0))
  assert(values.difference.values == (-4.0, -6.0))
  assert(values.grouped.values == (-4.0, -6.0))
  assert(values.scaled.values == (1.0, 0.0))
  assert(values.literal.values == (4.0, 6.0))
  assert(values.nested.values == (1.0, 2.0))
  assert(values.matrices.values == ((6.0, 8.0), (10.0, 12.0)))
  assert(values.product.values == (11.0, 25.0))
  assert(values.negative.values == ((4.0, 4.0), (4.0, 4.0)))
}

// Unit validation also applies within containers and expanded functions.
#let checked = calculation-builder(key: "review-strict-units", strict-units: true)
#checked(`badvec := vec(1 "meterrs", 2 "meterrs")`)
#checked(`badmat := mat(1 "meterrs", 2 "meterrs")`)
#checked(`makevec(x) := vec(x "meterrs", x)`)
#checked(`badcall := makevec(2)`)
#checked(`good := vec(1 m, 2 m)`)
#context {
  assert("badvec" not in checked())
  assert("badmat" not in checked())
  assert("badcall" not in checked())
  assert(checked().good.values == (1.0, 2.0))
}

// Compound preferred units must be resolved before rounding.
#let speed = calculate(`3.7 km/h`, unit: `km/h`)
#for (operation, expected) in (("floor", 3), ("ceil", 4), ("round", 4)) {
  let result = calculate(operation + "(speed)", scope: (speed: speed))
  assert(calc.abs(result.exact - expected) < 1e-10)
  assert(result.unit == "km/h")
}
#let pressure = calculate(`37000 Pa`, unit: `kN/m^2`)
#assert(calc.abs(calculate(`floor(pressure)`, scope: (pressure: pressure)).exact - 37) < 1e-10)

// Subtracting absolute temperatures produces a difference in any scale.
#for source in (`303.15 K - 20 celsius`, `30 celsius - 293.15 K`, `303.15 K - 293.15 K`, `545.67 rankine - 20 celsius`, `86 fahrenheit - 293.15 K`) {
  let result = calculate(source, unit: `celsius`)
  assert(calc.abs(result.exact - 10) < 1e-8)
  assert(result.affine-kind == "difference")
  let fahrenheit = calculate(`delta`, scope: (delta: result), unit: `fahrenheit`)
  assert(calc.abs(fahrenheit.exact - 18) < 1e-8)
}
#let delta = calculate(`30 celsius - 20 celsius`)
#assert(calc.abs(calculate(`20 celsius + delta`, scope: (delta: delta)).exact - 30) < 1e-10)

// Invalid real powers remain recoverable in the default builder.
#let soft = calculation-builder(key: "review-powers")
#soft(`badpower := (-1)^0.5`)
#soft(`badzero := 0^(-1)`)
#soft(`badroot := root(-3, 0)`)
#soft(`valid := (-2)^3`)
#context {
  assert("badpower" not in soft())
  assert("badzero" not in soft())
  assert("badroot" not in soft())
  assert(soft().valid.exact == -8)
}
