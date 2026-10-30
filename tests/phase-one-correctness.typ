#import "../math-once.typ": calculation-builder, school as s
#import "@preview/typcas:0.2.3": cas
#let eq=calculation-builder(key:"phase-one",angles:"radians")
#for (i,source) in (
("ka","integrate(1/(2*x+1),x,0,1)"),
("kb","integrate(2/(3*x-1),x,1,2)"),
("kc","integrate(1/(x^2-1),x,2,3)"),
("kd","integrate(3/x^2,x,1,2)"),
("ke","integrate(1/x^2,x,1,2)"),
("kf","integrate(x^-1,x,1,2)"),
("kg","integrate(2^x,x,0,1)"),
("kh","integrate(10*0.5^x,x,0,1)"),
("ki","integrate(x*sqrt(x),x,0,1)"),
) {eq(raw(i+" := "+source))}
#context {
 let state=eq()
 for (key,value) in (("ka",calc.ln(3)/2),("kb",2/3*calc.ln(2.5)),("kc",calc.ln(1.5)/2),("kd",1.5),("ke",0.5),("kf",calc.ln(2)),("kg",1/calc.ln(2)),("kh",-5/calc.ln(0.5)),("ki",0.4)) {
 assert(key in state,message:key+" missing")
 assert(calc.abs(cas.value-of(cas.eval(state.at(key).expression)) - value) < 1e-7,message:key)
 }
}
#for factor in (1e-12,1e-6,1,1e6,1e12,-1e-12,-1e12) {
 let roots=s.roots(x=>factor*(x - 1.54321),0,5)
 assert(roots.len()==1,message:repr((factor,roots)))
 assert(calc.abs(roots.first() - 1.54321) < 1e-7)
 assert(s.roots(x=>factor*((x - 1.54321)*(x - 1.54321)+1e-6),0,5).len()==0)
 assert(s.roots(x=>factor*(x - 1.54321)*(x - 1.54321),0,5).len()==1)
 assert(s.roots(x=>factor/(x - 1.54321),0,5).len()==0)
 assert(s.inequality(x=>factor*(x - 1.54321),0,5).len()==1)
}
Phase one: verified integrals and scale invariant numerical roots.
#for (key,source) in (
("poleone","limit(x^-1,x,0)"),("poletwo","limit(x^-2,x,0)"),
("polethree","limit(2*x^-1,x,0)"),("shiftpole","limit((x-2)^-1,x,2)"),
("leftpole","limit((x+1)^-1,x,-1)"),("growth","limit(e^x,x,oo)"),
("growthtwo","limit(2^x,x,oo)"),("growththree","limit(x*e^x,x,oo)"),
("polyinf","limit(x^2,x,oo)"),("sqrtinf","limit(sqrt(x),x,oo)"),
("loginf","limit(ln(x),x,oo)"),("logzero","limit(ln(x),x,0)"),
) {
 eq(raw(key+" := "+source))
 context assert(key not in eq(),message:key+" must diagnose")
}
#eq(`decay := limit(x^-1,x,oo)`)
#context assert(cas.value-of(cas.eval(eq().decay.expression))==0)
#for (key,source,expected) in (
("recipone","1/(x+1)",calc.ln(3/2)),
("reciptwo","1/(x+2)",calc.ln(4/3)),
("recipfour","4/(x+1)",4*calc.ln(3/2)),
("recipfive","5/x",5*calc.ln(2)),
) {
 eq(raw(key+" := integrate("+source+",x,1,2)"))
 context {
  assert(key in eq())
  assert(calc.abs(cas.value-of(cas.eval(eq().at(key).expression)) - expected) < 1e-7)
 }
}
#eq(`affineprimitive := integrate(1/(2*x+1),x)`)
#context {
 let primitive=cas.expr-of(cas.substitute(eq().affineprimitive.expression,"C",0))
 let d=cas.expr-of(cas.diff(primitive,"x"))
 for x in (0.2,1.2,3.4) {
  assert(calc.abs(cas.value-of(cas.eval(d,bindings:(x:x))) - 1/(2*x+1)) < 1e-7)
 }
}
#for factor in (1e-12,-1e-12,1e12,-1e12) {
 assert(s.roots(x=>factor*((x - 1.54321)*(x - 1.54321)+1e-12),0,5).len()==0)
}
#for (f,expected) in (
(x=>1000*x - 1234.5678,1.2345678),
(x=>6.67e-11*x - 1e-10,1e-10/6.67e-11),
(x=>1e-6*x - 1.5e-6,1.5),
) {
 let rs=s.roots(f,0,5)
 assert(rs.len()==1)
 assert(calc.abs(rs.first() - expected) < 1e-7)
}

#for (key,source,n,d,f,a,b) in (
("exacta","3/x^2",2,1,x=>3/(x*x),1,3),
("exactb","1/x^2",2,3,x=>1/(x*x),1,3),
("exactc","x^-2",2,3,x=>1/(x*x),1,3),
("exactd","1/(x+2)^2",1,12,x=>1/((x+2)*(x+2)),1,2),
("exacte","(2*x+1)^-2",1,3,x=>1/((2*x+1)*(2*x+1)),0,1),
("exactf","2/(2*x+1)^3",4,9,x=>2/calc.pow(2*x+1,3),0,1),
) {
 eq(raw(key+" := integrate("+source+",x,"+str(a)+","+str(b)+")"))
 context {
  assert(key in eq(),message:key)
  let expression=eq().at(key).expression
  let delta=cas.simplify((type:"add",args:(expression,(type:"neg",arg:cas.parse(str(n)+"/"+str(d))))))
  assert(cas.ok(delta))
  assert(cas.expr-of(delta)==(type:"num",val:0),message:repr((expression,delta)))
  assert(calc.abs(cas.value-of(cas.eval(expression))-s.integral(f,a,b,steps:2000)) < 1e-10)
 }
}
#for (key,source) in (
("tanpole","integrate(tan(x),x,0,2)"),
("tanlimit","limit(tan(x),x,pi/2)"),
("coslimit","limit(1/cos(x),x,pi/2)"),
("sqrtlimit","limit(sqrt(x)/x,x,0)"),
("sqrtshiftone","limit(sqrt(x-1)/(x-1),x,1)"),
("sqrtshifttwo","limit(sqrt(x+2)/(x+2),x,-2)"),
("sqrtscale","limit(sqrt(2*x)/x,x,0)"),
("sqrtshiftfour","limit(sqrt(x-4)/(x-4),x,4)"),
("sqrtreflect","limit(sqrt(1-x)/(1-x),x,1)"),
("sqrtquadraticden","limit(sqrt(x-1)/(x^2-1),x,1)"),
("sqrtquadraticnum","limit(sqrt(x^2-1)/(x-1),x,1)"),
("sqrtabsolute","limit(sqrt(x^2)/x,x,0)"),
("shifttrig","integrate(tan(2*x+1),x,0,2)"),
("sinlimit","limit(1/sin(x),x,pi)"),
("periodpole","integrate(1/cos(x),x,3,5)"),
("cotpole","limit(cot(x),x,pi)"),
("secpole","limit(sec(x),x,-pi/2)"),
) {
 eq(raw(key+" := "+source))
 context assert(key not in eq(),message:key)
}
#eq(`largeconstant := limit(10000000000000000,x,0)`)
#eq(`tanregular := limit(tan(x),x,0)`)
#context {
 assert("largeconstant" in eq())
 assert("tanregular" in eq())
}
#let rational=s.inequality(x=>(x - 1)/(x - 3.0123),0,5)
#assert(rational.len()==1 and calc.abs(rational.first().lo - 1) < 1e-7 and calc.abs(rational.first().hi - 3.0123) < 1e-7 and not rational.first().hi-closed)
#let reciprocal=s.inequality(x=>1/(x - 2.0123),0,5,relation:">")
#assert(reciprocal.len()==1 and calc.abs(reciprocal.first().lo - 2.0123) < 1e-7 and not reciprocal.first().lo-closed and reciprocal.first().hi-closed)
#assert(s.roots(x=>(x - 1)/(x - 3),0,5,exclusions:(3,)).len()==1)
#let excluded=s.inequality(x=>1/(x - 2),0,5,relation:">",exclusions:(2,))
#assert(excluded.first().lo==2 and not excluded.first().lo-closed)

#eq(`reverseexact := integrate(1/x^2,x,3,1)`)
#eq(`negativeexact := integrate(1/x^2,x,-3,-1)`)
#context {
 assert(cas.value-of(cas.eval(eq().reverseexact.expression)) == -2/3)
 assert(cas.value-of(cas.eval(eq().negativeexact.expression)) == 2/3)
}
