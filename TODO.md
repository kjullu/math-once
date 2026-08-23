# TODO

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
