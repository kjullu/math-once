#import "../math-once.typ": calculation-builder, reset-variables
#import "@preview/typcas:0.2.3": cas

#let eq = calculation-builder(key: "symbolic-cas")

// CAS results keep their expression tree and can feed later operations.
#eq(`f := simplify(x^2 + 2*x + 1)`)
#eq(`df := diff(f, x)`)
#context {
  let stored = eq()
  assert(stored.f.symbolic)
  assert(stored.f.symbolic-kind == "expression")
  assert(stored.df.operation == "diff")
  let evaluated = cas.eval(stored.df.expression, bindings: (x: 2))
  assert(cas.ok(evaluated))
  assert(cas.value-of(evaluated) == 6)
}

// Symbolic names may overlap catalog units. Here `a` is also the are unit,
// but a top-level CAS assignment keeps it in the symbolic context.
#eq(`a:=diff(x^2,x)`)
#eq(`a_second := diff(a, x)`)
#context {
  assert(eq().a.symbolic-kind == "expression")
  assert(not eq().a.at("unloaded", default: false))
  assert(eq().a_second.symbolic-kind == "expression")
  let evaluated = cas.eval(eq().a_second.expression)
  assert(cas.ok(evaluated))
  assert(cas.value-of(evaluated) == 2)
}

// Typst math input uses quoted multi-letter CAS operation names.
#eq($"identity" := "simplify"(sin(x)^2 + cos(x)^2)$)
#context assert(eq().identity.symbolic)

// Ordinary strings use the same syntax as raw input.
#eq("string_identity := simplify(sin(x)^2 + cos(x)^2)")
#context assert(eq().string_identity.symbolic)

// Existing dimensionless builder values are substituted into CAS input.
#eq(`coefficient := 3`)
#eq(`scaled := simplify(coefficient*x + coefficient*x)`)
#context {
  let evaluated = cas.eval(eq().scaled.expression, bindings: (x: 2))
  assert(cas.value-of(evaluated) == 12)
}

// The remaining public operations use the same stored-result contract.
#eq(`factored := factor(x^2 - 1, x)`)
#eq(`approach := limit(sin(x) / x, x, 0)`)
#eq(`series := taylor(sin(x), x, 0, 3)`)
#let limits = calculation-builder(key: "symbolic-cas-limits", strict: true)
#limits(`limit_ten := limit(1/x, x, 10)`)
#limits(`limit_zero := limit(1/x, x, 0)`)
#limits(`limit_infinity := limit(1/x, x, infinity)`)
#limits(`limit_oo := limit(1/x, x, oo)`)
#context {
  assert(eq().factored.operation == "factor")
  assert(eq().approach.operation == "limit")
  assert(eq().series.operation == "taylor")
  assert(cas.value-of(cas.eval(limits().limit_ten.expression)) == 0.1)
  assert(cas.value-of(cas.eval(limits().limit_infinity.expression)) == 0)
  assert(cas.value-of(cas.eval(limits().limit_oo.expression)) == 0)
}

// Solve stores a root set rather than pretending that it is one expression.
#eq(`roots := solve(x^2 - 4, x)`)
#eq(`shifted_roots := solve(x + 1, 3, x)`)
#eq(`fixed_points := solve(x = x^2)`)
#eq(`y_fixed_points := solve(y = y^2, y)`)
#context {
  assert(eq().roots.symbolic-kind == "roots")
  assert(eq().roots.roots.len() == 2)
  assert(eq().shifted_roots.roots.len() == 1)
  assert(eq().fixed_points.roots.len() == 2)
  assert(eq().y_fixed_points.roots.len() == 2)
  assert(eq().fixed_points.solution-variable == "x")
  assert(eq().y_fixed_points.solution-variable == "y")
  assert(eq().fixed_points.roots.any(root => cas.value-of(cas.eval(root)) == 0))
  assert(eq().fixed_points.roots.any(root => cas.value-of(cas.eval(root)) == 1))
}

// Quoted Typst math calls can contain the equation directly too.
#eq($ "solve"(x = x^2) $)

#eq(`not_scalar := simplify(roots + 1)`)
#context assert("not_scalar" not in eq())

// Physical quantities stay in the unit-aware evaluator.
#eq(`distance := 2 m`)
#eq(`not_dimensionless := simplify(distance*x)`)
#eq(`not_sized := simplify(x + 1)`, size: $10^3$)
#context assert("not_dimensionless" not in eq() and "not_sized" not in eq())

// A calculated assignment is displayed but not stored.
#eq(`temporary = factor(x^2 - 1, x)`)
#context assert("temporary" not in eq())

// Quiet definitions still store the reusable result.
#eq(`quiet := integrate(2*x, x)`, show-result: false)
#context assert("quiet" in eq())

// Symbolic values are ordinary stored variables for focused resets.
#reset-variables("quiet", key: "symbolic-cas")
#context assert("quiet" not in eq() and "f" in eq())

// A user-defined function with the same name takes precedence in its builder.
#let custom = calculation-builder(key: "symbolic-cas-function-precedence")
#custom(`factor(t) := t * 2`)
#custom(`value := factor(3)`)
#context assert(custom().value.value == 6.0)
