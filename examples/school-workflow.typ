#import "../math-once.typ": calculation-builder
#set page(width: 18cm, height: auto, margin: 1cm)
#let run = calculation-builder(key: "workflow", strict: true, digits: 3, angles: "radians")

= From a model to a tangent
Consider a model on the positive real axis. The logarithm restricts the domain to $x > 0$.
#run("f(x) := x - ln(x)")
#run("df(x) := diff(f(x),x)")
#run("df(2)")
#run("stationary := solve(df(x),x)")
The derivative changes from negative to positive at $x=1$, so the stationary point is a minimum.

The tangent at $x = 2$ uses the stored slope.
#run("t(x) := df(2)*(x - 2) + f(2)")
#run("plot(f(x), t(x), x, 0.25, 4)")
#run("area := integrate(f(x), x, 1, 2)")

= Fit measurements
#run("xdata := vec(0, 1, 2, 3)")
#run("ydata := vec(1, 3.1, 4.9, 7)")
#run("fit := linreg(xdata, ydata)")
#run("fit(4)")
#run("scatter(xdata, ydata, fit(x), x)", caption: [Measurements and the fitted line.])

= Statistics
#run("scores := vec(12, 15, 9, 18, 14, 11, 16)")
#run("stat := describe(scores)")
#run("binomcdf(20, 0.3, 4)")

= A right triangle
#let deg = calculation-builder(key: "workflow-degrees", strict: true, digits: 2)
#deg("tri := triangle(a = 3, b = 4, c = 5)")
#deg("tri_C")
