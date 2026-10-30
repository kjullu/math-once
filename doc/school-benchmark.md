# Bridge workflow benchmark

Measured locally with Typst 0.14.2 on 2026-10-30. Each timing includes a fresh compiler process and PDF output.

| Composite workflow | Elapsed |
| --- | ---: |
| Builder definitions and symbolic derivative → bridge → derivative check, roots, integral and two curves | 2.219 s |
| Native callbacks → same derivative check, roots, integral and two curves | 0.489 s |

The executable fixture is [school-benchmark.typ](../tests/school-benchmark.typ). It uses `x*exp(-x/2)*sin(x)+ln(x^2+1)` on [-2,2], including its derivative, with public default sampling counts. The native comparison supplied the analytic derivative directly. These single-run measurements describe this machine, not a portable performance guarantee. The bridge costs about 4.5 times the native workflow here. This is still measurable overhead; it is not native-speed evaluation.

Callbacks capture and parse the builder scope once. Later state updates and resets do not mutate an already created callback. For quick edits use smaller explicit plot/root `steps` and integral `steps`, then restore defaults for the final calculation. Fewer root samples can miss roots; Simpson steps must be even. For repeated dense plots, a native numeric callback avoids the CAS interpreter cost.
