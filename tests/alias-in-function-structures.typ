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

// Check nested values numerically as well as through the rendered snapshot.
#context {
  assert(eq().w.components.at(0).si-value == 6)
  assert(eq().w.components.at(1).si-value == 4)
  assert(eq().product.rows.at(1).at(1).si-value == 8)
}

// The output unit can be the only reference to an alias. Exercise all three
// accepted input forms and the state-update path for dependent assignments.
#let converted = calculation-builder(key: "output-alias-dependencies", strict: true, strict-units: true)
#rename-unit("cm", "short_length", key: "output-alias-dependencies")
#converted(`distance := 2 m`, hidden: true)
#converted(`as_string := distance`, unit: "short_length", hidden: true)
#converted(`as_raw := distance`, unit: `short_length`, hidden: true)
#converted(`as_math := distance`, unit: $"short_length"$, hidden: true)
#context {
  for name in ("as_string", "as_raw", "as_math") {
    let result = converted().at(name)
    assert(result.value == 200)
    assert(result.si-value == 2)
    assert(result.unit == "short_length")
    assert("display" in result)
  }
}
