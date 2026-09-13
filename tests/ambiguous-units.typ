#import "../math-once.typ": calculate, calculation-builder

// Directly named units retain their preferred semantic symbol.
#for unit in ("Hz", "Bq", "J", "Nm", "Gy", "Sv", "cd", "lm") {
  assert(calculate("1 " + unit).unit == unit)
}

// Every suggested interpretation can be selected explicitly.
#assert(calculate(`1 / (2 s)`, unit: `Hz`).unit == "Hz")
#assert(calculate(`1 / (2 s)`, unit: `Bq`).unit == "Bq")
#assert(calculate(`1 / (2 s)`, unit: `1/s`).unit == "1/s")
#assert(calculate(`2 N * 3 m`, unit: `J`).unit == "J")
#assert(calculate(`2 N * 3 m`, unit: `Nm`).unit == "Nm")
#assert(calculate(`2 N * 3 m`, unit: `kg*m^2/s^2`).unit == "kg*m^2/s^2")
#assert(calculate(`1 J / (1 kg)`, unit: `Gy`).unit == "Gy")
#assert(calculate(`1 J / (1 kg)`, unit: `Sv`).unit == "Sv")
#assert(calculate(`1 J / (1 kg)`, unit: `m^2/s^2`).unit == "m^2/s^2")
#assert(calculate(`1 cd * 1 sr`, unit: `cd`).unit == "cd")
#assert(calculate(`1 cd * 1 sr`, unit: `lm`).unit == "lm")

// Builder failures are visible but do not store invalid assignments.
#let eq = calculation-builder(key: "ambiguous-units")
#eq($x_1 := 1 / (2 s)$)
#eq($x_2 := 2 N * 3 m$)
#eq($x_3 := 1 J / (1 "kg")$)
#eq($x_4 := 1 "cd" * 1 "sr"$)
#context {
  let state = eq()
  assert("x_1" not in state)
  assert("x_2" not in state)
  assert("x_3" not in state)
  assert("x_4" not in state)
}
