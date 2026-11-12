#import "../math-once.typ": calculation-builder, unload, rename-unit, reset

#set page(width: 14cm, height: auto, margin: 1cm)

// A stored assignment shows the display that its own state update stored.
// Every case below must look exactly as if the equation were evaluated again.
#let eq = calculation-builder(key: "stored-display-reuse")

// The state before the first assignment changes between layout passes
// (the unload arrives one pass later). The output must still settle.
#unload($h$, key: "stored-display-reuse")
#eq($ h := 56 "cm" $, unit: "cm")
#eq($ P_y := h $, unit: "cm")

// An identical re-assignment leaves the stored entry unchanged.
#eq($ x := 5 m $)
#eq($ x := 5 m $)
// A different re-assignment replaces it.
#eq($ x := 7 m $)
#context assert(eq().x.value == 7)

// A failed update shows its error; a later definition recovers the chain.
#eq($ y := z + 1 m $)
#eq($ z := 2 m $)
#eq($ y := z + 1 m $)
#context assert(eq().y.value == 3)

// Per-call display options.
#eq($ n_1 := 3 "kg" $, show-result: false)
#eq($ n_2 := 2 n_1 $, show-substitution: false)
#eq($ n_3 := n_1 + n_2 $, result-only: true)
Inline: #eq($ n_4 := n_3 / 3 $, block: false).
#eq($ n_5 := n_4 + n_1 $, hidden: true)
#eq($n_5$, result-only: true)
#eq($ n_6 := n_5 * 2 $, label: <stored-n6>, caption: [Doubled])
#eq($ n_7 := n_6 $, digits: 1, unit: "g")

// A renamed unit as the output unit is read from the state.
#rename-unit($m$, $v$, key: "stored-display-reuse")
#eq($ L_1 := 3 v $, unit: $v$)
#eq($ L_2 := L_1 + 2 v $, unit: "v")

#context {
  let values = eq()
  assert(values.n_3.value == 9)
  assert(values.n_5.value == 6)
  assert(values.n_7.value == 12000)
  assert(values.L_2.value == 5)
  assert(values.L_1.display.func() == math.equation)
}

#reset(key: "stored-display-reuse")
// After a reset the same names start from an empty state again.
#eq($ x := 1 $)
#eq($ y := x + 1 $)
#context assert(eq().y.value == 2)
