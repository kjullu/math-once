// School operations written directly inside the calculation builder.
#import "../math-once.typ": calculation-builder
#set page(width: 18cm, height: auto, margin: 1cm)

#let eq = calculation-builder(key: "builder-school", digits: 3)
#let close(a, b, tolerance: 1e-6) = calc.abs(a - b) <= tolerance * calc.max(1, calc.abs(b))

= Statistics
#eq(`data := vec(2, 4, 5, 7, 9)`)
#eq(`xbar := mean(data)`)
#eq(`xbar * 2`)
#eq(`med := median(data)`)
#eq(`sd := stdev(data)`)
#eq(`sdp := stdevp(data)`)
#eq(`var := variance(data)`)
#eq(`q := quartiles(data)`)
#eq(`stat := describe(data)`)
#eq(`stat_q3 - stat_q1`)
#eq(`wm := mean(vec(1, 2, 3), vec(1, 1, 2))`)
#eq(`p90 := quantile(data, 0.9)`)

= Probability
#eq(`prob := binompdf(10, 0.5, 3)`)
#eq(`cum := binomcdf(10, 0.5, 3)`)
#eq(`between := binomcdf(10, 0.5, 2, 5)`)
#eq(`comb := choose(10, 3)`)
#eq(`z := normcdf(1.96)`)
#eq(`band := normcdf(90, 110, 100, 15)`)
#eq(`crit := invnorm(0.975)`)
#eq(`dens := normpdf(0)`)

= Regression
#eq(`xv := vec(1, 2, 3, 4)`)
#eq(`yv := vec(3, 5, 7, 9)`)
#eq(`fit := linreg(xv, yv)`)
#eq(`fit(10)`)
#eq(`ye := vec(6, 12, 24, 48)`)
#eq(`grow := expreg(xv, ye)`)
#eq(`grow(5)`)
#eq(`yp := vec(2, 16, 54, 128)`)
#eq(`pw := powreg(xv, yp)`)
#eq(`yq := vec(2, 5, 10, 17)`)
#eq(`quad := polyreg(xv, yq, 2)`)
#eq(`linreg(xv, yv)`)

= Vectors and matrices
#eq(`uu := vec(1, 2, 3)`)
#eq(`vv := vec(3, 0, 1)`)
#eq(`dp := dotprod(uu, vv)`)
#eq(`cp := cross(uu, vv)`)
#eq(`len := norm(vec(3, 4))`)
#eq(`ang := vecangle(vec(1, 0), vec(0, 2))`)
#eq(`M := mat(2, 1; 1, 3)`)
#eq(`detM := det(M)`)
#eq(`Mi := inv(M)`)
#eq(`sol := linsolve(M, vec(3, 5))`)
#eq(`rk := rank(mat(1, 2; 2, 4))`)

= Triangles and tests
#eq(`tri := triangle(a = 3, b = 4, c = 5)`)
#eq(`tri_C`)
#eq(`triangle(a = 5, b = 7, A = 30)`)
#eq(`gof := chi2gof(vec(18, 22, 20), vec(1/3, 1/3, 1/3))`)
#eq(`ind := chi2ind(mat(10, 20; 30, 40))`)
#eq(`ci := propci(45, 100)`)

= Numerical calculus fallbacks
#eq(`f(x) := x^3 - 3*x`)
#eq(`r := solve(f(x) = 1, x, -3, 3)`)
#eq(`area := integrate(exp(-x^2), x, 0, 1)`)
#eq(`area * 2`)

= Charts
#eq(`plot(f(x), x, -2.5, 2.5)`)
#eq(`plot(x^2, 1/x, x, -2, 2)`)
#eq(`scatter(xv, yv, fit(x), x)`)
#eq(`boxplot(data)`)
#eq(`histogram(data, vec(0, 5, 10))`)

= Radians
#let rad = calculation-builder(key: "builder-school-radians", digits: 3, angles: "radians")
#rad(`ra := vecangle(vec(1, 0), vec(0, 2))`)
#rad(`rt := triangle(a = 1, b = 1, C = pi/2)`)

#context {
  let v = eq()
  assert(close(v.xbar.exact, 5.4))
  assert(close(v.med.exact, 5))
  assert(close(v.sd.exact, calc.sqrt(7.3)))
  assert(close(v.sdp.exact, calc.sqrt(5.84)))
  assert(close(v.var.exact, 7.3))
  assert(v.q.values == (3.0, 5.0, 8.0))
  assert(v.stat_n.exact == 5 and v.stat_q1.exact == 3 and v.stat_q3.exact == 8 and v.stat_max.exact == 9)
  assert(close(v.wm.exact, 2.25))
  assert(close(v.p90.exact, 8.2))
  assert(close(v.prob.exact, 120 / 1024))
  assert(close(v.cum.exact, 176 / 1024))
  assert(close(v.between.exact, (45 + 120 + 210 + 252) / 1024))
  assert(v.comb.exact == 120)
  assert(close(v.z.exact, 0.975, tolerance: 1e-4))
  assert(close(v.band.exact, 0.4950, tolerance: 1e-3))
  assert(close(v.crit.exact, 1.95996, tolerance: 1e-4))
  assert(close(v.dens.exact, 1 / calc.sqrt(2 * calc.pi)))
  assert(close(v.fit_a.exact, 2) and close(v.fit_b.exact, 1) and close(v.fit_r2.exact, 1))
  assert(close(v.grow_a.exact, 2) and close(v.grow_b.exact, 3))
  assert(close(v.pw_a.exact, 3) and close(v.pw_b.exact, 2))
  assert(close(v.quad_a.exact, 1) and close(v.quad_b.exact, 0, tolerance: 1e-6) and close(v.quad_c.exact, 1))
  assert(v.dp.exact == 6)
  assert(v.cp.values == (2.0, 8.0, -6.0))
  assert(v.len.exact == 5)
  assert(close(v.ang.exact, 90))
  assert(close(v.detM.exact, 5))
  assert(close(v.Mi.values.at(0).at(0), 0.6) and close(v.Mi.values.at(1).at(0), -0.2))
  assert(close(v.sol.values.at(0), 0.8) and close(v.sol.values.at(1), 1.4))
  assert(v.rk.exact == 1)
  assert(close(v.tri_C.exact, 90) and close(v.tri_area.exact, 6))
  assert(close(v.gof_chi2.exact, 0.4) and v.gof_df.exact == 2)
  assert(v.ind_df.exact == 1)
  assert(close(v.ci.components.at(0).exact, 0.45 - 1.959964 * calc.sqrt(0.45 * 0.55 / 100), tolerance: 1e-4))
  assert(v.r.roots.len() == 3)
  assert(close(v.area.exact, 0.746824, tolerance: 1e-6))
  let w = rad()
  assert(close(w.ra.exact, calc.pi / 2))
  assert(close(w.rt_c.exact, calc.sqrt(2)))
}

// Stored fitted functions evaluate through the ordinary function path.
#context {
  let check = calculation-builder(key: "builder-school")
  assert(check().fit.function)
}
