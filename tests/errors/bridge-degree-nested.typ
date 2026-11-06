#import "../../math-once.typ": calculation-builder, school-bridge
#let run=calculation-builder(key:"guard",angles:"radians",strict:true)
#run("df(x) := diff(sin(x),x)")
#run("nested(x) := df(x)+1")
#school-bridge(cb => cb("nested(x)")(0),key:"guard",angles:"degrees")
