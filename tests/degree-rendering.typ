#import "../math-once.typ": calculate, calculation-builder
#set page(width: 14cm, height: auto, margin: 1cm)
#for name in ("deg", "degree", "degrees", "°") {
  assert(calculate("180 " + name + " to rad", digits: 12).value == calc.round(calc.pi, digits: 12))
  calculate("8 " + name).display
  linebreak()
  calculate("8", unit: name).display
  linebreak()
}
#calculate(`8 "deg"`).display
#calculate(`8 deg/s`, unit: `deg/s`).display
#calculate(`8 m`).display
#let work = calculation-builder(key: "degree-rendering")
#work($theta_a := 8 deg$)
#linebreak()
#work($theta_b := theta_a + 2 degree$)
#linebreak()
#work($theta_c := 8 degree$)
