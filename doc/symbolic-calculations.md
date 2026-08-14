# Symbolic calculations

`calculation-builder` can simplify, differentiate, integrate, solve, factor,
take limits, and create Taylor polynomials. These operations use
`@preview/typcas:0.2.3` internally and store reusable symbolic expression trees
alongside ordinary builder variables.

The CAS runs locally as Typst code. Typst downloads and caches the pinned
package dependency through its normal package system; there is no web service
or separate program to install.

## First calculation

Create the same builder used for unit-aware calculations:

```typ
#import "math-once.typ": calculation-builder

#let eq = calculation-builder(key: "symbolic-example")

// Use raw backticks for CAS input. Plain $...$ only works when
// multi-letter names are quoted.
#eq(`f := simplify(x^2 + 2*x + 1)`)
#eq(`df := diff(f, x)`)
```

This displays equations equivalent to:

```text
f  = simplify(x² + 2x + 1) = x² + 2x + 1
df = diff(f, x)             = 2x + 2
```

`f` stores a symbolic expression tree. When `diff(f, x)` is evaluated, the
builder passes that stored tree directly to typCAS. It does not copy the
rendered equation back into a string.

## Storing and displaying

Symbolic calls follow the normal builder assignment rules:

| Form | Behaviour |
| --- | --- |
| `f := simplify(...)` | Calculates, displays, and stores `f`. |
| `f = simplify(...)` | Calculates and displays without storing `f`. |
| `simplify(...)` | Calculates and displays without creating a name. |

`show-result: false` hides the calculated result but still stores it:

```typ
#eq(`antiderivative := integrate(2*x, x)`, show-result: false)
#eq(`slope := diff(antiderivative, x)`)
```

Symbolic results count as stored variables. They are removed by
`reset-variables`, and a complete `reset` also removes them.

## Supported operations

CAS operations must be the top-level operation on the right-hand side.

| Operation | Meaning |
| --- | --- |
| `simplify(expression)` | Simplify an expression. |
| `diff(expression, variable)` | Differentiate with respect to `variable`. |
| `integrate(expression, variable)` | Find an indefinite integral. |
| `solve(expression, variable)` | Solve `expression = 0`. |
| `solve(left, right, variable)` | Solve `left = right`. |
| `factor(expression)` | Factor with respect to `x`. |
| `factor(expression, variable)` | Factor with respect to the chosen variable. |
| `limit(expression, variable, target)` | Find the limit as the variable approaches the target. |
| `taylor(expression, variable, center, order)` | Create a Taylor polynomial with a non-negative integer order. |

For example:

```typ
#eq(`identity := simplify(sin(x)^2 + cos(x)^2)`)
#eq(`factored := factor(x^2 - 1, x)`)
#eq(`roots := solve(x^2 - 4, x)`)
#eq(`approach := limit(sin(x) / x, x, 0)`)
#eq(`series := taylor(sin(x), x, 0, 3)`)
```

The builder currently exposes this focused set of typCAS operations. Other
typCAS features can still be used through its direct API.

## Reusing numeric values

Stored dimensionless numbers are substituted into a symbolic expression at
their unrounded value:

```typ
#eq(`coefficient := 3`)
#eq(`scaled := simplify(coefficient*x + coefficient*x)`)
// scaled = simplify(coefficient⋅x + coefficient⋅x) = 6x
```

Unknown names that are not stored, such as `x`, remain symbolic. This differs
from a normal numeric builder expression, where an unknown name produces an
unset-variable error.

Symbolic expressions do not automatically become inputs to the numeric,
unit-aware evaluator. Use another CAS operation or typCAS' direct API when you
want to continue with a stored symbolic expression.

## Expressions and solution sets

Most operations return one expression and can feed another operation:

```typ
#eq(`f := factor(x^2 - 1, x)`)
#eq(`df := diff(f, x)`)
```

`solve` is different because it returns a set of roots:

```typ
#eq(`roots := solve(x^2 - 4, x)`)
// roots = solve(x² - 4, x) = 2, -2
```

A root set cannot be treated as one expression. For example,
`simplify(roots + 1)` produces a red inline error instead of silently choosing
one root.

## Reading stored results

Call the builder without an expression inside `context` to read its state:

```typ
#context {
  let stored = eq()
  assert(stored.df.symbolic)
  assert(stored.df.symbolic-kind == "expression")
  assert(stored.roots.symbolic-kind == "roots")
}
```

The symbolic fields intended for programmatic use are:

| Field | Contents |
| --- | --- |
| `symbolic` | `true` for a symbolic result. |
| `symbolic-kind` | Either `"expression"` or `"roots"`. |
| `expression` | The typCAS AST for an expression result, otherwise `none`. |
| `roots` | A tuple of typCAS AST roots for a solve result. |
| `operation` | The operation that created the result. |

The usual builder fields `display`, `variable`, and `source` are also present.

## Using the typCAS API directly

Import the same pinned typCAS version to evaluate or further process a stored
AST:

```typ
#import "@preview/typcas:0.2.3": cas

#context {
  let derivative = eq().df.expression
  let evaluated = cas.eval(derivative, bindings: (x: 2))

  assert(cas.ok(evaluated))
  assert(cas.value-of(evaluated) == 6)
}
```

For a solve result, iterate over `eq().roots.roots` instead of reading
`.expression`. Refer to the
[typCAS project](https://github.com/sihooleebd/typCAS) for its complete direct
API.

## Units and sizes

CAS expressions are dimensionless. A stored value such as `distance := 2 m`
cannot be substituted into a symbolic operation:

```typ
#eq(`distance := 2 m`)
#eq(`bad := simplify(distance*x)`)
// red: math-once: `distance` has a unit; CAS expressions must be dimensionless.
```

For the same reason, symbolic calls do not accept the builder's `unit:` or
`size:` arguments. Keep physical calculations in the unit-aware evaluator and
use CAS for dimensionless algebra.

## Raw and Typst math input

Plain, unquoted `$...$` input cannot be used for CAS calls such as this:

```typ
// This does not work:
#eq($identity := simplify(sin(x)^2 + cos(x)^2)$)
```

Typst parses and evaluates math content before `calculation-builder` receives
it. In math content, multi-letter words such as `identity` and `simplify` are
treated as Typst identifiers rather than plain mathematical names. Typst
therefore reports an unknown-variable error before math-once can recognize the
CAS operation.

Use one of these input forms instead.

### Raw input (recommended)

Raw input uses backticks. Multi-letter names need no special quoting:

```typ
#eq(`identity := simplify(sin(x)^2 + cos(x)^2)`)
```

### String input

An ordinary Typst string follows the same CAS syntax:

```typ
#eq("identity := simplify(sin(x)^2 + cos(x)^2)")
```

### Quoted Typst math input

`$...$` can only be used when multi-letter variable names and CAS operation
names are quoted so Typst treats them as text:

```typ
#eq($"identity" := "simplify"(sin(x)^2 + cos(x)^2)$)
```

Single-letter mathematical variables such as `x` and built-in mathematical
functions such as `sin` can still be written normally inside the quoted math
form.

## Errors and limitations

Builder-level CAS mistakes are rendered as red inline messages where possible.
Common examples are a wrong number of arguments, a non-name differentiation
variable, a unit-bearing stored value, or using a root set as one expression.

The supported algebra is ultimately determined by typCAS `0.2.3`. An operation
can therefore return an unsimplified expression or report that it cannot solve
a particular input. The pinned dependency keeps this behaviour stable for the
current math-once release.
