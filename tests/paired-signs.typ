#import "../math-once.typ": calculate, calculation-builder

#let eq = calculation-builder(key: "paired-signs")

// Numeric paired signs produce the two correlated results.
#let simple = calculate(`1 plus.minus 2`)
#assert(simple.alternatives)
#assert(simple.values == (3.0, -1.0))
#assert(simple.exacts == (3.0, -1.0))
#assert(simple.branches.len() == 2)

#let correlated = calculate(`10 ± 3 ∓ 1`)
#assert(correlated.values == (12.0, 8.0))

#let lengths = calculate($10 m plus.minus 2 m$)
#assert(lengths.values == (12.0, 8.0))
#assert(lengths.units == ("m", "m"))

#let converted = calculate(`1 m plus.minus 25 cm to cm`)
#assert(converted.values == (125.0, 75.0))
#assert(converted.units == ("cm", "cm"))
#assert(converted.si-values == (1.25, 0.75))

// The builder displays both results separated by the logical-or symbol.
#eq($10 plus.minus 2$)
#eq($1 minus.plus 2$)
#eq($x = 10 plus.minus 2$)

// Unknown operands remain symbolic display equations.
#eq($x = 1 plus.minus 2$)
#eq($y = 1 minus.plus 2$)
#eq($z = alpha plus.minus beta minus.plus gamma$)

// Raw and string input accept the spelled and Unicode forms.
#eq(`result = alpha plus.minus beta minus.plus gamma`)
#eq("other = 1 ± 2 ∓ 3")

// A paired-sign expression still cannot be stored as one scalar value.
#eq(`ambiguous := 1 plus.minus 2`)
#context assert("ambiguous" not in eq() and eq().len() == 0)
