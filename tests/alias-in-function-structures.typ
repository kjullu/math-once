#import "../math-once.typ": calculation-builder, rename-unit

// A renamed unit used only inside a stored function body and inside stored
// vectors and matrices still resolves when those values are reused.
#set page(width: 24cm, height: auto)
#let eq = calculation-builder(strict: true, strict-units: true)
#rename-unit("m", "foo_bar")
#eq(`f(x) := vec(x foo_bar, 2 foo_bar)`)
#eq(`v := f(3)`)
#eq(`M := mat(1 foo_bar, 2 foo_bar; 3 foo_bar, 4 foo_bar)`)
#eq(`w := v * 2`)
#eq(`product := M * 2`)
#context [#repr(eq())]
