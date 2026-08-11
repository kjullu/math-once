#import "../../math-once.typ": number-labelled-equations

// This file must fail: captions are keyed by label name in a dictionary.
#show: number-labelled-equations.with(captions: [not a dictionary])

$ E = m c^2 $ <energy>
