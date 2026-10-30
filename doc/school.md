# School mathematics (demo)

Import `school` from `math-once.typ`. These are Typst functions operating on plain
numbers and arrays, separate from the builder expression parser. They do not
carry physical units, store builder state, or automatically print working.
Angles returned by geometry functions are **radians as numbers**; multiply by
`180 / calc.pi` for degrees. Never pass Typst angles to these helpers.

```typ
#import "../math-once.typ": school
#let fit = school.regression((1, 2, 3), (3, 5, 7))
Prediction: #(fit.predict)(4)
Probability: #school.binomial(10, 0.5, 3, cumulative: true)
Area: #school.integral(x => x*x, 0, 2)
```

| Call | Contract |
| --- | --- |
| `mean(xs)` | Arithmetic mean; nonempty numeric array. |
| `variance(xs, sample: true)` | Sample variance divides by n−1; population option divides by n. |
| `quantile(xs, p)` | Sorted linear interpolation at index `(n−1)p`, not a Danish textbook-specific quartile convention. |
| `describe(xs)` | Count, mean, median, q1, q3, min, max, population variance and sd. |
| `choose(n, k)` | Binomial coefficient for integers 0 ≤ k ≤ n. Floating arithmetic. |
| `binomial(n, p, k, cumulative: false)` | P(X=k), or P(X≤k); tails outside support handled. |
| `normal-pdf(x, mean: 0, sd: 1)` | Normal density, positive sd. |
| `normal-cdf(x, mean: 0, sd: 1)` | Lower-tail approximation; absolute error about 7.5e−8. Subtract CDFs for intervals. Not suitable for extreme-tail relative precision. |
| `normal-quantile(p, mean: 0, sd: 1)` | Numerical CDF inverse for strictly interior p; inherits CDF error and tail saturation. |
| `bisect(f, a, b, tolerance: 1e-10, iterations: 200)` | One bracketed root; interval-width tolerance, assumes continuity. No completeness or residual guarantee at a pole. |
| `integral(f, a, b, steps: 200)` | Composite Simpson rule; positive even steps. Finite smooth integrand, no error estimate or singularity detection. Reversed bounds supported. |
| `derivative(f, x, h: 1e-5)` | Central difference; user controls step. No automatic error estimate. |
| `ode(f, x0, y0, end, steps: 100)` | Scalar y′=f(x,y), fixed-step RK4; returns `(x,y)` pairs including start. No stiffness/adaptive error handling. |
| `regression(xs, ys, model: "linear")` | Linear, exponential, power, logarithmic. Returns slope/intercept in transformed coordinates, coefficient, predict function, residuals and r-squared in original y space. Constant y gives `none` for r-squared. |
| `dot(u,v)`, `norm(u)`, `cross(u,v)` | Equal-length dot, Euclidean norm, 3D cross product. |
| `vector-angle(u,v)` | Angle between nonzero vectors, radians. |
| `triangle(a,b,c)` | SSS sides; returns sides, opposite angles alpha/beta/gamma, Heron area. Strict triangle inequality. |
| `linear-solve(a,b,tolerance: 1e-12)` | Square numerical system with partial pivoting. Arrays of rows, RHS array. Rejects small absolute pivots. |
| `inverse(a,tolerance: 1e-12)` | Square matrix inverse as row arrays, same pivot rules. |

For exponential fits, `coefficient * exp(slope*x)` is the model; for power fits,
`coefficient * x^slope`. Positive y is required for both, positive x for power
and logarithmic. Log-transformed least squares minimizes transformed residuals,
not original-space residuals. These are different fitting objectives.

Numerical routines use floating arithmetic. Small pivots, huge binomial
coefficients, poorly scaled data and cancellation need care. No claim of
arbitrary precision or full WordMat equivalence is made. See
[wordmat-coverage.md](wordmat-coverage.md) for remaining workflows.

## Extended daily workflows

All calls below are members of `school`. Callback arguments are Typst code, not builder expressions. See `tests/school-extended.typ` for executable examples, known-answer assertions and rendered charts.

| Call | Contract |
| --- | --- |
| `plot(f, a, b, steps: 200, ..options)` | Sample one function or an array of functions. Multiple curves use distinct colors in supplied order. |
| `parametric(t => (x,y), a, b, steps: 200, equal-scale: true, ..options)` | Sample a plane curve, including closed curves. Equal coordinate scaling defaults on. |
| `chart(series, x-range: none, y-range: none, width: 12cm, height: 7cm, x-label: "x", y-label: "y")` | Each series is `(points: ((x,y), ...), scatter: false)`. Explicit ranges clip the plot. Automatic ranges have 5% padding. `equal-scale: true` expands ranges to preserve coordinate aspect. Tick numbers show coordinate ranges; label arguments render below it. |
| `scatter(xs, ys, ..options)`, `residual-plot(xs, fit, ..options)` | Observations or original-space fit residuals. |
| `histogram(xs, edges, density: false, ..options)` | Explicit strictly increasing edges covering all data. Bins are left-closed, right-open except the last includes its endpoint. Density divides counts by sample size and bin width. |
| `box-plot(xs, ..options)` | Interpolated quartiles and median; whiskers reach min/max. This is **not** a Tukey outlier plot. |
| `slope-field(f, x-range, y-range, columns: 16, rows: 12, ..options)` | Short normalized direction segments for y′=f(x,y). |
| `weighted-summary(values, weights)` | Nonnegative weights, positive total. Population moments, not an unbiased sample estimator. Frequency or probability weights accepted. |
| `grouped-summary(edges, counts)` | Midpoint approximation of grouped population moments. Bin edges strictly increase. |
| `polynomial-fit(xs, ys, degree: 2)` | Ascending-power coefficients, predict and residuals. Any nonnegative degree below sample count, including WordMat's degrees 2–6. Normal equations need well-scaled x; singular designs reject. |
| `custom-fit(xs, ys, model, initial, iterations: 100, tolerance: 1e-8)` | Damped numerical least squares. `model(x, parameters)` returns y. Returns parameters, predict, residuals, **converged**. Always inspect that flag. Local stationary solutions depend on starting parameters; no global-optimum guarantee. |
| `sinus-fit(xs, ys, initial, iterations: 200)` | Custom fit of `A sin(ωx+φ)+offset`; initial is `(A,ω,φ,offset)`, radians. Supply a plausible frequency; aliases/local minima are possible. |
| `t-cdf(x, df)`, `t-quantile(p, df)` | Student t lower tail and inverse, positive df. |
| `chi-square-cdf(x, df)`, `chi-square-quantile(p, df)` | Chi-square lower tail and inverse, x≥0 and positive df. |
| `mean-ci(xs, confidence: 0.95)` | Two-sided Student t mean interval. Independent normal observations, or a suitable large-sample approximation. |
| `variance-ci(xs, confidence: 0.95)` | Chi-square variance interval; requires independent normal observations. |
| `t-test(xs, mu: 0, alternative: "two-sided")` | One-sample t test. Returns statistic, df, p-value. Nonzero sample variance required. |
| `welch-test(xs, ys, difference: 0, alternative: "two-sided")` | Independent unequal-variance mean comparison. |
| `paired-test(xs, ys, alternative: "two-sided")` | One-sample t test on paired differences, null mean difference zero. |
| `chi-square-test(observed, expected, parameters: 0)` | GOF statistic and upper-tail p. Totals must agree; fitted parameter count reduces df. Positive expected counts; caller must assess small-cell approximation validity. |
| `independence-test(rows)` | Contingency-table independence test; expected frequencies and statistic/df/p-value. No zero row/column margins. No continuity correction. |
| `proportion-ci(successes, n, confidence: 0.95)` | Wilson score interval, including zero/all successes. |
| `binomial-test(k, n, p, alternative: "two-sided")` | Exact discrete tails; two-sided sums masses no larger than observed mass. Large n may overflow the underlying binomial coefficient. |
| `regression-ci(xs, ys, x, confidence: 0.95, prediction: false)` | Linear regression mean-response interval, or individual prediction interval. Independent normal homoscedastic residual assumption. |
| `triangles(a: none, b: none, c: none, alpha: none, beta: none, gamma: none)` | Exactly three independent measurements. SSS, SAS, ASA/AAS, SSA. Returns array of zero, one or two solution dictionaries compatible with `triangle`. Impossible SSA returns empty; invalid non-SSA inputs reject. |
| `complex-add(z,w)`, `complex-mul(z,w)`, `complex-div(z,w)` | Cartesian `(real,imaginary)` pairs; subtraction uses addition of a negated pair. Division rejects zero divisor. |
| `complex-polar(z)`, `complex-cartesian(r,theta)`, `complex-roots(z,n)` | Modulus/argument, polar conversion and n distinct roots of nonzero z. Zero roots return one zero pair; zero has no argument. |
| `projection(u,v)`, `plane-projection(point,normal,offset)` | Vector projection onto nonzero v; perpendicular point projection onto `normal·x=offset`. |
| `line-plane(point,direction,normal,offset)` | Unique intersection point and line parameter. Rejects parallel or contained lines. |
| `line-intersection(p,u,q,v)` | Intersection of two nonparallel 2D/3D lines; rejects parallel and skew lines. |
| `plane-intersection(n1,d1,n2,d2)` | Point and direction of intersection line for two nonparallel 3D planes. |
| `determinant(a)`, `rank(a)`, `matrix-info(a)` | Pivoted elimination; singular determinants return zero, rank supports rectangular arrays. Absolute pivot tolerance defaults to 1e−12. |
| `ode-system(f,x0,y0,end,steps:100)` | Vector-state RK4. `f(x,ys)` returns derivative array. Higher-order ODEs use state `(y,y′,...)`. Same fixed-step limitations as scalar `ode`. |
| `system-root(f,initial,tolerance:1e-9,iterations:100,h:1e-5)` | Damped Newton, square residual array, finite-difference Jacobian. Returns only after residual norm meets tolerance, otherwise rejects. Singular Jacobian may reject even when other starts work. |
| `roots(f,a,b,steps:200,tolerance:1e-7)` | Bounded candidate scan using sign crossings and derivative sign crossings for tangent roots. Returns sorted deduplicated roots whose residual passes tolerance. Requires smooth, finite callbacks; **not a proof that all roots were found**. Increase steps and compare results, partition known domains, and use symbolic `solve` when completeness matters. |

Charts use embedded SVG and render in PDF without an external plotting service. They are fixed samples: discontinuities, poles and high-frequency oscillations need domain splitting and enough samples. Automatic pole detection, adaptive plotting and 3D surfaces are not implemented.

Distribution functions use Lanczos log-gamma, a regularized gamma series/continued fraction, and a regularized beta continued fraction. Quantiles use bracketed inversion. Ordinary school quantiles have reference assertions; extreme-tail relative precision is not guaranteed. No routine silently validates statistical modelling assumptions for you.

## Formula recipes

`quadratic(a,b,c)` returns real roots using a cancellation-resistant formula; no real roots gives `()`. `compound-interest(principal,rate,periods)` computes future value. `annuity(payment,rate,periods)` computes the future value of end-of-period payments, including rate zero. `kinematics(position,velocity,acceleration,time)` returns final position and velocity under constant acceleration. `decay(initial,half-life,time)` computes exponential decay. Rates are fractions per period; physics inputs need consistent units. Unit-aware expressions can instead be entered in the existing builder.

```typ
#let trajectory = school.ode-system((t,y) => (y.at(1), -9.82), 0, (0,20), 4)
#school.chart(((points: trajectory.map(p => (p.at(0),p.at(1).at(0)))),))
#let candidates = school.roots(x => calc.sin(x * 1rad), -10, 10)
#let interval = school.mean-ci((12.1, 12.4, 11.8, 12.2, 12.0))
#let ambiguous = school.triangles(a: 5, b: 8, alpha: calc.pi / 6)
```

## Existing CAS boundary

`math-once.typ` already dispatches builder `solve`, simplify, factor, differentiation and integration to typCAS 0.2.3. `tests/symbolic-cas.typ` verifies real polynomial solve and calculus paths. The installed CAS solver facade delegates to its solve engine, which includes complex polynomial roots and inverse-function branches. Those source capabilities are broader than the existing builder fixture; their general builder behaviour is not established by these school tests. These additions leave that engine intact. Numerical callbacks fill distinct workflows; they do not extend the expression parser or establish arbitrary symbolic nonlinear-system, complex-domain or inequality support.

Distribution/test references: NIST's [Student t distribution](https://www.itl.nist.gov/div898/handbook/eda/section3/eda3664.htm), [chi-square distribution](https://www.itl.nist.gov/div898/handbook/eda/section3/eda3666.htm), and [two-sample t test](https://www.itl.nist.gov/div898/handbook/eda/section3/eda353.htm). Implementation verification uses known quantiles and elementary special cases rather than relying on a link as proof.

`qq-plot(xs, quantile-function, ..options)` plots sorted observations against quantiles at `(i+0.5)/n`. `normal-plot(xs, ..options)` supplies standard normal quantiles. These are descriptive plots; no normality-test p-value is inferred from the picture.

`weighted-quantile(values, weights, p)` returns the first positive-weight observation whose cumulative weight reaches p of the total. This is an inverse empirical CDF, without interpolation. `grouped-histogram(edges, counts, density: false, ..options)` draws existing frequency tables directly; density uses count divided by total count and bin width, so unequal-width bins have the correct area interpretation.

### CAS school workflow repairs

The builder accepts `expand((x+1)^2-x^2)`, nested `solve(diff(x^3-3*x,x),x)`, and `integrate(x^2,x,0,2)`. `simplify` retains its existing non-expanding behavior. Nested `diff`, `simplify`, and `expand` work when they occupy a whole CAS argument; store other nested operations or calls embedded in sums in a separate assignment first. `limit(1/x,x,oo)` and `infinity` target positive infinity. Euler's `e` remains exact in symbolic input. Solve defaults to real numeric roots; symbolic parameter quadratics return the formula assuming a≠0, with real roots requiring b²−4ac≥0. Parameter/domain case splitting remains the caller’s responsibility. Empty unsupported fallback results now produce a diagnostic rather than claiming no solutions. Identical polynomial equations store `solution-status: "all"` and display ℝ.

Numerical real-domain and periodic routes require an explicit smooth finite domain:

```typ
#import "../school.typ" as school
#school.roots(x => calc.sin(x), 0, 2*calc.pi)
#school.roots(x => calc.sqrt(x+3) - (x - 3), 3, 10)
#school.inequality(x => x*x - 1, -2, 2, relation: "<=")
```

`inequality` returns records `(lo, hi, lo-closed, hi-closed)`, including isolated equality points for non-strict relations. Operators are `<`, `<=`, `>`, `>=`. Bounds are included only when the relation holds. Trigonometric callbacks use radians. Both routes use finite root scans, not complete symbolic solution families. Increase `steps` for oscillations or tightly spaced roots. Split at poles and outside real domains; callbacks must be finite and smooth throughout each supplied interval. No arbitrary search domain is chosen by the builder.

`school.ode-particular(kind, rate, initial, x0: 0, offset: 0, capacity: 1)` returns a typCAS expression for the solution with `y(x0)=initial`. Kinds are `"exponential"` for y′=ay, `"affine"` for y′=ay+b, and `"logistic"` for y′=ay(M−y). `offset` is b and `capacity` is M. Parameters may be numbers or CAS strings such as `"k"`. Symbolic affine rate assumes a≠0; numeric zero rate uses y=y₀+b(x−x₀). Logistic zero initial value returns the equilibrium zero. Formulas apply only where their denominator is nonzero. For example:

```typ
#import "@preview/typcas:0.2.3": cas
#let particular = school.ode-particular("logistic", 0.2, 2, capacity: 10)
$#cas.display(particular)$
```

Symbolic integration remains incomplete. In particular `x*e^x` and `sin(x)*cos(x)` are not promised symbolic primitives; inspect the returned expression for an unevaluated integral or use `school.integral` on explicit numeric bounds. The adapter handles the common linear-exponent `e^(a*x+b)` primitive. It does not claim arbitrary symbolic integral coverage.

### Phase-one correctness guardrails

Symbolic integration supports affine reciprocals through logarithms of absolute
values, reciprocal powers, positive constant-base exponentials, monomial
products (including square roots), and real quadratic reciprocals with distinct
roots. Engine fallback primitives must pass derivative comparison at at least
three independent real-domain samples; this is a numerical safeguard, not a
symbolic proof. Unsupported primitives produce a diagnostic.

Positive-infinity limits currently certify simple reciprocal and negative-power
decay to exact zero. Growing exponentials, polynomials, square roots and logarithms
at infinity produce an explicit unsupported-limit diagnostic before calling the
engine. Finite poles and logarithmic domain boundaries require one-sided analysis
and produce diagnostics. General negative infinity remains unsupported.

Bounded numerical roots use local slope and curvature residual scales without
an absolute unit floor. Multiplying a function by a nonzero constant therefore
does not change the acceptance criterion. Stationary-point scans retain repeated
roots; pole crossings must also pass the local residual check. Finite scans can
still miss closely spaced roots and cannot certify arbitrary discontinuous
callbacks. Inequalities use those same roots to classify interval endpoints.

Root scans and inequality charts retain rejected sign crossings as open domain
cuts. Pass known callback poles with `exclusions: (pole, ...)` to `roots` or
`inequality`; these points are not evaluated. Typst cannot catch errors thrown
by a callback, so an unsupplied pole hit exactly by the grid, bisection, or
derivative stencil can still stop compilation. Scanning cannot certify an
arbitrary callback's domain or discover every discontinuity. Exclusions also
leave a small numerical guard region during root search; roots inside that
region require a separate verified interval.
