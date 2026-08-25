#import "../math-once.typ": calculation-builder, matrix

#let eq = calculation-builder(key: "vectors-matrices", digits: 2)

// Arrow accents become stable variable names, while vec(...) stores a value.
#eq($arrow(v) := vec(1 m, 2 m)$)
#eq($arrow(w) := vec(3 m, 4 m)$)
#eq($arrow(q) := arrow(v) + arrow(w)$)
#eq($arrow(k) := 2 arrow(v)$)

// matrix(...) is a public spelling of Typst's mat(...); both are understood.
#eq($X := matrix(1, 2; 3, 4)$)
#eq($Y := mat(5, 6; 7, 8)$)
#eq($Z := X + Y$)
#eq($X_1 := X Y$)
#eq($arrow(c) := X vec(1, 2)$)
#eq($arrow(r) := vec(1, 2) X$)
#eq($X_2 := X / 2$)

// Stored functions may return vectors or matrices.
#eq($arrow(p)(t) := vec(t, t^2)$)
#eq($D(t) := matrix(t, 0; 0, t)$)
#eq($arrow(a) := arrow(p)(3)$)
#eq($X_3 := D(3)$)
#eq(`X_4 := mat(2, 0; 0, 2)`)

#context {
  let state = eq()
  assert(state.arrow_v.vector)
  assert(state.arrow_v.values == (1.0, 2.0))
  assert(state.arrow_v.components.first().unit == "m")
  assert(state.arrow_q.values == (4.0, 6.0))
  assert(state.arrow_k.values == (2.0, 4.0))
  assert(state.X.matrix and state.X.shape == (2, 2))
  assert(state.Z.values == ((6.0, 8.0), (10.0, 12.0)))
  assert(state.X_1.values == ((19.0, 22.0), (43.0, 50.0)))
  assert(state.arrow_c.values == (5.0, 11.0))
  assert(state.arrow_r.values == (7.0, 10.0))
  assert(state.X_2.values == ((0.5, 1.0), (1.5, 2.0)))
  assert(state.arrow_a.values == (3.0, 9.0))
  assert(state.D.matrix)
  assert(state.X_3.values == ((3.0, 0.0), (0.0, 3.0)))
  assert(state.X_4.values == ((2.0, 0.0), (0.0, 2.0)))
}

Result only: #eq($X$, result-only: true)
