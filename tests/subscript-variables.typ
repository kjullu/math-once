#import "../math-once.typ": calculation-builder, unload

#let eq = calculation-builder(key: "subscript-variable-test")

#eq($theta_m := 15$)
#eq($lambda_0 := 530 m$)
#eq($x := 2 lambda_0$)

// Raw input and multi-letter subscripts use the same storage convention.
#eq(`speed_max := 20 m/s`)
#eq(`distance := speed_max * 2 s`)

// Typst text subscripts map to the same reusable ASCII-style state key.
#unload("d", key: "subscript-variable-test")
#eq($d := 10 "mm"$)
#eq($lambda := 2 "mm"$)
#eq($n_"maks" := d / lambda$)
#eq($y := 2 n_"maks"$)

#context {
  let variables = eq()
  assert(variables.at("theta_m").value == 15.0)
  assert(variables.at("lambda_0").value == 530.0)
  assert(variables.x.value == 1060.0)
  assert(variables.at("speed_max").value == 20.0)
  assert(variables.distance.value == 40.0)
  assert(variables.at("n_maks").exact == 5)
  assert(variables.y.exact == 10)
}
