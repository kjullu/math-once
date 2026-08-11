#import "../../math-once.typ": calculation-builder, unload

#let eq = calculation-builder(key: "unloaded-before-assignment")
#unload("a", key: "unloaded-before-assignment")
#eq($x = a + 1$)
