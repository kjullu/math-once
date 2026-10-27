#import "../math-once.typ": calculate, calculation-builder
#set page(width: 18cm, height: auto, margin: 1cm)

// Significant mode no longer needs a separate `digits: auto`.
#let sig = calculation-builder(key: "review-sig", strict: true, auto-digits: "significant")
#sig(`force := 1.50 * 2.000`)
#sig(`power := 1.234^(1+2)`)
#sig(`negpower := 2.000^(-(1+1))`)
#sig(`small := 1.5e-3 * 2.00`)
#sig(`big := 1.5e3 * 2.00`)
#sig(`fixed := 1 / 3`, digits: 2)
#context {
  let r = sig()
  assert(r.force.value == 3)
  assert(r.force.significant-digits == 3)
  assert(r.power.value == 1.879)
  assert(r.negpower.value == 0.25)
  assert(r.negpower.significant-digits == 4)
  assert(r.small.value == 0.003)
  assert(r.big.value == 3000)
  assert(r.fixed.value == 0.33)
}

// Precision survives switching between rounding modes.
#let mixed = calculation-builder(key: "review-mixed", strict: true, digits: auto)
#mixed(`length := 1.20`)
#mixed(`scaled := length * 1.000`, auto-digits: "significant")
#context {
  assert(mixed().length.input-significant-digits == 3)
  assert(mixed().scaled.significant-digits == 3)
}

// Invalid per-call modes render an error without stopping compilation.
#let soft = calculation-builder(key: "review-soft")
#soft(`y := 1 / 3`, auto-digits: "bogus")
#context assert("y" not in soft())

// Quoted custom output labels can be reused by later calculations.
#let labels = calculation-builder(key: "review-labels", strict: true)
#labels(`count := 3`, unit: "\"widget\"")
#labels(`more := count + 1`)
#context {
  assert(labels().count.unit == "widget")
  assert(labels().more.value == 4)
  assert(labels().more.unit == "widget")
}

// `calculate` accepts the same rounding mode.
#let single = calculate(`1.50 * 2.000`, auto-digits: "significant")
#single.display
#assert(single.value == 3)
#assert(single.significant-digits == 3)
#assert(calculate(`1 / 3`).value == 0.3333)

// Function exponents and grouped scientific literals.
#let fn-power = calculate(`1.234^abs(2)`, auto-digits: "significant")
#assert(fn-power.value == 1.523)
#assert(fn-power.significant-digits == 4)
#calculate(`1.00 / 1.5e3`, digits: 6).display
#calculate(`1.5e3 / 2`).display
#calculate(`2.000^1.5e-3`).display
