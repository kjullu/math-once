# Changelog

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
