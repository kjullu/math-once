#import "../math-once.typ": qalc-builder, number-labelled-equations

#show: number-labelled-equations.with(supplement: [Ligning])

Unlabelled native equation:
$ 1 + 1 = 2 $

Labelled native equation:
$ E = m c^2 $ <energy>

Native reference: @energy.

#let eq = qalc-builder(key: "labelled-equation-test", digits: 2)

Unlabelled calculator equation:
#eq($v = 902 / 3.6$, unit: $m/s$)

Labelled calculator equation:
#eq($a = v * 2$, label: <calculation>)

Calculator reference: @calculation.

#context {
  let equations = query(math.equation.where(block: true))
  let labelled = equations.filter(equation => equation.has("label"))
  assert(labelled.len() == 2)
  assert(labelled.all(equation => equation.numbering == "(1)"))
  assert(labelled.map(equation => counter(math.equation).at(equation.location())) == ((1,), (2,)))
  assert(query(ref.where(target: <energy>)).len() == 1)
  assert(query(ref.where(target: <calculation>)).len() == 1)
}
