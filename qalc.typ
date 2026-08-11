// A compact, qalc-inspired quantity evaluator for Typst.

#let zero-dim = (
  length: 0,
  mass: 0,
  time: 0,
  current: 0,
  temperature: 0,
  amount: 0,
  luminosity: 0,
)

#let dim(..values) = {
  let result = zero-dim
  for (name, value) in values.named() {
    result.insert(name, value)
  }
  result
}

#let units = (
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
)

#let quantity(si-value, dims: zero-dim, preferred: none) = (
  si-value: si-value,
  dims: dims,
  preferred: preferred,
)

#let dims-add(a, b, factor: 1) = {
  let result = zero-dim
  for (name, value) in a {
    result.insert(name, value + factor * b.at(name))
  }
  result
}

#let dims-scale(a, factor) = {
  let result = zero-dim
  for (name, value) in a {
    result.insert(name, value * factor)
  }
  result
}

#let is-dimensionless(q) = q.dims == zero-dim

#let dimensions-name(dims) = {
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

#let canonical-unit(dims) = {
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

#let source-string(source) = if type(source) == str {
  source.trim()
} else if type(source) == content and source.func() == raw {
  source.text.trim()
} else {
  panic("math-once qalc: expression must be a string or raw text")
}

#let tokenize(source) = {
  let pattern = regex("(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?|[A-Za-z]+|[()+*/^+\\-]")
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

#let is-number(token) = regex("^(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?$") in token
#let is-name(token) = regex("^[A-Za-z]+$") in token
#let can-end(token) = is-number(token) or is-name(token) or token == ")"
#let can-start(token) = is-number(token) or is-name(token) or token == "("

#let add-implicit-multiplication(tokens) = {
  let result = ()
  for (index, token) in tokens.enumerate() {
    if index > 0 and can-end(tokens.at(index - 1)) and can-start(token) {
      result.push("*")
    }
    result.push(token)
  }
  result
}

#let render-tokens(tokens) = {
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

#let normalize-scope(scope) = {
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

#let apply-op(op, left, right) = {
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

#let parse(tokens, scope: (:)) = {
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
      if token in units {
        let unit = units.at(token)
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
/// Use `to` to request an output unit, for example `10 m/s to km/t`.
#let qalc(source, digits: 4, scope: (:), block: false) = {
  let source = source-string(source)
  let raw-tokens = tokenize(source)
  let depth = 0
  let conversion-index = none
  for (index, token) in raw-tokens.enumerate() {
    if token == "(" { depth += 1 }
    if token == ")" { depth -= 1 }
    if token == "to" and depth == 0 {
      if conversion-index != none { panic("math-once qalc: only one `to` conversion is allowed") }
      conversion-index = index
    }
  }
  if depth != 0 { panic("math-once qalc: unbalanced parentheses") }

  let expression-tokens = if conversion-index == none { raw-tokens } else { raw-tokens.slice(0, conversion-index) }
  let target-tokens = if conversion-index == none { none } else { raw-tokens.slice(conversion-index + 1) }
  if expression-tokens.len() == 0 { panic("math-once qalc: missing expression before `to`") }
  if target-tokens != none and target-tokens.len() == 0 { panic("math-once qalc: missing unit after `to`") }

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
