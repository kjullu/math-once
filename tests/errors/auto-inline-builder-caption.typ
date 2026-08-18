#import "../../math-once.typ": calculation-builder

#let eq = calculation-builder(key: "auto-inline-caption")

// Compact Typst math is inline under block:auto, so it cannot hold a caption.
#eq($1 + 1$, caption: [Invalid inline caption])
