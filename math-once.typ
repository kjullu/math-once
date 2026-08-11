// math-once: reusable calculations and a qalc-inspired unit evaluator.

/// Evaluate a trusted numerical expression, prepare a visible equation, and
/// return both the rounded and exact values.
///
/// - `source`: A trusted Typst code expression as a string or raw block.
/// - `digits`: Decimal places used for the visible `value`. Default: `0`.
/// - `scope`: Values made available to the expression. Earlier `calculate`
///   results are automatically unwrapped to their exact value.
/// - `unit`: Optional display label as a string, raw block, math, or content.
/// - `block`: Whether the rendered equation is centered. Default: `false`.
///
/// Returns a dictionary with `display`, `value`, `exact`, `source`, and `unit`.
/// Only pass expressions you trust: this function uses unrestricted `eval`.
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

// Everything in this dictionary is an implementation detail. Keeping the
// parser in one value leaves only the documented wrappers below as public API.
#let _engine = {

let zero-dim = (
  length: 0,
  mass: 0,
  time: 0,
  current: 0,
  temperature: 0,
  amount: 0,
  luminosity: 0,
)

let dim(..values) = {
  let result = zero-dim
  for (name, value) in values.named() {
    result.insert(name, value)
  }
  result
}

let units = (
  m:   (scale: 1.0, dims: dim(length: 1)),
  km:  (scale: 1000.0, dims: dim(length: 1)),
  cm:  (scale: 0.01, dims: dim(length: 1)),
  mm:  (scale: 0.001, dims: dim(length: 1)),
  s:   (scale: 1.0, dims: dim(time: 1)),
  min: (scale: 60.0, dims: dim(time: 1)),
  h:   (scale: 3600.0, dims: dim(time: 1)),
  t:   (scale: 3600.0, dims: dim(time: 1)), // Danish "timer".
  g:   (scale: 0.001, dims: dim(mass: 1)),
  kg:  (scale: 1.0, dims: dim(mass: 1)),
  L:   (scale: 0.001, dims: dim(length: 3)),
  mL:  (scale: 0.000001, dims: dim(length: 3)),
  Hz:  (scale: 1.0, dims: dim(time: -1)),
  N:   (scale: 1.0, dims: dim(length: 1, mass: 1, time: -2)),
  Pa:  (scale: 1.0, dims: dim(length: -1, mass: 1, time: -2)),
  J:   (scale: 1.0, dims: dim(length: 2, mass: 1, time: -2)),
  W:   (scale: 1.0, dims: dim(length: 2, mass: 1, time: -3)),
  A:   (scale: 1.0, dims: dim(current: 1)),
  K:   (scale: 1.0, dims: dim(temperature: 1)),
  mol: (scale: 1.0, dims: dim(amount: 1)),
  cd:  (scale: 1.0, dims: dim(luminosity: 1)),
  rad: (scale: 1.0, dims: dim()),
  sr:  (scale: 1.0, dims: dim()),
  deg: (scale: calc.pi / 180, dims: dim()),
  C:   (scale: 1.0, dims: dim(time: 1, current: 1)),
  V:   (scale: 1.0, dims: dim(length: 2, mass: 1, time: -3, current: -1)),
  F:   (scale: 1.0, dims: dim(length: -2, mass: -1, time: 4, current: 2)),
  ohm: (scale: 1.0, dims: dim(length: 2, mass: 1, time: -3, current: -2)),
  S:   (scale: 1.0, dims: dim(length: -2, mass: -1, time: 3, current: 2)),
  Wb:  (scale: 1.0, dims: dim(length: 2, mass: 1, time: -2, current: -1)),
  T:   (scale: 1.0, dims: dim(mass: 1, time: -2, current: -1)),
  H:   (scale: 1.0, dims: dim(length: 2, mass: 1, time: -2, current: -2)),
  lm:  (scale: 1.0, dims: dim(luminosity: 1)),
  lx:  (scale: 1.0, dims: dim(length: -2, luminosity: 1)),
  Bq:  (scale: 1.0, dims: dim(time: -1)),
  Gy:  (scale: 1.0, dims: dim(length: 2, time: -2)),
  Sv:  (scale: 1.0, dims: dim(length: 2, time: -2)),
  kat: (scale: 1.0, dims: dim(time: -1, amount: 1)),
  Wh:  (scale: 3600.0, dims: dim(length: 2, mass: 1, time: -2)),
  bar: (scale: 100000.0, dims: dim(length: -1, mass: 1, time: -2)),
  atm: (scale: 101325.0, dims: dim(length: -1, mass: 1, time: -2)),
  eV:  (scale: 1.602176634e-19, dims: dim(length: 2, mass: 1, time: -2)),
  cal: (scale: 4.184, dims: dim(length: 2, mass: 1, time: -2)),
  day: (scale: 86400.0, dims: dim(time: 1)),
  week: (scale: 604800.0, dims: dim(time: 1)),
  ton: (scale: 1000.0, dims: dim(mass: 1)),
  inch: (scale: 0.0254, dims: dim(length: 1)),
  ft: (scale: 0.3048, dims: dim(length: 1)),
  yd: (scale: 0.9144, dims: dim(length: 1)),
  mi: (scale: 1609.344, dims: dim(length: 1)),
  kn: (scale: 1852.0 / 3600, dims: dim(length: 1, time: -1)),
  mph: (scale: 1609.344 / 3600, dims: dim(length: 1, time: -1)),
)

// Symbol and spelling aliases that cannot all be written as dictionary keys.
units.insert("Ω", units.ohm)
units.insert("°", units.deg)
units.insert("l", units.L)
units.insert("sec", units.s)
units.insert("hr", units.h)

let prefixes = (
  ("da", 1e1),
  ("Y", 1e24), ("Z", 1e21), ("E", 1e18), ("P", 1e15),
  ("T", 1e12), ("G", 1e9), ("M", 1e6), ("k", 1e3), ("h", 1e2),
  ("d", 1e-1), ("c", 1e-2), ("m", 1e-3),
  ("µ", 1e-6), ("μ", 1e-6), ("u", 1e-6),
  ("n", 1e-9), ("p", 1e-12), ("f", 1e-15), ("a", 1e-18),
  ("z", 1e-21), ("y", 1e-24),
)

let prefixable = (
  "m", "g", "s", "A", "K", "mol", "cd", "rad", "sr", "Hz", "N",
  "Pa", "J", "W", "C", "V", "F", "ohm", "S", "Wb", "T", "H",
  "lm", "lx", "Bq", "Gy", "Sv", "kat", "L", "l", "Wh", "eV", "Ω",
)

let resolve-unit(name) = {
  if name in units { return units.at(name) }
  for (prefix, factor) in prefixes {
    if name.starts-with(prefix) {
      let base = name.slice(prefix.len())
      if base in prefixable {
        let unit = units.at(base)
        return (scale: factor * unit.scale, dims: unit.dims)
      }
    }
  }
  none
}

let quantity(si-value, dims: zero-dim, preferred: none) = (
  si-value: si-value,
  dims: dims,
  preferred: preferred,
)

let dims-add(a, b, factor: 1) = {
  let result = zero-dim
  for (name, value) in a {
    result.insert(name, value + factor * b.at(name))
  }
  result
}

let dims-scale(a, factor) = {
  let result = zero-dim
  for (name, value) in a {
    result.insert(name, value * factor)
  }
  result
}

let is-dimensionless(q) = q.dims == zero-dim

let dimensions-name(dims) = {
  let known = (
    (dim(length: 1), "length"),
    (dim(mass: 1), "mass"),
    (dim(time: 1), "time"),
    (dim(length: 1, time: -1), "speed"),
    (dim(length: 1, time: -2), "acceleration"),
    (dim(length: 2), "area"),
    (dim(length: 3), "volume"),
    (dim(length: 1, mass: 1, time: -2), "force"),
    (dim(length: -1, mass: 1, time: -2), "pressure"),
    (dim(length: 2, mass: 1, time: -2), "energy"),
    (dim(length: 2, mass: 1, time: -3), "power"),
  )
  for (candidate, name) in known {
    if dims == candidate { return name }
  }
  "incompatible dimensions"
}

let canonical-unit(dims) = {
  let known = (
    (dim(length: 1), "m"),
    (dim(mass: 1), "kg"),
    (dim(time: 1), "s"),
    (dim(length: 1, time: -1), "m/s"),
    (dim(length: 1, time: -2), "m/s^2"),
    (dim(length: 2), "m^2"),
    (dim(length: 3), "m^3"),
    (dim(length: 1, mass: 1, time: -2), "N"),
    (dim(length: -1, mass: 1, time: -2), "Pa"),
    (dim(length: 2, mass: 1, time: -2), "J"),
    (dim(length: 2, mass: 1, time: -3), "W"),
    (dim(current: 1), "A"),
    (dim(temperature: 1), "K"),
    (dim(amount: 1), "mol"),
    (dim(luminosity: 1), "cd"),
  )
  for (candidate, symbol) in known {
    if dims == candidate { return symbol }
  }

  let symbols = (
    length: "m",
    mass: "kg",
    time: "s",
    current: "A",
    temperature: "K",
    amount: "mol",
    luminosity: "cd",
  )
  let numerator = ()
  let denominator = ()
  for (name, exponent) in dims {
    if exponent != 0 {
      let symbol = symbols.at(name)
      let magnitude = calc.abs(exponent)
      let part = symbol + if magnitude == 1 { "" } else { "^" + str(magnitude) }
      if exponent > 0 { numerator.push(part) } else { denominator.push(part) }
    }
  }
  if numerator.len() == 0 { numerator.push("1") }
  numerator.join(" ") + if denominator.len() == 0 { "" } else { "/" + denominator.join(" ") }
}

let source-string(source) = if type(source) == str {
  source.trim()
} else if type(source) == content and source.func() == raw {
  source.text.trim()
} else {
  panic("math-once qalc: expression must be a string or raw text")
}

let tokenize(source) = {
  let pattern = regex("(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?|[A-Za-zµμΩ°]+|[=()+*/^+\\-]")
  let tokens = ()
  let cursor = 0
  for found in source.matches(pattern) {
    if source.slice(cursor, found.start).trim() != "" {
      panic("math-once qalc: unsupported syntax near `" + source.slice(cursor, found.start) + "`")
    }
    tokens.push(found.text)
    cursor = found.end
  }
  if source.slice(cursor).trim() != "" {
    panic("math-once qalc: unsupported syntax near `" + source.slice(cursor) + "`")
  }
  if tokens.len() == 0 { panic("math-once qalc: expression must not be empty") }
  tokens
}

let is-number(token) = regex("^(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?$") in token
let is-name(token) = regex("^[A-Za-zµμΩ°]+$") in token
let can-end(token) = is-number(token) or is-name(token) or token == ")"
let can-start(token) = is-number(token) or is-name(token) or token == "("

let add-implicit-multiplication(tokens) = {
  let result = ()
  for (index, token) in tokens.enumerate() {
    if index > 0 and can-end(tokens.at(index - 1)) and can-start(token) {
      result.push("*")
    }
    result.push(token)
  }
  result
}

let render-tokens(tokens) = {
  let source = tokens.map(token => {
    if is-name(token) {
      "\"" + token + "\""
    } else if token == "*" {
      "times"
    } else {
      token
    }
  }).join(" ")
  eval(source, mode: "math").body
}

let normalize-scope(scope) = {
  let normalized = (:)
  for (name, item) in scope {
    if type(item) == dictionary and "si-value" in item and "dimensions" in item {
      normalized.insert(name, quantity(item.si-value, dims: item.dimensions, preferred: item.unit))
    } else if type(item) in (int, float, decimal) {
      normalized.insert(name, quantity(float(item)))
    } else {
      panic("math-once qalc: scope `" + name + "` must be a number or qalc result")
    }
  }
  normalized
}

let apply-op(op, left, right) = {
  if op == "+" or op == "-" {
    if left.dims != right.dims {
      panic(
        "math-once qalc: cannot " + if op == "+" { "add " } else { "subtract " }
        + dimensions-name(left.dims) + " and " + dimensions-name(right.dims),
      )
    }
    return quantity(
      if op == "+" { left.si-value + right.si-value } else { left.si-value - right.si-value },
      dims: left.dims,
      preferred: if left.preferred != none { left.preferred } else { right.preferred },
    )
  }
  if op == "*" {
    return quantity(
      left.si-value * right.si-value,
      dims: dims-add(left.dims, right.dims),
      preferred: if is-dimensionless(left) { right.preferred } else if is-dimensionless(right) { left.preferred } else { none },
    )
  }
  if op == "/" {
    return quantity(
      left.si-value / right.si-value,
      dims: dims-add(left.dims, right.dims, factor: -1),
      preferred: if is-dimensionless(right) { left.preferred } else { none },
    )
  }
  if op == "^" {
    if not is-dimensionless(right) {
      panic("math-once qalc: exponent must be dimensionless")
    }
    let exponent = right.si-value
    if not is-dimensionless(left) and exponent != calc.round(exponent) {
      panic("math-once qalc: a unit may only be raised to an integer power")
    }
    return quantity(
      calc.pow(left.si-value, exponent),
      dims: dims-scale(left.dims, exponent),
    )
  }
  panic("math-once qalc: unsupported operator `" + op + "`")
}

let parse(tokens, scope: (:)) = {
  let scope = normalize-scope(scope)
  let precedence = ("+": 1, "-": 1, "*": 2, "/": 2, "^": 3)

  let parse-expression(tokens, position, minimum: 0) = {
    if position >= tokens.len() {
      panic("math-once qalc: expected a number, variable, unit, or parenthesis")
    }

    let token = tokens.at(position)
    let left = none
    if token == "+" or token == "-" {
      let (operand, next) = parse-expression(tokens, position + 1, minimum: 3)
      left = if token == "-" {
        quantity(-operand.si-value, dims: operand.dims, preferred: operand.preferred)
      } else {
        operand
      }
      position = next
    } else if token == "(" {
      let (inside, next) = parse-expression(tokens, position + 1)
      if next >= tokens.len() or tokens.at(next) != ")" {
        panic("math-once qalc: missing closing parenthesis")
      }
      left = inside
      position = next + 1
    } else if is-number(token) {
      left = quantity(float(token))
      position += 1
    } else if is-name(token) {
      let unit = resolve-unit(token)
      if unit != none {
        left = quantity(unit.scale, dims: unit.dims, preferred: token)
      } else if token in scope {
        left = scope.at(token)
      } else {
        panic("math-once qalc: unknown variable or unit `" + token + "`")
      }
      position += 1
    } else {
      panic("math-once qalc: unexpected token `" + token + "`")
    }

    while position < tokens.len() {
      let op = tokens.at(position)
      if op == ")" or op not in precedence { break }
      let op-precedence = precedence.at(op)
      if op-precedence < minimum { break }
      let next-minimum = if op == "^" { op-precedence } else { op-precedence + 1 }
      let (right, next) = parse-expression(tokens, position + 1, minimum: next-minimum)
      left = apply-op(op, left, right)
      position = next
    }
    (left, position)
  }

  let (result, position) = parse-expression(tokens, 0)
  if position != tokens.len() {
    panic("math-once qalc: unexpected token `" + tokens.at(position) + "`")
  }
  result
}

/// Evaluate a qalc-like expression containing numbers, units, variables, and
/// the operators `+`, `-`, `*`, `/`, and `^`.
///
/// Use `to`, `=`, or the `unit` argument to request an output unit.
let qalc(source, digits: 4, scope: (:), unit: none, block: true) = {
  let source = source-string(source)
  let raw-tokens = tokenize(source)
  let depth = 0
  let conversion-index = none
  for (index, token) in raw-tokens.enumerate() {
    if token == "(" { depth += 1 }
    if token == ")" { depth -= 1 }
    if token in ("to", "=") and depth == 0 {
      if conversion-index != none { panic("math-once qalc: only one output-unit separator is allowed") }
      conversion-index = index
    }
  }
  if depth != 0 { panic("math-once qalc: unbalanced parentheses") }

  if conversion-index != none and unit != none {
    panic("math-once qalc: use only one of `to`, `=`, or `unit`")
  }

  let expression-tokens = if conversion-index == none { raw-tokens } else { raw-tokens.slice(0, conversion-index) }
  let target-tokens = if conversion-index != none {
    raw-tokens.slice(conversion-index + 1)
  } else if unit != none {
    tokenize(source-string(unit))
  } else {
    none
  }
  if expression-tokens.len() == 0 { panic("math-once qalc: missing expression before output conversion") }
  if target-tokens != none and target-tokens.len() == 0 { panic("math-once qalc: missing output unit") }

  let result = parse(add-implicit-multiplication(expression-tokens), scope: scope)
  let output-unit = result.preferred
  let output-scale = 1.0
  if target-tokens != none {
    let target = parse(add-implicit-multiplication(target-tokens))
    if target.dims != result.dims {
      panic("math-once qalc: cannot convert " + dimensions-name(result.dims) + " to " + dimensions-name(target.dims))
    }
    output-unit = target-tokens.join("")
    output-scale = target.si-value
  } else if output-unit == none and not is-dimensionless(result) {
    output-unit = canonical-unit(result.dims)
  } else if output-unit != none {
    let preferred = parse(add-implicit-multiplication(tokenize(output-unit)))
    output-scale = preferred.si-value
  }

  let exact = result.si-value / output-scale
  let value = calc.round(exact, digits: digits)
  let display-body = render-tokens(expression-tokens) + h(0.25em) + math.eq + h(0.25em) + str(value)
  if output-unit != none {
    let output-tokens = if target-tokens != none { target-tokens } else { tokenize(output-unit) }
    display-body += h(0.2em) + render-tokens(output-tokens)
  }

  (
    value: value,
    exact: exact,
    si-value: result.si-value,
    dimensions: result.dims,
    unit: output-unit,
    source: source,
    display: math.equation(display-body, block: block),
  )
}

/// Create a stateful equation runner similar to eqrun.
///
/// Named expressions such as `v = 10 m/s` are stored and automatically made
/// available to later calls. Call the runner without an expression inside a
/// context block to retrieve its dictionary of results.
let qalc-builder(
  initial-state: (:),
  key: "math-once-qalc",
  digits: 4,
  block: true,
) = {
  let variables = state(key, initial-state)

  (..args, digits: digits, unit: none, block: block) => {
    if args.pos().len() > 1 {
      panic("math-once qalc: the runner accepts at most one expression")
    }
    let source = args.pos().at(0, default: none)
    if source == none {
      return variables.get()
    }

    let source = source-string(source)
    let assignment = source.match(regex("^\\s*([A-Za-z]+)\\s*=\\s*(.+)$"))
    let name = if assignment == none { none } else { assignment.captures.at(0) }
    let expression = if assignment == none { source } else { assignment.captures.at(1) }

    context {
      let current = variables.get()
      let result = qalc(expression, digits: digits, scope: current, unit: unit, block: block)

      if name != none {
        let labelled-body = render-tokens((name,)) + h(0.25em) + math.eq + h(0.25em) + result.display.body
        result.insert("display", math.equation(labelled-body, block: block))
        result.insert("variable", name)
        variables.update(old => {
          old.insert(name, result)
          old
        })
      }

      result.display
    }
  }
}

(
  qalc: qalc,
  qalc-builder: qalc-builder,
)
}

/// Evaluate a dimensional, qalc-style expression.
///
/// - `source`: A trusted string or raw block containing numbers, units,
///   variables, parentheses, `+`, `-`, `*`, `/`, `^`, and optionally `to` or
///   `=` for output conversion.
/// - `digits`: Decimal places used for the visible `value`. Default: `4`.
/// - `scope`: Numbers or earlier qalc results available as variables.
/// - `unit`: Optional requested output unit as a string or raw block. This is
///   an alternative to `to` or `=` in `source`.
/// - `block`: Whether the rendered equation is centered. Default: `true`.
///
/// Returns a dictionary with `display`, `value`, `exact`, `si-value`,
/// `dimensions`, `unit`, and `source`.
#let qalc(source, digits: 4, scope: (:), unit: none, block: true) = (_engine.qalc)(
  source,
  digits: digits,
  scope: scope,
  unit: unit,
  block: block,
)

/// Create an eqrun-style stateful calculator.
///
/// - `initial-state`: Initial numeric values or qalc results. Default: empty.
/// - `key`: Typst state key. Give independent runners different keys.
/// - `digits`: Default decimal places for runner calls. Default: `4`.
/// - `block`: Whether runner equations are centered. Default: `true`.
///
/// The returned runner accepts zero or one expression plus the named
/// `digits`, `unit`, and `block` overrides. An assignment like
/// `v = 10 m/s` stores `v`; calling the runner without an expression returns
/// its result dictionary and must happen in a `context` block.
#let qalc-builder(
  initial-state: (:),
  key: "math-once-qalc",
  digits: 4,
  block: true,
) = (_engine.qalc-builder)(
  initial-state: initial-state,
  key: key,
  digits: digits,
  block: block,
)
