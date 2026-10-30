#import "../../math-once.typ": calculation-builder, school-bridge
#let run=calculation-builder(key:"guard",angles:"radians",strict:true)
#run("derived := diff(sin(x),x)")
#school-bridge(cb => cb("derived(x)")(0),key:"guard",angles:"degrees")
