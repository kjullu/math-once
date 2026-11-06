#import "../../math-once.typ": calculation-builder, school-bridge
#let run=calculation-builder(key:"guard",angles:"radians",strict:true)
#run("f(x) := sin(x)")
#run("df(x) := diff(f(x),x)")
#school-bridge(cb => cb("df(x)")(0),key:"guard",angles:"degrees")
