#import "../math-once.typ": calculation-builder, equation, equation-outline, number-labelled-equations

#show: number-labelled-equations.with(
  supplement: [Ligning],
  captions: (
    energy: [Sammenhængen mellem masse og energi],
    calculation: [Den dobbelte hastighed],
  ),
)

#equation-outline(title: [Ligningsoversigt])

Unlabelled native equation:
$ 1 + 1 = 2 $

Labelled native equation:
$ E = m c^2 $ <energy>

Native reference: @energy.

Labelled native equation without a caption:
$ F = m a $ <force>

No-caption reference: @force.

Native equation with a per-equation caption:
#equation(
  $ p = m v $,
  caption: [Impuls som produktet af masse og hastighed],
) <momentum>

Per-equation-caption reference: @momentum.

#let eq = calculation-builder(key: "labelled-equation-test", digits: 2)

Unlabelled calculator equation:
#eq($v := 902 / 3.6$, unit: $m/s$)

Labelled calculator equation:
#eq($x := v * 2$) <calculation>

Calculator reference: @calculation.

Calculator equation with the equivalent named label argument:
#eq($y := x / 2$, label: <named-calculation>)

Named-label reference: @named-calculation.

Calculator equation with a per-equation caption:
#eq(
  $z := y * 2$,
  caption: [Den genberegnede hastighed],
) <captioned-calculation>

Captioned calculator reference: @captioned-calculation.

#context {
  let equations = query(math.equation.where(block: true))
  let labelled = equations.filter(equation => equation.has("label"))
  assert(labelled.len() == 6)
  assert(labelled.all(equation => equation.numbering == "(1)"))
  assert(labelled.map(equation => counter(math.equation).at(equation.location())) == ((1,), (2,), (3,), (4,), (5,), (6,)))
  // One reference in the prose and one in each generated caption.
  assert(query(ref.where(target: <energy>)).len() == 2)
  assert(query(ref.where(target: <force>)).len() == 1)
  assert(query(ref.where(target: <calculation>)).len() == 2)
  assert(query(ref.where(target: <named-calculation>)).len() == 1)
  assert(query(ref.where(target: <momentum>)).len() == 3)
  assert(query(ref.where(target: <captioned-calculation>)).len() == 3)
}
