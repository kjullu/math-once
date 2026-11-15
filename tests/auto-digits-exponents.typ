#import "../math-once.typ": calculate, calculation-builder, unload

#set page(width: 16cm, height: auto, margin: 1cm)

// Exponents are exact operations, not measured inputs, so `digits: auto`
// ignores their literals in both rounding modes.
#assert(calculate(`9.82 m/s^2`, digits: auto).digits == 2)
#assert(calculate(`9.82 m/s/s`, digits: auto).digits == 2)
#assert(calculate($9.82 m/s^2$, digits: auto).digits == 2)
#assert(calculate(`9.82 m/s^(2)`, digits: auto).digits == 2)
#assert(calculate(`9.82 m^-2`, digits: auto).digits == 2)
// Three significant figures of 9.82 are two decimal places.
#assert(calculate(`9.82 m/s^2`, digits: auto, auto-digits: "significant").digits == 2)
#assert(calculate(`98.2 m/s^2`, digits: auto, auto-digits: "significant").digits == 1)
#calculate(`9.82 m/s^2`, digits: auto).display

// Numeric exponents on numbers and variables are exact too.
#assert(calculate(`2.5^2`, digits: auto).digits == 1)
#assert(calculate(`2.5^2`, digits: auto).value == 6.3)
#assert(calculate(`1.50^0.5`, digits: auto).digits == 2)
#assert(calculate(`x^2`, scope: (x: 1.25), digits: auto).digits == 2)
// The base still counts, and so does a referenced variable in the exponent.
#assert(calculate(`2^1.5`, digits: auto).digits == 0)
#assert(calculate(`2.00^n`, scope: (n: 1.5), digits: auto).digits == 1)

// A stored value with a unit power keeps its own decimal places in a chain.
#let eq = calculation-builder(key: "auto-digits-exponents")
#unload($F$, $a$, key: "auto-digits-exponents")
#eq($F := 11.5 "N"$)
#eq($a := 9.82 m/s^2$)
#unload($m$, key: "auto-digits-exponents")
#eq($m := F/a$)
#eq($m$, result-only: true, digits: auto)
#eq($m$, result-only: true, digits: auto, auto-digits: "significant")
#context {
  let values = eq()
  assert(values.a.input-digits == 2)
  assert(values.m.input-digits == 1)
}

#let chain = calculation-builder(key: "auto-digits-exponents-chain", digits: auto)
#unload($F$, $a$, key: "auto-digits-exponents-chain")
#chain($F := 11.5 "N"$)
#chain($a := 9.82 m/s^2$)
#unload($m$, key: "auto-digits-exponents-chain")
#chain($m := F/a$)
#context {
  let values = chain()
  assert(values.a.digits == 2)
  assert(values.m.digits == 1)
  assert(values.m.value == 1.2)
}

// Whole-number factors are exact formula constants in both modes.
#let rod = (M: calculate(`0.60 kg`, digits: auto), X: calculate(`1.64 m`, digits: auto))
#assert(calculate($1/3 dot M dot X^2$, scope: rod, digits: auto).value == 0.54)
#assert(calculate(`1/3 * M * X^2`, scope: rod, digits: auto).value == 0.54)
#assert(calculate(`M * X^2 / 3`, scope: rod, digits: auto).value == 0.54)
#assert(calculate($1/(3 M)$, scope: rod, digits: auto).digits == 2)
#assert(calculate($1/3 dot M dot X^2$, scope: rod, digits: auto, auto-digits: "significant").value == 0.54)
#assert(calculate(`2 * 1.5`, digits: auto).digits == 1)
#assert(calculate(`-3 * x`, scope: (x: calculate(`1.25`, digits: auto)), digits: auto).digits == 2)
#assert(calculate(`1.25 / (-2)`, digits: auto).value == -0.63)
#assert(calculate(`1.5 - 2 * 1.25`, digits: auto).digits == 1)
// A unit before the number belongs to another value, so the 12 is a count.
#assert(calculate(`1.234 m * 12`, digits: auto).digits == 3)
#assert(calculate(`1.234 m^2 * 12`, digits: auto).digits == 3)
// Whole numbers with units, sums, and function arguments still count.
#assert(calculate(`1 + 3.456`, digits: auto).digits == 0)
#assert(calculate($2 x + 1$, scope: (x: 1.25), digits: auto).digits == 0)
#assert(calculate($12 m dot 1.5$, digits: auto).digits == 0)
#assert(calculate($12 "m" dot 1.5$, digits: auto).digits == 0)
#assert(calculate(`12 * m * 1.5`, digits: auto).digits == 0)
#assert(calculate(`3 / s * 1.5 m`, digits: auto).digits == 0)
#assert(calculate(`12 * (m) * 1.234`, digits: auto).digits == 0)
#assert(calculate(`12 * m^2 * 1.234`, digits: auto).digits == 0)
#assert(calculate(`12 * (m^2) * 1.234`, digits: auto).digits == 0)
#assert(calculate(`12 * ((m)) * 1.234`, digits: auto).digits == 0)
#assert(calculate(`1.234 * (12) m`, digits: auto).digits == 0)
#assert(calculate(`"kg" * 3 * 1.234`, digits: auto).digits == 0)
#assert(calculate(`m^2 * 3 * 1.234`, digits: auto).digits == 0)
#assert(calculate(`(m^2) * 3 * 1.234`, digits: auto).digits == 0)
#assert(calculate(`m^(2) * 3 * 1.234`, digits: auto, auto-digits: "significant").value == 4)
#assert(calculate(`x^2 * 3`, scope: (x: 1.25), digits: auto).digits == 2)
#assert(calculate(`12 * (m) * 1.234`, digits: auto, auto-digits: "significant").value == 15)
#assert(calculate(`1.25 - 2`, digits: auto).digits == 0)
#assert(calculate(`sin(-30) * 1.5`, digits: auto).digits == 0)
#assert(calculate(`sin(30) * 1.5`, digits: auto).digits == 0)
#assert(calculate(`1200 m * 2.0`, digits: auto, auto-digits: "significant").digits == -2)
#calculate($1/3 dot M dot X^2$, scope: rod, digits: auto).display

// The builder chain from a physics hand-in: the moment of inertia of a rod.
#let inertia = calculation-builder(key: "auto-digits-inertia")
#unload($L$, key: "auto-digits-inertia")
#inertia($ L := 1.64 "m" $)
#unload($m$, key: "auto-digits-inertia")
#inertia($ m := 0.60 "kg" $)
#inertia($ I_0 := 1/3 dot m dot L^2 $)
#inertia($I_0$, result-only: true, digits: auto)
#inertia($I_0$, result-only: true, digits: auto, auto-digits: "significant")
#context {
  let values = inertia()
  assert(values.I_0.input-digits == 2)
}

// A whole number that scales a vector or matrix is exact too.
#let scaled = calculation-builder(key: "auto-digits-structures", digits: auto)
#scaled(`v := vec(1.20, 3.456)`)
#scaled(`twice := 2 * v`)
#scaled(`half := v / (2)`)
#scaled(`negated := v * (-2)`)
#scaled(`negated_outside := -(2) * v`)
#scaled(`shifted := v + vec(1, 1)`)
#scaled(`Qone := mat(1.5, 2.25; 3.5, 4.75)`)
#scaled(`Qtwo := Qone * 3`)
#context {
  let values = scaled()
  assert(values.twice.components.map(c => c.digits) == (2, 3))
  assert(values.twice.components.first().value == 2.4)
  assert(values.half.components.map(c => c.digits) == (2, 3))
  assert(values.negated.components.map(c => c.digits) == (2, 3))
  assert(values.negated_outside.components.map(c => c.digits) == (2, 3))
  // Added whole numbers still count.
  assert(values.shifted.components.map(c => c.digits) == (0, 0))
  assert(values.Qtwo.rows.flatten().map(c => c.digits) == (1, 2, 1, 2))
}

// A unit-only operand before or after a stored function argument keeps it measured.
#let unit-functions = calculation-builder(key: "auto-digits-unit-functions", digits: auto)
#unit-functions(`Qfn(x) := "kg" * x`)
#unit-functions(`Qone := Qfn(3) * 1.234`)
#unit-functions(`Qgn(x) := x * "kg"`)
#unit-functions(`Qtwo := Qgn(3) * 1.234`)
#unit-functions(`Qpow(x) := m^2 * x`)
#unit-functions(`Qthree := Qpow(3) * 1.234`)
#context {
  let values = unit-functions()
  assert(values.Qone.digits == 0)
  assert(values.Qtwo.digits == 0)
  assert(values.Qthree.digits == 0)
}
