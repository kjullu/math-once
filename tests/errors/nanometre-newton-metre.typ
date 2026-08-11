#import "../../math-once.typ": calculate

// This file must fail: nm is a length while Nm is torque/energy.
#calculate(`1 nm + 1 Nm`)
