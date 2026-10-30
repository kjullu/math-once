# WordMat → MathOnce school workflow inventory

Status: **phase one PASS**, independently reviewed by Claude Opus 5.5 on 2026-10-30 after six coverage rounds. Daily-school coverage is sufficient to proceed to the integration hill climb, subject to the explicit limits below.
Research date: 2026-10-30. Base package: 0.45.0, school mathematics demo.

## Sources and method

Primary reference: [EDUAP WordMath manual, 20 May 2026](https://eduap.com/wordmatdoc/en/WordMatManual_english.pdf),
particularly the contents and sections 5–21. The manual explicitly covers
polynomial degrees 2–6 and sinus/custom fitting (pp. 68–70), general triangle
inputs including ambiguous cases (pp. 102–103), and matrix inverses (p. 92).
[Official online contents](https://wordmat.dk/docs/en/) and
[official solving guide](https://wordmat.dk/docs/en/?page=Equation-solving)
provide cross-checks. The latter distinguishes numerical answers from complete
symbolic solution sets. [WordMat source repository](https://github.com/Eduap-com/WordMat/)
was identified, but no VBA/Maxima source audit or live Word run was performed.

Rows below map school tasks to actual calls or explicit gaps. “Existing” means
repository evidence, not a claim that typCAS covers every input WordMat accepts.
The new numeric assertions are in `tests/school.typ`; existing fixture names are
listed where relevant. This is a workflow inventory, not a button-count score.

## Coverage

Existing builder evidence remains in `tests/calculate.typ`, `tests/functions.typ`, `tests/qalc-units.typ`, `tests/trigonometry.typ`, `tests/symbolic-cas.typ` and `tests/vectors-matrices.typ`. Those cover arithmetic, reusable definitions, units, symbolic simplification/factor/calculus, real polynomial solve and matrix/vector arithmetic. They do not prove arbitrary CAS equivalence.

The original `tests/school.typ` exercises descriptive statistics, transformed regressions, binomial/normal distributions, scalar numerical calculus, SSS and pivoted systems. `tests/school-extended.typ` is the runnable evidence for this phase:

| Manual workflow | Runnable evidence | Limits |
| --- | --- | --- |
| Function/parametric graphs, §§8 | Two functions and closed circle | Fixed finite samples; split discontinuous domains manually. |
| Histogram, box, scatter, residual charts, §8 | Rendered chart page for each | Explicit histogram edges, interpolated quartiles, min/max whiskers; no Tukey outlier convention; `normal-plot` adds a rendered normal QQ chart. |
| Slope field, §8 | y′=x−y field | Fixed grid; no 3D surface renderer. |
| Polynomial, sinus/custom regression, §9 | Known quadratic and recovered sine/line parameters | Polynomial normal equations can be ill-conditioned. Custom/sinus fit is local, must inspect `converged` and try plausible starts. |
| Grouped/frequency data, §8 | Weighted and grouped means | Population moments; grouped midpoint approximation. |
| t and chi-square, §10 | Cauchy CDF, t10 and chi-square4 reference quantiles, one-sample/Welch, GOF/independence | Numerical finite precision; modelling and expected-cell assumptions remain caller responsibility. |
| Intervals and tests, §10 | Mean, variance, Wilson, regression intervals and exact binomial test | No automatic assumptions check or multiple-testing correction. |
| Coupled/higher-order ODE, §12 | Harmonic oscillator reaches y=1 at π/2 | First-order state arrays; fixed RK4, not stiff/adaptive or symbolic solving. |
| Vector geometry, §13 | Projection, line/plane, line/line, plane/plane | Unique intersections only; degenerate cases reject. |
| Matrices, §14 | Singular-safe determinant, row swap and rectangular rank | Absolute numeric pivot tolerance; eigen decomposition remains unimplemented. |
| Complex numbers, §15 | Product/division, polar argument, roots of −1 | Numeric Cartesian pairs, separate from builder expressions; no symbolic complex equation solving. |
| Formula collection, §16 | Quadratic, interest/annuity, decay, constant acceleration | Callable recipes rather than formula browser; not a complete physics formula collection. |
| General triangle, §19 | SAS, AAS, SSA zero and two solutions | Exactly three independent measurements; radians, no measurement uncertainty. |
| Numerical equation systems, §6 | Two nonlinear equations from nearby start | Local damped Newton; singular Jacobian/nonconvergence reject. |
| Multiple numerical roots, §6 | Simple and repeated roots from a non-aligned scan | Bounded smooth finite domain search; no completeness guarantee. Existing symbolic solve is preferable for exact polynomial root sets. |

School helpers take plain numbers. Unit-aware builder calls remain available separately. `doc/school.md` specifies signatures, assumptions, numerical conventions and runnable recipes.

## Justified exclusions

Word ribbon controls, cursor selection, Office macro shortcuts, equation-editor
conversion, Word/Excel table synchronization, COM automation, backup/install
utilities and Word-to-HTML export are host application features. MathOnce is a
Typst library: copying those mechanisms is outside this task. Word-specific
numbering is represented by existing Typst equation/outline helpers rather than
Office automation. These exclusions do **not** exclude underlying mathematics,
plots, regression or statistics merely because WordMat launches Excel/GeoGebra.

Lambert W, arbitrary user programs, advanced solid-of-revolution visualization,
and CAS engine switching are deferred beyond the first daily-school subset;
this is a priority judgement, not proof that HTX never uses them.

## Gate and validation

The independent Claude coverage gate passed after the removable-limit derivative guard and eight regression cases were added. No phase-two integration work or complete WordMat-equivalence claim has been made. Remaining gaps include eigenvalues, broader formula recipes, and symbolic inequality/assumption and general solution-family coverage. These remain visible for reviewer assessment, not silently excluded as exotic.

The reference inventory was cross-checked against the official online contents and manual on 2026-10-30. No live WordMat or VBA/Maxima audit was performed. Installed typCAS 0.2.3 source and the existing dispatch/tests were inspected before adding separate numerical routines. Its solve engine already contains complex polynomial roots and inverse-function isolation; the builder now adds an adapter for common school equation classes and tests those branches explicitly. It does not claim complete CAS equivalence.

### Earlier school-expansion validation

- `python3 tools/test.py`: 105/105 compilation and expected-diagnostic checks passed before acceptance, with only the new `tests/school-extended.typ` PDF awaiting review. Existing baselines remained unchanged.
- The extended fixture contains 64 direct numeric/assertion checks, covering nonlinear residuals, repeated roots, degree-six polynomial fitting, sinus fitting and explicit nonconvergence, distribution reference quantiles, Welch degrees of freedom, chi-square p-values, weighted moments, SSA ambiguity, geometry and recipes. These supplement the original school fixture.
- Two new expected diagnostics cover nonlinear nonconvergence and a parallel line/plane; the original three cover singular systems, root brackets and invalid transformed-regression domains.
- Inspected all five pages of the retained PDF linked by `build/pdf-review/review.md`, including chart scaling, visible scatter markers, and the short-height grouped histogram. Accepted only `tests/school-extended.typ` after that inspection. The accepted SHA-256 is `ec9f369388419a1fc20fab50cfe80d823f359dee2b480e5fdab1134e14bed979`.
- The staged local-package import fixture exercises `school.rank`; no additional modules require staging. Base version stays 0.45.0.
- Post-acceptance `python3 tools/test.py`: **105/105 passed**, with no pending PDF reviews. `git diff --check` passed. No Git mutation, live WordMat run, independent Claude review or phase-two integration work was performed.


### CAS blocker repair evidence awaiting independent re-review

`tests/symbolic-school.typ` asserts numeric answers for every reported common-equation blocker, the parameter-quadratic root count, identity status, nested extrema roots, exact-e derivative evaluation, definite integral, expansion, both positive infinity spellings, real-only quadratic/cubic roots and unsupported periodic diagnostics. It checks first-order particular ODE initial conditions and differential residuals at several x values, symbolic parameter evaluation, inequality endpoint flags and isolated equality points, and bounded sine roots.

The builder now offers `expand(expression)` and `integrate(expression,variable,lower,upper)`. `solve` keeps real numeric candidates that satisfy the original equation. Symbolic parameter formulas assume nondegenerate coefficients and require caller domain checks. Unsupported empty fallback solves emit diagnostics. Periodic equations require the explicit bounded `school.roots` route rather than displaying incomplete inverse-trigonometric branches as complete sets. `school.inequality` provides finite smooth-domain interval records with endpoint flags; it shares the numerical scan's completeness limits. `school.ode-particular` supplies exponential, affine and logistic symbolic initial-value recipes. See `doc/school.md` for signatures and examples.

Remaining limits: no general symbolic inequality engine, periodic families, automatic assumptions/parameter case splitting, eigenvalues, or arbitrary symbolic integration. Numerical scans require finite smooth callbacks and cannot guarantee all roots. Symbolic `x*e^x` and `sin(x)*cos(x)` primitives are not promised. These limits remain part of the coverage gate, not phase-two work.

Final local validation of these CAS repairs: `python3 tools/test.py` passed **106/106** compilation/diagnostic checks after acceptance, with no pending PDF differences. Inspected both actual retained pages of `tests/symbolic-school.typ`, reviewed its assertions and intended equations, and accepted only that fixture's new PDF baseline, SHA-256 `e5a525e2ea58c3067b493bc4cc2cde467eda4922f6c7bb38466baf3e875c894e`. Existing fixture baselines stayed unchanged during these repairs. `git diff --check` passed. No agents, Git mutations, WordMat live execution or phase-two work were performed; independent Claude re-review remains required.

### Native Typst workflows

| Workflow | Runnable route | Limit |
| --- | --- | --- |
| Piecewise functions | `let f(x) = if x < 0 {-x} else {x}; school.roots(x => f(x) - 2, -3, 3)` | Numeric callbacks only; no symbolic piecewise solver. Caller must split discontinuous domains. |
| Finite sums | `range(1, 6).map(x => x*x).sum()` | No symbolic summation or infinite-series convergence engine. |
| Lists | `let xs = (1, 2, 3); xs.map(x => 2*x)` | Native Typst arrays; no WordMat list-command parser. |

The regression fixture executes these native workflows. Scale-aware numerical root validation rejects the tested jump and pole, but is not a continuity proof. The callback contract still requires a finite continuous real domain, and scanning does not guarantee completeness.

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

### Independent coverage decision

Claude Opus 5.5 passed phase one on 2026-10-30. The final focused review compiled all eight shifted/scaled square-root crash cases independently, confirmed diagnostics with no stored results, checked nearby singular expressions, and verified seven valid limits. Earlier rounds checked daily-school equation, calculus, statistics, geometry, graphing and numerical workflows. This is daily-school coverage approval under the documented limitations, not complete WordMat or CAS equivalence. The integration score remains pending.
