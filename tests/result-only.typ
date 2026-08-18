#import "../math-once.typ": calculation-builder

#let eq = calculation-builder(key: "result-only", digits: 4)

#eq($v_0 := 11.1822 "km"/s$, unit: $"km"/s$)

// Compact math input remains inline and displays only the stored result.
Conclusion: #eq($v_0$, result-only: true).
#assert(eq($v_0$, result-only: true).block == false)

// The option applies to ordinary expressions, conversions, and paired values.
Twice: #eq($v_0 * 2$, result-only: true).
Converted: #eq($v_0$, unit: $m/s$, result-only: true).
Alternatives: #eq($10 plus.minus 2$, result-only: true).

// It may also store a definition while only rendering the resulting value.
#eq($"distance" := 1 "km" + 250 m$, result-only: true)
#context {
  assert(eq().distance.value == 1.25)
  assert(eq().distance.unit == "km")
}

// Unknown and display-only expressions produce focused inline feedback.
Unknown: #eq($q$, result-only: true).
Symbolic: #eq($x arrow.r y$, result-only: true).
