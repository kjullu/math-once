#import "../math-once.typ": calculation-builder
#set page(width: auto, height: auto, margin: 12pt)
#let eq = calculation-builder(key: "vector-angles", strict: true, block: true)
#eq($arrow(a) := vec(2, -3, 0)$)
#eq($arrow(b) := vec(-1, -2, 1)$)
#eq($"acute" := arcsin(abs(arrow(a) times arrow(b)) / (abs(arrow(a)) dot abs(arrow(b))))$)
#eq($"angle" := arccos((arrow(a) bullet arrow(b)) / (abs(arrow(a)) dot abs(arrow(b))))$)
#eq($"rooted" := sqrt(arrow(a) bullet arrow(a))$)
#eq($"nested" := abs(abs(arrow(a)))$)
#context {
  let values = eq()
  assert(calc.abs(values.acute.exact - calc.asin(calc.sqrt(62 / 78)) / 1deg) < 1e-10)
  assert(calc.abs(values.angle.exact - calc.acos(4 / calc.sqrt(78)) / 1deg) < 1e-10)
  assert(calc.abs(values.rooted.exact - calc.sqrt(13)) < 1e-10)
  assert(calc.abs(values.nested.exact - calc.sqrt(13)) < 1e-10)
}
