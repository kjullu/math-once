#import "../math-once.typ": calculation-builder, equation, equation-outline, number-labelled-equations

#show: number-labelled-equations

#equation-outline(title: [Formula List], indent: 1em)

#let eq = calculation-builder(
  key: "supplement-outline-test",
  supplement: [Equation],
)

#eq(
  $v = 10 m/s$,
  caption: [Initial velocity],
) <initial-velocity>

#equation(
  $ E = m c^2 $,
  caption: [Mass-energy equivalence],
  supplement: [Formula],
) <mass-energy>

See @initial-velocity and @mass-energy.

Inline supplement without a caption:
#equation($x = 1$, supplement: [Inline]).

#context {
  let entries = query(outline.entry)
  assert(entries.len() == 2)
  assert(entries.all(entry => entry.element.has("label")))
}
