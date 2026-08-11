/// Evaluate a trusted numerical expression, prepare a visible equation, and
/// return both the rounded and exact values.
///
/// `source` must be either a string or raw text, for example `902 / 3.6`.
/// Names used by the expression can be supplied through `scope`.
///
/// The returned dictionary contains:
/// - `value`: the rounded value shown in the equation
/// - `exact`: the unrounded value
/// - `display`: the rendered `expression = result` equation
/// - `source`: the expression as a string
///
/// Only pass expressions you trust: this function evaluates Typst code.
#let calculate(source, digits: 0, scope: (:), unit: none, block: false) = {
  let source = if type(source) == str {
    source
  } else if type(source) == content and source.func() == raw {
    source.text
  } else {
    panic("math-once: source must be a string or raw text")
  }

  source = source.trim()
  if source == "" {
    panic("math-once: source must not be empty")
  }

  // A previous math-once result can be passed directly in the scope. Its
  // unrounded value is used to avoid accumulating rounding errors.
  let evaluation-scope = (:)
  for (name, item) in scope {
    let item = if type(item) == dictionary and "exact" in item {
      item.exact
    } else {
      item
    }
    evaluation-scope.insert(name, item)
  }

  let exact = eval(source, mode: "code", scope: evaluation-scope)
  if type(exact) not in (int, float, decimal) {
    panic("math-once: expression must evaluate to an int, float, or decimal")
  }

  let value = calc.round(exact, digits: digits)
  let rendered = eval(
    source + " = #result",
    mode: "math",
    scope: (result: value),
  )

  let unit-body = if unit == none {
    none
  } else if type(unit) == str {
    text(unit)
  } else if type(unit) == content and unit.func() == raw {
    text(unit.text)
  } else if type(unit) == content and unit.func() == math.equation {
    unit.body
  } else if type(unit) == content {
    unit
  } else {
    panic("math-once: unit must be a string, raw text, math, content, or none")
  }

  let display-body = rendered.body
  if unit-body != none {
    display-body += h(0.2em) + math.upright(unit-body)
  }

  (
    value: value,
    exact: exact,
    display: math.equation(display-body, block: block),
    source: source,
    unit: unit,
  )
}

#import "qalc.typ" as qalc-module

/// Evaluate an expression with physical units and automatic conversion.
/// See `qalc.typ` for the full API documentation.
#let qalc = qalc-module.qalc
