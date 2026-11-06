#import "../../math-once.typ": calculation-builder, school-bridge
#let run=calculation-builder(key:"guard",angles:"degrees",strict:true)
#run("F(x) := integrate(cos(x),x)")
