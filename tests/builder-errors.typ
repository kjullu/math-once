#import "../math-once.typ": calculation-builder

#let eq = calculation-builder(key: "friendly-errors")

// Each common error must render feedback instead of stopping compilation.
#eq(`1 m + 2 s`)
#eq(`1 m`, unit: `s`)
#eq(`1 / 0`)
#eq(`sin(1 m)`)
#eq(`(1 m)^0.5`)
#eq(`1 m`, size: 0)
#eq(`2`, size: 0.01)
#eq(`1 m to cm`, size: 0.01)
#eq(`1 m to`)
#eq(`1 m to cm to mm`)
#eq(`(1 m + 2 m`)

// `d` is the built-in day unit here, so this is inverse time, not inverse
// length. The mismatch must still be friendly feedback rather than a panic.
#eq($1 / d$, unit: $"linjer" / m$)

// A failed definition must not enter state.
#eq(`bad := 1 m + 2 s`)
#eq(`bad + 1`)
