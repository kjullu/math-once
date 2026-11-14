#import "../math-once.typ": calculation-builder

// A substituted value is grouped where the equation would otherwise read
// differently, for example (-3)^2 instead of -3^2.
#let eq = calculation-builder(key: "substitution-grouping")

#eq($ x := -3 $)
#eq($ x^2 $)
#eq($ 2 - x $)
#eq($ 2 x $)
#eq($ -x $)
#eq($ 2 * x $)
#eq($ 2^x $)
#eq($ x + 1 $)
#eq($ sin(x) $)
#eq($ (x)^2 $)
#eq($ x / 2 $)

#eq($ k := 1.5 * 10^12 $)
#eq($ k^2 $)
#eq($ 3 - k $)
#eq(`3 / k`)
#eq(`k / 3`)

#eq($ "dist" := 12.0 "km" $)
#eq($ "dist"^2 $)
#eq(`7 km / dist`)
#eq(`dist / 4`)

#context {
  let state = eq()
  assert(state.x.exact == -3.0)
}
