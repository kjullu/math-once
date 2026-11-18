#import "../math-once.typ": calculation-builder

#set page(width: 25cm, height: auto)
#let eq = calculation-builder(key: "structure-copy-order")
#eq(`v_1 := vec(1, 2) m`, hidden: true)
#eq(`v_2 := v_1`, hidden: true)
#eq(`v_3 := (v_2)`, hidden: true)
#eq(`M_1 := mat(1, 2; 3, 4)`, hidden: true)
#eq(`M_2 := M_1`, hidden: true)
#eq(`M_3 := (M_1)`, hidden: true)

#context {
  let values = eq()
  for (copy, original) in (("v_2", "v_1"), ("v_3", "v_1"), ("M_2", "M_1"), ("M_3", "M_1")) {
    let result = values.at(copy)
    let source = values.at(original)
    assert(result.keys() == source.keys(), message: copy)
    assert(result.variable == copy)
    assert(result.display.func() == math.equation)
    if "components" in result { assert(result.components == source.components) }
    if "rows" in result { assert(result.rows == source.rows) }
    [#copy: #repr(result.keys()) #linebreak()]
  }
}

// Supplied result dictionaries may have a different order. Preserve that too,
// rather than rebuilding every result with display before variable.
#context {
  let original = eq().v_1
  let variable = original.remove("variable")
  let display = original.remove("display")
  original.insert("variable", variable)
  original.insert("display", display)
  let initial = calculation-builder(key: "structure-copy-initial", initial-state: (seed: original))
  initial(`copied := seed`, hidden: true)
  context {
    let result = initial().copied
    assert(result.keys() == original.keys())
    assert(result.variable == "copied")
    [initial copy: #repr(result.keys())]
  }
}
