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
