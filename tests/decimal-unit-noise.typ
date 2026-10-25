#import "../math-once.typ": calculate, calculation-builder, unload

#set page(width: 14cm, height: auto, margin: 1cm)
#show math.equation: it => { show ".": ","; it }

// SI conversion introduces a one-bit difference: 56 cm becomes
// 56.00000000000001. It must not trigger fixed-decimal padding.
#let check(source, digits, expected) = {
  let result = calculate(source, digits: digits)
  let rendered = repr(result.display.body).split("[=]").last()
  assert("[" + expected + "]" in rendered, message: rendered)
  result.display
}
#check(`56 cm to cm`, 4, "56")
#check(`-56 cm to cm`, 4, "56")
#check(`0.1 + 0.2`, 4, "0.3")
// Actual rounding still preserves the requested decimal places.
#check(`0.0599`, 3, "0.060")
#check(`55.99999 cm to cm`, 4, "56.0000")
#check(`0.00011 / 10000`, 4, "1.1000")

#let eq = calculation-builder(key: "decimal-unit-noise")
#unload($h$, key: "decimal-unit-noise")
#eq($ h := 56 "cm" $, show-result: false, unit: "cm")
#eq($ P_y := h $, unit: "cm")
Inline: #eq($P_y$, unit: "cm", result-only: true).
#context {
  let result = eq().P_y
  assert(result.value == 56)
  assert("[56.0000]" not in repr(result.display))
  assert("[56]" in repr(result.display))
}

// Per-call digits overrides apply to reused units and result-only output.
#eq($"rounded" := 56.789 "cm"$, show-result: false, unit: "cm")


#eq($"copy" := "rounded"$, unit: "cm", digits: 2)


One decimal: #eq($"rounded"$, unit: "cm", result-only: true, digits: 1).
Whole centimetres: #eq($"rounded"$, unit: "cm", result-only: true, digits: 0).
Exact integer: #eq($h$, unit: "cm", result-only: true, digits: 2).
#context {
  assert(eq().copy.value == 56.79)
  assert("[56.79]" in repr(eq().copy.display))
}
