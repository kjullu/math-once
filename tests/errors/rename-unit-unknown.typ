#import "../../math-once.typ": calculation-builder, rename-unit
#let eq = calculation-builder(key: "rename-unit-unknown")
#rename-unit("not_a_unit", "alias", key: "rename-unit-unknown")
#context eq()
