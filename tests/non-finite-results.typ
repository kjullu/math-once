#import "../math-once.typ": calculate, calculation-builder

// Results that overflow or are undefined are ordinary calculation errors. They
// used to stop compilation inside Typst's own comparison and rounding code.
#let eq = calculation-builder(key: "non-finite-results")

#eq(`0^0`)
#eq(`0^0 m`)
#eq(`10^400`)
#eq(`1e400`)
#eq(`-1e400`)
#eq(`1e300 * 1e10`)
#eq(`1e400 - 1e400`)
#eq(`2^(1e10)`)
#eq(`1e308 * 10 m`)
#eq(`big := 10^400`)
#eq(`sin(1e400)`)
#eq(`sqrt(1e400)`)
#eq(`vec(1e400, 2)`)
#eq(`floor(1e300 * 1e300)`)
#eq($ x := 5 "m" $, size: 1e400)

// A failed assignment stores nothing, and large finite values still work.
#eq(`large := floor(1e300)`)
#context {
  let state = eq()
  assert("big" not in state)
  assert(state.large.exact == 1e300)
}
#assert(calculate(`round(1e30)`).exact == 1e30)
#assert(calculate(`(3 m)^0`).exact == 1.0)
