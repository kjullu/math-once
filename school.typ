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
#let quantile(xs, p, method: "linear") = {
  check-data(xs)
  assert(0 <= p and p <= 1, message: "school: probability must be in [0,1]")
  let ys = xs.sorted()
  assert(method in ("linear", "median-halves"), message: "school: unknown quantile method")
  if method == "median-halves" {
    assert(p in (0, 0.25, 0.5, 0.75, 1), message: "school: median-halves supports quartiles only")
    if p == 0 { return ys.first() }
    if p == 1 { return ys.last() }
    if p == 0.5 or ys.len() == 1 { return quantile(ys, 0.5) }
    let half = int(calc.floor(ys.len()/2))
    return quantile(if p == 0.25 { ys.slice(0, half) } else { ys.slice(ys.len() - half) }, 0.5)
  }
  let h = (ys.len() - 1) * p
  let i = int(calc.floor(h))
  ys.at(i) + (h - i) * (ys.at(calc.min(i + 1, ys.len() - 1)) - ys.at(i))
}
#let describe(xs, method: "linear") = (
  count: xs.len(), mean: mean(xs), median: quantile(xs, 0.5),
  q1: quantile(xs, 0.25, method: method), q3: quantile(xs, 0.75, method: method),
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

// Vector state RK4 also represents higher-order equations as first-order systems.
#let ode-system(f, x0, y0, end, steps: 100) = {
  check-data(y0)
  assert(type(steps) == int and steps > 0, message: "school: ODE steps must be positive")
  let add(a,b,s) = { assert(a.len() == b.len()); a.zip(b).map(p => p.at(0)+s*p.at(1)) }
  let h = (end - x0)/steps
  let y = y0
  let points = ((x0,y),)
  for i in range(steps) {
    let x = x0+i*h
    let k1 = f(x,y)
    let k2 = f(x+h/2,add(y,k1,h/2))
    let k3 = f(x+h/2,add(y,k2,h/2))
    let k4 = f(x+h,add(y,k3,h))
    y = range(y.len()).map(j => y.at(j)+h*(k1.at(j)+2*k2.at(j)+2*k3.at(j)+k4.at(j))/6)
    points.push((x+h,y))
  }
  points
}
#let matrix-info(a, tolerance: 1e-12) = {
  assert(a.len() > 0 and a.first().len() > 0 and tolerance > 0)
  let width = a.first().len()
  for row in a { check-data(row); assert(row.len()==width) }
  let r = 0
  let det = 1.0
  for j in range(width) {
    if r < a.len() {
      let pivot = r
      for i in range(r,a.len()) { if calc.abs(a.at(i).at(j)) > calc.abs(a.at(pivot).at(j)) { pivot=i } }
      if calc.abs(a.at(pivot).at(j)) > tolerance {
        if pivot!=r { let saved=a.at(r); a.at(r)=a.at(pivot); a.at(pivot)=saved; det =  - det }
        let d=a.at(r).at(j)
        det *= d
        a.at(r)=a.at(r).map(v=>v/d)
        for i in range(r+1,a.len()) {
          let factor=a.at(i).at(j)
          a.at(i)=a.at(i).zip(a.at(r)).map(p=>p.at(0) - factor*p.at(1))
        }
        r+=1
      }
    }
  }
  (rank:r, determinant: if width!=a.len() { none } else if r < width { 0.0 } else { det })
}
#let determinant(a, tolerance: 1e-12) = { assert(a.len() > 0 and a.all(r=>r.len()==a.len())); matrix-info(a,tolerance:tolerance).determinant }
#let rank(a, tolerance: 1e-12) = matrix-info(a,tolerance:tolerance).rank
#let projection(u,v) = { assert(dot(v,v) > 0); v.map(x=>x*dot(u,v)/dot(v,v)) }
#let line-plane(point,direction,normal,offset,tolerance:1e-12) = {
  let d=dot(direction,normal)
  assert(calc.abs(d) > tolerance,message:"school: parallel or contained line has no unique intersection")
  let t=(offset - dot(point,normal))/d
  (parameter:t, point:point.zip(direction).map(p=>p.at(0)+t*p.at(1)))
}
#let plane-projection(point,normal,offset) = {
  assert(dot(normal,normal) > 0)
  point.zip(normal).map(p=>p.at(0) - (dot(point,normal) - offset)*p.at(1)/dot(normal,normal))
}
// Complex numbers are (real, imaginary) pairs, independent of the expression CAS.
#let complex-mul(z,w) = (z.at(0)*w.at(0) - z.at(1)*w.at(1),z.at(0)*w.at(1)+z.at(1)*w.at(0))
#let complex-add(z,w) = (z.at(0)+w.at(0),z.at(1)+w.at(1))
#let complex-div(z,w) = { assert(dot(w,w) > 0); complex-mul(z,(w.at(0), - w.at(1))).map(v=>v/dot(w,w)) }
#let complex-polar(z) = { assert(norm(z) > 0); (modulus:norm(z),argument:calc.atan2(z.at(0),z.at(1))/1rad) }
#let complex-cartesian(r,theta) = { assert(r >= 0); (r*calc.cos(theta*1rad),r*calc.sin(theta*1rad)) }
#let complex-roots(z,n) = {
  assert(type(n)==int and n > 0)
  if norm(z)==0 { return ((0,0),) }
  let p=complex-polar(z)
  range(n).map(k=>complex-cartesian(calc.pow(p.modulus,1/n),(p.argument+2*calc.pi*k)/n))
}
// Any three independent side/angle measurements; returns all valid triangles.
#let triangles(a:none,b:none,c:none,alpha:none,beta:none,gamma:none) = {
  let sides=(a,b,c)
  let angles=(alpha,beta,gamma)
  assert(sides.filter(v=>v!=none).len()+angles.filter(v=>v!=none).len()==3,message:"school: supply three triangle measurements")
  for v in sides { if v!=none { assert(v > 0) } }
  for v in angles { if v!=none { assert(0 < v and v < calc.pi) } }
  let known=range(3).filter(i=>angles.at(i)!=none)
  if known.len() >= 2 {
    assert(known.len()==2,message:"school: angles alone do not fix triangle size")
    let missing=range(3).filter(i=>angles.at(i)==none).first()
    angles.at(missing)=calc.pi - angles.at(known.at(0)) - angles.at(known.at(1))
    assert(angles.at(missing) > 0)
    let j=range(3).filter(i=>sides.at(i)!=none).first()
    let scale=sides.at(j)/calc.sin(angles.at(j)*1rad)
    return (triangle(..angles.map(v=>scale*calc.sin(v*1rad))),)
  }
  if known.len()==0 { return (triangle(a,b,c),) }
  let i=known.first()
  let other=range(3).filter(j=>j!=i)
  if sides.at(i)==none {
    let u=sides.at(other.at(0)); let v=sides.at(other.at(1))
    sides.at(i)=calc.sqrt(u*u+v*v - 2*u*v*calc.cos(angles.at(i)*1rad))
    return (triangle(..sides),)
  }
  let j=other.filter(j=>sides.at(j)!=none).first()
  let k=other.filter(jj=>jj!=j).first()
  let sine=sides.at(j)*calc.sin(angles.at(i)*1rad)/sides.at(i)
  if sine > 1+1e-12 { return () }
  let first=calc.asin(calc.min(1,sine))/1rad
  let candidates=if calc.abs(first - calc.pi/2) < 1e-12 { (first,) } else { (first,calc.pi - first) }
  let result=()
  for angle in candidates {
    let remaining=calc.pi - angles.at(i) - angle
    if remaining > 1e-12 {
      sides.at(k)=sides.at(i)*calc.sin(remaining*1rad)/calc.sin(angles.at(i)*1rad)
      result.push(triangle(..sides))
    }
  }
  result
}
#let weighted-summary(values,weights) = {
  check-data(values); check-data(weights)
  assert(values.len()==weights.len() and weights.all(w=>w >= 0) and weights.sum() > 0)
  let total=weights.sum()
  let m=dot(values,weights)/total
  let v=dot(values.map(x=>(x - m)*(x - m)),weights)/total
  (weight:total,mean:m,variance:v,sd:calc.sqrt(v))
}
#let grouped-summary(edges,counts) = {
  assert(edges.len()==counts.len()+1 and range(counts.len()).all(i=>edges.at(i) < edges.at(i+1)))
  weighted-summary(range(counts.len()).map(i=>(edges.at(i)+edges.at(i+1))/2),counts)
}
// Newton with numerical Jacobian, damping and explicit failure on nonconvergence.
#let system-root(f,initial,tolerance:1e-9,iterations:100,h:1e-5) = {
  check-data(initial); assert(tolerance > 0 and iterations > 0 and h > 0)
  let x=initial
  for iteration in range(iterations) {
    let y=f(x)
    assert(y.len()==x.len())
    if norm(y) <= tolerance { return x }
    let columns=range(x.len()).map(j=> {
      let plus=x; let minus=x
      plus.at(j)+=h; minus.at(j)-=h
      f(plus).zip(f(minus)).map(p=>(p.at(0) - p.at(1))/(2*h))
    })
    let jac=range(x.len()).map(i=>columns.map(c=>c.at(i)))
    let delta=linear-solve(jac,y)
    let scale=1.0
    let next=x.zip(delta).map(p=>p.at(0) - scale*p.at(1))
    while norm(f(next)) >= norm(y) and scale > 1/1024 {
      scale/=2
      next=x.zip(delta).map(p=>p.at(0) - scale*p.at(1))
    }
    x=next
  }
  panic("school: nonlinear system did not converge")
}
// Finite scan: sign crossings plus stationary points for even-multiplicity roots.
#let root-scan(f,a,b,steps:200,tolerance:1e-7) = {
  assert(a < b and type(steps)==int and steps > 1 and tolerance > 0)
  let found=()
  let poles=()
  let add(found,x) = {
    let h=calc.max(tolerance,1e-5*calc.max(1,calc.abs(x)))
    let scale=calc.abs(f(x+h) - f(x - h))/(2*h)+tolerance*calc.abs(f(x+h) - 2*f(x)+f(x - h))/(h*h)
    if calc.abs(f(x)) <= tolerance*scale and (f(x)==0 or calc.abs(f(x)) < calc.min(calc.abs(f(x+h)),calc.abs(f(x - h)))) and not found.any(r=>calc.abs(r - x) < 10*tolerance) { found + (x,) } else { found } }
  for i in range(steps) {
    let l=a+(b - a)*i/steps; let r=a+(b - a)*(i+1)/steps
    found=add(found,l)
    if (f(l) < 0)!=(f(r) < 0) {
      let candidate=bisect(f,l,r,tolerance:tolerance/100)
      found=add(found,candidate)
      if not found.any(x=>calc.abs(x - candidate) < 10*tolerance) {poles.push(candidate)}
    }
    let df(x)=derivative(f,x)
    if (df(l) < 0)!=(df(r) < 0) { found=add(found,bisect(df,l,r,tolerance:tolerance/100)) }
  }
  found=add(found,b)
  (roots:found.sorted(),poles:poles.sorted())
}
// Exclusions are never evaluated, including by the local derivative stencil.
#let domain-scan(f,a,b,steps:200,tolerance:1e-7,exclusions:()) = {
  assert(exclusions.all(x=>type(x) in (int,float) and a <= x and x <= b))
  let cuts=(a,)+exclusions.filter(x=>a < x and x < b).dedup().sorted()+(b,)
  let zeros=(); let poles=exclusions
  for (l,r) in cuts.slice(0,-1).zip(cuts.slice(1)) {
    let margin=calc.min((r - l)/4,calc.max(100*tolerance,1e-4*calc.max(1,calc.abs(l),calc.abs(r))))
    let left=if l in exclusions {l+margin} else {l}
    let right=if r in exclusions {r - margin} else {r}
    let result=root-scan(f,left,right,steps:steps,tolerance:tolerance)
    zeros+=result.roots; poles+=result.poles
  }
  (roots:zeros.sorted(),poles:poles.sorted())
}
#let roots(f,a,b,steps:200,tolerance:1e-7,exclusions:()) = {
  domain-scan(f,a,b,steps:steps,tolerance:tolerance,exclusions:exclusions).roots
}
#let polynomial-fit(xs,ys,degree:2) = {
  assert(type(degree)==int and degree >= 0 and xs.len()==ys.len() and xs.len() > degree)
  let power(x,n)=if n==0 { 1 } else { calc.pow(x,n) }
  let a=range(degree+1).map(i=>range(degree+1).map(j=>xs.map(x=>power(x,i+j)).sum()))
  let b=range(degree+1).map(i=>xs.zip(ys).map(p=>power(p.at(0),i)*p.at(1)).sum())
  let coefficients=linear-solve(a,b)
  let predict(x)=coefficients.enumerate().map(p=>p.at(1)*power(x,p.at(0))).sum()
  (coefficients:coefficients,predict:predict,residuals:xs.zip(ys).map(p=>p.at(1) - predict(p.at(0))))
}
#let custom-fit(xs,ys,model,initial,iterations:100,tolerance:1e-8) = {
  assert(xs.len()==ys.len() and xs.len() >= initial.len() and initial.len() > 0)
  let p=initial
  let loss(p)=xs.zip(ys).map(v=>calc.pow(v.at(1) - model(v.at(0),p),2)).sum()
  let damping=1e-3
  for iteration in range(iterations) {
    let residual=xs.zip(ys).map(v=>v.at(1) - model(v.at(0),p))
    let jac=xs.map(x=>range(p.len()).map(j=> {
      let h=1e-5*(1+calc.abs(p.at(j)))
      let plus=p; let minus=p
      plus.at(j)+=h; minus.at(j)-=h
      (model(x,plus) - model(x,minus))/(2*h)
    }))
    let a=range(p.len()).map(i=>range(p.len()).map(j=>jac.map(row=>row.at(i)*row.at(j)).sum()+if i==j { damping } else { 0 }))
    let b=range(p.len()).map(i=>jac.zip(residual).map(v=>v.at(0).at(i)*v.at(1)).sum())
    let delta=linear-solve(a,b)
    if norm(b) < tolerance { return (parameters:p,predict:x=>model(x,p),residuals:residual,converged:true) }
    let next=p.zip(delta).map(v=>v.at(0)+v.at(1))
    if loss(next) < loss(p) { p=next; damping=calc.max(1e-12,damping/3) } else { damping*=10 }
  }
  (parameters:p,predict:x=>model(x,p),residuals:xs.zip(ys).map(v=>v.at(1) - model(v.at(0),p)),converged:false)
}
#let sinus-fit(xs,ys,initial,iterations:200) = custom-fit(xs,ys,(x,p)=>p.at(0)*calc.sin((p.at(1)*x+p.at(2))*1rad)+p.at(3),initial,iterations:iterations)
// Lanczos log-gamma, positive arguments, with reflection below 1/2.
#let log-gamma(z) = {
  assert(z > 0)
  if z < 0.5 { return calc.ln(calc.pi) - calc.ln(calc.sin(calc.pi*z*1rad)) - log-gamma(1 - z) }
  let c=(676.5203681218851, - 1259.1392167224028,771.3234287776531, - 176.6150291621406,12.507343278686905, - 0.13857109526572012,9.984369578019572e-6,1.5056327351493116e-7)
  let x=0.9999999999998099
  let w=z - 1
  for (i,v) in c.enumerate() { x+=v/(w+i+1) }
  let t=w+7.5
  0.5*calc.ln(2*calc.pi)+(w+0.5)*calc.ln(t) - t+calc.ln(x)
}
#let chi-square-cdf(x,df) = {
  assert(df > 0 and x >= 0)
  if x==0 { return 0.0 }
  let a=df/2; let z=x/2
  let scale=calc.exp( - z+a*calc.ln(z) - log-gamma(a))
  if z < a+1 {
    let term=1/a; let total=term
    for n in range(1,2000) {
      term*=z/(a+n); total+=term
      if calc.abs(term) < calc.abs(total)*1e-14 { return calc.min(1,total*scale) }
    }
  } else {
    let b=z+1 - a; let c=1e300; let d=1/b; let total=d
    for i in range(1,2000) {
      let an =  - i*(i - a)
      b+=2
      d=an*d+b; if calc.abs(d) < 1e-300 { d=1e-300 }
      c=b+an/c; if calc.abs(c) < 1e-300 { c=1e-300 }
      d=1/d
      let delta=d*c; total*=delta
      if calc.abs(delta - 1) < 1e-14 { return calc.max(0,1 - scale*total) }
    }
  }
  panic("school: chi-square CDF did not converge")
}
#let beta-fraction(a,b,x) = {
  let qab=a+b; let qap=a+1; let qam=a - 1
  let c=1.0; let d=1 - qab*x/qap
  if calc.abs(d) < 1e-300 { d=1e-300 }
  d=1/d
  let result=d
  for m in range(1,1000) {
    let m2=2*m
    let aa=m*(b - m)*x/((qam+m2)*(a+m2))
    d=1+aa*d; if calc.abs(d) < 1e-300 { d=1e-300 }
    c=1+aa/c; if calc.abs(c) < 1e-300 { c=1e-300 }
    d=1/d; result*=d*c
    aa =  - (a+m)*(qab+m)*x/((a+m2)*(qap+m2))
    d=1+aa*d; if calc.abs(d) < 1e-300 { d=1e-300 }
    c=1+aa/c; if calc.abs(c) < 1e-300 { c=1e-300 }
    d=1/d
    let delta=d*c; result*=delta
    if calc.abs(delta - 1) < 1e-14 { return result }
  }
  panic("school: beta fraction did not converge")
}
#let beta-cdf(x,a,b) = {
  assert(a > 0 and b > 0 and 0 <= x and x <= 1)
  if x==0 or x==1 { return x }
  let scale=calc.exp(log-gamma(a+b) - log-gamma(a) - log-gamma(b)+a*calc.ln(x)+b*calc.ln(1 - x))
  if x < (a+1)/(a+b+2) { scale*beta-fraction(a,b,x)/a } else { 1 - scale*beta-fraction(b,a,1 - x)/b }
}
#let t-cdf(x,df) = {
  assert(df > 0)
  let tail=beta-cdf(df/(df+x*x),df/2,0.5)/2
  if x < 0 { tail } else { 1 - tail }
}
#let t-quantile(p,df) = {
  assert(0 < p and p < 1 and df > 0)
  let bound=1.0
  while t-cdf(bound,df) < calc.max(p,1 - p) and bound < 1e12 { bound*=2 }
  bisect(x=>t-cdf(x,df) - p, - bound,bound)
}
#let chi-square-quantile(p,df) = {
  assert(0 < p and p < 1 and df > 0)
  let bound=calc.max(1,df)
  while chi-square-cdf(bound,df) < p { bound*=2 }
  bisect(x=>chi-square-cdf(x,df) - p,0,bound)
}
#let tail-probability(cdf,alternative) = {
  assert(alternative in ("two-sided","less","greater"))
  if alternative=="less" { cdf } else if alternative=="greater" { 1 - cdf } else { 2*calc.min(cdf,1 - cdf) }
}
#let mean-ci(xs,confidence:0.95) = {
  assert(0 < confidence and confidence < 1)
  let margin=t-quantile((1+confidence)/2,xs.len() - 1)*calc.sqrt(variance(xs)/xs.len())
  (lower:mean(xs) - margin,upper:mean(xs)+margin)
}
#let t-test(xs,mu:0,alternative:"two-sided") = {
  let se=calc.sqrt(variance(xs)/xs.len()); assert(se > 0)
  let statistic=(mean(xs) - mu)/se
  (statistic:statistic,df:xs.len() - 1,p-value:tail-probability(t-cdf(statistic,xs.len() - 1),alternative))
}
#let welch-test(xs,ys,difference:0,alternative:"two-sided") = {
  let a=variance(xs)/xs.len(); let b=variance(ys)/ys.len(); assert(a+b > 0)
  let df=(a+b)*(a+b)/(a*a/(xs.len() - 1)+b*b/(ys.len() - 1))
  let statistic=(mean(xs) - mean(ys) - difference)/calc.sqrt(a+b)
  (statistic:statistic,df:df,p-value:tail-probability(t-cdf(statistic,df),alternative))
}
#let paired-test(xs,ys,alternative:"two-sided") = { assert(xs.len()==ys.len()); t-test(xs.zip(ys).map(p=>p.at(0) - p.at(1)),alternative:alternative) }
#let chi-square-test(observed,expected,parameters:0) = {
  check-data(observed,minimum:2); check-data(expected,minimum:2)
  assert(observed.len()==expected.len() and observed.all(v=>v >= 0) and expected.all(v=>v > 0))
  assert(calc.abs(observed.sum() - expected.sum()) < 1e-7*calc.max(1,observed.sum()),message:"school: expected and observed totals differ")
  let df=observed.len() - 1 - parameters; assert(df > 0)
  let statistic=observed.zip(expected).map(p=>calc.pow(p.at(0) - p.at(1),2)/p.at(1)).sum()
  (statistic:statistic,df:df,p-value:1 - chi-square-cdf(statistic,df))
}
#let independence-test(rows) = {
  assert(rows.len() > 1 and rows.first().len() > 1 and rows.all(r=>r.len()==rows.first().len() and r.all(v=>v >= 0)))
  let totals=rows.map(r=>r.sum()); let total=totals.sum(); assert(total > 0 and totals.all(v=>v > 0))
  let columns=range(rows.first().len()).map(j=>rows.map(r=>r.at(j)).sum()); assert(columns.all(v=>v > 0))
  let expected=totals.map(r=>columns.map(c=>r*c/total)).flatten()
  let statistic=rows.flatten().zip(expected).map(p=>calc.pow(p.at(0) - p.at(1),2)/p.at(1)).sum()
  let df=(rows.len() - 1)*(columns.len() - 1)
  (statistic:statistic,df:df,p-value:1 - chi-square-cdf(statistic,df),expected:expected)
}
#let proportion-ci(successes,n,confidence:0.95) = {
  assert(type(n)==int and n > 0 and type(successes)==int and 0 <= successes and successes <= n and 0 < confidence and confidence < 1)
  let p=successes/n; let z=normal-quantile((1+confidence)/2)
  let center=(p+z*z/(2*n))/(1+z*z/n)
  let margin=z*calc.sqrt(p*(1 - p)/n+z*z/(4*n*n))/(1+z*z/n)
  (lower:center - margin,upper:center+margin)
}
#let binomial-test(k,n,p,alternative:"two-sided") = {
  assert(0 <= k and k <= n)
  let observed=binomial(n,p,k)
  let probability=if alternative=="two-sided" {
    range(n+1).map(i=> { let v=binomial(n,p,i); if v <= observed+1e-14 { v } else { 0 } }).sum()
  } else if alternative=="less" { binomial(n,p,k,cumulative:true) } else {
    assert(alternative=="greater"); 1 - binomial(n,p,k - 1,cumulative:true)
  }
  (p-value:calc.min(1,probability))
}
// SVG output is portable to PDF and requires no external plotting package.
#let chart(series,x-range:none,y-range:none,width:12cm,height:7cm,x-label:"x",y-label:"y",labels:(),equal-scale:false) = {
  assert(series.len() > 0)
  let points=series.fold((),(acc,s)=>acc+s.points)
  assert(points.len() > 0)
  let xr=if x-range==none { (calc.min(..points.map(p=>p.at(0))),calc.max(..points.map(p=>p.at(0)))) } else { x-range }
  let yr=if y-range==none { (calc.min(..points.map(p=>p.at(1))),calc.max(..points.map(p=>p.at(1)))) } else { y-range }
  if xr.at(0)==xr.at(1) { xr=(xr.at(0) - 1,xr.at(1)+1) }
  if yr.at(0)==yr.at(1) { yr=(yr.at(0) - 1,yr.at(1)+1) }
  assert(xr.at(0) < xr.at(1) and yr.at(0) < yr.at(1))
  if x-range==none {
    let pad=(xr.at(1) - xr.at(0))*0.05
    xr=(xr.at(0) - pad,xr.at(1)+pad)
  }
  if y-range==none {
    let pad=(yr.at(1) - yr.at(0))*0.05
    yr=(yr.at(0) - pad,yr.at(1)+pad)
  }
  if equal-scale {
    let xspan=xr.at(1) - xr.at(0)
    let yspan=yr.at(1) - yr.at(0)
    if xspan/yspan < 500/280 {
      let mid=(xr.at(0)+xr.at(1))/2
      xr=(mid - yspan*500/560,mid+yspan*500/560)
    } else {
      let mid=(yr.at(0)+yr.at(1))/2
      yr=(mid - xspan*280/1000,mid+xspan*280/1000)
    }
  }
  let px(x)=50+500*(x - xr.at(0))/(xr.at(1) - xr.at(0))
  let py(y)=310 - 280*(y - yr.at(0))/(yr.at(1) - yr.at(0))
  let svg="<svg xmlns='http://www.w3.org/2000/svg' width='600' height='360'><defs><clipPath id='plot'><rect x='50' y='30' width='500' height='280'/></clipPath></defs><path d='M50 30V310H550' fill='none' stroke='black'/>"
  for i in range(6) {
    let x=xr.at(0)+(xr.at(1) - xr.at(0))*i/5
    let y=yr.at(0)+(yr.at(1) - yr.at(0))*i/5
    svg+="<g font-size='12' font-family='sans-serif'><text x='"+str(px(x))+"' y='330' text-anchor='middle'>"+str(calc.round(x,digits:2))+"</text><text x='45' y='"+str(py(y)+4)+"' text-anchor='end'>"+str(calc.round(y,digits:2))+"</text></g>"
  }
  svg+="<g clip-path='url(#plot)'>"
  let colors=("#1664a0","#b13b26","#26733e","#75439a")
  for (i,s) in series.enumerate() {
    let color=colors.at(calc.rem(s.at("color-index",default:i),colors.len()))
    if s.at("scatter",default:false) {
      for p in s.points { svg+="<circle cx='"+str(px(p.at(0)))+"' cy='"+str(py(p.at(1)))+"' r='3' fill='"+color+"'/>" }
    } else {
      let coords=s.points.map(p=>str(px(p.at(0)))+","+str(py(p.at(1)))).join(" ")
      svg+="<polyline points='"+coords+"' fill='none' stroke='"+color+"' stroke-width='2'/>"
    }
  }
  svg+="</g></svg>"
  assert(labels.len() == 0 or labels.len() == series.len(), message: "school: one label per series required")
  let legend = labels.enumerate().map(((i,label)) => text(fill: rgb(colors.at(calc.rem(i,colors.len()))), label)).join(h(1em))
  stack(spacing:3pt,image(bytes(svg),width:width,height:height,fit:"contain"), ..if x-label == "x" and y-label == "y" { () } else { (align(center,[#y-label versus #x-label]),) }, ..if labels.len() == 0 { () } else { (align(center,legend),) })
}
#let plot(functions,a,b,steps:200,..options) = {
  assert(a < b and type(steps)==int and steps > 0)
  let fs=if type(functions)==array { functions } else { (functions,) }
  chart(fs.map(f=>(points:range(steps+1).map(i=> { let x=a+(b - a)*i/steps; (x,f(x)) }))),..options)
}
#let parametric(f,a,b,steps:200,equal-scale:true,..options) = { assert(a < b and type(steps)==int and steps > 0); chart(((points:range(steps+1).map(i=>f(a+(b - a)*i/steps))),),equal-scale:equal-scale,..options) }
#let scatter(xs,ys,..options) = { assert(xs.len()==ys.len()); chart(((points:xs.zip(ys),scatter:true),),..options) }
#let residual-plot(xs,fit,..options) = scatter(xs,fit.residuals,..options)
#let histogram(xs,edges,density:false,..options) = {
  check-data(xs); check-data(edges,minimum:2)
  assert(range(edges.len() - 1).all(i=>edges.at(i) < edges.at(i+1)))
  assert(xs.all(x=>edges.first() <= x and x <= edges.last()),message:"school: histogram edges must cover data")
  let bars=range(edges.len() - 1).map(i=> {
    let l=edges.at(i); let r=edges.at(i+1)
    let count=xs.filter(x=>l <= x and (x < r or (i==edges.len() - 2 and x==r))).len()
    let y=if density { count/(xs.len()*(r - l)) } else { count }
    (points:((l,0),(l,y),(r,y),(r,0)))
  })
  chart(bars,..options)
}
#let box-plot(xs,method: "linear",..options) = {
  let d=describe(xs, method: method)
  chart(((points:((d.min,0.5),(d.q1,0.5),(d.q1,0),(d.q3,0),(d.q3,1),(d.q1,1),(d.q1,0.5),(d.max,0.5))),
    (points:((d.median,0),(d.median,1)))),y-range:( - 0.5,1.5),..options)
}
#let line-intersection(p,u,q,v,tolerance:1e-8) = {
  assert(p.len()==u.len() and p.len()==q.len() and p.len()==v.len() and p.len() in (2,3))
  let w=q.zip(p).map(pair=>pair.at(0) - pair.at(1))
  let parameters=linear-solve(((dot(u,u), -dot(u,v)),(dot(u,v), -dot(v,v))),(dot(u,w),dot(v,w)))
  let point=p.zip(u).map(pair=>pair.at(0)+parameters.at(0)*pair.at(1))
  let other=q.zip(v).map(pair=>pair.at(0)+parameters.at(1)*pair.at(1))
  assert(norm(point.zip(other).map(pair=>pair.at(0) - pair.at(1))) <= tolerance,message:"school: skew lines have no intersection")
  (point:point,parameters:parameters)
}
#let plane-intersection(n1,d1,n2,d2) = {
  let direction=cross(n1,n2)
  let point=linear-solve((n1,n2,direction),(d1,d2,0))
  (point:point,direction:direction)
}
#let regression-ci(xs,ys,x,confidence:0.95,prediction:false) = {
  assert(xs.len() > 2 and 0 < confidence and confidence < 1)
  let fit=regression(xs,ys)
  let s2=dot(fit.residuals,fit.residuals)/(xs.len() - 2)
  let sxx=xs.map(v=>calc.pow(v - mean(xs),2)).sum()
  let margin=t-quantile((1+confidence)/2,xs.len() - 2)*calc.sqrt(s2*((if prediction { 1 } else { 0 })+1/xs.len()+calc.pow(x - mean(xs),2)/sxx))
  (lower:(fit.predict)(x) - margin,upper:(fit.predict)(x)+margin)
}
#let variance-ci(xs,confidence:0.95) = {
  assert(0 < confidence and confidence < 1)
  let df=xs.len() - 1
  let scale=df*variance(xs)
  (lower:scale/chi-square-quantile((1+confidence)/2,df),upper:scale/chi-square-quantile((1 - confidence)/2,df))
}
#let slope-field(f,x-range,y-range,columns:16,rows:12,..options) = {
  assert(columns > 0 and rows > 0 and x-range.at(0) < x-range.at(1) and y-range.at(0) < y-range.at(1))
  let dx=(x-range.at(1) - x-range.at(0))/columns
  let dy=(y-range.at(1) - y-range.at(0))/rows
  let segments=()
  for i in range(columns+1) { for j in range(rows+1) {
    let x=x-range.at(0)+i*dx; let y=y-range.at(0)+j*dy
    let slope=f(x,y)
    let h=0.35/calc.sqrt(1/(dx*dx)+slope*slope/(dy*dy))
    segments.push((color-index:0,points:((x - h,y - slope*h),(x+h,y+slope*h))))
  } }
  chart(segments,x-range:x-range,y-range:y-range,..options)
}
// Reusable formula recipes. SI inputs unless a caller consistently converts units.
#let quadratic(a,b,c) = {
  assert(a!=0)
  let d=b*b - 4*a*c
  if d < 0 { return () }
  if d==0 { return (-b/(2*a),) }
  let q = -0.5*(b+(if b >= 0 { 1 } else { -1 })*calc.sqrt(d))
  (q/a,c/q).sorted()
}
#let compound-interest(principal,rate,periods) = { assert(rate > -1); principal*calc.pow(1+rate,periods) }
#let annuity(payment,rate,periods) = {
  assert(rate > -1 and periods >= 0)
  if rate==0 { payment*periods } else { payment*(calc.pow(1+rate,periods) - 1)/rate }
}
#let kinematics(position,velocity,acceleration,time) = (position:position+velocity*time+acceleration*time*time/2,velocity:velocity+acceleration*time)
#let decay(initial,half-life,time) = { assert(half-life > 0); initial*calc.pow(0.5,time/half-life) }
#let qq-plot(xs,quantile-function,..options) = {
  check-data(xs,minimum:2)
  let sorted=xs.sorted()
  scatter(range(xs.len()).map(i=>quantile-function((i+0.5)/xs.len())),sorted,..options)
}
#let normal-plot(xs,..options) = qq-plot(xs,p=>normal-quantile(p),..options)
#let weighted-quantile(values,weights,p) = {
  check-data(values); check-data(weights)
  assert(values.len()==weights.len() and weights.all(w=>w >= 0) and weights.sum() > 0 and 0 <= p and p <= 1)
  let pairs=values.zip(weights).filter(pair=>pair.at(1) > 0).sorted(key:pair=>pair.at(0))
  let threshold=p*weights.sum()
  let cumulative=0.0
  for pair in pairs {
    cumulative+=pair.at(1)
    if cumulative >= threshold { return pair.at(0) }
  }
  pairs.last().at(0)
}
#let grouped-histogram(edges,counts,density:false,..options) = {
  check-data(edges,minimum:2); check-data(counts)
  assert(edges.len()==counts.len()+1 and counts.all(c=>c >= 0) and counts.sum() > 0)
  assert(range(counts.len()).all(i=>edges.at(i) < edges.at(i+1)))
  let bars=range(counts.len()).map(i=> {
    let l=edges.at(i); let r=edges.at(i+1)
    let y=if density { counts.at(i)/(counts.sum()*(r - l)) } else { counts.at(i) }
    (points:((l,0),(l,y),(r,y),(r,0)))
  })
  chart(bars,..options)
}

// Symbolic particular solutions with y(x0)=initial. Parameters may be numbers
// or CAS source strings. The affine formula requires a nonzero rate.
#let ode-particular(kind, rate, initial, x0: 0, offset: 0, capacity: 1) = {
  import "@preview/typcas:0.2.3": cas
  assert(kind in ("exponential", "affine", "logistic"))
  let source(v)=if type(v)==str { "("+v+")" } else { "("+str(v)+")" }
  let a=source(rate); let y=source(initial); let t="(x-"+source(x0)+")"
  let formula=if kind=="exponential" { y+"*e^("+a+"*"+t+")" }
    else if kind=="affine" {
      if type(rate) in (int,float) and rate==0 { y+"+"+source(offset)+"*"+t }
      else { "("+y+"+"+source(offset)+"/"+a+")*e^("+a+"*"+t+")-"+source(offset)+"/"+a }
    } else {
      let m=source(capacity)
      if type(initial) in (int,float) and initial==0 { "0" }
      else { m+"/(1+("+m+"/"+y+"-1)*e^(-"+a+"*"+m+"*"+t+"))" }
    }
  let result=cas.simplify(formula)
  assert(cas.ok(result))
  cas.expr-of(result)
}

// Finite smooth-domain sign chart. Completeness depends on the root scan.
// Each returned record describes a closed/open interval or an isolated point.
#let inequality(f,a,b,relation:"<=",steps:200,tolerance:1e-7,exclusions:()) = {
  assert(relation in ("<","<=",">",">="))
  let scan=domain-scan(f,a,b,steps:steps,tolerance:tolerance,exclusions:exclusions)
  let zeros=scan.roots
  let cuts=((a,)+ (zeros+scan.poles).filter(x=>a < x and x < b)+(b,)).dedup().sorted()
  let inclusive=relation in ("<=",">=")
  let accepts(x)=if relation in ("<","<=") { f(x) < 0 } else { f(x) > 0 }
  let endpoint(x)=if scan.poles.any(p=>calc.abs(p - x) <= tolerance) {false} else if zeros.any(z=>calc.abs(z - x) <= tolerance) { inclusive } else { accepts(x) }
  let intervals=()
  for (l,r) in cuts.slice(0,-1).zip(cuts.slice(1)) {
    if accepts((l+r)/2) { intervals.push((lo:l,hi:r,lo-closed:endpoint(l),hi-closed:endpoint(r))) }
  }
  if inclusive {
    for x in zeros {
      if not intervals.any(i=>(i.lo==x and i.lo-closed) or (i.hi==x and i.hi-closed)) {
        intervals.push((lo:x,hi:x,lo-closed:true,hi-closed:true))
      }
    }
  }
  intervals.sorted(key:i=>i.lo)
}

// One explicit convention shared by trigonometry, geometry and complex numbers.
#let angles(mode: "radians") = {
  assert(mode in ("radians", "degrees"), message: "school: angle mode must be radians or degrees")
  let scale = if mode == "degrees" { calc.pi/180 } else { 1 }
  let convert(t) = {
    for name in ("alpha", "beta", "gamma") { t.at(name) /= scale }
    t
  }
  (
    sin: x => calc.sin(x*scale*1rad),
    cos: x => calc.cos(x*scale*1rad),
    tan: x => calc.tan(x*scale*1rad),
    vector-angle: (u,v) => vector-angle(u,v)/scale,
    triangle: (a,b,c) => convert(triangle(a,b,c)),
    triangles: (a:none,b:none,c:none,alpha:none,beta:none,gamma:none) => triangles(
      a:a,b:b,c:c,
      alpha:if alpha==none { none } else { alpha*scale },
      beta:if beta==none { none } else { beta*scale },
      gamma:if gamma==none { none } else { gamma*scale }).map(convert),
    complex-polar: z => { let p=complex-polar(z); p.argument /= scale; p },
    complex-cartesian: (r,theta) => complex-cartesian(r,theta*scale),
  )
}

// Serialize only numeric scalars/vectors/matrices for the existing builder API.
#let value-source(value) = {
  if type(value) in (int,float) {
    assert(value == value and calc.abs(value) != calc.inf, message: "school: only finite values can be stored")
    return str(value)
  }
  assert(type(value)==array and value.len()>0, message: "school: store a numeric field, vector or matrix")
  if type(value.first())==array {
    assert(value.all(row=>type(row)==array and row.len()==value.first().len()), message: "school: rectangular matrix required")
    return "mat(" + value.map(row=>row.map(value-source).join(",")).join(";") + ")"
  }
  "vec(" + value.map(value-source).join(",") + ")"
}
