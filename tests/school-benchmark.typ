#import "../math-once.typ": calculation-builder,school-bridge,school
#let run=calculation-builder(key:"benchmark",strict:true,angles:"radians")
#run("f(x) := x*exp(-x/2)*sin(x)+ln(x^2+1)")
#run("df(x) := diff(f(x),x)")
// Long second derivatives can be stored without an overflowing formula.
#run("ddf(x) := diff(df(x),x)", hidden: true)
#run("ddf(1)")
#school-bridge(callback=>{
  let f=callback("f(x)")
  let df=callback("df(x)")
  let ddf=callback("ddf(x)")
  assert(calc.abs(ddf(1) - school.derivative(df,1)) < 1e-6)
  for x in (-1.5, -0.5, 0, 1, 1.5) {
    assert(calc.abs(df(x)-school.derivative(f,x)) < 1e-6)
  }
  let roots=school.roots(f,-2,2)
  let area=school.integral(f,-2,2)
  assert(type(area) in (int,float))
  school.plot((f,df),-2,2,labels:([Model],[Derivative]))
},key:"benchmark",angles:"radians")

// Default working steps must remain readable on an ordinary A4 page.
#run("df(1)")
#run("F(x) := integrate(x^2,x)")
#run("F(3)")
#run("L(x) := integrate(1/x,x)")
#run("L(2)")
