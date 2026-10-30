#import "../math-once.typ": calculation-builder
#import "@preview/typcas:0.2.3": cas
#let eq=calculation-builder(key:"school-cas")
#eq(`expone := solve(5*e^(0.3*x),20,x)`)
#eq(`exptwo := solve(5*2^(0.3*x),20,x)`)
#eq(`radical := solve(sqrt(x),3,x)`)
#eq(`shifted := solve(sqrt(x+3),x-3,x)`)
#eq(`rational := solve(1/(x+1),2,x)`)
#eq(`ratio := solve(x/(x-1),3,x)`)
#eq(`absolute := solve(abs(x-2),3,x)`)
#eq(`logs := solve(log(x)+log(x-3),1,x)`)
#eq(`repeated := solve(x+1/x,2,x)`)
#eq(`quadratic := solve(a*x^2+b*x+c,x)`)
#eq(`identity := solve(2*x+3,2*x+3,x)`)
#eq(`extrema := solve(diff(x^3-3*x,x),x)`)
#eq(`deriv := diff(e^x,x)`)
#eq(`series := taylor(e^x,x,0,3)`)
#eq(`primitive := integrate(e^(2*x),x)`)
#eq(`area := integrate(x^2,x,0,2)`)
#eq(`expanded := expand((x+1)^2-x^2)`)
#eq(`infinite := limit(1/x,x,oo)`)
#context {
 let s=eq()
 for (name,expected) in (("expone",(calc.ln(4)/0.3,)),("exptwo",(2/0.3,)),("radical",(9,)),("shifted",(6,)),("rational",(-0.5,)),("ratio",(1.5,)),("absolute",(-1,5)),("logs",(5,)),("repeated",(1,)),("extrema",(-1,1))) {
   assert(name in s,message:name+" missing")
   let actual=s.at(name).roots.map(r=>cas.value-of(cas.eval(r))).sorted()
   assert(actual.len()==expected.len(),message:name+repr(actual))
   for (a,b) in actual.zip(expected) { assert(calc.abs(a - b) < 1e-6,message:name) }
 }
 assert(s.quadratic.roots.len()==2)
 assert(s.identity.solution-status=="all")
 assert(calc.abs(cas.value-of(cas.eval(s.area.expression)) - 8/3) < 1e-9)
 assert(cas.value-of(cas.eval(s.infinite.expression))==0)
 assert(cas.value-of(cas.eval(s.expanded.expression,bindings:(x:3)))==7)
 assert(calc.abs(cas.value-of(cas.eval(s.deriv.expression,bindings:(x:1))) - calc.e) < 1e-8)
}
#import "../school.typ" as school
#let particular=school.ode-particular("exponential",2,3)
#let affine=school.ode-particular("affine",2,3,offset:4)
#let logistic=school.ode-particular("logistic",0.2,2,capacity:10)
#for (f,rate) in ((particular,6),(affine,10),(logistic,3.2)) {
  assert(calc.abs(cas.value-of(cas.eval(f,bindings:(x:0))) - if f==logistic {2} else {3}) < 1e-8)
  assert(calc.abs(cas.value-of(cas.eval(cas.expr-of(cas.diff(f,"x")),bindings:(x:0))) - rate) < 1e-8)
}
#let intervals=school.inequality(x=>x*x - 1,-2,2)
#assert(intervals.len()==1 and intervals.first().lo-closed and intervals.first().hi-closed)
#assert(calc.abs(intervals.first().lo + 1) < 1e-6)
#let strict=school.inequality(x=>x*x - 1,-2,2,relation:"<")
#assert(not strict.first().lo-closed and not strict.first().hi-closed)
#assert(school.roots(x=>calc.sin(x),0,2*calc.pi).len()==3)
#eq(`nonreal := solve(x^2,-4,x)`)
#eq(`cube := solve(x^3,8,x)`)
#context {
 assert(eq().nonreal.roots.len()==0)
 assert(eq().cube.roots.len()==1)
 assert(calc.abs(cas.value-of(cas.eval(eq().cube.roots.first())) - 2) < 1e-6)
}
// Verify the differential equations away from the initial point as well.
#for x in (0.2,0.7,1.1) {
 for (f,kind) in ((particular,"exponential"),(affine,"affine"),(logistic,"logistic")) {
  let y=cas.value-of(cas.eval(f,bindings:(x:x)))
  let dy=cas.value-of(cas.eval(cas.expr-of(cas.diff(f,"x")),bindings:(x:x)))
  let rhs=if kind=="exponential" {2*y} else if kind=="affine" {2*y+4} else {0.2*y*(10 - y)}
  assert(calc.abs(dy - rhs) < 1e-7)
 }
}
#let symbolic=school.ode-particular("exponential","k","y0")
#assert(calc.abs(cas.value-of(cas.eval(symbolic,bindings:(k:2,y0:3,x:1))) - 3*calc.exp(2)) < 1e-7)
#let point=school.inequality(x=>x*x,-1,1)
#assert(point.len()==1 and point.first().lo==point.first().hi)
#eq(`unknown := solve(x+sin(x),1,x)`)
#context assert("unknown" not in eq())
#eq(`impossible := solve(sqrt(x),-3,x)`)
#context assert(eq().impossible.solution-status=="none")
#eq(`infinityword := limit(1/x,x,infinity)`)
#context assert(cas.value-of(cas.eval(eq().infinityword.expression))==0)

Symbolic initial-value solutions:
$y(x) = #cas.display(particular)$
$y(x) = #cas.display(affine)$
$y(x) = #cas.display(logistic)$
#context {
 let s=eq()
 assert(calc.abs(cas.value-of(cas.eval(s.series.expression,bindings:(x:2))) - 19/3) < 1e-8)
 let derivative=cas.expr-of(cas.diff(s.primitive.expression,"x"))
 for x in (0,0.4,1) {
  assert(calc.abs(cas.value-of(cas.eval(derivative,bindings:(x:x))) - calc.exp(2*x)) < 1e-8)
 }
 // The parameterized formula satisfies the original polynomial for both roots.
 for root in s.quadratic.roots {
  let value=cas.value-of(cas.eval(root,bindings:(a:2,b:3,c:-2)))
  assert(calc.abs(2*value*value+3*value - 2) < 1e-8)
 }
}

// Phase-one review regressions, including rejected domains.
#for line in (
 `negativeexp := solve(e^x,-1,x)`,
 `negativebase := solve(2^x,-3,x)`,
 `fractionpower := solve(3*x^2.5,100,x)`,
 `thirdpower := solve(x^(1/3),2,x)`,
 `logisticroot := solve(50/(1+4*e^(-0.5*x)),40,x)`,
 `growthroot := solve(100*1.05^x,80*1.08^x,x)`,
 `stationary := solve(diff(x^2*e^(-x),x),x)`,
 `zeroproduct := solve(x*e^x,x)`,
 `dependentabs := solve(abs(2*x-1),x+2,x)`,
 `exparea := integrate(e^x,x,0,1)`,
 `sqrtarea := integrate(sqrt(x),x,0,4)`,
 `scaledarea := integrate(2*e^(0.5*x),x,0,2)`,
 `scaledprimitive := integrate(3*e^(2*x),x)`,
 `negativeinfinity := limit(e^x,x,-oo)`,
 `polearea := integrate(1/x,x,-1,1)`,
 `polelimit := limit(1/x,x,0)`,
 `excludedidentity := solve((x^2-1)/(x-1),x+1,x)`,
 `samefraction := solve(1/(x-2),1/(x-2),x)`,
 `conditional := solve(x+a,x+1,x)`,
 `badarea := integrate(sqrt(x),x,-4,-1)`,
) {eq(line)}
#context {
 let s=eq()
 for name in ("negativeexp","negativebase") {assert(s.at(name).solution-status=="none")}
 for (name,expected) in (("fractionpower",(calc.pow(100/3,0.4),)),("thirdpower",(8,)),("logisticroot",(2*calc.ln(16),)),("growthroot",(calc.ln(0.8)/calc.ln(1.05/1.08),)),("stationary",(0,2)),("zeroproduct",(0,)),("dependentabs",(-1/3,3))) {
  assert(name in s,message:name+" missing")
  let actual=s.at(name).roots.map(r=>cas.value-of(cas.eval(r))).sorted()
  assert(actual.len()==expected.len(),message:name+repr(actual))
  for (a,b) in actual.zip(expected) {assert(calc.abs(a - b) < 1e-6,message:name)}
 }
 for (name,expected) in (("exparea",calc.e - 1),("sqrtarea",16/3),("scaledarea",4*(calc.e - 1)),("negativeinfinity",0)) {
  assert(name in s,message:name+" missing")
  assert(calc.abs(cas.value-of(cas.eval(s.at(name).expression)) - expected) < 1e-8,message:name)
 }
 for name in ("polearea","polelimit","excludedidentity","samefraction","conditional","badarea") {assert(name not in s,message:name+" must reject")}
 for x in (-1,0,2) {
  let d=cas.expr-of(cas.diff(s.scaledprimitive.expression,"x"))
  assert(calc.abs(cas.value-of(cas.eval(d,bindings:(x:x))) - 3*calc.exp(2*x)) < 1e-7)
 }
}
#let scaledroots=school.roots(x=>1000*x - 1234.5678,0,5)
#assert(scaledroots.len()==1)
#assert(calc.abs(scaledroots.first() - 1.2345678) < 1e-7)
#assert(school.inequality(x=>1000*x - 1234.5678,0,5,relation:"<").len()==1)
#assert(school.roots(x=>if x < 1.2345678 {-1} else {1},0,5)==())
#assert(school.roots(x=>1/(x - 1.2345678),0,5)==())
#let piecewise(x)=if x < 0 {-x} else {x}
#assert(school.roots(x=>piecewise(x) - 2,-3,3).len()==2)
#assert(range(1,6).map(x=>x*x).sum()==55)
#assert((1,2,3).map(x=>2*x)==(2,4,6))
#eq(`interiorbad := integrate(sqrt(x^2-1),x,-2,2)`)
#eq(`unsupportedarea := integrate(x*e^x,x,0,1)`)
#context {
 assert("interiorbad" not in eq())
 assert("unsupportedarea" not in eq())
}
#eq(`negativepowerzero := solve(x^(-2),0,x)`)
#eq(`oddnegative := solve(x^(1/3),-2,x)`)
#eq(`outsideinterval := integrate(x^(-0.5),x,-1,1)`)
#context {
 assert(eq().negativepowerzero.solution-status=="none")
 assert("oddnegative" not in eq()) // Explicit unsupported real branch, never a false empty set.
 assert("outsideinterval" not in eq())
}
#eq(`radicalidentity := solve(sqrt(x),sqrt(x),x)`)
#context assert("radicalidentity" not in eq())
#eq(`scaledzero := solve(7*x*e^(3*x),x)`)
#context {
 assert(eq().scaledzero.roots.len()==1)
 assert(cas.value-of(cas.eval(eq().scaledzero.roots.first()))==0)
}
#eq(`conditionalexp := solve(e^x,a,x)`)
#context assert("conditionalexp" not in eq())
