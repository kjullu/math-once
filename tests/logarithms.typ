#import "../math-once.typ": calculate, calculation-builder

#assert(calc.abs(calculate(`ln(6)`).exact - calc.log(6, base: calc.e)) < 1e-12)
#assert(calculate(`ln(1)`).exact == 0)
#assert(calc.abs(calculate(`log(100, 10)`).exact - 2) < 1e-12)
#assert(calc.abs(calculate(`log(0.01, 10)`).exact + 2) < 1e-12)
#assert(calc.abs(calculate(`log(9, 3)`).exact - 2) < 1e-12)
#assert(calc.abs(calculate($log_4 32$).exact - 2.5) < 1e-12)
#assert(calc.abs(calculate($log_4(32)$).exact - 2.5) < 1e-12)
#assert(calc.abs(calculate(`ln(8) / ln(2)`).exact - 3) < 1e-12)
#assert(calc.abs(calculate(`ln(6 mm / (0.1 cm))`).exact - calc.log(6, base: calc.e)) < 1e-12)
#assert(calc.abs(calculate(`2 ln(6)`).exact - 2 * calc.log(6, base: calc.e)) < 1e-12)

#let eq = calculation-builder(key: "logarithms", digits: 4)
#eq($C_1 := 2.5 "nF"$)
#eq($epsilon_r := 4$)
#eq($d_1 := 6 "mm"$)
#eq($d_2 := 1 "mm"$)
#eq($epsilon_0 := 8.854 times 10^(-12) "C"^2 / ("N" dot "m"^2)$)
#eq($L_1 := (C_1 dot ln(d_1 / d_2)) / (2 pi dot epsilon_r dot epsilon_0)$)
#eq($x := log_10(100)$)
#eq($k := 3$)
// Subscript bases: number, decimal, variable, nested, and no parentheses.
#eq($z_1 := log_4 32$)
#eq($z_2 := log_(2.5)(6.25)$)
#eq($z_3 := log_k (z_1 + 6.5)$)
#eq($z_4 := log_2(log_2(16))$)
#eq($z_5 := log(9, 3)$)
#eq($y := ln(1)$)
#context {
  assert(calc.abs(eq().L_1.value - 20.1298) < 1e-8)
  assert(eq().L_1.unit == "m")
  assert(eq().x.value == 2)
  assert(eq().y.value == 0)
  for (name, value) in (z_1: 2.5, z_2: 2, z_3: 2, z_4: 2, z_5: 2) {
    assert(calc.abs(eq().at(name).value - value) < 1e-9)
  }
}

// Domain failures must render as calculation errors instead of crashing Typst.
#eq($ln(0)$)
#eq($log_10(-1)$)
#eq($ln(2 "m")$)
#eq($log_10(2 "m")$)
#eq($log(100)$)
#eq($log_1(5)$)
