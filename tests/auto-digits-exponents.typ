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
