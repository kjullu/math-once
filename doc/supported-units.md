# Supported units

This page lists every named unit and alias supported by `calculate` and
`calculation-builder`. Unit names are case-sensitive.

## Prefixes

Supported SI prefixes: `Q`, `R`, `Y`, `Z`, `E`, `P`, `T`, `G`, `M`,
`k`, `h`, `da`, `d`, `c`, `m`, `µ`/`μ`/`u`, `n`, `p`, `f`, `a`,
`z`, `y`, `r`, and `q`.

Bits and bytes also support binary prefixes: `Ki`, `Mi`, `Gi`, `Ti`,
`Pi`, `Ei`, `Zi`, `Yi`, `Ri`, and `Qi`.

Prefixes combine with supported prefixable units, so forms such as
`nm`, `kPa`, `MHz`, `mV`, `kWh`, `MB`, and `GiB` do not need separate
entries below. Products, quotients, and integer powers such as `m/s`,
`kg/m^3`, and `N*m` are also supported.

## math-once additions

| Purpose | Accepted names |
| --- | --- |
| Danish hours | `t`, `timer` |
| Knot abbreviation | `kn` |
| Newton metre | `Nm`, `Ncm`, `Nmm` |
| Watt-hour | `Wh` |

`t` deliberately means hours for backwards compatibility. Use `tonne`
or `ton` for tonnes.

## Qalculate-compatible catalog

The table contains 244 supported Qalculate unit groups and
all of their usable listed aliases.

| Unit group | Accepted names |
| --- | --- |
| abampere | `abampere`, `abA`, `Bi`, `biot` |
| abcoulomb | `abcoulomb`, `abC`, `aC` |
| abhenry | `abhenry`, `abH` |
| abohm | `abohm`, `abΩ` |
| abvolt | `abvolt`, `abV` |
| acre | `acre` |
| agate | `agate` |
| ampere | `ampere`, `A`, `amp` |
| angstrom | `angstrom`, `Å`, `ångström` |
| arcminute | `arcminute`, `arcmin` |
| arcsecond | `arcsecond`, `arcsec` |
| are | `are`, `a` |
| AstronomicalUnit | `AstronomicalUnit`, `au` |
| atmosphere | `atmosphere`, `atm` |
| AtomicMassUnit | `AtomicMassUnit`, `u`, `AMU` |
| bar | `bar` |
| barn | `barn`, `b` |
| barrel | `barrel`, `bbl` |
| barye | `barye`, `Ba` |
| becquerel | `becquerel`, `Bq` |
| bel | `bel` |
| bit | `bit`, `shannon`, `Sh`, `BinaryDigit` |
| BohrUnit | `BohrUnit` |
| BoltzmannUnit | `BoltzmannUnit`, `k_Bunit` |
| Btu | `Btu` |
| bushel | `bushel`, `bu` |
| byte | `byte`, `B`, `octet`, `o` |
| c_unit | `c_unit` |
| cal_fifteen | `cal_fifteen` |
| cal_IT | `cal_IT` |
| cal_mean | `cal_mean` |
| Calorie | `Calorie` |
| calorie | `calorie`, `cal` |
| candela | `candela`, `cd` |
| carat | `carat` |
| celsius | `celsius`, `oC`, `°C`, `℃`, `centigrade` |
| cfm | `cfm` |
| cfs | `cfs` |
| chain | `chain`, `ch` |
| cicero | `cicero` |
| cmil | `cmil` |
| coulomb | `coulomb`, `C` |
| cup | `cup` |
| curie | `curie`, `Ci` |
| dalton | `dalton`, `Da` |
| daraf | `daraf` |
| darcy | `darcy` |
| day | `day`, `d` |
| debye | `debye`, `D` |
| decare | `decare`, `da` |
| decibel | `decibel`, `dB` |
| declet | `declet` |
| degree | `degree`, `deg`, `°` |
| dessertspoon | `dessertspoon` |
| didot | `didot`, `dd` |
| dram | `dram`, `dr` |
| DryPint | `DryPint`, `dry_pt` |
| DryQuart | `DryQuart`, `dry_qt` |
| dyne | `dyne`, `dyn` |
| e_unit | `e_unit`, `q_A` |
| einstein | `einstein` |
| ElectronUnit | `ElectronUnit`, `m_eunit` |
| electronvolt | `electronvolt`, `eV` |
| erg | `erg` |
| fahrenheit | `fahrenheit`, `oF`, `°F`, `℉` |
| farad | `farad`, `F` |
| fathom | `fathom` |
| FluidDrachm | `FluidDrachm`, `fl_dr` |
| FluidOunce | `FluidOunce`, `fl_oz` |
| foe | `foe` |
| foot | `foot`, `ft` |
| FootCandle | `FootCandle`, `fc` |
| FootLambert | `FootLambert` |
| fortnight | `fortnight` |
| furlong | `furlong`, `fur` |
| galileo | `galileo`, `Gal` |
| gallon | `gallon`, `gal` |
| gauss | `gauss` |
| gee | `gee` |
| gill | `gill`, `gi` |
| gph | `gph` |
| gpm | `gpm` |
| gradian | `gradian`, `gra`, `gon` |
| grain | `grain`, `gr` |
| gram | `gram`, `g` |
| gramTNT | `gramTNT`, `gTNT` |
| gray | `gray`, `Gy` |
| GregorianYear | `GregorianYear`, `a_g` |
| hand | `hand` |
| hartley | `hartley`, `Hart`, `dit`, `DecimalDigit` |
| hartree | `hartree`, `Ha`, `E_h` |
| hectare | `hectare`, `ha` |
| henry | `henry`, `H` |
| hertz | `hertz`, `Hz` |
| horsepower | `horsepower`, `hp` |
| hour | `hour`, `h`, `hr`, `hrs` |
| hundredweight | `hundredweight`, `cwt`, `cental`, `centals` |
| ImperialBushel | `ImperialBushel`, `bu_UK` |
| ImperialFluidDrachm | `ImperialFluidDrachm`, `fl_dr_UK` |
| ImperialFluidOunce | `ImperialFluidOunce`, `fl_oz_UK` |
| ImperialFluidScruple | `ImperialFluidScruple` |
| ImperialGallon | `ImperialGallon`, `gal_UK` |
| ImperialGill | `ImperialGill`, `gi_UK` |
| ImperialMinim | `ImperialMinim` |
| ImperialPint | `ImperialPint`, `pt_UK` |
| ImperialQuart | `ImperialQuart`, `qt_UK` |
| inch | `inch`, `in` |
| inHg | `inHg` |
| inWC | `inWC`, `iwg`, `inH₂O` |
| JohnsonPica | `JohnsonPica` |
| joule | `joule`, `J` |
| katal | `katal`, `kat` |
| kayser | `kayser` |
| kcmil | `kcmil`, `MCM` |
| kelvin | `kelvin`, `K` |
| knot | `knot` |
| ksi | `ksi` |
| l_N | `l_N`, `ƛ_unit` |
| lambert | `lambert` |
| LightHour | `LightHour` |
| LightMinute | `LightMinute` |
| LightSecond | `LightSecond` |
| lightyear | `lightyear`, `ly` |
| ligne | `ligne` |
| link | `link`, `li` |
| LiquidPint | `LiquidPint`, `liq_pt` |
| LiquidQuart | `LiquidQuart`, `liq_qt` |
| liter | `liter`, `L`, `l`, `litre` |
| LongHundredweight | `LongHundredweight`, `l_cwt` |
| LongTon | `LongTon`, `l_ton` |
| lumen | `lumen`, `lm` |
| lux | `lux`, `lx` |
| maxwell | `maxwell`, `Mx` |
| meter | `meter`, `m`, `metre` |
| micron | `micron` |
| mile | `mile`, `mi` |
| minim | `minim` |
| minute | `minute`, `min` |
| mmHg | `mmHg` |
| molar | `molar` |
| mole | `mole`, `mol` |
| month | `month` |
| mpg | `mpg` |
| mph | `mph` |
| mWC | `mWC`, `mwg`, `mH₂O` |
| nat | `nat` |
| NauticalMile | `NauticalMile`, `nmi` |
| neper | `neper`, `Np` |
| NewDidot | `NewDidot` |
| newton | `newton`, `N` |
| nibble | `nibble`, `nybble`, `semioctet`, `HexDigit`, `HexadecimalDigit` |
| nonet | `nonet` |
| OctalDigit | `OctalDigit` |
| oersted | `oersted`, `Oe` |
| ohm | `ohm`, `Ω` |
| ounce | `ounce`, `oz` |
| OunceForce | `OunceForce`, `ozf` |
| parsec | `parsec`, `pc` |
| pascal | `pascal`, `Pa` |
| peck | `peck`, `pk` |
| pennyweight | `pennyweight`, `pwt` |
| pfund | `pfund` |
| phot | `phot`, `ph` |
| pica | `pica` |
| PiedDuRoi | `PiedDuRoi` |
| PlanckCharge | `PlanckCharge`, `q_P` |
| PlanckLength | `PlanckLength`, `l_P` |
| PlanckMass | `PlanckMass`, `m_P` |
| PlanckTemperature | `PlanckTemperature`, `T_P` |
| PlanckTime | `PlanckTime`, `t_P` |
| PlanckUnit | `PlanckUnit`, `ℏ_unit` |
| point | `point`, `pt`, `pts`, `bp_tex` |
| poise | `poise`, `P` |
| pond | `pond`, `gf` |
| pouce | `pouce` |
| pound | `pound`, `lb` |
| poundal | `poundal`, `pdl` |
| PoundForce | `PoundForce`, `lbf` |
| PS | `PS`, `pferdestärke` |
| psi | `psi` |
| RackUnit | `RackUnit`, `U`, `RU` |
| radian | `radian`, `rad` |
| RadRadioactivity | `RadRadioactivity` |
| rankine | `rankine`, `oR`, `oRa`, `°R`, `°Ra` |
| rem | `rem` |
| rod | `rod`, `rd` |
| roentgen | `roentgen`, `R`, `röntgen` |
| rood | `rood` |
| rpm | `rpm` |
| rutherford | `rutherford`, `Rd` |
| RydbergUnit | `RydbergUnit`, `Ry` |
| second | `second`, `s` |
| section | `section` |
| ShortTon | `ShortTon`, `s_ton` |
| siemens | `siemens`, `S` |
| sievert | `sievert`, `Sv` |
| slug | `slug` |
| SolarLuminosity | `SolarLuminosity`, `L_☉` |
| SolarMass | `SolarMass`, `M_☉` |
| SolarRadius | `SolarRadius`, `R_☉` |
| statcoulomb | `statcoulomb`, `statC`, `franklin`, `Fr`, `esu` |
| statohm | `statohm`, `statΩ` |
| statvolt | `statvolt`, `statV` |
| steradian | `steradian`, `sr` |
| stilb | `stilb`, `sb` |
| stokes | `stokes`, `St` |
| stone | `stone` |
| sverdrup | `sverdrup` |
| tablespoon | `tablespoon` |
| teaspoon | `teaspoon` |
| tesla | `tesla`, `T` |
| TexPoint | `TexPoint`, `pt_TeX` |
| TexScaledPoint | `TexScaledPoint`, `sp_TeX` |
| therm | `therm`, `thm` |
| thermie | `thermie`, `th` |
| ThermISO | `ThermISO`, `thm_ISO` |
| ThermUS | `ThermUS`, `thm_US` |
| thou | `thou`, `mil` |
| toise | `toise` |
| tonne | `tonne`, `ton` |
| TonRefrigaration | `TonRefrigaration`, `TOR` |
| tonTNT | `tonTNT`, `tTNT` |
| torr | `torr`, `Torr` |
| township | `township` |
| tribble | `tribble` |
| trit | `trit`, `TrinaryDigit`, `TernaryDigit` |
| TropicalYear | `TropicalYear`, `a_t` |
| TroyOunce | `TroyOunce`, `oz_t` |
| TroyPound | `TroyPound`, `lb_t` |
| turn | `turn`, `tr`, `pla`, `rev`, `revolution`, `cyc`, `cycle` |
| twip | `twip` |
| US_foot | `US_foot`, `ft_US` |
| US_inch | `US_inch`, `in_US` |
| US_mile | `US_mile`, `mi_US` |
| US_point | `US_point`, `pt_US` |
| US_rod | `US_rod`, `rd_US` |
| volt | `volt`, `V` |
| watt | `watt`, `W` |
| weber | `weber`, `Wb` |
| week | `week` |
| word | `word` |
| yard | `yard`, `yd` |
| year | `year`, `a_j`, `yr`, `annus` |
| zentner | `zentner` |

## Unsupported qalc units

`dBW`, `dBm` are logarithmic power-level
transforms rather than fixed linear or affine units, so they are not
supported. Currencies and context-dependent conversions are also outside
the static unit system.
