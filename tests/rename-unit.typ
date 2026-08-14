#import "../math-once.typ": calculation-builder, rename-unit, reset, reset-unit-aliases, unload

#let eq = calculation-builder(key: "rename-unit-test")

#rename-unit($m$, $v$, key: "rename-unit-test")
#eq($m := 2$)
#eq($x := 3 v$)
#context {
  assert(eq().m.value == 2.0)
  assert(eq().x.si-value == 3.0)
  assert(eq().x.dimensions.length == 1)
}

#rename-unit($v$, $"vme"$, key: "rename-unit-test")
#eq($y := 4 "vme"$)
#eq($v := 5$)
#context {
  assert(eq().y.si-value == 4.0)
  assert(eq().v.value == 5.0)
}

#reset-unit-aliases($"vme"$, key: "rename-unit-test")
#context {
  assert("y" in eq())
  assert("v" in eq())
  assert("m" not in eq())
}

#reset(key: "rename-unit-test")
#context assert(eq().len() == 0)

// An explicitly unloaded catalog spelling can become the destination alias.
#let time = calculation-builder(key: "rename-unit-unloaded-destination")
#unload("T", "t", key: "rename-unit-unloaded-destination")
#rename-unit($h$, $t$, key: "rename-unit-unloaded-destination")
#time($T := 8t + 30 "min"$)
#context {
  assert(time().T.value == 8.5)
  assert(time().T.exact == 8.5)
  assert(time().T.si-value == 30600.0)
  assert(time().T.unit == "t")
}
