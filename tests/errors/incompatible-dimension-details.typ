#import "../../math-once.typ": calculate

// Left-to-right precedence makes this power squared, not a dimensionless ratio.
#calculate(`1200 W / 420 W`, unit: `J`).display
