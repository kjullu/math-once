# WordMat → MathOnce school workflow inventory

Status: **phase one incomplete; independent Claude coverage gate pending**.
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

| HTX task | MathOnce evidence / example | Status and limits |
| --- | --- | --- |
| Arithmetic, substitutions, reusable definitions | `calculate`, builder assignments; `tests/calculate.typ`, `tests/functions.typ` | Existing; unit-aware. |
| Units, conversion, degrees, precision | `tests/qalc-units.typ`, `tests/trigonometry.typ`, significant-digit fixtures | Existing; school numeric helpers below do not carry units. |
| Simplify, factor, derivative, antiderivative, limits, Taylor | `tests/symbolic-cas.typ`; `diff(f,x)`, `integrate(2*x,x)` | Existing typCAS subset; operation names alone do not establish full algebraic coverage. |
| Solve polynomial equation | `solve(x^2-4,x)` in symbolic fixture | Existing tested root set; transcendental/trigonometric families, assumptions and inequalities remain unverified/gaps. |
| Numerical equation or intersection | `school.bisect(x => x*x - 2,0,2)` | Added; one continuous sign-changing bracket only. Tangent/even roots and all-root search remain gaps. |
| Simultaneous linear equations | `school.linear-solve(((0,2),(1,1)),(4,3))` → (1,2) | Added pivoted numeric square systems; symbolic and nonlinear systems missing. |
| Definite area/integral | Simpson cubic integral 0..2 → 4, reversed quadratic bounds tested | Added fixed-step finite numerical integral; improper integrals missing. |
| Numerical derivative | Cubic at 2 → 12 | Added central difference; no symbolic working output. |
| Differential equation with initial value | RK4 y′=y, y(0)=1 → y(1)≈e | Added scalar first order; symbolic, higher-order and coupled systems missing. |
| Data summary and quartiles | Mean/variance assertions, interpolated quartile 1.75 | Added numeric API; grouped/weighted data and textbook quartile modes missing. |
| Linear regression and prediction | y=2x+1; slope, prediction and R² checked | Added; inferential statistics and parameter confidence intervals missing. |
| Exponential/power/log regression | Predict 24, 27, 7 from known synthetic models | Added transformed least squares; polynomial, sinus and custom regression missing. |
| Combinations, binomial point/tail | C(5,2)=10; P(X=3)=.1171875, P(X≤3)=.171875 | Added; hypothesis tests and interval estimators missing. |
| Normal density, interval, inverse | CDF ±1.96 and 97.5% quantile checked | Added approximation; tails have limited precision. |
| t and chi-square distributions/tests | No public implementation | Gap; not excluded from school scope. |
| Vector arithmetic | `tests/vectors-matrices.typ` | Existing unit-aware addition/scaling. |
| Dot/cross, length, angle | Basis-vector cross and right angle checked; numeric `school` calls | Added; line/plane intersections and projection workflows remain gaps. |
| Matrix arithmetic | Matrix multiplication and vector products asserted in existing fixture | Existing. |
| Matrix inverse/system solve | Triangular inverse, row-pivoted solve checked | Added numerical arrays; standalone singular-safe determinant, rank and eigenvalues missing. |
| Triangle geometry | SSS 3–4–5 area and right angle checked | Added SSS only; SAS/ASA/SSA and ambiguous two-solution cases missing. |
| 2D plots, intersections visually | No MathOnce plot API | Gap; Typst drawing primitives alone do not count. |
| Histograms, box plots, scatter/residual plots | No MathOnce chart API | Gap. |
| Slope fields, parametric/3D plots | No implementation | Gap; 2D daily-use graphing has priority. |
| Complex arithmetic and polar form | No verified public workflow | Gap. |
| Lists, sums, products, piecewise | Typst arrays/map/sum and function `if` expressions | Available through Typst code, not builder expression syntax; school docs provide numeric callbacks. Symbolic sum/product remains unverified. |
| Formula collection and physical constants | Unit catalogue exists; no comparable formula browser | Gap for reusable school formula recipes; browser UI is excluded below. |

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

No complete-coverage claim and no phase-two integration score. Remaining school
mathematics gaps above must be implemented or explicitly agreed with the parent
and independent Claude reviewer before phase two. The module is a usable first
increment, not completion of the requested hill climb.

Validation details are recorded after the test run below. Numeric fixture tests
check answers rather than merely successful rendering; they do not establish
WordMat UI fidelity or full CAS equivalence.

### Validation result

- `python3 tools/test.py`: **102/102 compilation and expected-diagnostic checks
  passed**, with no pending PDF baseline changes on the final run (Typst 0.14.2).
- `tests/school.typ`: 40 known-answer numerical comparisons and three explicit
  assertions, including boundary binomial probabilities, transformed prediction,
  noisy-data R², reversed integration and row-pivoted equations.
- Three expected errors cover singular systems, an unbracketed root and invalid
  regression domains. Broader invalid-input coverage remains desirable.
- Reviewed the retained new school PDF from `build/pdf-review/review.md`, including
  rendered text, before accepting only `tests/school.typ`. Existing PDF baselines
  remained unchanged. The final run verified the accepted hash.
- Local-package staging now includes `school.typ`; the package import fixture
  passed. No live WordMat comparison or independent reviewer gate occurred.
- `git diff --check` passed. No commits, tags, or other Git mutations were made.
