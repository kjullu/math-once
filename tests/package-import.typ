#import "@local/math-once:0.37.0": evaluate-code, calculate, calculation-builder, reset, reset-variables, reset-functions, restore-units, reset-unit-aliases, unload, rename-unit, text-unit, matrix, equation, equation-outline

#let result = evaluate-code(`6 * 7`, unit: `kg`)
#assert(result.value == 42)
#assert(calculate(`floor(3.7)`).exact == 3)
#assert(calculate(`ceil(-3.2)`).exact == -3)
#assert(calculate(`round(3.5)`).exact == 4)
#assert(calculate($floor(3.7)$).exact == 3)
#assert(calculate($ceil(3.2)$).exact == 4)
#assert(calculate($round(3.5)$).exact == 4)
#assert(calculate(`abs(-3)`).exact == 3)
#assert(calculate($|-3|$).exact == 3)
#assert(calculate(`30 celsius - 20 celsius`).exact == 10.0)
#assert(calculate(`2 cm`, strict-units: true).unit == "cm")
#assert(result.exact == 42)
#result.display

#let speed = calculate(`10 m/s + 1 km/h`)
#assert(speed.value == 10.2778)
#assert(speed.unit == "m/s")
#speed.display

#let run = calculation-builder(key: "package-import-runner")
#assert(type(equation) == function)
#assert(type(equation-outline) == function)
#run(`v := 10 m/s`)
#run(`x := v * 2 s`)
#context {
  let variables = run()
  assert(variables.x.value == 20.0)
  assert(variables.x.unit == "m")
}

#let options = calculation-builder(key: "package-import-options", strict: true)
#options(`x := 3`)
#options(`y := x * 2`, show-substitution: false)
#options(`hidden_value := y + 1`, hidden: true)
#options(`labelled := 4`, unit: $#text-unit("panels")$)
#options(`labelled`, result-only: true)
#context {
  assert(options().hidden_value.exact == 7.0)
  assert(options().labelled.unit == "panels")
}

#let package_characters = "309"
#run($ #package_characters/2400 $)

#let symbolic_unit_name = calculation-builder(key: "package-import-symbolic-unit-name")
#symbolic_unit_name(`a := diff(x^2, x)`)
#symbolic_unit_name(`second := diff(a, x)`)
#context {
  assert(symbolic_unit_name().a.symbolic-kind == "expression")
  assert(symbolic_unit_name().second.symbolic-kind == "expression")
}
#reset-variables("x", key: "package-import-runner")
#context assert("x" not in run())
#run($f(t) := t + 1$)
#unload("a", key: "package-import-runner")
#run($a := 2$)
#context assert(run().a.value == 2.0)
#reset-variables(key: "package-import-runner")
#context assert(run().f.function and "a" not in run())
#reset-functions(key: "package-import-runner")
#restore-units(key: "package-import-runner")
#rename-unit($m$, $v$, key: "package-import-runner")
#run($x := 2 v$)
#context assert(run().x.si-value == 2.0)
#reset-unit-aliases(key: "package-import-runner")
#reset(key: "package-import-runner")

#let symbolic = calculation-builder(key: "package-import-symbolic")
#symbolic(`f := simplify(x^2 + 2*x + 1)`)
#symbolic(`df := diff(f, x)`)
#context assert(symbolic().df.symbolic-kind == "expression")

#let paired = calculation-builder(key: "package-import-paired-signs")
#paired($x = 1 plus.minus 2$)
#context assert(paired().len() == 0)
#let paired-result = calculate(`10 plus.minus 2`)
#assert(paired-result.values == (12.0, 8.0))

#let conclusion = calculation-builder(key: "package-import-result-only")
#conclusion($speed := 10 m/s$)
#assert(conclusion($speed$, result-only: true).block == false)

#let subscript = calculation-builder(key: "package-import-text-subscript")
#unload("d", key: "package-import-text-subscript")
#subscript($d := 10 "mm"$)
#subscript($lambda := 2 "mm"$)
#subscript($n_"maks" := d / lambda$)
#context assert(subscript().at("n_maks").exact == 5)

#let structures = calculation-builder(key: "package-import-structures")
#structures($arrow(v) := vec(1, 2)$)
#structures($X := matrix(1, 2; 3, 4)$)
#structures($arrow(w) := X arrow(v)$)
#context {
  assert(structures().arrow_v.values == (1.0, 2.0))
  assert(structures().X.shape == (2, 2))
  assert(structures().arrow_w.values == (5.0, 11.0))
}
