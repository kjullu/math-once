# Changelog

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
