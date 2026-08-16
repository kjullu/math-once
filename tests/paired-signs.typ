#import "../math-once.typ": calculation-builder

#let eq = calculation-builder(key: "paired-signs")

// Typst math symbols are preserved in display-only equations.
#eq($x = 1 plus.minus 2$)
#eq($y = 1 minus.plus 2$)
#eq($z = alpha plus.minus beta minus.plus gamma$)

// Raw and string input accept the spelled and Unicode forms.
#eq(`result = alpha plus.minus beta minus.plus gamma`)
#eq("other = 1 ± 2 ∓ 3")

// A paired-sign expression has two results and cannot be stored as one value.
#eq(`ambiguous := 1 plus.minus 2`)
#context assert("ambiguous" not in eq() and eq().len() == 0)
