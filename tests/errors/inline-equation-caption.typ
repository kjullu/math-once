#import "../../math-once.typ": equation

// This file must fail: captions need the vertical space of a block equation.
#equation($x = 2$, caption: [Not valid inline])
