# TODO

## Address findings from the 0.35.0 external review

The following behavior was reproduced against the exact `math-once.typ` from version 0.35.0. Keep correctness fixes separate from optional API changes.

### Correctness bugs

- [ ] Give affine temperature arithmetic correct temperature-difference semantics.

  `30 celsius - 20 celsius` retains `10 K` internally but currently displays `-263.15 °C`. Do not apply an absolute Celsius offset to a difference. Either distinguish absolute temperatures from temperature differences throughout the evaluator or reject ambiguous affine arithmetic. Add direct and builder tests for Celsius and Fahrenheit subtraction before removing the documented Kelvin workaround below.

- [ ] Preserve physical dimensions when rendering mixed opaque and physical units.

  `2.35 "DKK"/kWh` keeps inverse-energy dimensions internally but displays a converted value with only `DKK`, omitting `/J`. Update the canonical opaque unit path to include both opaque and physical dimensions. Test direct display, stored substitution, `result-only`, and cancellation such as `1.4 kWh * tariff = 3.29 DKK`.

- [ ] Make stored `text-unit` results reusable.

  A builder can store a value with `unit: text-unit("panels")`, but retrieving it with `result-only: true` reparses `panels` as an unknown unit and panics. Preserve the internal text-unit marker in stored results and output-unit reconstruction. Cover plain labels and compound labels such as `text-unit("lines") / m`.

- [ ] Reject reserved unit names and built-in constants as stored function names.

  `m(x) := x + 1` is currently accepted even though `m` means metre. Apply the same catalog-unit, alias, built-in-constant, and unloaded-name rules to functions as to scalar assignments.

- [ ] Expand stored function calls to arbitrary practical depth.

  Three levels such as `h -> g -> f` fail because the implementation performs exactly two expansion passes. Replace those fixed passes with a bounded loop that stops when no calls remain, and detect direct and indirect cycles with a focused error.

### Diagnostics and optional API changes

- [ ] Improve incompatible-dimension errors by showing the actual source and target dimensions or units.

  `1200 W / 420 W` follows normal left-to-right precedence and means `(1200 W / 420) * W`, not `1200 W / (420 W)`. The current message, `cannot convert incompatible dimensions to incompatible dimensions`, does not reveal the resulting power-squared dimension or suggest parentheses.

- [ ] Consider a `strict: true` calculation-builder mode for CI.

  Normal builder errors render in red while Typst still exits successfully. Strict mode should panic on calculation errors so automated builds can catch broken equations. The existing friendly inline behavior should remain the default.

- [ ] Consider strict handling of unknown quoted unit names.

  Quoted unknown names intentionally become opaque custom units, which means a typo such as `"celcius"` is accepted. Possible designs include a strict-unit option or an explicit custom-unit constructor. Preserve the current behavior by default unless a deliberate breaking change is chosen.

- [ ] Add a native hidden-assignment option.

  The desired form is `#eq($x := 3 * 2$, hidden: true)`: store the exact value without visible output or layout space. Until then, `#place(hide[#eq($x := 3 * 2$)])` is the tested workaround.

- [ ] Add a call-level option that hides the substituted middle step while retaining the written expression and final result.

  This is separate from `show-result: false`, `result-only: true`, and a fully hidden assignment. It should shorten long calculation chains without hiding the answer.

### Documentation and packaging

- [ ] Fix the `rename-unit` example that assigns `d` after renaming metre to `v`. `d` is still the day unit, so the example currently renders an error. Use a non-reserved variable name or unload `d` explicitly.

- [ ] Isolate the plain `=` example in `doc/calculation-builder.md`. It claims that `x` remains unset, but the preceding example already stored `x` in the same builder state.

- [ ] Correct the public `calculate` doc comment that says `size:` cannot be combined with `unit:`. The implementation and detailed docs allow both.

- [ ] Check release-package contents against README and documentation links. The repository contains `examples/all-functions.typ`, `CHANGELOG.md`, `tests/qalc-units.typ`, and `tools/audit-qalc-units.py`, but the directory supplied for the external review did not. Ensure published archives either include linked files or link to their GitHub locations.

- [ ] Copy edit the README acknowledgements and name-history sections. Known mistakes include `math-one`, `variabels`, `adresses`, and `bare`.

- [ ] Turn the external review reproductions into permanent regression tests when each behavior is fixed. Include rendered-output checks for temperature differences and mixed opaque/physical units, since internal assertions alone did not catch the false visible results.

## Decide how to represent compound mathematical variable names

- [ ] Choose a syntax and storage rule for names such as the temperature
  difference `ΔT`.

The desired input is similar to:

```typ
#eq($"Delta T" := T_0 - T_3$)
#eq($"Delta T"$)
```

Quoted names with spaces are not currently accepted by the tokenizer,
assignment parser, or focused reset functions. If added, a quoted name on the
left of `:=` could always mean a variable. The same quoted name could then
refer to that variable in later expressions. Before a variable exists, quoted
text would retain its current unit meaning.

Decisions still needed:

- Keep the exact state key `"Delta T"`, or normalize it to `Delta_T`.
- Render the name as literal upright text, `Delta T`, or recognize mathematical
  words and render it as `ΔT`.
- Decide whether quoted mathematical words such as `Delta`, `theta`, and
  `lambda` should receive the same rendering rule.
- Keep quoted compound names separate from the existing `$Delta_T$` syntax,
  which already works but renders T as a subscript.

There is also a separate temperature-unit issue. `13 degree C` currently means
13 degrees multiplied by the coulomb unit `C`; it does not mean 13 degrees
Celsius. Celsius input should use `13 "°C"` or `13 celsius`. Subtracting two
absolute Celsius values also needs explicit temperature-difference semantics.
Until that is implemented, convert stored absolute temperatures to Kelvin
before calculating their difference.
