#import "@local/math-once:0.27.1": evaluate-code, calculate, calculation-builder, reset, reset-variables, reset-functions, restore-units, reset-unit-aliases, unload, rename-unit, text-unit, equation, equation-outline

#let result = evaluate-code(`6 * 7`, unit: `kg`)
#assert(result.value == 42)
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
