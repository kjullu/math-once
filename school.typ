// Numerical school mathematics. Plain numbers; angles in radians.
#let check-data(xs, minimum: 1) = {
  assert(type(xs) == array and xs.len() >= minimum, message: "school: insufficient data")
  for x in xs { assert(type(x) in (int, float), message: "school: expected numeric data") }
}
#let mean(xs) = { check-data(xs); xs.sum() / xs.len() }
#let variance(xs, sample: true) = {
  check-data(xs, minimum: if sample { 2 } else { 1 })
  let m = mean(xs)
  xs.map(x => (x - m) * (x - m)).sum() / (xs.len() - if sample { 1 } else { 0 })
}
#let quantile(xs, p) = {
  check-data(xs)
  assert(0 <= p and p <= 1, message: "school: probability must be in [0,1]")
  let ys = xs.sorted()
  let h = (ys.len() - 1) * p
  let i = int(calc.floor(h))
  ys.at(i) + (h - i) * (ys.at(calc.min(i + 1, ys.len() - 1)) - ys.at(i))
}
#let describe(xs) = (
  count: xs.len(), mean: mean(xs), median: quantile(xs, 0.5),
  q1: quantile(xs, 0.25), q3: quantile(xs, 0.75),
  min: calc.min(..xs), max: calc.max(..xs),
  variance: variance(xs, sample: false), sd: calc.sqrt(variance(xs, sample: false)),
)
#let choose(n, k) = {
  assert(type(n) == int and type(k) == int and 0 <= k and k <= n, message: "school: require integers 0 <= k <= n")
  let result = 1.0
  let k = calc.min(k, n - k)
  for i in range(1, k + 1) { result *= (n - k + i) / i }
  result
}
#let binomial(n, p, k, cumulative: false) = {
  assert(type(n) == int and n >= 0 and type(k) == int, message: "school: invalid binomial integers")
  assert(0 <= p and p <= 1, message: "school: invalid binomial probability")
  let mass(j) = if j < 0 or j > n { 0.0 } else { choose(n, j) * (if j == 0 { 1 } else { calc.pow(p, j) }) * (if n == j { 1 } else { calc.pow(1 - p, n - j) }) }
  if cumulative {
    if k < 0 { 0.0 } else { range(0, calc.min(k, n) + 1).map(mass).sum() }
  } else { mass(k) }
}
#let normal-pdf(x, mean: 0, sd: 1) = {
  assert(sd > 0, message: "school: sd must be positive")
  calc.exp(-0.5 * calc.pow((x - mean) / sd, 2)) / (sd * calc.sqrt(2 * calc.pi))
}
// Abramowitz-Stegun 26.2.17, absolute CDF error approximately < 7.5e-8.
#let normal-cdf(x, mean: 0, sd: 1) = {
  assert(sd > 0, message: "school: sd must be positive")
  let z = (x - mean) / sd
  let t = 1 / (1 + 0.2316419 * calc.abs(z))
  let tail = normal-pdf(calc.abs(z)) * t * (0.319381530 + t * (-0.356563782 + t * (1.781477937 + t * (-1.821255978 + t * 1.330274429))))
  if z < 0 { tail } else { 1 - tail }
}
#let bisect(f, a, b, tolerance: 1e-10, iterations: 200) = {
  assert(a < b and tolerance > 0 and type(iterations) == int and iterations > 0, message: "school: invalid bisection settings")
  let fa = f(a)
  let fb = f(b)
  if fa == 0 { return a }
  if fb == 0 { return b }
  assert((fa < 0) != (fb < 0), message: "school: root must be bracketed")
  for i in range(iterations) {
    let c = a + (b - a) / 2
    let fc = f(c)
    if fc == 0 or b - a <= tolerance { return c }
    if (fa < 0) != (fc < 0) { b = c } else { a = c; fa = fc }
  }
  panic("school: bisection did not converge")
}
#let normal-quantile(p, mean: 0, sd: 1) = {
  assert(0 < p and p < 1 and sd > 0, message: "school: quantile requires 0 < p < 1 and sd > 0")
  mean + sd * bisect(z => normal-cdf(z) - p, -40, 40)
}
#let integral(f, a, b, steps: 200) = {
  assert(type(steps) == int and steps > 0 and calc.rem(steps, 2) == 0, message: "school: Simpson steps must be positive and even")
  let h = (b - a) / steps
  let total = f(a) + f(b)
  for i in range(1, steps) { total += (if calc.rem(i, 2) == 0 { 2 } else { 4 }) * f(a + i * h) }
  total * h / 3
}
#let derivative(f, x, h: 1e-5) = {
  assert(h > 0, message: "school: derivative step must be positive")
  (f(x + h) - f(x - h)) / (2 * h)
}
#let ode(f, x0, y0, end, steps: 100) = {
  assert(type(steps) == int and steps > 0, message: "school: ODE steps must be positive")
  let h = (end - x0) / steps
  let y = y0
  let points = ((x0, y0),)
  for i in range(steps) {
    let x = x0 + i * h
    let k1 = f(x, y)
    let k2 = f(x + h / 2, y + h * k1 / 2)
    let k3 = f(x + h / 2, y + h * k2 / 2)
    let k4 = f(x + h, y + h * k3)
    y += h * (k1 + 2*k2 + 2*k3 + k4) / 6
    points.push((x0 + (i + 1)*h, y))
  }
  points
}
#let regression(xs, ys, model: "linear") = {
  check-data(xs, minimum: 2); check-data(ys, minimum: 2)
  assert(xs.len() == ys.len(), message: "school: regression data lengths differ")
  assert(model in ("linear", "exponential", "power", "logarithmic"), message: "school: unsupported regression model")
  let logx = model in ("power", "logarithmic")
  let logy = model in ("power", "exponential")
  if logx { assert(xs.all(x => x > 0), message: "school: x must be positive") }
  if logy { assert(ys.all(y => y > 0), message: "school: y must be positive") }
  let xx = if logx { xs.map(x => calc.ln(x)) } else { xs }
  let yy = if logy { ys.map(y => calc.ln(y)) } else { ys }
  let mx = mean(xx); let my = mean(yy)
  let sxx = xx.map(x => calc.pow(x - mx, 2)).sum()
  assert(sxx > 0, message: "school: regression needs distinct x values")
  let slope = xx.zip(yy).map(p => (p.at(0) - mx) * (p.at(1) - my)).sum() / sxx
  let intercept = my - slope * mx
  let predict(x) = {
    if logx { assert(x > 0, message: "school: prediction x must be positive") }
    let v = intercept + slope * if logx { calc.ln(x) } else { x }
    if logy { calc.exp(v) } else { v }
  }
  let residuals = xs.zip(ys).map(p => p.at(1) - predict(p.at(0)))
  let sst = ys.map(y => calc.pow(y - mean(ys), 2)).sum()
  (model: model, slope: slope, intercept: intercept,
   coefficient: if logy { calc.exp(intercept) } else { intercept },
   predict: predict, residuals: residuals,
   r-squared: if sst == 0 { none } else { 1 - residuals.map(r => r*r).sum() / sst })
}
#let dot(u, v) = {
  check-data(u); check-data(v)
  assert(u.len() == v.len(), message: "school: vector sizes differ")
  u.zip(v).map(p => p.at(0)*p.at(1)).sum()
}
#let norm(u) = calc.sqrt(dot(u, u))
#let cross(u, v) = {
  assert(u.len() == 3 and v.len() == 3, message: "school: cross product needs 3D vectors")
  (u.at(1)*v.at(2) - u.at(2)*v.at(1), u.at(2)*v.at(0) - u.at(0)*v.at(2), u.at(0)*v.at(1) - u.at(1)*v.at(0))
}
#let vector-angle(u, v) = {
  let scale = norm(u)*norm(v)
  assert(scale > 0, message: "school: zero vector has no angle")
  calc.acos(calc.max(-1, calc.min(1, dot(u,v)/scale))) / 1rad
}
#let triangle(a, b, c) = {
  assert(a > 0 and b > 0 and c > 0 and a+b > c and a+c > b and b+c > a, message: "school: invalid triangle")
  let angle(x,y,z) = calc.acos(calc.max(-1, calc.min(1, (y*y+z*z - x*x)/(2*y*z)))) / 1rad
  let s = (a+b+c)/2
  (a: a, b: b, c: c, alpha: angle(a,b,c), beta: angle(b,a,c), gamma: angle(c,a,b), area: calc.sqrt(s*(s - a)*(s - b)*(s - c)))
}
// Partial-pivot Gaussian elimination; rows are arrays, not rendered mat content.
#let eliminate(rows, tolerance: 1e-12) = {
  let n = rows.len()
  assert(n > 0 and tolerance > 0, message: "school: invalid matrix settings")
  assert(rows.all(r => r.len() >= n), message: "school: matrix needs at least n columns")
  let width = rows.first().len()
  for row in rows { check-data(row); assert(row.len() == width, message: "school: ragged matrix") }
  let a = rows
  let determinant = 1.0
  for j in range(n) {
    let pivot = j
    for i in range(j + 1,n) { if calc.abs(a.at(i).at(j)) > calc.abs(a.at(pivot).at(j)) { pivot = i } }
    assert(calc.abs(a.at(pivot).at(j)) > tolerance, message: "school: singular matrix or pivot below tolerance")
    if pivot != j {
      let saved = a.at(j); a.at(j) = a.at(pivot); a.at(pivot) = saved
      determinant = -determinant
    }
    let divisor = a.at(j).at(j)
    determinant *= divisor
    a.at(j) = a.at(j).map(v => v / divisor)
    for i in range(n) {
      if i != j {
        let factor = a.at(i).at(j)
        a.at(i) = a.at(i).zip(a.at(j)).map(p => p.at(0) - factor*p.at(1))
      }
    }
  }
  (rows: a, determinant: determinant)
}
#let linear-solve(a, b, tolerance: 1e-12) = {
  check-data(b)
  let n = a.len()
  assert(b.len() == n and a.all(r => r.len() == n), message: "school: linear system sizes differ")
  eliminate(a.zip(b).map(p => p.at(0) + (p.at(1),)), tolerance: tolerance).rows.map(r => r.last())
}
#let inverse(a, tolerance: 1e-12) = {
  let n = a.len()
  assert(n > 0 and a.all(r => r.len() == n), message: "school: inverse needs square matrix")
  eliminate(a.enumerate().map(p => p.at(1) + range(n).map(j => if j == p.at(0) { 1 } else { 0 })), tolerance: tolerance).rows.map(r => r.slice(n))
}
