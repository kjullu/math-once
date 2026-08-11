# Units and prefixes

`calculate` and `calculation-builder` track the seven SI base dimensions. Compatible units
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

## SI prefixes

Prefixes are resolved generically for supported SI units. Micro accepts `µ`,
`μ`, and ASCII `u`.

| Range | Symbols |
| --- | --- |
| yotta through kilo | `Y`, `Z`, `E`, `P`, `T`, `G`, `M`, `k` |
| hecto through deci | `h`, `da`, `d` |
| centi through yocto | `c`, `m`, `µ`/`μ`/`u`, `n`, `p`, `f`, `a`, `z`, `y` |

```typ
#calculate(`1 µm to nm`).display
#calculate(`1 MHz to Hz`).display
#calculate(`1 mV * 1 A`, unit: `mW`).display
```

## Supported units

| Dimension or group | Units |
| --- | --- |
| SI bases | `m`, `g`/`kg`, `s`, `A`, `K`, `mol`, `cd` |
| Time | `s`/`sec`, `min`, `h`/`hr`, `t`, `day`, `week` |
| Volume | `L`/`l` and derived `m^3` |
| Angles | `rad`, `sr`, `deg`, `degree`, `°` |
| Mechanical SI | `Hz`, `N`, `Pa`, `J`, `W` |
| Electrical SI | `C`, `V`, `F`, `ohm`/`Ω`, `S`, `Wb`, `T`, `H` |
| Other derived SI | `lm`, `lx`, `Bq`, `Gy`, `Sv`, `kat` |
| Energy and pressure | `Wh`, `eV`, `cal`, `bar`, `atm` |
| Imperial and common | `inch`, `ft`, `yd`, `mi`, `mph`, `kn`, `ton` |

`t` is accepted as the Danish abbreviation for hours. Arbitrary products,
quotients, and integer powers can be built from supported units.

```typ
#calculate(`1 MJ to kWh`).display
#calculate(`1 mph to km/h`).display
#calculate(`1 s^-1 to Hz`).display
```

## Limitations

- Unit names are reserved and take precedence over variables with the same
  name.
- Affine temperature scales such as Celsius and Fahrenheit are not supported.
  Kelvin is supported.
- Currencies and context-dependent conversions are not supported.
- A dimensioned value can only be raised to an integer power.

Incompatible operations fail instead of silently mixing dimensions. For
example, `10 m + 2 s` cannot add length and time, and `10 m to s` cannot
convert length to time.
