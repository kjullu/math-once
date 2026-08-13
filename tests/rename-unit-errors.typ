#import "../math-once.typ": calculation-builder, rename-unit

#let eq = calculation-builder(key: "rename-unit-errors")

// Each failure is visible in red and leaves the builder state unchanged.
#rename-unit($m$, $s$, key: "rename-unit-errors")
#rename-unit("not_a_unit", "alias", key: "rename-unit-errors")
#rename-unit($m$, $m$, key: "rename-unit-errors")

#rename-unit($m$, $v$, key: "rename-unit-errors")
#rename-unit($s$, $v$, key: "rename-unit-errors")
#context assert(eq().len() == 0)

#eq($x := 2$)
#rename-unit($m$, $x$, key: "rename-unit-errors")

#context {
  assert(eq().x.value == 2.0)
  assert(eq().len() == 1)
}
