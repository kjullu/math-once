#import "../math-once.typ": calculation-builder, school-bridge, school
#set page(width: 18cm, height: auto, margin: 1cm)
#let run = calculation-builder(key: "workflow", strict: true, digits: 3, angles: "radians")
= From a model to a tangent
Consider a model on the positive real axis. The logarithm restricts the domain to $x > 0$.
#run("f(x) := x - ln(x)")
#run("df(x) := diff(f(x),x)")
#run("df(2)")
#run("stationary := solve(df(x),x)")
The derivative changes from negative to positive at $x=1$, so the stationary point is a minimum.
#school-bridge(callback => {
  let f = callback("f(x)")
  let df = callback("df(x)")
  let slope = df(2)
  let tangent(x) = f(2) + slope*(x - 2)
  [At $x=2$ the tangent slope is #slope. The graph shows the model and its tangent.]
  school.plot((f,tangent), 0.25, 4, x-range:(0,4), y-range:(0,3), labels:([Model], [Tangent at $x=2$]))
  [The area under the model between 1 and 2 is #calc.round(school.integral(f,1,2),digits:4).]
}, key: "workflow")
= Fit measurements
The measurements $(0,1), (1,3), (2,5), (3,7)$ follow a straight line.
#let fit = school.regression((0,1,2,3),(1,3,5,7))
#run("\"a\" := " + school.value-source(fit.slope), hidden: true)
#run("\"b\" := " + school.value-source(fit.intercept), hidden: true)
The fitted slope is #run("\"a\"", result-only: true) and the intercept is #run("\"b\"", result-only: true).
The fitted model is $y = a x + b$.
#run("\"a\" * 4 + \"b\"")
= A right triangle
Geometry in this section uses degrees explicitly.
#let degrees = school.angles(mode:"degrees")
#let triangle = (degrees.triangle)(3,4,5)
The angle opposite the side of length 5 is #triangle.gamma degrees.
