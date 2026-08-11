# Units and prefixes

`calculate` and `calculation-builder` track the seven SI base dimensions plus
information and logarithmic-ratio dimensions. Compatible units
are converted before addition or subtraction, while multiplication, division,
and integer powers combine dimensions.

```typ
#calculate(`10 m/s + 1 km/h`).display
#calculate(`2 N * 3 m`).display
#calculate(`(2 m + 30 cm)^2`).display
```

## Output conversion

Select an output unit with `to`, `=`, or the `unit` parameter:

```typ
#calculate(`10 m/s to km/h`).display
#calculate(`10 m/s = km/h`).display
#calculate(`10 m/s`, unit: `km/h`).display
```

Use only one conversion form in each call. The target must have the same
dimensions as the result. On a plain number, `unit` assigns the requested
physical unit:

```typ
#calculate($902 / 3.6$, unit: $m/s$, digits: 2).display
// 902/3.6 = 250.56 m/s
```

Unit symbols are rendered upright, following normal mathematical typography.

## Custom output labels

Quote an unknown name inside a Typst math unit to use it as a symbolic count
label. This is useful for results such as lines per metre:

```typ
#let eq = calculation-builder(key: "line-density", digits: 0)
#unload($d$, key: "line-density")
#eq($d := 0.5 "mm"$)
#eq($1 / d$, unit: $"linjer" / m$)
// 1/d = 1/(0.5 mm) = 2000 linjer/m
```

The quoted custom part has scale one and is dimensionless, while known parts
of the unit expression are still checked and converted. Consequently,
`$"linjer"/m$` is compatible with inverse length, but not with an ordinary
length.

Use math syntax around the output unit so quoted custom names remain explicit:
`unit: $"linjer"/m$`. A known quoted name retains its catalog meaning, so
`unit: $"cm"/h$` still means centimetres per hour. An unquoted unknown name is
an error, which helps catch misspelled units.

In this example, `d` is first passed to `unload` because it is also a catalog
spelling for the day unit. This lets the builder use it as a variable until the
next complete reset.

## SI prefixes

Prefixes are resolved generically for supported SI units. Micro accepts `µ`,
`μ`, and ASCII `u`.

| Range | Symbols |
| --- | --- |
| yotta through kilo | `Y`, `Z`, `E`, `P`, `T`, `G`, `M`, `k` |
| hecto through deci | `h`, `da`, `d` |
| centi through yocto | `c`, `m`, `µ`/`μ`/`u`, `n`, `p`, `f`, `a`, `z`, `y` |
| 2022 SI extensions | `Q`, `R`, `r`, `q` |
| Binary prefixes | `Ki`, `Mi`, `Gi`, `Ti`, `Pi`, `Ei`, `Zi`, `Yi`, `Ri`, `Qi` |

```typ
#calculate(`1 µm to nm`).display
#calculate(`1 MHz to Hz`).display
#calculate(`1 mV * 1 A`, unit: `mW`).display
```

## Supported units

| Dimension or group | Units |
| --- | --- |
| SI bases | `m`/`meter`/`metre`, `g`/`kg`, `s`, `A`, `K`, `mol`, `cd` |
| Length | `km`, `dm`, `cm`, `mm`, `µm`/`μm`/`um`, `nm`, `pm` |
| Time | `s`/`sec`, `min`, `h`/`hr`, `t`, `day`, `week` |
| Volume | `L`/`l` and derived `m^3` |
| Angles | `rad`, `sr`, `deg`, `degree`, `°` |
| Mechanical SI | `Hz`, `N`, `Nm`, `Ncm`, `Nmm`, `Pa`, `J`, `W` |
| Electrical SI | `C`, `V`, `F`, `ohm`/`Ω`, `S`, `Wb`, `T`, `H` |
| Other derived SI | `lm`, `lx`, `Bq`, `Gy`, `Sv`, `kat` |
| Energy and pressure | `Wh`, `eV`, `cal`, `bar`, `atm` |
| Imperial and common | `inch`, `ft`, `yd`, `mi`, `mph`, `kn`, `ton` |

The built-in catalog mirrors 244 of the 246 named unit groups shipped by
Qalculate 5.10, including their listed aliases. This adds astronomical and
Planck units, CGS/electromagnetic units, US and Imperial volume, area, mass,
force and pressure units, photometric units, typography units, data units,
calendar durations, temperature scales, and historical/scientific units.
For example:

```typ
#calculate(`1 pc to ly`).display
#calculate(`1 acre to m^2`).display
#calculate(`1 hp to W`).display
#calculate(`1 KiB to bit`).display
#calculate(`32 fahrenheit to celsius`).display
```

The complete machine-checked spelling list is in `tests/qalc-units.typ`.
`tools/audit-qalc-units.py` records how the static catalog is checked against
the installed qalc data; qalc is not a runtime dependency.

For backwards compatibility, math-once keeps `t` as the Danish abbreviation
for hours. Qalculate uses `t` for tonnes; use `tonne` or `ton` for that unit in
math-once.

`t` is accepted as the Danish abbreviation for hours. Arbitrary products,
quotients, and integer powers can be built from supported units.

Unit symbols are case-sensitive. In particular:

- `nm` is a nanometre (`10^-9 m`).
- `Nm` is a newton metre, used for torque and dimensionally equivalent to `J`.
- `mN` is a millinewton (`10^-3 N`).
- `Nmm` is a newton millimetre (`10^-3 Nm`).

```typ
#calculate(`530 nm to µm`).display
#calculate(`2 N * 3 m`, unit: `Nm`).display
#calculate(`1 kNm to Nm`).display
```

```typ
#calculate(`1 MJ to kWh`).display
#calculate(`1 mph to km/h`).display
#calculate(`1 s^-1 to Hz`).display
```

## Limitations

- Unit names are reserved and take precedence over variables with the same
  name.
- Celsius, Fahrenheit, Kelvin, and Rankine are supported. Affine temperature
  names must be multiplied by a plain number (for example, `20 celsius`).
- Qalculate's `dBW` and `dBm` are not supported because they are logarithmic
  power-level transforms rather than fixed linear or affine units.
- Currencies and context-dependent conversions are not supported.
- A dimensioned value can only be raised to an integer power.

Incompatible operations fail instead of silently mixing dimensions. For
example, `10 m + 2 s` cannot add length and time, and `10 m to s` cannot
convert length to time.
