#import "../math-once.typ": evaluate-code, calculate, calculation-builder, reset, reset-variables, reset-functions, restore-units, reset-unit-aliases, unload, rename-unit, text-unit, equation, equation-outline, number-labelled-equations

#assert(type(evaluate-code) == function)
#assert(type(calculate) == function)
#assert(type(calculation-builder) == function)
#assert(type(reset) == function)
#assert(type(reset-variables) == function)
#assert(type(reset-functions) == function)
#assert(type(restore-units) == function)
#assert(type(reset-unit-aliases) == function)
#assert(type(unload) == function)
#assert(type(rename-unit) == function)
#assert(type(text-unit) == function)
#assert(type(equation) == function)
#assert(type(equation-outline) == function)
#assert(type(number-labelled-equations) == function)

The documented public API exports all fourteen functions.
