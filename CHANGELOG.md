# Changelog

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
