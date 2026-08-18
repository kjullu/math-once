# Changelog

## 0.31.0

- Made `calculation-builder` use `block: auto` by default, following Typst's
  own math layout: `$1 + 1$` stays inline, while `$ 1 + 1 $` and multiline
  math input become centered block equations.
- Kept raw and string builder input centered by default because those forms do
  not contain Typst equation-layout metadata.
- Preserved explicit `block: true` and `block: false` overrides at both builder
  and individual-call level.

## 0.30.0

- Evaluated numeric `plus.minus` (`±`) and `minus.plus` (`∓`) expressions as
  two correlated branches, displayed with the logical-or symbol `∨` between
  their results.
- Added paired-result dictionaries with `branches`, `values`, `exacts`,
  `si-values`, and `units`, including unit-aware calculations and conversions.
- Kept `:=` restricted to one scalar value; paired results can be calculated
  directly or labelled with plain `=` but cannot be stored as one variable.

## 0.29.0

- Added general pass-through support for Typst's mathematical symbols in
  builder equations, including named, Unicode, and `$...$` input forms.
- Kept ordinary arithmetic symbols evaluatable while treating relations, set
  operators, calculus marks, logic signs, geometry signs, and other
  non-scalar symbols as display-only instead of reporting parser errors.
- Added a generated catalog pinned to Typst 0.14.2's codex 0.2.0 symbol data
  and exhaustive coverage of its 312 warning-free concrete mathematical
  symbol paths. The generator verifies catalog counts and variation selectors.
- Rejected attempts to store a display-only symbol expression with `:=`, since
  it does not represent one numeric result.

## 0.28.0

- Added display support for Typst's paired `plus.minus` (`±`) and `minus.plus`
  (`∓`) signs in math, raw, and string input, with focused errors when a
  two-result expression is used as one numeric or stored value.
- Clarified why unquoted `$...$` math content cannot contain CAS operations
  and documented raw, string, and quoted-math input alternatives, including
  guidance directly beside the copyable README and symbolic-guide examples.

## 0.27.1

- Added a dedicated symbolic-calculations guide covering CAS syntax, storage,
  result reuse, roots, units, input forms, and direct typCAS API access.
- Added typCAS to the README acknowledgements.

## 0.27.0

- Added symbolic algebra to `calculation-builder` through the pinned
  MIT-licensed `@preview/typcas:0.2.3` dependency. Top-level `simplify`,
  `diff`, `integrate`, `solve`, `factor`, `limit`, and `taylor` calls can now
  be displayed and stored with the existing `:=` syntax.
- Stored reusable symbolic expression trees in the same builder state as
  numeric variables, so later CAS calls can consume earlier results. Existing
  stored dimensionless numbers are substituted into symbolic input.
- Kept CAS expressions dimensionless and separate from the unit-aware
  evaluator. Unit-bearing inputs, `unit:`, `size:`, and attempts to use a
  solution set as one scalar expression now produce focused inline errors.
- Documented typCAS attribution, its separate API, and the shape of stored
  symbolic results in `THIRD-PARTY.md` and the builder reference.

## 0.26.0

- Changed `reset` into an unambiguous complete-state operation with only the
  optional named `key:` parameter. Older selective calls must use
  `reset-variables`, `reset-functions`, `restore-units`, or
  `reset-unit-aliases` according to the state being changed.
- Removed the Danish `timer` alias for hours from the built-in unit catalog.
  The catalog now keeps English unit names; translated builder spellings can
  be introduced explicitly with `rename-unit`, such as renaming `h` to
  `timer`.

## 0.25.0

- Added `reset-variables` for clearing selected or all stored values while
  preserving functions, unloaded unit names, and unit aliases. Values supplied
  through `initial-state` are restored to their configured defaults.
- Added `reset-functions` for independently clearing stored scalar and vector
  function definitions.
- Added `restore-units` for undoing selected or all `unload` settings without
  resetting unrelated builder state.
- Added `reset-unit-aliases` for undoing selected or all `rename-unit`
  relationships without resetting unrelated values or functions.
- Kept `reset()` as the backward-compatible complete reset and documented the
  focused alternatives directly at the top of its reference page.

## 0.24.1

- Allowed `rename-unit` to use an explicitly unloaded catalog spelling as its
  destination, enabling workflows such as unloading tonne `t` and renaming
  hour `h` to `t`.

## 0.24.0

- Made simple `name = expression` builder equations calculate and display
  substituted values and their result without storing `name`.
- Kept `name := expression` as the explicit storing form and kept non-simple
  equations or equations with unknown symbolic names display-only.

## 0.23.1

- Fixed scientific `size:` rendering without an explicit `unit:`, so
  `size: $10^22$` displays `3.5439 · 10^22 N` instead of
  `3.5439 (10000000000000000000000) N`.
- Preserved compound scientific scale notation such as `size: $2 * 10^3$`
  and `size: $3 * 10^(-4)$` while continuing to evaluate the numerical scale.

## 0.23.0

- Displayed very large and very small calculation values in compact scientific
  notation, including stored-variable substitutions. Exact stored values and
  calculation precision remain unchanged.
- Kept long substituted calculation chains within ordinary page widths by
  avoiding expanded decimal forms such as `1989000000000000200000000000000`.
- Fixed the Qalculate audit generator so `t` remains the metric-tonne alias,
  `timer` remains the hour alias, and generated unit tests cover `t`.

## 0.22.0

- Added `sqrt(x)` and indexed `root(n, x)` calculations to `calculate` and
  `calculation-builder`, including native Typst radical rendering.
- Added dimension-aware roots for compatible units and red inline errors for
  invalid indices, non-real even roots, and indivisible unit dimensions.

## 0.21.0

- Changed `t` from the Danish hour abbreviation to the Qalculate-compatible
  metric tonne (`1000 kg`). `timer` remains available for hours.
- Changed common `rename-unit` configuration failures into centered red
  document messages. A failed rename leaves the builder state unchanged.

## 0.20.0

- Added `rename-unit(from, to)` for moving an active catalog unit spelling to
  a custom alias within one calculation-builder state.
- Renamed units retain their dimensions and conversion factor; the original
  spelling becomes available as a variable until reset.
- Added chained renames, collision checks, custom builder keys, and selective
  reset of a complete rename relationship.

## 0.19.0

- Added stored scalar functions to `calculation-builder`, using definitions
  such as `f(x) := x + 1` and later calls such as `f(2)`.
- Added multiple function parameters, unit-aware component calculations, arrow
  function names, and vector functions written with `vec(...)`.
- Kept ordinary `f(x) = ...` equations display-only, consistent with scalar
  variable assignment semantics.
- Added friendly inline errors for incorrect function argument counts.

## 0.18.4

- Fixed the multiplication dot between the coefficient and power of ten in
  scientific `size:` output.

## 0.18.3

- Rendered power-of-ten `size:` values as scientific notation. For example,
  `size: $10^5$` now displays `4.88 · 10^5 linjer/m` instead of
  `4.88 (100000) linjer/m`.

## 0.18.2

- Allowed an explicit `unit:` to override opaque custom units in the input.
  Their labels are ignored for that calculation, normal arithmetic continues,
  and the result is assigned the requested physical unit.

## 0.18.1

- Changed `equation-outline` entries to use equation references and Typst's
  standard outline page rendering instead of custom explicit links. This
  matches normal outline styling and also works without page numbering.

## 0.18.0

- Added opaque user-defined units for unknown quoted names such as
  `1 "micrometer"`. Normal arithmetic works with matching custom units, but
  they cannot be mixed with different custom units or converted to catalog
  units.
- Known quoted names such as `"cm"` retain their physical conversion rules.

## 0.17.1

- Added `show-result: false` to `calculation-builder` calls. A `:=`
  definition still stores its exact calculated value, but only the written
  definition is displayed.

## 0.17.0

- Added `text-unit("label")` for explicit symbolic output-unit labels. Quoted
  known names such as `"cm"` retain their physical meaning, while
  `text-unit("cm")` is literal text with no conversion factor or dimension.

## 0.16.1

- Restored visible substitution and final results for calculated `:=`
  definitions while still avoiding redundant output for direct values such as
  `v := 10 m/s`.

## 0.16.0

- Allowed `unit:` and `size:` to be used together. `unit:` chooses the output
  unit and `size:` scales it, so `unit: $m$, size: 0.01` displays centimetres.
- Familiar scaled length units use their normal SI symbols; other scaled units
  display the scale explicitly.
- Kept `size:` incompatible with inline `to` and output-`=` conversions; use
  the named `unit:` parameter when both controls are needed.
- Rejected additional scaling of affine output units such as Celsius.

## 0.15.0

- Changed `calculation-builder` to render common calculation failures as
  centered red messages instead of stopping Typst compilation.
- Added friendly feedback for incompatible dimensions and conversions,
  division by zero, invalid trigonometric arguments and unit powers, common
  `size` mistakes, output-unit conflicts, and malformed parentheses.
- Failed definitions are not stored, so later use produces the existing
  `is not set` feedback.
- Improved inverse-dimension names so errors can distinguish inverse time from
  inverse length.
- Kept direct `calculate` calls strict: they continue to panic on invalid input
  for programmatic error detection.

## 0.14.0

- Added quoted symbolic count labels in output-unit expressions. For example,
  `unit: $"linjer"/m$` displays an inverse length as lines per metre while
  retaining dimensional validation of `m`.
- Quoted names that already exist in the unit catalog, such as `"cm"`, keep
  their normal physical meaning.

## 0.13.0

- Changed calculation-builder storage to the explicit `name := expression`
  syntax. The definition is rendered with an ordinary equals sign.
- Plain `name = expression` calls are now display-only and do not update
  builder state.
- Expressions containing unset variables now render a red `is not set`
  message instead of stopping Typst compilation.
- Non-assignment expressions now visibly substitute stored values before the
  final calculated result.

## 0.12.0

- Added `unload` for temporarily allowing known unit names to be assigned and
  reused as calculation-builder variables.
- `reset(name)` restores that individual unit, while `reset()` restores every
  unloaded unit together with clearing the builder state.

## 0.11.0

- Added `reset()` for clearing all variables stored by the default
  `calculation-builder` state.
- Added selective reset through string, raw, or math names, such as
  `reset("height", "width")`, plus `key:` for custom builders.

## 0.10.0

- Expanded the static unit catalog to 244 of Qalculate 5.10's 246 named unit
  groups, including aliases, affine temperature scales, information units,
  astronomical and Planck units, CGS, Imperial/US, photometric, typographic,
  historical, and scientific units.
- Added the 2022 SI prefixes (`Q`, `R`, `r`, `q`) and binary prefixes from
  `Ki` through `Qi` for bits and bytes.
- Added a generated smoke test for every accepted qalc spelling and a local
  audit helper. `dBW` and `dBm` remain excluded because their conversion is
  logarithmic rather than linear or affine.

## 0.9.0

- Added `size` to `calculate` and calculation-builder calls. It accepts a
  positive number or wrapped expression such as `$10^(-6)$` and displays the
  result in that SI scale while preserving its exact SI value.
- Familiar length scales use their normal unit symbol, so `size: $10^(-6)$`
  displays metres as micrometres (`µm`).

## 0.8.0

- Unit names are now reserved and cannot be assigned as builder variables or
  supplied as `calculate` scope variables. This prevents a variable such as
  `m` from silently changing the metre unit into a dimensionless value.
- Builder assignments such as `m = 1` now print a red message in the document
  without storing the variable. Use another name such as `n` instead.

## 0.7.0

- Added explicit common metric length units: `dm`, `µm`/`μm`/`um`, `nm`, and
  `pm`.
- Added newton-metre units `Nm`, `Ncm`, and `Nmm`; SI prefixes also produce
  forms such as `kNm`.
- Documented and tested case-sensitive unit symbols: `nm` is nanometres, `Nm`
  is newton metres, and `mN` is millinewtons.

## 0.6.0

- Added `sin`, `cos`, and `tan`; bare numeric angles use degrees, while explicit
  degree and radian units remain supported.
- Stored variables now take precedence over colliding unit symbols, allowing
  conventional variables such as `m`; `meter` and `metre` disambiguate the unit.
- Microscopic SI length results automatically choose a readable engineering
  prefix, such as converting `2047.762752 nm` to `2.047762752 µm`.
- Typst math operators and parenthesized expressions are parsed without adding
  duplicate parentheses.

## 0.5.0

- Variable names can contain letter or number subscripts, so equations such as
  `theta_m = 15` retain the mathematical form `θ_m` and use the state key
  `theta_m`.
- Added `degree` as an input alias for `°` in raw and string expressions.
- Angle units are preserved through multiplication and division by plain
  scalars, so `theta_m * 2` remains expressed in degrees.

## 0.4.0

- Greek mathematical variable names such as `lambda`, `theta`, and `omega`
  now work in builder equations, retain their symbols, and use readable state
  keys such as `variables.lambda`.
- Implicit multiplication around expanded variables is now shown explicitly,
  for example `2 lambda = 2 ⋅ 530 m = 1060 m`.

## 0.3.1

- Direct assignments no longer repeat an identical value and unit. For
  example, `v = 10 m/s = 10 m/s` is now displayed as `v = 10 m/s`.
- Variable aliases also omit a duplicate final step, while arithmetic,
  conversions, and rounded results remain visible.

## 0.3.0

- Captioned, labelled equations now display their reference prefix before the
  caption, for example `Ligning 1: Mass-energy equivalence`.
- `equation` and `calculation-builder` now accept `supplement` overrides, so
  individual equation families can use names such as `Equation` or `Formula`.
- Added `equation-outline`, which creates a linked list of labelled, captioned
  equations with dot leaders and page numbers.

## 0.2.2

- Added the figure-like `equation(body, caption: ...)` wrapper for captions
  placed directly beside native equations in the source.
- Added per-call `caption:` and `gap:` parameters to `calculation-builder`
  runners.
- Captioned equations remain native `math.equation` elements, so postfix
  labels, selective numbering, and references keep using one equation counter.

## 0.2.1

- Labels written after `calculation-builder` output now attach directly to the
  generated equation: `#eq(...) <label>`.
- `number-labelled-equations` can add captions to labelled native and
  calculated equations through its `captions` dictionary.
- Labelled equations receive numbers; unlabelled equations remain unnumbered
  and do not advance the equation counter.

## 0.2.0

Breaking API rename:

| 0.1.x | 0.2.0 |
| --- | --- |
| `qalc` | `calculate` |
| `qalc-builder` | `calculation-builder` |
| `calculate` | `evaluate-code` |

The names now describe the functions without referring to another calculator
project. `calculate` is the unit-aware default; `evaluate-code` is the
unrestricted evaluator for trusted Typst expressions.

## 0.1.0

Initial release.
