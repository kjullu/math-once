#import "../../math-once.typ": calculate

// Direct calculate calls remain strict when bars do not form an absolute value.
#calculate(`|-3`)
