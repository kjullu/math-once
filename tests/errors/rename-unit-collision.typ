#import "../../math-once.typ": calculation-builder, rename-unit
#let eq = calculation-builder(key: "rename-unit-collision")
#rename-unit($m$, $s$, key: "rename-unit-collision")
#context eq()
