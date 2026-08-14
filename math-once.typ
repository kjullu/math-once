// math-once v0.26.0
// Reusable calculations with a unit-aware evaluator.

/// Evaluate a trusted numerical expression, prepare a visible equation, and
/// return both the rounded and exact values.
///
/// - `source`: A trusted Typst code expression as a string or raw block.
/// - `digits`: Decimal places used for the visible `value`. Default: `0`.
/// - `scope`: Values made available to the expression. Earlier `evaluate-code`
///   results are automatically unwrapped to their exact value.
/// - `unit`: Optional display label as a string, raw block, math, or content.
/// - `block`: Whether the rendered equation is centered. Default: `false`.
///
/// Returns a dictionary with `display`, `value`, `exact`, `source`, and `unit`.
/// Only pass expressions you trust: this function uses unrestricted `eval`.
#let evaluate-code(source, digits: 0, scope: (:), unit: none, block: false) = {
  let source = if type(source) == str {
    source
  } else if type(source) == content and source.func() == raw {
    source.text
  } else {
    panic("math-once: source must be a string or raw text")
  }

  source = source.trim()
  if source == "" {
    panic("math-once: source must not be empty")
  }

  let evaluation-scope = (:)
  for (name, item) in scope {
    let item = if type(item) == dictionary and "exact" in item {
      item.exact
    } else {
      item
    }
    evaluation-scope.insert(name, item)
  }

  let exact = eval(source, mode: "code", scope: evaluation-scope)
  if type(exact) not in (int, float, decimal) {
    panic("math-once: expression must evaluate to an int, float, or decimal")
  }

  let value = calc.round(exact, digits: digits)
  let rendered = eval(
    source + " = #result",
    mode: "math",
    scope: (result: value),
  )

  let unit-body = if unit == none {
    none
  } else if type(unit) == str {
    text(unit)
  } else if type(unit) == content and unit.func() == raw {
    text(unit.text)
  } else if type(unit) == content and unit.func() == math.equation {
    unit.body
  } else if type(unit) == content {
    unit
  } else {
    panic("math-once: unit must be a string, raw text, math, content, or none")
  }

  let display-body = rendered.body
  if unit-body != none {
    display-body += h(0.2em) + math.upright(unit-body)
  }

  (
    value: value,
    exact: exact,
    display: math.equation(display-body, block: block),
    source: source,
    unit: unit,
  )
}

// The show rule exposes the current equation label to its caption without
// replacing the original, referenceable math.equation element.
#let _caption-label = state("math-once-caption-label", none)

// Keep captions inside the equation element. This lets a postfix label attach
// to the real math.equation instead of to a surrounding layout container. The
// metadata makes the caption available to equation-outline without displaying
// anything extra.
#let _captioned-body(body, caption, gap) = if caption == none {
  body
} else {
  let visible-caption = context {
    let label = _caption-label.get()
    let prefix = if label == none { none } else { [#ref(label): ] }
    text(size: 0.9em)[#prefix#caption]
  }
  stack(
    dir: ttb,
    spacing: gap,
    align(center, body),
    align(center, visible-caption + metadata((
      kind: "math-once-caption",
      body: caption,
    ))),
  )
}

#let _equation-caption(equation) = {
  if equation.body.func() != stack or not equation.body.has("children") {
    return none
  }
  let children = equation.body.children
  if children.len() != 2 or children.at(1).func() != align {
    return none
  }
  let caption-line = children.at(1).body
  if not caption-line.has("children") {
    return none
  }
  let marker = caption-line.children.last()
  if marker.func() != metadata or type(marker.value) != dictionary {
    return none
  }
  if marker.value.at("kind", default: none) != "math-once-caption" {
    return none
  }
  marker.value.body
}

#let _make-equation(body, block, supplement) = if supplement == auto {
  math.equation(body, block: block)
} else {
  math.equation(body, block: block, supplement: supplement)
}

// Everything in this dictionary is an implementation detail. Keeping the
// parser in one value leaves only the documented wrappers below as public API.
#let _engine = {

let zero-dim = (
  length: 0,
  mass: 0,
  time: 0,
  current: 0,
  temperature: 0,
  amount: 0,
  luminosity: 0,
  information: 0,
  logratio: 0,
)

let dim(..values) = {
  let result = zero-dim
  for (name, value) in values.named() {
    result.insert(name, value)
  }
  result
}

let units = (
  m:   (scale: 1.0, dims: dim(length: 1)),
  km:  (scale: 1000.0, dims: dim(length: 1)),
  dm:  (scale: 0.1, dims: dim(length: 1)),
  cm:  (scale: 0.01, dims: dim(length: 1)),
  mm:  (scale: 0.001, dims: dim(length: 1)),
  um:  (scale: 0.000001, dims: dim(length: 1)),
  nm:  (scale: 0.000000001, dims: dim(length: 1)),
  pm:  (scale: 0.000000000001, dims: dim(length: 1)),
  s:   (scale: 1.0, dims: dim(time: 1)),
  min: (scale: 60.0, dims: dim(time: 1)),
  h:   (scale: 3600.0, dims: dim(time: 1)),
  t:   (scale: 1000.0, dims: dim(mass: 1)),
  g:   (scale: 0.001, dims: dim(mass: 1)),
  kg:  (scale: 1.0, dims: dim(mass: 1)),
  L:   (scale: 0.001, dims: dim(length: 3)),
  mL:  (scale: 0.000001, dims: dim(length: 3)),
  Hz:  (scale: 1.0, dims: dim(time: -1)),
  N:   (scale: 1.0, dims: dim(length: 1, mass: 1, time: -2)),
  Nm:  (scale: 1.0, dims: dim(length: 2, mass: 1, time: -2)),
  Ncm: (scale: 0.01, dims: dim(length: 2, mass: 1, time: -2)),
  Nmm: (scale: 0.001, dims: dim(length: 2, mass: 1, time: -2)),
  Pa:  (scale: 1.0, dims: dim(length: -1, mass: 1, time: -2)),
  J:   (scale: 1.0, dims: dim(length: 2, mass: 1, time: -2)),
  W:   (scale: 1.0, dims: dim(length: 2, mass: 1, time: -3)),
  A:   (scale: 1.0, dims: dim(current: 1)),
  K:   (scale: 1.0, dims: dim(temperature: 1)),
  mol: (scale: 1.0, dims: dim(amount: 1)),
  cd:  (scale: 1.0, dims: dim(luminosity: 1)),
  rad: (scale: 1.0, dims: dim()),
  sr:  (scale: 1.0, dims: dim()),
  deg: (scale: calc.pi / 180, dims: dim()),
  C:   (scale: 1.0, dims: dim(time: 1, current: 1)),
  V:   (scale: 1.0, dims: dim(length: 2, mass: 1, time: -3, current: -1)),
  F:   (scale: 1.0, dims: dim(length: -2, mass: -1, time: 4, current: 2)),
  ohm: (scale: 1.0, dims: dim(length: 2, mass: 1, time: -3, current: -2)),
  S:   (scale: 1.0, dims: dim(length: -2, mass: -1, time: 3, current: 2)),
  Wb:  (scale: 1.0, dims: dim(length: 2, mass: 1, time: -2, current: -1)),
  T:   (scale: 1.0, dims: dim(mass: 1, time: -2, current: -1)),
  H:   (scale: 1.0, dims: dim(length: 2, mass: 1, time: -2, current: -2)),
  lm:  (scale: 1.0, dims: dim(luminosity: 1)),
  lx:  (scale: 1.0, dims: dim(length: -2, luminosity: 1)),
  Bq:  (scale: 1.0, dims: dim(time: -1)),
  Gy:  (scale: 1.0, dims: dim(length: 2, time: -2)),
  Sv:  (scale: 1.0, dims: dim(length: 2, time: -2)),
  kat: (scale: 1.0, dims: dim(time: -1, amount: 1)),
  Wh:  (scale: 3600.0, dims: dim(length: 2, mass: 1, time: -2)),
  bar: (scale: 100000.0, dims: dim(length: -1, mass: 1, time: -2)),
  atm: (scale: 101325.0, dims: dim(length: -1, mass: 1, time: -2)),
  eV:  (scale: 1.602176634e-19, dims: dim(length: 2, mass: 1, time: -2)),
  cal: (scale: 4.184, dims: dim(length: 2, mass: 1, time: -2)),
  day: (scale: 86400.0, dims: dim(time: 1)),
  week: (scale: 604800.0, dims: dim(time: 1)),
  ton: (scale: 1000.0, dims: dim(mass: 1)),
  inch: (scale: 0.0254, dims: dim(length: 1)),
  ft: (scale: 0.3048, dims: dim(length: 1)),
  yd: (scale: 0.9144, dims: dim(length: 1)),
  mi: (scale: 1609.344, dims: dim(length: 1)),
  kn: (scale: 1852.0 / 3600, dims: dim(length: 1, time: -1)),
  mph: (scale: 1609.344 / 3600, dims: dim(length: 1, time: -1)),
)

// Symbol and spelling aliases that cannot all be written as dictionary keys.
units.insert("Ω", units.ohm)
units.insert("°", units.deg)
units.insert("degree", units.deg)
units.insert("meter", units.m)
units.insert("metre", units.m)
units.insert("µm", units.um)
units.insert("μm", units.um)
units.insert("l", units.L)
units.insert("sec", units.s)
units.insert("hr", units.h)

// Generated from Qalculate 5.10's built-in unit catalog; see
// tools/audit-qalc-units.py. Runtime use remains dependency-free.
let qalc-unit-definitions = (
  (names: ("AstronomicalUnit", "au"), scale: 149597870700, dims: dim(length: 1)),
  (names: ("AtomicMassUnit", "u", "AMU"), scale: 1.66053907e-27, dims: dim(mass: 1)),
  (names: ("BohrUnit",), scale: 5.2917721e-11, dims: dim(length: 1)),
  (names: ("BoltzmannUnit", "k_Bunit"), scale: 1.380649e-23, dims: dim(mass: 1, length: 2, temperature: -1, time: -2)),
  (names: ("Btu",), scale: 1055.05585262, dims: dim(mass: 1, length: 2, time: -2)),
  (names: ("Calorie",), scale: 4184, dims: dim(mass: 1, length: 2, time: -2)),
  (names: ("DryPint", "dry_pt"), scale: 0.0005506104713575, dims: dim(length: 3)),
  (names: ("DryQuart", "dry_qt"), scale: 0.001101220942715, dims: dim(length: 3)),
  (names: ("ElectronUnit", "m_eunit"), scale: 9.1093837139e-31, dims: dim(mass: 1)),
  (names: ("FluidDrachm", "fl_dr"), scale: 3.696691195313e-06, dims: dim(length: 3)),
  (names: ("FluidOunce", "fl_oz"), scale: 2.95735295625e-05, dims: dim(length: 3)),
  (names: ("FootCandle", "fc"), scale: 10.763910417, dims: dim(luminosity: 1, length: -2)),
  (names: ("FootLambert",), scale: 3.4262591, dims: dim(luminosity: 1, length: -2)),
  (names: ("GregorianYear", "a_g"), scale: 31556952, dims: dim(time: 1)),
  (names: ("ImperialBushel", "bu_UK"), scale: 0.03636872, dims: dim(length: 3)),
  (names: ("ImperialFluidDrachm", "fl_dr_UK"), scale: 3.5516328125e-06, dims: dim(length: 3)),
  (names: ("ImperialFluidOunce", "fl_oz_UK"), scale: 2.84130625e-05, dims: dim(length: 3)),
  (names: ("ImperialFluidScruple",), scale: 1.183877604167e-06, dims: dim(length: 3)),
  (names: ("ImperialGallon", "gal_UK"), scale: 0.00454609, dims: dim(length: 3)),
  (names: ("ImperialGill", "gi_UK"), scale: 0.0001420653125, dims: dim(length: 3)),
  (names: ("ImperialMinim",), scale: 5.9193880208e-08, dims: dim(length: 3)),
  (names: ("ImperialPint", "pt_UK"), scale: 0.00056826125, dims: dim(length: 3)),
  (names: ("ImperialQuart", "qt_UK"), scale: 0.0011365225, dims: dim(length: 3)),
  (names: ("JohnsonPica",), scale: 0.0042164, dims: dim(length: 1)),
  (names: ("LightHour",), scale: 1079252848800, dims: dim(length: 1)),
  (names: ("LightMinute",), scale: 17987547480, dims: dim(length: 1)),
  (names: ("LightSecond",), scale: 299792458, dims: dim(length: 1)),
  (names: ("LiquidPint", "liq_pt"), scale: 0.000473176473, dims: dim(length: 3)),
  (names: ("LiquidQuart", "liq_qt"), scale: 0.000946352946, dims: dim(length: 3)),
  (names: ("LongHundredweight", "l_cwt"), scale: 50.80234544, dims: dim(mass: 1)),
  (names: ("LongTon", "l_ton"), scale: 1016.0469088, dims: dim(mass: 1)),
  (names: ("NauticalMile", "nmi"), scale: 1852, dims: dim(length: 1)),
  (names: ("NewDidot",), scale: 0.000375, dims: dim(length: 1)),
  (names: ("OctalDigit",), scale: 3, dims: dim(information: 1)),
  (names: ("OunceForce", "ozf"), scale: 0.278013850954, dims: dim(mass: 1, length: 1, time: -2)),
  (names: ("PS", "pferdestärke"), scale: 735.49875, dims: dim(mass: 1, length: 2, time: -3)),
  (names: ("PiedDuRoi",), scale: 0.324839384971, dims: dim(length: 1)),
  (names: ("PlanckCharge", "q_P"), scale: 1.87554604e-18, dims: dim(current: 1, time: 1)),
  (names: ("PlanckLength", "l_P"), scale: 1.616255e-35, dims: dim(length: 1)),
  (names: ("PlanckMass", "m_P"), scale: 2.176e-08, dims: dim(mass: 1)),
  (names: ("PlanckTemperature", "T_P"), scale: 1.416784e32, dims: dim(temperature: 1)),
  (names: ("PlanckTime", "t_P"), scale: 5.391247e-44, dims: dim(time: 1)),
  (names: ("PlanckUnit", "ℏ_unit"), scale: 1.054571817e-34, dims: dim(mass: 1, length: 2, time: -1)),
  (names: ("PoundForce", "lbf"), scale: 4.448221615, dims: dim(mass: 1, length: 1, time: -2)),
  (names: ("RackUnit", "U", "RU"), scale: 0.04445, dims: dim(length: 1)),
  (names: ("RadRadioactivity",), scale: 0.01, dims: dim(length: 2, time: -2)),
  (names: ("RydbergUnit", "Ry"), scale: 2.179872361e-18, dims: dim(mass: 1, length: 2, time: -2)),
  (names: ("ShortTon", "s_ton"), scale: 907.18474, dims: dim(mass: 1)),
  (names: ("SolarLuminosity", "L_☉"), scale: 3.828e26, dims: dim(mass: 1, length: 2, time: -3)),
  (names: ("SolarMass", "M_☉"), scale: 1.98847e30, dims: dim(mass: 1)),
  (names: ("SolarRadius", "R_☉"), scale: 695700000, dims: dim(length: 1)),
  (names: ("TexPoint", "pt_TeX"), scale: 0.000351459803515, dims: dim(length: 1)),
  (names: ("TexScaledPoint", "sp_TeX"), scale: 5.362851006e-09, dims: dim(length: 1)),
  (names: ("ThermISO", "thm_ISO"), scale: 105506000, dims: dim(mass: 1, length: 2, time: -2)),
  (names: ("ThermUS", "thm_US"), scale: 105480400, dims: dim(mass: 1, length: 2, time: -2)),
  (names: ("TonRefrigaration", "TOR"), scale: 3516.852842067, dims: dim(mass: 1, length: 2, time: -3)),
  (names: ("TropicalYear", "a_t"), scale: 31556925.216, dims: dim(time: 1)),
  (names: ("TroyOunce", "oz_t"), scale: 0.0311034768, dims: dim(mass: 1)),
  (names: ("TroyPound", "lb_t"), scale: 0.3732417216, dims: dim(mass: 1)),
  (names: ("US_foot", "ft_US"), scale: 0.304800609601, dims: dim(length: 1)),
  (names: ("US_inch", "in_US"), scale: 0.0254000508, dims: dim(length: 1)),
  (names: ("US_mile", "mi_US"), scale: 1609.347219, dims: dim(length: 1)),
  (names: ("US_point", "pt_US"), scale: 0.000351366666667, dims: dim(length: 1)),
  (names: ("US_rod", "rd_US"), scale: 5.029210058, dims: dim(length: 1)),
  (names: ("abampere", "abA", "Bi", "biot"), scale: 10, dims: dim(current: 1)),
  (names: ("abcoulomb", "abC", "aC"), scale: 10, dims: dim(current: 1, time: 1)),
  (names: ("abhenry", "abH"), scale: 1e-09, dims: dim(mass: 1, length: 2, current: -2, time: -2)),
  (names: ("abohm", "abΩ"), scale: 1e-09, dims: dim(mass: 1, length: 2, current: -2, time: -3)),
  (names: ("abvolt", "abV"), scale: 1e-08, dims: dim(mass: 1, length: 2, current: -1, time: -3)),
  (names: ("acre",), scale: 4046.8564224, dims: dim(length: 2)),
  (names: ("agate",), scale: 0.001940277778, dims: dim(length: 1)),
  (names: ("ampere", "A", "amp"), scale: 1, dims: dim(current: 1)),
  (names: ("angstrom", "Å", "ångström"), scale: 1e-10, dims: dim(length: 1)),
  (names: ("arcminute", "arcmin"), scale: 0.000290888208666, dims: dim()),
  (names: ("arcsecond", "arcsec"), scale: 4.848136811e-06, dims: dim()),
  (names: ("are", "a"), scale: 100, dims: dim(length: 2)),
  (names: ("atmosphere", "atm"), scale: 101325, dims: dim(mass: 1, length: -1, time: -2)),
  (names: ("bar",), scale: 100000, dims: dim(mass: 1, length: -1, time: -2)),
  (names: ("barn", "b"), scale: 1e-28, dims: dim(length: 2)),
  (names: ("barrel", "bbl"), scale: 0.158987295, dims: dim(length: 3)),
  (names: ("barye", "Ba"), scale: 0.1, dims: dim(mass: 1, length: -1, time: -2)),
  (names: ("becquerel", "Bq"), scale: 1, dims: dim(time: -1)),
  (names: ("bel",), scale: 1.151292546, dims: dim(logratio: 1)),
  (names: ("bit", "shannon", "Sh", "BinaryDigit"), scale: 1, dims: dim(information: 1)),
  (names: ("bushel", "bu"), scale: 0.03523907, dims: dim(length: 3)),
  (names: ("byte", "B", "octet", "o"), scale: 8, dims: dim(information: 1)),
  (names: ("c_unit",), scale: 299792458, dims: dim(length: 1, time: -1)),
  (names: ("cal_IT",), scale: 4.1868, dims: dim(mass: 1, length: 2, time: -2)),
  (names: ("cal_fifteen",), scale: 4.2, dims: dim(mass: 1, length: 2, time: -2)),
  (names: ("cal_mean",), scale: 4.19002, dims: dim(mass: 1, length: 2, time: -2)),
  (names: ("calorie", "cal"), scale: 4.184, dims: dim(mass: 1, length: 2, time: -2)),
  (names: ("candela", "cd"), scale: 1, dims: dim(luminosity: 1)),
  (names: ("carat",), scale: 0.0002, dims: dim(mass: 1)),
  (names: ("celsius", "oC", "°C", "℃", "centigrade"), scale: 1, dims: dim(temperature: 1), offset: 273.15),
  (names: ("cfm",), scale: 0.0004719474432, dims: dim(length: 3, time: -1)),
  (names: ("cfs",), scale: 0.028316847, dims: dim(length: 3, time: -1)),
  (names: ("chain", "ch"), scale: 20.1168, dims: dim(length: 1)),
  (names: ("cicero",), scale: 0.004511658125, dims: dim(length: 1)),
  (names: ("cmil",), scale: 5.06707479097e-10, dims: dim(length: 2)),
  (names: ("coulomb", "C"), scale: 1, dims: dim(current: 1, time: 1)),
  (names: ("cup",), scale: 0.0002365882365, dims: dim(length: 3)),
  (names: ("curie", "Ci"), scale: 37000000000, dims: dim(time: -1)),
  (names: ("dalton", "Da"), scale: 1.66053907e-27, dims: dim(mass: 1)),
  (names: ("daraf",), scale: 1, dims: dim(mass: 1, length: 2, current: -2, time: -4)),
  (names: ("darcy",), scale: 9.86923267e-13, dims: dim(length: 2)),
  (names: ("day", "d"), scale: 86400, dims: dim(time: 1)),
  (names: ("debye", "D"), scale: 3.33564095198152e-30, dims: dim(current: 1, length: 1, time: 1)),
  (names: ("decare", "da"), scale: 1000, dims: dim(length: 2)),
  (names: ("decibel", "dB"), scale: 0.115129255, dims: dim(logratio: 1)),
  (names: ("declet",), scale: 10, dims: dim(information: 1)),
  (names: ("degree", "deg", "°"), scale: 0.01745329252, dims: dim()),
  (names: ("dessertspoon",), scale: 1e-05, dims: dim(length: 3)),
  (names: ("didot", "dd"), scale: 0.000375971510383, dims: dim(length: 1)),
  (names: ("dram", "dr"), scale: 0.001771845195, dims: dim(mass: 1)),
  (names: ("dyne", "dyn"), scale: 1e-05, dims: dim(mass: 1, length: 1, time: -2)),
  (names: ("e_unit", "q_A"), scale: 1.602176634e-19, dims: dim(current: 1, time: 1)),
  (names: ("einstein",), scale: 1, dims: dim(amount: 1)),
  (names: ("electronvolt", "eV"), scale: 1.602176634e-19, dims: dim(mass: 1, length: 2, time: -2)),
  (names: ("erg",), scale: 1e-07, dims: dim(mass: 1, length: 2, time: -2)),
  (names: ("fahrenheit", "oF", "°F", "℉"), scale: 0.555555555555556, dims: dim(temperature: 1), offset: 255.372222222222),
  (names: ("farad", "F"), scale: 1, dims: dim(current: 2, time: 4, mass: -1, length: -2)),
  (names: ("fathom",), scale: 1.8288, dims: dim(length: 1)),
  (names: ("foe",), scale: 1e44, dims: dim(mass: 1, length: 2, time: -2)),
  (names: ("foot", "ft"), scale: 0.3048, dims: dim(length: 1)),
  (names: ("fortnight",), scale: 1209600, dims: dim(time: 1)),
  (names: ("furlong", "fur"), scale: 201.168, dims: dim(length: 1)),
  (names: ("galileo", "Gal"), scale: 0.01, dims: dim(length: 1, time: -2)),
  (names: ("gallon", "gal"), scale: 0.003785411784, dims: dim(length: 3)),
  (names: ("gauss",), scale: 0.0001, dims: dim(mass: 1, current: -1, time: -2)),
  (names: ("gee",), scale: 9.80665, dims: dim(length: 1, time: -2)),
  (names: ("gill", "gi"), scale: 0.00011829411825, dims: dim(length: 3)),
  (names: ("gph",), scale: 1.051503273e-06, dims: dim(length: 3, time: -1)),
  (names: ("gpm",), scale: 6.30901964e-05, dims: dim(length: 3, time: -1)),
  (names: ("gradian", "gra", "gon"), scale: 0.015707963268, dims: dim()),
  (names: ("grain", "gr"), scale: 6.479891e-05, dims: dim(mass: 1)),
  (names: ("gram", "g"), scale: 0.001, dims: dim(mass: 1)),
  (names: ("gramTNT", "gTNT"), scale: 4184, dims: dim(mass: 1, length: 2, time: -2)),
  (names: ("gray", "Gy"), scale: 1, dims: dim(length: 2, time: -2)),
  (names: ("hand",), scale: 0.1016, dims: dim(length: 1)),
  (names: ("hartley", "Hart", "dit", "DecimalDigit"), scale: 3.32192809488736, dims: dim(information: 1)),
  (names: ("hartree", "Ha", "E_h"), scale: 4.359744722e-18, dims: dim(mass: 1, length: 2, time: -2)),
  (names: ("hectare", "ha"), scale: 10000, dims: dim(length: 2)),
  (names: ("henry", "H"), scale: 1, dims: dim(mass: 1, length: 2, current: -2, time: -2)),
  (names: ("hertz", "Hz"), scale: 1, dims: dim(time: -1)),
  (names: ("horsepower", "hp"), scale: 745.699987158, dims: dim(mass: 1, length: 2, time: -3)),
  (names: ("hour", "h", "hr", "hrs"), scale: 3600, dims: dim(time: 1)),
  (names: ("hundredweight", "cwt", "cental", "centals"), scale: 45.359237, dims: dim(mass: 1)),
  (names: ("inHg",), scale: 3386.388158, dims: dim(mass: 1, length: -1, time: -2)),
  (names: ("inWC", "iwg", "inH₂O"), scale: 249.08891, dims: dim(mass: 1, length: -1, time: -2)),
  (names: ("inch", "in"), scale: 0.0254, dims: dim(length: 1)),
  (names: ("joule", "J"), scale: 1, dims: dim(mass: 1, length: 2, time: -2)),
  (names: ("katal", "kat"), scale: 1, dims: dim(amount: 1, time: -1)),
  (names: ("kayser",), scale: 100, dims: dim(length: -1)),
  (names: ("kcmil", "MCM"), scale: 5.06707479e-07, dims: dim(length: 2)),
  (names: ("kelvin", "K"), scale: 1, dims: dim(temperature: 1)),
  (names: ("knot",), scale: 0.514444444444, dims: dim(length: 1, time: -1)),
  (names: ("ksi",), scale: 6894757.293, dims: dim(mass: 1, length: -1, time: -2)),
  (names: ("l_N", "ƛ_unit"), scale: 3.8615927e-13, dims: dim(length: 1)),
  (names: ("lambert",), scale: 3183.098862, dims: dim(luminosity: 1, length: -2)),
  (names: ("lightyear", "ly"), scale: 9.4607304725808e15, dims: dim(length: 1)),
  (names: ("ligne",), scale: 0.002255829062, dims: dim(length: 1)),
  (names: ("link", "li"), scale: 0.201168, dims: dim(length: 1)),
  (names: ("liter", "L", "l", "litre"), scale: 0.001, dims: dim(length: 3)),
  (names: ("lumen", "lm"), scale: 1, dims: dim(luminosity: 1)),
  (names: ("lux", "lx"), scale: 1, dims: dim(luminosity: 1, length: -2)),
  (names: ("mWC", "mwg", "mH₂O"), scale: 9806.65, dims: dim(mass: 1, length: -1, time: -2)),
  (names: ("maxwell", "Mx"), scale: 1e-08, dims: dim(mass: 1, length: 2, current: -1, time: -2)),
  (names: ("meter", "m", "metre"), scale: 1, dims: dim(length: 1)),
  (names: ("micron",), scale: 1e-06, dims: dim(length: 1)),
  (names: ("mile", "mi"), scale: 1609.344, dims: dim(length: 1)),
  (names: ("minim",), scale: 6.1611519922e-08, dims: dim(length: 3)),
  (names: ("minute", "min"), scale: 60, dims: dim(time: 1)),
  (names: ("mmHg",), scale: 133.322368421, dims: dim(mass: 1, length: -1, time: -2)),
  (names: ("molar",), scale: 1000, dims: dim(amount: 1, length: -3)),
  (names: ("mole", "mol"), scale: 1, dims: dim(amount: 1)),
  (names: ("month",), scale: 2629800, dims: dim(time: 1)),
  (names: ("mpg",), scale: 425143.707430272, dims: dim(length: -2)),
  (names: ("mph",), scale: 0.44704, dims: dim(length: 1, time: -1)),
  (names: ("nat",), scale: 1.44269504088896, dims: dim(information: 1)),
  (names: ("neper", "Np"), scale: 1, dims: dim(logratio: 1)),
  (names: ("newton", "N"), scale: 1, dims: dim(mass: 1, length: 1, time: -2)),
  (names: ("nibble", "nybble", "semioctet", "HexDigit", "HexadecimalDigit"), scale: 4, dims: dim(information: 1)),
  (names: ("nonet",), scale: 9, dims: dim(information: 1)),
  (names: ("oersted", "Oe"), scale: 79.577471546, dims: dim(current: 1, length: -1)),
  (names: ("ohm", "Ω"), scale: 1, dims: dim(mass: 1, length: 2, current: -2, time: -3)),
  (names: ("ounce", "oz"), scale: 0.028349523125, dims: dim(mass: 1)),
  (names: ("parsec", "pc"), scale: 3.08567758149137e16, dims: dim(length: 1)),
  (names: ("pascal", "Pa"), scale: 1, dims: dim(mass: 1, length: -1, time: -2)),
  (names: ("peck", "pk"), scale: 0.00880976754172, dims: dim(length: 3)),
  (names: ("pennyweight", "pwt"), scale: 0.00155517384, dims: dim(mass: 1)),
  (names: ("pfund",), scale: 0.5, dims: dim(mass: 1)),
  (names: ("phot", "ph"), scale: 10000, dims: dim(luminosity: 1, length: -2)),
  (names: ("pica",), scale: 0.004233333333, dims: dim(length: 1)),
  (names: ("point", "pt", "pts", "bp_tex"), scale: 0.000352777777778, dims: dim(length: 1)),
  (names: ("poise", "P"), scale: 0.1, dims: dim(mass: 1, length: -1, time: -1)),
  (names: ("pond", "gf"), scale: 0.00980665, dims: dim(mass: 1, length: 1, time: -2)),
  (names: ("pouce",), scale: 0.027069948748, dims: dim(length: 1)),
  (names: ("pound", "lb"), scale: 0.45359237, dims: dim(mass: 1)),
  (names: ("poundal", "pdl"), scale: 0.138254954376, dims: dim(mass: 1, length: 1, time: -2)),
  (names: ("psi",), scale: 6894.757293, dims: dim(mass: 1, length: -1, time: -2)),
  (names: ("radian", "rad"), scale: 1, dims: dim()),
  (names: ("rankine", "oR", "oRa", "°R", "°Ra"), scale: 0.555555555556, dims: dim(temperature: 1)),
  (names: ("rem",), scale: 0.01, dims: dim(length: 2, time: -2)),
  (names: ("rod", "rd"), scale: 5.0292, dims: dim(length: 1)),
  (names: ("roentgen", "R", "röntgen"), scale: 0.000258, dims: dim(current: 1, time: 1, mass: -1)),
  (names: ("rood",), scale: 1011.7141056, dims: dim(length: 2)),
  (names: ("rpm",), scale: 0.10471975512, dims: dim(time: -1)),
  (names: ("rutherford", "Rd"), scale: 1000000, dims: dim(time: -1)),
  (names: ("second", "s"), scale: 1, dims: dim(time: 1)),
  (names: ("section",), scale: 2589998.47, dims: dim(length: 2)),
  (names: ("siemens", "S"), scale: 1, dims: dim(current: 2, time: 3, mass: -1, length: -2)),
  (names: ("sievert", "Sv"), scale: 1, dims: dim(length: 2, time: -2)),
  (names: ("slug",), scale: 14.593902937, dims: dim(mass: 1)),
  (names: ("statcoulomb", "statC", "franklin", "Fr", "esu"), scale: 3.33564095198e-10, dims: dim(current: 1, time: 1)),
  (names: ("statohm", "statΩ"), scale: 898755179000, dims: dim(mass: 1, length: 2, current: -2, time: -3)),
  (names: ("statvolt", "statV"), scale: 299.792458, dims: dim(mass: 1, length: 2, current: -1, time: -3)),
  (names: ("steradian", "sr"), scale: 1, dims: dim()),
  (names: ("stilb", "sb"), scale: 10000, dims: dim(luminosity: 1, length: -2)),
  (names: ("stokes", "St"), scale: 0.0001, dims: dim(length: 2, time: -1)),
  (names: ("stone",), scale: 6.35029318, dims: dim(mass: 1)),
  (names: ("sverdrup",), scale: 1000000, dims: dim(length: 3, time: -1)),
  (names: ("tablespoon",), scale: 1.5e-05, dims: dim(length: 3)),
  (names: ("teaspoon",), scale: 5e-06, dims: dim(length: 3)),
  (names: ("tesla", "T"), scale: 1, dims: dim(mass: 1, current: -1, time: -2)),
  (names: ("therm", "thm"), scale: 105505585.262, dims: dim(mass: 1, length: 2, time: -2)),
  (names: ("thermie", "th"), scale: 4186800, dims: dim(mass: 1, length: 2, time: -2)),
  (names: ("thou", "mil"), scale: 2.54e-05, dims: dim(length: 1)),
  (names: ("toise",), scale: 1.94903631, dims: dim(length: 1)),
  (names: ("tonTNT", "tTNT"), scale: 4184000000, dims: dim(mass: 1, length: 2, time: -2)),
  (names: ("tonne", "ton"), scale: 1000, dims: dim(mass: 1)),
  (names: ("torr", "Torr"), scale: 133.322368421, dims: dim(mass: 1, length: -1, time: -2)),
  (names: ("township",), scale: 93239944.932, dims: dim(length: 2)),
  (names: ("tribble",), scale: 12, dims: dim(information: 1)),
  (names: ("trit", "TrinaryDigit", "TernaryDigit"), scale: 1.58496250072116, dims: dim(information: 1)),
  (names: ("turn", "tr", "pla", "rev", "revolution", "cyc", "cycle"), scale: 6.283185307, dims: dim()),
  (names: ("twip",), scale: 1.7638888889e-05, dims: dim(length: 1)),
  (names: ("volt", "V"), scale: 1, dims: dim(mass: 1, length: 2, current: -1, time: -3)),
  (names: ("watt", "W"), scale: 1, dims: dim(mass: 1, length: 2, time: -3)),
  (names: ("weber", "Wb"), scale: 1, dims: dim(mass: 1, length: 2, current: -1, time: -2)),
  (names: ("week",), scale: 604800, dims: dim(time: 1)),
  (names: ("word",), scale: 16, dims: dim(information: 1)),
  (names: ("yard", "yd"), scale: 0.9144, dims: dim(length: 1)),
  (names: ("year", "a_j", "yr", "annus"), scale: 31557600, dims: dim(time: 1)),
  (names: ("zentner",), scale: 50, dims: dim(mass: 1)),
)

for definition in qalc-unit-definitions {
  let item = (scale: definition.scale, dims: definition.dims,
    offset: definition.at("offset", default: 0.0))
  for name in definition.names { units.insert(name, item) }
}

// Project-specific compatibility aliases and named composites.
units.insert("t", units.tonne)
units.insert("kn", units.knot)
units.insert("Nm", (scale: 1.0, dims: dim(length: 2, mass: 1, time: -2)))
units.insert("Ncm", (scale: 0.01, dims: units.Nm.dims))
units.insert("Nmm", (scale: 0.001, dims: units.Nm.dims))
units.insert("Wh", (scale: 3600.0, dims: dim(length: 2, mass: 1, time: -2)))
for name in ("degree", "deg", "°") {
  units.insert(name, (scale: calc.pi / 180, dims: dim()))
}
for name in ("arcminute", "arcmin") {
  units.insert(name, (scale: calc.pi / 10800, dims: dim()))
}
for name in ("arcsecond", "arcsec") {
  units.insert(name, (scale: calc.pi / 648000, dims: dim()))
}
for name in ("gradian", "gra", "gon") {
  units.insert(name, (scale: calc.pi / 200, dims: dim()))
}
for name in ("turn", "tr", "pla", "rev", "revolution", "cyc", "cycle") {
  units.insert(name, (scale: 2 * calc.pi, dims: dim()))
}
units.insert("rpm", (scale: 2 * calc.pi / 60, dims: dim(time: -1)))
// Not representable as linear or affine units: dBW, dBm


let prefixes = (
  ("Q", 1e30), ("R", 1e27),
  ("da", 1e1),
  ("Y", 1e24), ("Z", 1e21), ("E", 1e18), ("P", 1e15),
  ("T", 1e12), ("G", 1e9), ("M", 1e6), ("k", 1e3), ("h", 1e2),
  ("d", 1e-1), ("c", 1e-2), ("m", 1e-3),
  ("µ", 1e-6), ("μ", 1e-6), ("u", 1e-6),
  ("n", 1e-9), ("p", 1e-12), ("f", 1e-15), ("a", 1e-18),
  ("z", 1e-21), ("y", 1e-24),
  ("r", 1e-27), ("q", 1e-30),
)

let binary-prefixes = (
  ("Qi", calc.pow(1024.0, 10)), ("Ri", calc.pow(1024.0, 9)),
  ("Yi", calc.pow(1024.0, 8)), ("Zi", calc.pow(1024.0, 7)),
  ("Ei", calc.pow(1024.0, 6)), ("Pi", calc.pow(1024.0, 5)),
  ("Ti", calc.pow(1024.0, 4)), ("Gi", calc.pow(1024.0, 3)),
  ("Mi", calc.pow(1024.0, 2)), ("Ki", 1024.0),
)

let prefixable = (
  "m", "g", "s", "A", "K", "mol", "cd", "rad", "sr", "Hz", "N", "Nm",
  "Pa", "J", "W", "C", "V", "F", "ohm", "S", "Wb", "T", "H",
  "lm", "lx", "Bq", "Gy", "Sv", "kat", "L", "l", "Wh", "eV", "Ω",
  "bit", "B", "byte", "bar", "cal", "Da", "barn", "Ci", "rad",
)

let binary-prefixable = ("bit", "B", "byte", "o", "octet")

let resolve-unit(name) = {
  if name in units { return units.at(name) }
  for (prefix, factor) in prefixes {
    if name.starts-with(prefix) {
      let base = name.slice(prefix.len())
      if base in prefixable {
        let unit = units.at(base)
        if unit.at("offset", default: 0.0) == 0.0 {
          return (scale: factor * unit.scale, dims: unit.dims, offset: 0.0)
        }
      }
    }
  }
  for (prefix, factor) in binary-prefixes {
    if name.starts-with(prefix) {
      let base = name.slice(prefix.len())
      if base in binary-prefixable {
        let unit = units.at(base)
        return (scale: factor * unit.scale, dims: unit.dims, offset: 0.0)
      }
    }
  }
  none
}

let resolve-unit-with-aliases(name, aliases: (:)) = {
  if name in aliases { resolve-unit(aliases.at(name)) } else { resolve-unit(name) }
}

let quantity(si-value, dims: zero-dim, preferred: none, affine: none, opaque: (:)) = (
  si-value: si-value,
  dims: dims,
  preferred: preferred,
  affine: affine,
  opaque: opaque,
)

let calculation-failure(message) = (error: message)
let is-calculation-failure(value) = type(value) == dictionary and "error" in value
let calculation-fail(message, soft: false) = if soft {
  calculation-failure(message)
} else {
  panic("math-once calculate: " + message)
}

let dims-add(a, b, factor: 1) = {
  let result = zero-dim
  for (name, value) in a {
    result.insert(name, value + factor * b.at(name))
  }
  result
}

let dims-scale(a, factor) = {
  let result = zero-dim
  for (name, value) in a {
    result.insert(name, value * factor)
  }
  result
}

let opaque-add(a, b, factor: 1) = {
  let result = a
  for (name, value) in b {
    let exponent = result.at(name, default: 0) + factor * value
    if exponent == 0 { result.remove(name) } else { result.insert(name, exponent) }
  }
  result
}

let opaque-scale(a, factor) = {
  let result = (:)
  for (name, value) in a {
    let exponent = value * factor
    if exponent != 0 { result.insert(name, exponent) }
  }
  result
}

let is-dimensionless(q) = q.dims == zero-dim and q.opaque.len() == 0

let dimensions-name(dims) = {
  let known = (
    (dim(length: 1), "length"),
    (dim(mass: 1), "mass"),
    (dim(time: 1), "time"),
    (dim(length: 1, time: -1), "speed"),
    (dim(length: 1, time: -2), "acceleration"),
    (dim(length: 2), "area"),
    (dim(length: 3), "volume"),
    (dim(length: -1), "inverse length"),
    (dim(time: -1), "inverse time"),
    (dim(length: 1, mass: 1, time: -2), "force"),
    (dim(length: -1, mass: 1, time: -2), "pressure"),
    (dim(length: 2, mass: 1, time: -2), "energy"),
    (dim(length: 2, mass: 1, time: -3), "power"),
    (dim(information: 1), "information"),
    (dim(logratio: 1), "logarithmic ratio"),
  )
  for (candidate, name) in known {
    if dims == candidate { return name }
  }
  "incompatible dimensions"
}

let unit-kind-name(q) = if q.opaque.len() > 0 {
  "custom unit `" + q.opaque.keys().join(" ") + "`"
} else {
  dimensions-name(q.dims)
}

let canonical-unit(dims) = {
  let known = (
    (dim(length: 1), "m"),
    (dim(mass: 1), "kg"),
    (dim(time: 1), "s"),
    (dim(length: 1, time: -1), "m/s"),
    (dim(length: 1, time: -2), "m/s^2"),
    (dim(length: 2), "m^2"),
    (dim(length: 3), "m^3"),
    (dim(length: 1, mass: 1, time: -2), "N"),
    (dim(length: -1, mass: 1, time: -2), "Pa"),
    (dim(length: 2, mass: 1, time: -2), "J"),
    (dim(length: 2, mass: 1, time: -3), "W"),
    (dim(current: 1), "A"),
    (dim(temperature: 1), "K"),
    (dim(amount: 1), "mol"),
    (dim(luminosity: 1), "cd"),
    (dim(information: 1), "bit"),
    (dim(logratio: 1), "Np"),
  )
  for (candidate, symbol) in known {
    if dims == candidate { return symbol }
  }

  let symbols = (
    length: "m",
    mass: "kg",
    time: "s",
    current: "A",
    temperature: "K",
    amount: "mol",
    luminosity: "cd",
    information: "bit",
    logratio: "Np",
  )
  let numerator = ()
  let denominator = ()
  for (name, exponent) in dims {
    if exponent != 0 {
      let symbol = symbols.at(name)
      let magnitude = calc.abs(exponent)
      let part = symbol + if magnitude == 1 { "" } else { "^" + str(magnitude) }
      if exponent > 0 { numerator.push(part) } else { denominator.push(part) }
    }
  }
  if numerator.len() == 0 { numerator.push("1") }
  numerator.join(" ") + if denominator.len() == 0 { "" } else { "/" + denominator.join(" ") }
}

let canonical-opaque-unit(opaque) = {
  let numerator = ()
  let denominator = ()
  for (name, exponent) in opaque {
    let magnitude = calc.abs(exponent)
    let part = name + if magnitude == 1 { "" } else { "^" + str(magnitude) }
    if exponent > 0 { numerator.push(part) } else { denominator.push(part) }
  }
  if numerator.len() == 0 { numerator.push("1") }
  numerator.join(" ") + if denominator.len() == 0 { "" } else { "/" + denominator.join(" ") }
}

let engineering-length-units = (
  ("Ym", 1e24), ("Zm", 1e21), ("Em", 1e18), ("Pm", 1e15),
  ("Tm", 1e12), ("Gm", 1e9), ("Mm", 1e6), ("km", 1e3),
  ("hm", 1e2), ("dam", 1e1), ("m", 1.0), ("dm", 1e-1),
  ("cm", 1e-2), ("mm", 1e-3), ("µm", 1e-6), ("nm", 1e-9),
  ("pm", 1e-12), ("fm", 1e-15), ("am", 1e-18), ("zm", 1e-21),
  ("ym", 1e-24),
)

let auto-length-unit(si-value, current-unit) = {
  let si-spellings = engineering-length-units.map(pair => pair.first()) + (
    "cm", "dm", "dam", "hm", "um", "μm",
  )
  if current-unit not in si-spellings or si-value == 0 { return current-unit }
  let magnitude = calc.abs(si-value)
  // Automatically improve microscopic SI lengths without rewriting ordinary
  // metre-scale results that existing documents deliberately express in m.
  if magnitude >= 1 { return current-unit }
  for (unit, scale) in engineering-length-units {
    if magnitude >= scale and magnitude < scale * 1000 {
      return unit
    }
  }
  current-unit
}

let power-of-ten-exponent(value) = {
  for exponent in range(-30, 31) {
    let candidate = calc.pow(10.0, exponent)
    if calc.abs(candidate - value) <= calc.max(candidate, value) * 1e-12 {
      return exponent
    }
  }
  none
}

let scientific-size-expression(size, notation: none) = {
  if notation != none { return notation }
  let exponent = power-of-ten-exponent(size)
  if exponent == none { return none }
  let exponent-text = if exponent < 0 { "-" + str(-exponent) } else { str(exponent) }
  "10^(" + exponent-text + ")"
}

let sized-output-unit(dims, size, notation: none) = {
  if dims == dim(length: 1) {
    for (unit, scale) in engineering-length-units {
      if calc.abs(scale - size) <= calc.max(calc.abs(scale), calc.abs(size)) * 1e-12 { return unit }
    }
  }
  let expression = scientific-size-expression(size, notation: notation)
  if expression != none {
    expression + " " + canonical-unit(dims)
  } else {
    "(" + str(size) + ") " + canonical-unit(dims)
  }
}

let sized-requested-unit(dims, unit, unit-scale, size, notation: none) = {
  let scale = unit-scale * size
  let familiar = sized-output-unit(dims, scale)
  if not familiar.starts-with("(") and "10^(" not in familiar {
    familiar
  } else if size == 1 {
    unit
  } else {
    let expression = scientific-size-expression(size, notation: notation)
    if expression != none {
      expression + " " + unit
    } else {
      "(" + str(size) + ") " + unit
    }
  }
}

let source-string(source) = if type(source) == str {
  source.trim()
} else if type(source) == content and source.func() == raw {
  source.text.trim()
} else {
  panic("math-once calculate: expression must be a string, raw text, or math equation")
}

// Typst turns names such as `lambda` into mathematical symbols before this
// package sees the equation. Store them under readable ASCII keys while
// rendering them as their original Greek symbols.
let variable-symbols = (
  alpha: "α",
  beta: "β",
  gamma: "γ",
  delta: "δ",
  epsilon: "ε",
  zeta: "ζ",
  eta: "η",
  theta: "θ",
  iota: "ι",
  kappa: "κ",
  lambda: "λ",
  mu: "μ",
  nu: "ν",
  xi: "ξ",
  omicron: "ο",
  pi: "π",
  rho: "ρ",
  sigma: "σ",
  tau: "τ",
  upsilon: "υ",
  phi: "φ",
  chi: "χ",
  psi: "ψ",
  omega: "ω",
  Gamma: "Γ",
  Delta: "Δ",
  Theta: "Θ",
  Lambda: "Λ",
  Xi: "Ξ",
  Pi: "Π",
  Sigma: "Σ",
  Upsilon: "Υ",
  Phi: "Φ",
  Psi: "Ψ",
  Omega: "Ω",
)

let variable-symbol-name(symbol) = {
  for (name, value) in variable-symbols {
    if value == symbol { return name }
  }
  none
}

let math-functions = ("sin", "cos", "tan", "sqrt", "root")
let text-unit-prefix = "⟦"
let text-unit-suffix = "⟧"

/// Create an explicit symbolic text label for an output unit.
///
/// Unlike a quoted known unit such as `"cm"`, `text-unit("cm")` has no
/// physical dimension or conversion factor. Use it inside the `unit:` math
/// expression, for example `unit: $#text-unit("lines") / m$`.
let text-unit(label) = {
  if type(label) != str or label.trim() == "" {
    panic("math-once text-unit: label must be a non-empty string")
  }
  if text-unit-prefix in label or text-unit-suffix in label {
    panic("math-once text-unit: label contains reserved characters")
  }
  text(text-unit-prefix + label + text-unit-suffix)
}

// Convert the supported subset of Typst math back into parser input, including
// the builder's `:=` storage operator.
let math-items(value) = if value.has("children") { value.children } else { (value,) }

let math-source-part(value, parse, preserve-text: false) = {
  if repr(value.func()) == "space" { return "" }
  if repr(value.func()) == "sequence" {
    return parse(value)
  }
  if repr(value.func()) == "accent" {
    return "arrow_" + parse(value.base)
  }
  if value.func() == math.vec {
    return "vec(" + value.children.map(child => parse(child)).join(",") + ")"
  }
  if value.func() == math.frac {
    return "(" + parse(value.num) + ")/(" + parse(value.denom) + ")"
  }
  if value.func() == math.root {
    return if value.has("index") {
      "root(" + parse(value.index) + "," + parse(value.radicand) + ")"
    } else {
      "sqrt(" + parse(value.radicand) + ")"
    }
  }
  if value.func() == math.attach {
    let base = math-source-part(value.base, parse)
    if value.has("b") {
      let subscript = parse(value.b)
      if regex("^[A-Za-z0-9]+$") not in subscript {
        panic("math-once calculate: variable subscripts must contain only letters or digits")
      }
      base += "_" + subscript
    }
    if value.has("t") {
      return base + "^(" + parse(value.t) + ")"
    }
    return base
  }
  if value.func() == math.lr {
    return parse(value.body)
  }
  if value.func() == math.op {
    return parse(value.text)
  }
  if not value.has("text") {
    panic("math-once calculate: unsupported Typst math element `" + repr(value.func()) + "`")
  }

  let token = value.text.trim()
  if token.starts-with(text-unit-prefix) and token.ends-with(text-unit-suffix) {
    return token
  }
  if (value.func() == text
    and preserve-text != false
    and regex("^[\\p{L}°℃℉ℏ₂☉]+(?:_[\\p{L}0-9°℃℉ℏ₂☉]+)*$") in token
    and token not in math-functions
    and (preserve-text == true or resolve-unit(token) != none)) {
    return "\"" + token + "\""
  }
  let variable-name = variable-symbol-name(token)
  if variable-name != none { variable-name }
  else if token == "≔" { ":=" }
  else if token in ("⋅", "∗", "×") { "*" }
  else if token in ("÷",) { "/" }
  else if token in ("−",) { "-" }
  else { token }
}

let math-source-body(body, preserve-text: false) = math-items(body).map(item => {
  let parse = child => math-source-body(child, preserve-text: preserve-text)
  if item == [#math.eq] { "=" } else { math-source-part(item, parse, preserve-text: preserve-text) }
}).filter(item => item != "").join(" ")

let input-source(source, preserve-text: false) = if type(source) == content and source.func() == math.equation {
  math-source-body(source.body, preserve-text: preserve-text).trim()
} else {
  source-string(source)
}

let tokenize(source) = {
  let name = "[\\p{L}°℃℉ℏ₂☉]+(?:_[\\p{L}0-9°℃℉ℏ₂☉]+)*"
  let symbolic = "⟦[^⟦⟧]+⟧"
  let pattern = regex("(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?|" + symbolic + "|\"" + name + "\"|" + name + "|:=|[=(),+*/^+\\-]")
  let tokens = ()
  let cursor = 0
  for found in source.matches(pattern) {
    if source.slice(cursor, found.start).trim() != "" {
      panic("math-once calculate: unsupported syntax near `" + source.slice(cursor, found.start) + "`")
    }
    tokens.push(found.text)
    cursor = found.end
  }
  if source.slice(cursor).trim() != "" {
    panic("math-once calculate: unsupported syntax near `" + source.slice(cursor) + "`")
  }
  if tokens.len() == 0 { panic("math-once calculate: expression must not be empty") }
  tokens
}

let is-number(token) = regex("^(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?$") in token
let is-name(token) = regex("^[\\p{L}°℃℉ℏ₂☉]+(?:_[\\p{L}0-9°℃℉ℏ₂☉]+)*$") in token
let is-quoted-unit(token) = token.len() >= 2 and token.starts-with("\"") and token.ends-with("\"")
let quoted-unit-name(token) = token.slice(1, token.len() - 1)
let is-text-unit(token) = token.len() >= 2 and token.starts-with(text-unit-prefix) and token.ends-with(text-unit-suffix)
let text-unit-name(token) = token.slice(text-unit-prefix.len(), token.len() - text-unit-suffix.len())
let can-end(token) = is-number(token) or is-name(token) or is-quoted-unit(token) or is-text-unit(token) or token == ")"
let can-start(token) = is-number(token) or is-name(token) or is-quoted-unit(token) or is-text-unit(token) or token == "("

let add-implicit-multiplication(tokens) = {
  let result = ()
  for (index, token) in tokens.enumerate() {
    if (index > 0
      and can-end(tokens.at(index - 1))
      and can-start(token)
      and not (tokens.at(index - 1) in math-functions and token == "(")) {
      result.push("*")
    }
    result.push(token)
  }
  result
}

let render-tokens(tokens, scope: (:), aliases: (:)) = {
  let render-variable(token) = if "_" in token {
    let parts = token.split("_")
    let render-part(part) = if part in variable-symbols {
      part
    } else if part.len() == 1 or is-number(part) {
      part
    } else {
      "\"" + part + "\""
    }
    render-part(parts.first()) + parts.slice(1).map(part => "_" + render-part(part)).join("")
  } else if token in variable-symbols {
    token
  } else {
    "\"" + token + "\""
  }

  let rendered = tokens.map(token => {
    if is-text-unit(token) {
      "upright(\"" + text-unit-name(token) + "\")"
    } else if is-quoted-unit(token) {
      "upright(\"" + quoted-unit-name(token) + "\")"
    } else if is-name(token) {
      if token in math-functions {
        token
      } else if token == "vec" {
        "vec"
      } else if token.starts-with("arrow_") {
        "arrow(" + render-variable(token.slice(6)) + ")"
      } else if token in aliases {
        "upright(\"" + token + "\")"
      } else if token in scope {
        render-variable(token)
      } else if token == "degree" {
        "degree"
      } else if token in ("meter", "metre") {
        "upright(\"m\")"
      } else if resolve-unit(token) != none {
        "upright(\"" + token + "\")"
      } else {
        render-variable(token)
      }
    } else if token == "*" {
      "dot"
    } else {
      token
    }
  })
  let source = ""
  for (index, item) in rendered.enumerate() {
    if index > 0 and not (tokens.at(index - 1) in math-functions and tokens.at(index) == "(") {
      source += " "
    }
    source += item
  }
  eval(source, mode: "math").body
}

let compact-unit-tokens(tokens) = {
  let result = ()
  let index = 0
  while index < tokens.len() {
    if (index + 2 < tokens.len()
      and tokens.at(index) == "("
      and (is-name(tokens.at(index + 1)) or is-quoted-unit(tokens.at(index + 1)) or is-text-unit(tokens.at(index + 1)))
      and tokens.at(index + 2) == ")") {
      result.push(tokens.at(index + 1))
      index += 3
    } else {
      result.push(tokens.at(index))
      index += 1
    }
  }
  result
}

let expression-tokens(source) = {
  let tokens = tokenize(source)
  let depth = 0
  for (index, token) in tokens.enumerate() {
    if token == "(" { depth += 1 }
    if token == ")" { depth -= 1 }
    if token in ("to", "=") and depth == 0 {
      return tokens.slice(0, index)
    }
  }
  tokens
}

let split-top-level(tokens, separator: ",") = {
  let parts = ()
  let part = ()
  let depth = 0
  for token in tokens {
    if token == "(" { depth += 1 }
    if token == ")" { depth -= 1 }
    if token == separator and depth == 0 {
      parts.push(part)
      part = ()
    } else {
      part.push(token)
    }
  }
  parts.push(part)
  parts
}

let function-definition(source) = {
  let matched = source.match(regex("^\\s*([A-Za-z]+(?:_[A-Za-z0-9]+)*)\\s*\\(([^()]*)\\)\\s*:=\\s*(.+)$"))
  if matched == none { return none }
  let parameters = matched.captures.at(1).split(",").map(item => item.trim())
  if parameters.len() == 0 or parameters.any(item => not is-name(item)) {
    return none
  }
  let body = matched.captures.at(2).trim()
  let body-tokens = tokenize(body)
  let vector = body-tokens.len() >= 3 and body-tokens.first() == "vec" and body-tokens.at(1) == "(" and body-tokens.last() == ")"
  (
    function: true,
    name: matched.captures.at(0),
    parameters: parameters,
    body: body,
    body-tokens: body-tokens,
    vector: vector,
  )
}

let substitute-function(definition, arguments) = {
  if arguments.len() != definition.parameters.len() {
    return calculation-failure(
      "function `" + definition.name + "` expects " + str(definition.parameters.len())
      + " argument" + if definition.parameters.len() == 1 { "" } else { "s" },
    )
  }
  let substitutions = (:)
  for (parameter, argument) in definition.parameters.zip(arguments) {
    substitutions.insert(parameter, argument)
  }
  let result = ()
  for token in definition.body-tokens {
    if token in substitutions {
      result.push("(")
      result += substitutions.at(token)
      result.push(")")
    } else {
      result.push(token)
    }
  }
  result
}

let expand-function-calls(tokens, scope) = {
  let result = ()
  let changed = false
  let index = 0
  while index < tokens.len() {
    let token = tokens.at(index)
    let definition = scope.at(token, default: none)
    if (type(definition) == dictionary
      and definition.at("function", default: false)
      and index + 1 < tokens.len()
      and tokens.at(index + 1) == "(") {
      let depth = 1
      let closing = index + 2
      while closing < tokens.len() and depth > 0 {
        if tokens.at(closing) == "(" { depth += 1 }
        if tokens.at(closing) == ")" { depth -= 1 }
        closing += 1
      }
      if depth != 0 { return calculation-failure("missing closing parenthesis in function call") }
      let arguments = split-top-level(tokens.slice(index + 2, closing - 1))
      let expanded = substitute-function(definition, arguments)
      if is-calculation-failure(expanded) { return expanded }
      result.push("(")
      result += expanded
      result.push(")")
      changed = true
      index = closing
    } else {
      result.push(token)
      index += 1
    }
  }
  (result, changed)
}

let function-call-name(tokens, index) = {
  if index + 1 < tokens.len() and tokens.at(index + 1) == "(" {
    return (tokens.at(index), index + 1)
  }
  if (index + 2 < tokens.len()
    and tokens.at(index) == "arrow"
    and tokens.at(index + 1) == "_"
    and is-name(tokens.at(index + 2))) {
    return ("arrow_" + tokens.at(index + 2), index + 3)
  }
  none
}

let numeric-scope(scope) = {
  let result = (:)
  for (name, value) in scope {
    let unloaded-marker = type(value) == dictionary and value.at("unloaded", default: false) and "si-value" not in value
    let unit-alias = type(value) == dictionary and value.at("unit-alias", default: false)
    let initial-state-marker = type(value) == dictionary and value.at("initial-state-marker", default: false)
    let stored-function = type(value) == dictionary and value.at("function", default: false)
    if (not unloaded-marker
      and not unit-alias
      and not initial-state-marker
      and not stored-function) {
      result.insert(name, value)
    }
  }
  result
}

let unwrap-tokens(tokens) = {
  while tokens.len() >= 2 and tokens.first() == "(" and tokens.last() == ")" {
    let depth = 0
    let closes-at-end = true
    for (index, token) in tokens.enumerate() {
      if token == "(" { depth += 1 }
      if token == ")" { depth -= 1 }
      if depth == 0 and index < tokens.len() - 1 { closes-at-end = false; break }
    }
    if not closes-at-end { break }
    tokens = tokens.slice(1, tokens.len() - 1)
  }
  tokens
}

let vector-components(tokens) = {
  tokens = unwrap-tokens(tokens)
  if (tokens.len() >= 3
  and tokens.first() == "vec"
  and tokens.at(1) == "("
  and tokens.last() == ")") {
    split-top-level(tokens.slice(2, tokens.len() - 1))
  } else {
    none
  }
}

let calculate-expanded(calculate-fn, tokens, digits, scope, unit, size, block, unloaded, aliases) = {
  let components = vector-components(tokens)
  if components == none {
    return calculate-fn(
      tokens.join(" "),
      digits: digits,
      scope: scope,
      unit: unit,
      size: size,
      block: block,
      unloaded: unloaded,
      aliases: aliases,
      soft: true,
    )
  }
  if unit != none or size != none {
    return calculation-failure("unit and size are not supported for a whole vector result")
  }
  let results = ()
  for component in components {
    let result = calculate-fn(
      component.join(" "),
      digits: digits,
      scope: scope,
      block: false,
      unloaded: unloaded,
      aliases: aliases,
      soft: true,
    )
    if is-calculation-failure(result) { return result }
    results.push(result)
  }
  (
    vector: true,
    components: results,
    values: results.map(result => result.value),
    source: tokens.join(" "),
  )
}

let equivalent-tokens(left, right) = {
  left = compact-unit-tokens(left)
  right = compact-unit-tokens(right)
  if left.len() != right.len() { return false }
  for (left-token, right-token) in left.zip(right) {
    if is-number(left-token) and is-number(right-token) {
      if float(left-token) != float(right-token) { return false }
    } else if is-quoted-unit(left-token) and quoted-unit-name(left-token) == right-token {
      continue
    } else if is-quoted-unit(right-token) and quoted-unit-name(right-token) == left-token {
      continue
    } else if left-token != right-token {
      return false
    }
  }
  true
}

// Keep very large and very small displayed values readable. Calculations still
// retain and use their complete exact value; this only changes equation output.
let display-number-tokens(value, exact: none) = {
  if exact == none { exact = value }
  let magnitude = calc.abs(float(exact))
  if magnitude == 0 or (magnitude >= 0.0001 and magnitude < 1000000000) {
    return (str(value),)
  }

  let normalized = magnitude
  let exponent = 0
  while normalized >= 10 {
    normalized /= 10
    exponent += 1
  }
  while normalized < 1 {
    normalized *= 10
    exponent -= 1
  }
  if exact < 0 { normalized = -normalized }

  // Ten coefficient decimals suppress floating-point noise while retaining
  // substantially more precision than the normal four displayed decimals.
  let coefficient = calc.round(normalized, digits: 10)
  if calc.abs(coefficient) >= 10 {
    coefficient /= 10
    exponent += 1
  }
  let exponent-tokens = if exponent < 0 {
    ("-", str(-exponent))
  } else {
    (str(exponent),)
  }
  (str(coefficient), "*", "10", "^", "(") + exponent-tokens + (")",)
}

let is-scientific-size-unit(unit) = unit != none and "10^(" in unit

let result-tokens(result) = {
  let tokens = display-number-tokens(
    result.value,
    exact: result.at("exact", default: result.value),
  )
  if result.unit != none {
    if is-scientific-size-unit(result.unit) { tokens.push("*") }
    tokens += tokenize(result.unit)
  }
  tokens
}

let render-result(result, aliases: (:)) = {
  if result.at("vector", default: false) {
    let children = result.components.map(component => render-result(component, aliases: aliases))
    return math.vec(..children)
  }
  if is-scientific-size-unit(result.unit) {
    render-tokens(
      display-number-tokens(
        result.value,
        exact: result.at("exact", default: result.value),
      ) + ("*",) + tokenize(result.unit),
      aliases: aliases,
    )
  } else {
    let body = render-tokens(display-number-tokens(
      result.value,
      exact: result.at("exact", default: result.value),
    ))
    if result.unit != none {
      body += h(0.2em) + render-tokens(tokenize(result.unit), aliases: aliases)
    }
    body
  }
}

let expand-variables(tokens, scope) = {
  let expanded = ()
  let changed = false
  for (index, token) in tokens.enumerate() {
    let item = scope.at(token, default: none)
    let unloaded-marker = type(item) == dictionary and item.at("unloaded", default: false) and "si-value" not in item
    let unit-alias = type(item) == dictionary and item.at("unit-alias", default: false)
    if (is-name(token)
      and token in scope
      and not unloaded-marker
      and not unit-alias
      and not (type(scope.at(token)) == dictionary and scope.at(token).at("function", default: false))) {
      if index > 0 and can-end(tokens.at(index - 1)) {
        expanded.push("*")
      }
      let item = scope.at(token)
      if type(item) == dictionary and "value" in item {
        expanded += display-number-tokens(
          item.value,
          exact: item.at("exact", default: item.value),
        )
        if item.unit != none { expanded += tokenize(item.unit) }
      } else {
        expanded.push(str(item))
      }
      if (index + 1 < tokens.len()
        and can-start(tokens.at(index + 1))
        and not (is-name(tokens.at(index + 1)) and tokens.at(index + 1) in scope)) {
        expanded.push("*")
      }
      changed = true
    } else {
      expanded.push(token)
    }
  }
  (expanded, changed)
}

let is-unloaded(item) = type(item) == dictionary and item.at("unloaded", default: false) == true
let is-unloaded-marker(item) = is-unloaded(item) and "si-value" not in item
let is-unit-alias(item) = type(item) == dictionary and item.at("unit-alias", default: false)
let is-stored-function(item) = type(item) == dictionary and item.at("function", default: false)
let is-renamed-unit(item) = is-unloaded(item) and type(item) == dictionary and item.at("renamed-unit", default: false)
let initial-state-marker-name = "math-once--initial-state"
let is-initial-state-marker(item) = type(item) == dictionary and item.at("initial-state-marker", default: false)
let is-stored-variable(item) = (
  not is-unloaded-marker(item)
  and not is-unit-alias(item)
  and not is-stored-function(item)
  and not is-initial-state-marker(item)
)

let state-initial-values(scope) = {
  let marker = scope.at(initial-state-marker-name, default: none)
  if marker != none and is-initial-state-marker(marker) { marker.values } else { (:) }
}

let builder-initial-state(initial) = {
  let result = initial
  result.insert(initial-state-marker-name, (
    initial-state-marker: true,
    values: initial,
  ))
  result
}

let unit-aliases(scope) = {
  let aliases = (:)
  for (name, item) in scope {
    if is-unit-alias(item) { aliases.insert(name, item.original) }
  }
  aliases
}

let missing-variables(tokens, scope, unloaded, aliases: (:)) = {
  let missing = ()
  for token in tokens {
    if (is-name(token)
      and token not in math-functions
      and token != "to"
      and token != "vec"
      and (token not in scope or is-unloaded-marker(scope.at(token, default: (:))))
      and ((resolve-unit(token) == none and token not in aliases) or token in unloaded)
      and token not in missing) {
      missing.push(token)
    }
  }
  missing
}

let normalize-scope(scope) = {
  let normalized = (:)
  for (name, item) in scope {
    if is-unloaded-marker(item) or is-unit-alias(item) or is-initial-state-marker(item) { continue }
    if resolve-unit(name) != none and not is-unloaded(item) {
      panic(
        "math-once calculate: `" + name
        + "` is a unit name and cannot be used as a variable",
      )
    }
    if type(item) == dictionary and "si-value" in item and "dimensions" in item {
      normalized.insert(name, quantity(
        item.si-value,
        dims: item.dimensions,
        preferred: item.unit,
        opaque: item.at("custom-units", default: (:)),
      ))
    } else if type(item) in (int, float, decimal) {
      normalized.insert(name, quantity(float(item)))
    } else {
      panic("math-once calculate: scope `" + name + "` must be a number or calculate result")
    }
  }
  normalized
}

let apply-op(op, left, right, soft: false) = {
  if op == "+" or op == "-" {
    if left.dims != right.dims or left.opaque != right.opaque {
      return calculation-fail(
        "cannot " + if op == "+" { "add " } else { "subtract " }
        + unit-kind-name(left) + " and " + unit-kind-name(right),
        soft: soft,
      )
    }
    return quantity(
      if op == "+" { left.si-value + right.si-value } else { left.si-value - right.si-value },
      dims: left.dims,
      opaque: left.opaque,
      preferred: if left.preferred != none { left.preferred } else { right.preferred },
    )
  }
  if op == "*" {
    if right.affine != none and is-dimensionless(left) and left.preferred == none {
      return quantity(
        left.si-value * right.affine.scale + right.affine.offset,
        dims: right.dims,
        preferred: right.preferred,
      )
    }
    if left.affine != none and is-dimensionless(right) and right.preferred == none {
      return quantity(
        right.si-value * left.affine.scale + left.affine.offset,
        dims: left.dims,
        preferred: left.preferred,
      )
    }
    if left.affine != none or right.affine != none {
      return calculation-fail("affine units must be multiplied by a plain number", soft: soft)
    }
    return quantity(
      left.si-value * right.si-value,
      dims: dims-add(left.dims, right.dims),
      opaque: opaque-add(left.opaque, right.opaque),
      preferred: if (left.preferred != none
        and is-dimensionless(right)
        and right.preferred == none) {
        left.preferred
      } else if (right.preferred != none
        and is-dimensionless(left)
        and left.preferred == none) {
        right.preferred
      } else if is-dimensionless(left) {
        right.preferred
      } else if is-dimensionless(right) {
        left.preferred
      } else {
        none
      },
    )
  }
  if op == "/" {
    if left.affine != none or right.affine != none {
      return calculation-fail("affine units cannot be divided", soft: soft)
    }
    if right.si-value == 0 {
      return calculation-fail("cannot divide by zero", soft: soft)
    }
    return quantity(
      left.si-value / right.si-value,
      dims: dims-add(left.dims, right.dims, factor: -1),
      opaque: opaque-add(left.opaque, right.opaque, factor: -1),
      preferred: if is-dimensionless(right) and right.preferred == none { left.preferred } else { none },
    )
  }
  if op == "^" {
    if left.affine != none {
      return calculation-fail("affine units cannot be raised to a power", soft: soft)
    }
    if not is-dimensionless(right) {
      return calculation-fail("exponent must be dimensionless", soft: soft)
    }
    let exponent = right.si-value
    if not is-dimensionless(left) and exponent != calc.round(exponent) {
      return calculation-fail("a unit may only be raised to an integer power", soft: soft)
    }
    return quantity(
      calc.pow(left.si-value, exponent),
      dims: dims-scale(left.dims, exponent),
      opaque: opaque-scale(left.opaque, exponent),
    )
  }
  calculation-fail("unsupported operator `" + op + "`", soft: soft)
}

let apply-function(name, argument, soft: false) = {
  if not is-dimensionless(argument) {
    return calculation-fail("`" + name + "` requires a dimensionless angle", soft: soft)
  }
  let angle = if argument.preferred == none {
    argument.si-value * calc.pi / 180
  } else {
    argument.si-value
  }
  quantity(
    if name == "sin" { calc.sin(angle) }
    else if name == "cos" { calc.cos(angle) }
    else if name == "tan" { calc.tan(angle) }
    else { calculation-fail("unsupported function `" + name + "`", soft: soft) },
  )
}

let apply-root(index, radicand, soft: false) = {
  if not is-dimensionless(index) or index.preferred != none {
    return calculation-fail("root index must be dimensionless", soft: soft)
  }
  let degree = index.si-value
  if degree == 0 {
    return calculation-fail("root index must not be zero", soft: soft)
  }
  if degree != calc.round(degree) {
    return calculation-fail("root index must be an integer", soft: soft)
  }
  if radicand.si-value < 0 and calc.rem(calc.abs(degree), 2) == 0 {
    return calculation-fail("an even root of a negative number is not real", soft: soft)
  }
  for (_, exponent) in radicand.dims {
    if calc.rem(exponent, degree) != 0 {
      return calculation-fail("unit dimensions must be divisible by the root index", soft: soft)
    }
  }
  for (_, exponent) in radicand.opaque {
    if calc.rem(exponent, degree) != 0 {
      return calculation-fail("custom-unit dimensions must be divisible by the root index", soft: soft)
    }
  }
  let magnitude = calc.pow(calc.abs(radicand.si-value), 1 / degree)
  quantity(
    if radicand.si-value < 0 { -magnitude } else { magnitude },
    dims: dims-scale(radicand.dims, 1 / degree),
    opaque: opaque-scale(radicand.opaque, 1 / degree),
  )
}

let parse(tokens, scope: (:), unloaded: (), aliases: (:), custom-units: false, override-opaque: false, soft: false) = {
  let scope = normalize-scope(scope)
  if override-opaque {
    for (name, item) in scope {
      if item.opaque.len() > 0 {
        scope.insert(name, quantity(item.si-value))
      }
    }
  }
  let precedence = ("+": 1, "-": 1, "*": 2, "/": 2, "^": 3)

  let parse-expression(tokens, position, minimum: 0) = {
    if position >= tokens.len() {
      return (calculation-fail("expected a number, variable, unit, or parenthesis", soft: soft), position)
    }

    let token = tokens.at(position)
    let left = none
    if token in math-functions {
      if position + 1 >= tokens.len() or tokens.at(position + 1) != "(" {
        return (calculation-fail("`" + token + "` must be followed by parentheses", soft: soft), position)
      }
      let (first, next) = parse-expression(tokens, position + 2)
      if is-calculation-failure(first) { return (first, next) }
      if token == "root" {
        if next >= tokens.len() or tokens.at(next) != "," {
          return (calculation-fail("`root` requires an index and a radicand", soft: soft), next)
        }
        let (radicand, closing) = parse-expression(tokens, next + 1)
        if is-calculation-failure(radicand) { return (radicand, closing) }
        if closing >= tokens.len() or tokens.at(closing) != ")" {
          return (calculation-fail("missing closing parenthesis after `root`", soft: soft), closing)
        }
        left = apply-root(first, radicand, soft: soft)
        if is-calculation-failure(left) { return (left, closing + 1) }
        position = closing + 1
      } else {
        if next >= tokens.len() or tokens.at(next) != ")" {
          return (calculation-fail("missing closing parenthesis after `" + token + "`", soft: soft), next)
        }
        left = if token == "sqrt" {
          apply-root(quantity(2.0), first, soft: soft)
        } else {
          apply-function(token, first, soft: soft)
        }
        if is-calculation-failure(left) { return (left, next + 1) }
        position = next + 1
      }
    } else if token == "+" or token == "-" {
      let (operand, next) = parse-expression(tokens, position + 1, minimum: 3)
      if is-calculation-failure(operand) { return (operand, next) }
      left = if token == "-" {
        quantity(-operand.si-value, dims: operand.dims, preferred: operand.preferred, opaque: operand.opaque)
      } else {
        operand
      }
      position = next
    } else if token == "(" {
      let (inside, next) = parse-expression(tokens, position + 1)
      if is-calculation-failure(inside) { return (inside, next) }
      if next >= tokens.len() or tokens.at(next) != ")" {
        return (calculation-fail("missing closing parenthesis", soft: soft), next)
      }
      left = inside
      position = next + 1
    } else if is-number(token) {
      left = quantity(float(token))
      position += 1
    } else if is-name(token) or is-quoted-unit(token) or is-text-unit(token) {
      let symbolic = is-text-unit(token)
      let quoted = is-quoted-unit(token)
      let unit-name = if symbolic { text-unit-name(token) } else if quoted { quoted-unit-name(token) } else { token }
      if symbolic and custom-units {
        left = quantity(1.0, preferred: token)
      } else if quoted and resolve-unit-with-aliases(unit-name, aliases: aliases) == none and unit-name in scope {
        // Typst represents both quoted units and multi-letter math variables
        // as text. An existing variable wins; otherwise the quoted name is a
        // known or opaque unit.
        left = scope.at(unit-name)
      } else if token in scope {
        left = scope.at(token)
      } else if token in unloaded {
        return (calculation-fail("`" + token + "` is not set", soft: soft), position + 1)
      } else {
        let resolved-name = aliases.at(unit-name, default: unit-name)
        let unit = resolve-unit(resolved-name)
        if unit != none {
          let offset = unit.at("offset", default: 0.0)
          let affine = if offset == 0.0 { none } else {
            (scale: unit.scale, offset: offset)
          }
          left = quantity(
            unit.scale + offset,
            dims: unit.dims,
            preferred: unit-name,
            affine: affine,
          )
        } else if quoted and custom-units {
          // Preserve the legacy unit: behavior: an unknown quoted output name
          // is a dimensionless label. text-unit is the unambiguous form.
          left = quantity(1.0, preferred: token)
        } else if quoted and override-opaque {
          // An explicit physical unit: overrides unknown input-unit labels.
          left = quantity(1.0)
        } else if quoted {
          // Unknown quoted names are opaque user-defined units. They support
          // ordinary arithmetic, but only identical opaque dimensions are
          // compatible and they never convert to catalog units.
          let opaque = (:)
          opaque.insert(unit-name, 1)
          left = quantity(1.0, preferred: unit-name, opaque: opaque)
        } else {
          return (calculation-fail("unknown variable or unit `" + token + "`", soft: soft), position + 1)
        }
      }
      position += 1
    } else {
      return (calculation-fail("unexpected token `" + token + "`", soft: soft), position + 1)
    }

    while position < tokens.len() {
      let op = tokens.at(position)
      if op == ")" or op not in precedence { break }
      let op-precedence = precedence.at(op)
      if op-precedence < minimum { break }
      let next-minimum = if op == "^" { op-precedence } else { op-precedence + 1 }
      let (right, next) = parse-expression(tokens, position + 1, minimum: next-minimum)
      if is-calculation-failure(right) { return (right, next) }
      left = apply-op(op, left, right, soft: soft)
      if is-calculation-failure(left) { return (left, next) }
      position = next
    }
    (left, position)
  }

  let (result, position) = parse-expression(tokens, 0)
  if is-calculation-failure(result) { return result }
  if position != tokens.len() {
    return calculation-fail("unexpected token `" + tokens.at(position) + "`", soft: soft)
  }
  result
}

let normalize-size(size, soft: false) = {
  if size == none { return none }
  let notation = none
  let value = if type(size) in (int, float, decimal) {
    float(size)
  } else if type(size) in (str, content) {
    let source = input-source(size)
    let parsed = parse(add-implicit-multiplication(tokenize(source)), soft: soft)
    if is-calculation-failure(parsed) { return parsed }
    if not is-dimensionless(parsed) {
      return calculation-fail("size must not contain a physical unit", soft: soft)
    }
    let compact = source.replace(regex("\\s+"), "")
    let scientific = compact.match(regex(
      "^(?:([0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)\\*)?10\\^\\(?(-?[0-9]+)\\)?$",
    ))
    if scientific != none {
      let coefficient = scientific.captures.at(0)
      let exponent = scientific.captures.at(1)
      notation = if coefficient == none or float(coefficient) == 1 {
        "10^(" + exponent + ")"
      } else {
        "(" + coefficient + "*10^(" + exponent + "))"
      }
    }
    parsed.si-value
  } else {
    return calculation-fail("size must be a positive number or math expression", soft: soft)
  }
  if value <= 0 {
    return calculation-fail("size must be greater than zero", soft: soft)
  }
  (value: value, notation: notation)
}

/// Evaluate a unit-aware expression containing numbers, units, variables,
/// `sin`, `cos`, `tan`, and the operators `+`, `-`, `*`, `/`, and `^`.
///
/// Use `to`, `=`, or the `unit` argument to request an output unit.
let calculate(source, digits: 4, scope: (:), unit: none, size: none, block: true, unloaded: (), aliases: (:), soft: false) = {
  let normalized-size = normalize-size(size, soft: soft)
  if is-calculation-failure(normalized-size) { return normalized-size }
  let size = if normalized-size == none { none } else { normalized-size.value }
  let size-notation = if normalized-size == none { none } else { normalized-size.notation }
  // Preserve quoted Typst math text so `"m"` remains an explicit metre even
  // when the bare name `m` has been unloaded for use as a variable.
  let source = input-source(source, preserve-text: true)
  let raw-tokens = tokenize(source)
  let depth = 0
  let conversion-index = none
  for (index, token) in raw-tokens.enumerate() {
    if token == "(" { depth += 1 }
    if token == ")" { depth -= 1 }
    if token in ("to", "=") and depth == 0 {
      if conversion-index != none { return calculation-fail("only one output-unit separator is allowed", soft: soft) }
      conversion-index = index
    }
  }
  if depth != 0 { return calculation-fail("unbalanced parentheses", soft: soft) }

  if conversion-index != none and unit != none {
    return calculation-fail("use only one of `to`, `=`, or `unit`", soft: soft)
  }
  if size != none and conversion-index != none {
    return calculation-fail("use `size` with the `unit` parameter, not with `to` or `=`", soft: soft)
  }
  let expression-tokens = if conversion-index == none { raw-tokens } else { raw-tokens.slice(0, conversion-index) }
  let target-tokens = if conversion-index != none {
    raw-tokens.slice(conversion-index + 1)
  } else if unit != none {
    compact-unit-tokens(tokenize(input-source(unit, preserve-text: true)))
  } else {
    none
  }
  if expression-tokens.len() == 0 { return calculation-fail("missing expression before output conversion", soft: soft) }
  if target-tokens != none and target-tokens.len() == 0 { return calculation-fail("missing output unit", soft: soft) }

  let result = parse(
    add-implicit-multiplication(expression-tokens),
    scope: scope,
    unloaded: unloaded,
    aliases: aliases,
    override-opaque: unit != none,
    soft: soft,
  )
  if is-calculation-failure(result) { return result }
  let output-unit = result.preferred
  let output-scale = 1.0
  let output-offset = 0.0
  if target-tokens != none {
    let target = parse(add-implicit-multiplication(target-tokens), aliases: aliases, custom-units: true, soft: soft)
    if is-calculation-failure(target) { return target }
    if target.dims != result.dims or target.opaque != result.opaque {
      if is-dimensionless(result) and not is-dimensionless(target) {
        // A requested unit on a plain number assigns that physical dimension.
        // For example, `902 / 3.6` with `unit: `m/s`` means 250.55... m/s.
        let assigned-value = if target.affine == none {
          result.si-value * target.si-value
        } else {
          result.si-value * target.affine.scale + target.affine.offset
        }
        result = quantity(
          assigned-value,
          dims: target.dims,
          preferred: target-tokens.join(""),
        )
      } else {
        return calculation-fail(
          "cannot convert " + unit-kind-name(result) + " to " + unit-kind-name(target),
          soft: soft,
        )
      }
    }
    output-unit = target-tokens.map(token => if is-quoted-unit(token) { quoted-unit-name(token) } else if is-text-unit(token) { text-unit-name(token) } else { token }).join("")
    output-scale = if target.affine == none { target.si-value } else { target.affine.scale }
    output-offset = if target.affine == none { 0.0 } else { target.affine.offset }
  } else if output-unit == none and result.opaque.len() > 0 {
    output-unit = canonical-opaque-unit(result.opaque)
  } else if output-unit == none and not is-dimensionless(result) {
    output-unit = canonical-unit(result.dims)
  } else if output-unit != none and result.opaque.len() == 0 {
    let preferred = parse(add-implicit-multiplication(tokenize(output-unit)), aliases: aliases)
    output-scale = if preferred.affine == none { preferred.si-value } else { preferred.affine.scale }
    output-offset = if preferred.affine == none { 0.0 } else { preferred.affine.offset }
  }

  if size != none {
    if is-dimensionless(result) {
      return calculation-fail("size requires a result with a physical unit", soft: soft)
    }
    if output-offset != 0 {
      return calculation-fail("size cannot scale an affine output unit", soft: soft)
    }
    if target-tokens == none {
      output-unit = sized-output-unit(result.dims, size, notation: size-notation)
      output-scale = size
    } else {
      output-unit = sized-requested-unit(
        result.dims,
        output-unit,
        output-scale,
        size,
        notation: size-notation,
      )
      output-scale *= size
      target-tokens = none
    }
  } else if target-tokens == none and result.dims == dim(length: 1) and output-unit not in aliases {
    let scaled-unit = auto-length-unit(result.si-value, output-unit)
    if scaled-unit != output-unit {
      output-unit = scaled-unit
      output-scale = resolve-unit(output-unit).scale
    }
  }

  let exact = (result.si-value - output-offset) / output-scale
  let value = calc.round(exact, digits: digits)
  let scientific-output = is-scientific-size-unit(output-unit)
  let display-body = render-tokens(expression-tokens, scope: scope, aliases: aliases) + h(0.25em) + math.eq + h(0.25em)
  if output-unit != none {
    let output-tokens = if target-tokens != none { target-tokens } else { tokenize(output-unit) }
    if scientific-output {
      display-body += render-tokens(
        display-number-tokens(value, exact: exact) + ("*",) + output-tokens,
        aliases: aliases,
      )
    } else {
      let rendered-value = render-tokens(display-number-tokens(value, exact: exact))
      display-body += rendered-value + h(0.2em) + render-tokens(output-tokens, aliases: aliases)
    }
  } else {
    display-body += render-tokens(display-number-tokens(value, exact: exact))
  }

  (
    value: value,
    exact: exact,
    si-value: result.si-value,
    dimensions: result.dims,
    custom-units: result.opaque,
    unit: output-unit,
    size: size,
    source: source,
    display: math.equation(display-body, block: block),
  )
}

/// Create a stateful equation runner with reusable variables.
///
/// Definitions such as `v := 10 m/s` are stored and automatically made
/// available to later calls. A simple `v = expression` is calculated and
/// displayed without storing `v`. Call the runner without an expression inside
/// a context block to retrieve its dictionary of results.
let calculation-builder(
  initial-state: (:),
  key: "math-once-calculation",
  digits: 4,
  block: true,
  supplement: auto,
) = {
  for (name, _) in initial-state {
    if name == initial-state-marker-name {
      panic("math-once calculation-builder: reserved initial-state key")
    }
    if resolve-unit(name) != none {
      panic(
        "math-once calculation-builder: `" + name
        + "` is a unit name and cannot be used as a variable",
      )
    }
  }
  let variables = state(key, builder-initial-state(initial-state))

  (
    ..args,
    digits: digits,
    unit: none,
    size: none,
    show-result: true,
    block: block,
    label: none,
    caption: none,
    gap: 0.65em,
    supplement: supplement,
  ) => {
    if args.pos().len() > 1 {
      panic("math-once calculate: the runner accepts at most one expression")
    }
    let source = args.pos().at(0, default: none)
    if source == none {
      let visible = (:)
      for (name, value) in variables.get() {
        if not is-unloaded-marker(value) and not is-unit-alias(value) and not is-initial-state-marker(value) {
          visible.insert(name, value)
        }
      }
      return visible
    }

    let source = input-source(source, preserve-text: true)
    let parsed-function = function-definition(source)
    let stored-assignment = source.match(regex("^\\s*(?:\"([A-Za-z]+(?:_[A-Za-z0-9]+)*)\"|([A-Za-z]+(?:_[A-Za-z0-9]+)*))\\s*:=\\s*(.+)$"))
    let calculated-assignment = if stored-assignment == none {
      source.match(regex("^\\s*(?:\"([A-Za-z]+(?:_[A-Za-z0-9]+)*)\"|([A-Za-z]+(?:_[A-Za-z0-9]+)*))\\s*=\\s*(.+)$"))
    } else {
      none
    }
    let assignment = if stored-assignment != none { stored-assignment } else { calculated-assignment }
    let stores-result = stored-assignment != none
    let name = if assignment == none {
      none
    } else if assignment.captures.at(0) != none {
      assignment.captures.at(0)
    } else {
      assignment.captures.at(1)
    }
    let expression = if assignment == none { source } else { assignment.captures.at(2) }
    let display-only = assignment == none and "=" in tokenize(source)

    if caption != none and not block {
      panic("math-once calculation-builder: captions require block: true")
    }
    if caption != none and type(caption) not in (content, str) {
      panic("math-once calculation-builder: caption must be content, a string, or none")
    }

    let equation-body = context {
      let current = variables.get()
      let aliases = unit-aliases(current)
      if parsed-function != none {
        if parsed-function.name in aliases {
          text(
            fill: red,
            [math-once: #raw(parsed-function.name) is a unit name and cannot be used as a function.],
          )
          return
        }
        variables.update(old => {
          old.insert(parsed-function.name, parsed-function)
          old
        })
        render-tokens(tokenize(source.replace(":=", "=")), scope: current, aliases: aliases)
        return
      }
      let unloaded = ()
      for (stored-name, item) in current {
        if is-unloaded(item) { unloaded.push(stored-name) }
      }
      let assignment-is-unloaded = stores-result and name != none and name in unloaded
      let illegal-assignment = stores-result and name != none and (resolve-unit(name) != none or name in aliases) and not assignment-is-unloaded
      let tokens = if display-only { tokenize(source) } else { expression-tokens(expression) }
      let evaluation-tokens = if display-only { tokens } else { tokenize(expression) }
      let function-expansion = if display-only { (evaluation-tokens, false) } else { expand-function-calls(evaluation-tokens, current) }
      let function-error = if is-calculation-failure(function-expansion) { function-expansion.error } else { none }
      let calculation-tokens = if function-error == none { function-expansion.first() } else { tokens }
      let nested-expansion = if function-error == none and function-expansion.last() {
        expand-function-calls(calculation-tokens, current)
      } else {
        (calculation-tokens, false)
      }
      if not is-calculation-failure(nested-expansion) and nested-expansion.last() {
        calculation-tokens = nested-expansion.first()
      }
      let missing = if display-only { () } else { missing-variables(tokens, current, unloaded, aliases: aliases) }
      let result = if illegal-assignment or display-only or missing.len() > 0 or function-error != none { none } else {
        let calculation-scope = numeric-scope(current)
        calculate-expanded(
          calculate,
          calculation-tokens,
          digits,
          calculation-scope,
          unit,
          size,
          block,
          unloaded,
          aliases,
        )
      }
      let calculation-error = if is-calculation-failure(result) { result.error } else { none }

      if illegal-assignment {
        text(
          fill: red,
          [math-once: #raw(name) is a unit name and cannot be used as a variable.],
        )
      } else if missing.len() > 0 and calculated-assignment != none {
        // Preserve ordinary symbolic equations when their right-hand side
        // cannot be evaluated from known variables, numbers, and units.
        render-tokens(tokenize(source), scope: current, aliases: aliases)
      } else if missing.len() > 0 {
        text(
          fill: red,
          [math-once: #raw(missing.first()) is not set.],
        )
      } else if function-error != none {
        text(fill: red, [math-once: #function-error.])
      } else if calculation-error != none {
        text(
          fill: red,
          [math-once: #calculation-error.],
        )
      } else if display-only {
        render-tokens(tokens, scope: current, aliases: aliases)
      } else if name != none {
        let name-scope = current
        name-scope.insert(name, 0)
        let labelled-body = render-tokens((name,), scope: name-scope, aliases: aliases) + h(0.25em) + math.eq + h(0.25em) + render-tokens(tokens, scope: current, aliases: aliases)
        if show-result {
          let (expanded, has-variables) = expand-variables(tokens, current)
          if has-variables {
            labelled-body += h(0.25em) + math.eq + h(0.25em) + render-tokens(expanded, aliases: aliases)
          }
          let last-visible-tokens = if has-variables { expanded } else { tokens }
          if not equivalent-tokens(last-visible-tokens, result-tokens(result)) {
            labelled-body += h(0.25em) + math.eq + h(0.25em) + render-result(result, aliases: aliases)
          }
        }
        if stores-result {
          result.insert("display", math.equation(labelled-body, block: block))
          result.insert("variable", name)
          if assignment-is-unloaded { result.insert("unloaded", true) }
          variables.update(old => {
            old.insert(name, result)
            old
          })
          result.display.body
        } else {
          labelled-body
        }
      } else {
        let labelled-body = render-tokens(tokens, scope: current, aliases: aliases)
        if function-expansion.last() and vector-components(calculation-tokens) == none {
          labelled-body += h(0.25em) + math.eq + h(0.25em) + render-tokens(calculation-tokens, scope: numeric-scope(current), aliases: aliases)
        }
        let (expanded, has-variables) = expand-variables(tokens, current)
        if has-variables {
          labelled-body += h(0.25em) + math.eq + h(0.25em) + render-tokens(expanded, aliases: aliases)
        }
        let last-visible-tokens = if has-variables { expanded } else { tokens }
        if result.at("vector", default: false) or not equivalent-tokens(last-visible-tokens, result-tokens(result)) {
          labelled-body += h(0.25em) + math.eq + h(0.25em) + render-result(result, aliases: aliases)
        }
        labelled-body
      }
    }
    let output = _make-equation(
      _captioned-body(equation-body, caption, gap),
      block,
      supplement,
    )
    if label == none { output } else { [#output #label] }
  }
}

// Normalize a reset or unload argument to a builder state name.
let state-name(value, action) = {
  let name = input-source(value).trim()
  if regex("^[A-Za-z]+(?:_[A-Za-z0-9]+)*$") not in name {
    panic(
      "math-once " + action
      + ": names must contain letters and optional letter or number subscripts",
    )
  }
  name
}

/// Clear the complete calculation-builder state.
let reset(key: "math-once-calculation") = {
  let variables = state(key, (:))
  variables.update(_ => (:))
}

/// Clear selected or all stored values while preserving builder configuration.
let reset-variables(..names, key: "math-once-calculation") = {
  let selected = names.pos().map(value => state-name(value, "reset-variables"))
  let variables = state(key, (:))
  variables.update(old => {
    let initial = state-initial-values(old)
    let kept = old
    let targets = if selected.len() == 0 { old.keys() } else { selected }
    for name in targets {
      let item = kept.at(name, default: none)
      if item == none or is-stored-variable(item) {
        if item != none and is-unloaded(item) {
          let marker = (unloaded: true)
          if is-renamed-unit(item) { marker.insert("renamed-unit", true) }
          kept.insert(name, marker)
        } else if item != none {
          let _ = kept.remove(name)
        }
        if name in initial and name not in kept {
          kept.insert(name, initial.at(name))
        }
      }
    }
    if selected.len() == 0 {
      for (name, value) in initial {
        if name not in kept { kept.insert(name, value) }
      }
    }
    kept
  })
}

/// Clear selected or all stored function definitions.
let reset-functions(..names, key: "math-once-calculation") = {
  let selected = names.pos().map(value => state-name(value, "reset-functions"))
  let variables = state(key, (:))
  variables.update(old => {
    let initial = state-initial-values(old)
    let kept = old
    for (name, value) in old {
      if is-stored-function(value) and (selected.len() == 0 or name in selected) {
        let _ = kept.remove(name)
        if name in initial { kept.insert(name, initial.at(name)) }
      }
    }
    kept
  })
}

/// Restore selected or all unit names made available with unload.
let restore-units(..names, key: "math-once-calculation") = {
  let selected = names.pos().map(value => state-name(value, "restore-units"))
  let variables = state(key, (:))
  variables.update(old => {
    let kept = old
    for (name, value) in old {
      if (is-unloaded(value)
        and not is-renamed-unit(value)
        and (selected.len() == 0 or name in selected)) {
        let _ = kept.remove(name)
      }
    }
    kept
  })
}

/// Remove selected or all rename-unit relationships.
let reset-unit-aliases(..names, key: "math-once-calculation") = {
  let selected = names.pos().map(value => state-name(value, "reset-unit-aliases"))
  let variables = state(key, (:))
  variables.update(old => {
    let originals = ()
    if selected.len() == 0 {
      for (_, value) in old {
        if is-unit-alias(value) and value.original not in originals {
          originals.push(value.original)
        }
      }
    } else {
      for name in selected {
        let item = old.at(name, default: none)
        let original = if item != none and is-unit-alias(item) {
          item.original
        } else if item != none and is-renamed-unit(item) {
          name
        } else {
          none
        }
        if original != none and original not in originals { originals.push(original) }
      }
    }
    let kept = (:)
    for (name, value) in old {
      let belongs-to-reset-alias = is-unit-alias(value) and value.original in originals
      if name not in originals and not belongs-to-reset-alias {
        kept.insert(name, value)
      }
    }
    kept
  })
}

/// Temporarily make unit names available as builder variable names.
let unload(..names, key: "math-once-calculation") = {
  let selected = names.pos().map(value => state-name(value, "unload"))
  if selected.len() == 0 {
    panic("math-once unload: pass at least one unit name")
  }
  let variables = state(key, (:))
  variables.update(old => {
    for name in selected {
      if resolve-unit(name) == none {
        continue
      } else if name in old and type(old.at(name)) == dictionary and "si-value" in old.at(name) {
        let value = old.at(name)
        value.insert("unloaded", true)
        old.insert(name, value)
      } else {
        old.insert(name, (unloaded: true))
      }
    }
    old
  })
}

/// Move an active unit spelling to a new alias until reset.
let rename-unit(from, to, key: "math-once-calculation") = {
  let from = state-name(from, "rename-unit")
  let to = state-name(to, "rename-unit")
  let variables = state(key, (:))
  context {
    let old = variables.get()
    let aliases = unit-aliases(old)
    let original = aliases.at(from, default: from)
    let source-is-unloaded = from in old and is-unloaded(old.at(from)) and from not in aliases
    let destination-is-unloaded = to in old and is-unloaded-marker(old.at(to))
    let error = if from == to {
      "source and destination must differ"
    } else if resolve-unit(original) == none or source-is-unloaded {
      "`" + from + "` is not an active unit or alias"
    } else if (resolve-unit(to) != none or to in aliases) and not destination-is-unloaded {
      "destination `" + to + "` is already a unit or alias"
    } else if to in old and not is-unloaded-marker(old.at(to)) and not is-unit-alias(old.at(to)) {
      "destination `" + to + "` is already a stored variable"
    } else {
      none
    }

    if error != none {
      align(center, text(fill: red, [math-once: #error.]))
    } else {
      variables.update(old => {
        if from in aliases {
          let _ = old.remove(from)
        }
        if original in old and type(old.at(original)) == dictionary and "si-value" in old.at(original) {
          let value = old.at(original)
          value.insert("unloaded", true)
          value.insert("renamed-unit", true)
          old.insert(original, value)
        } else {
          old.insert(original, (unloaded: true, renamed-unit: true))
        }
        old.insert(to, (unit-alias: true, original: original))
        old
      })
    }
  }
}

(
  calculate: calculate,
  calculation-builder: calculation-builder,
  reset: reset,
  reset-variables: reset-variables,
  reset-functions: reset-functions,
  restore-units: restore-units,
  reset-unit-aliases: reset-unit-aliases,
  unload: unload,
  rename-unit: rename-unit,
  text-unit: text-unit,
)
}

/// Create a literal, dimensionless label for a requested output unit.
///
/// - `label`: Non-empty text to display upright in the unit.
///
/// Use it inside unit math, such as
/// `unit: $#text-unit("lines") / m$`. A known quoted name such as `"cm"`
/// remains centimetres; `text-unit("cm")` is literal text instead.
#let text-unit(label) = (_engine.text-unit)(label)

/// Evaluate a dimensional, unit-aware expression.
///
/// - `source`: A trusted string, raw block, or Typst math equation containing
///   numbers, units, variables, parentheses, `sin`, `cos`, `tan`, `+`, `-`,
///   `*`, `/`, `^`, and optionally `to` or `=` for output conversion.
/// - `digits`: Decimal places used for the visible `value`. Default: `4`.
/// - `scope`: Numbers or earlier calculate results available as variables.
///   Unit names are reserved and cannot be used as variable names.
/// - `unit`: Optional requested output unit as a string, raw block, or Typst
///   math equation. This is an alternative to `to` or `=` in `source`.
/// - `size`: Optional positive SI scale for the displayed result. For example,
///   `$10^(-6)$` displays a length in micrometres. Cannot be combined with an
///   output unit.
/// - `block`: Whether the rendered equation is centered. Default: `true`.
///
/// Returns a dictionary with `display`, `value`, `exact`, `si-value`,
/// `dimensions`, `unit`, `size`, and `source`.
#let calculate(source, digits: 4, scope: (:), unit: none, size: none, block: true) = (_engine.calculate)(
  source,
  digits: digits,
  scope: scope,
  unit: unit,
  size: size,
  block: block,
)

/// Create a stateful calculator for sequences of equations.
///
/// - `initial-state`: Initial numeric values or calculate results. Unit names
///   are reserved and cannot be used as keys. Default: empty.
/// - `key`: Typst state key. Give independent runners different keys.
/// - `digits`: Default decimal places for runner calls. Default: `4`.
/// - `block`: Whether runner equations are centered. Default: `true`.
/// - `supplement`: Optional reference and caption name. Default: `auto`.
///
/// The returned runner accepts zero or one string, raw block, or Typst math
/// equation plus the named `digits`, `unit`, `size`, `show-result`, `block`, `label`,
/// `caption`, and `gap`, and `supplement` overrides.
/// Set `show-result: false` on a `:=` definition to store the exact calculated
/// value while showing only the written definition.
/// Scalar and vector functions can also be stored with `:=`, such as
/// `$f(x) := x + 1$` and `$arrow(s)(t) := vec(t, t^2)$`, then evaluated by
/// calling `$f(2)$` or `$arrow(s)(2)$`.
/// A definition like `$v := 10 m/s$` stores `v`; `$v = 10 m/s$` calculates and
/// displays the result without storing `v`. Other equations that do not have a
/// simple variable on the left remain display-only. Later expressions show an
/// extra step with stored variable values substituted. A label can be written after
/// the call as `#runner(...) <name>` or passed with `label: <name>`. Calling
/// the runner without an expression returns its result dictionary and must
/// happen in a `context` block. `caption` adds text below a block equation;
/// `gap` controls the space above that caption. Assigning to a reserved unit
/// name prints a red message and does not update the state.
#let calculation-builder(
  initial-state: (:),
  key: "math-once-calculation",
  digits: 4,
  block: true,
  supplement: auto,
) = (_engine.calculation-builder)(
  initial-state: initial-state,
  key: key,
  digits: digits,
  block: block,
  supplement: supplement,
)

/// Clear the complete `calculation-builder` state.
///
/// You may want `reset-variables` to keep unit configuration, `reset-functions`
/// to remove stored functions, `restore-units` to undo `unload`, or
/// `reset-unit-aliases` to undo `rename-unit` instead.
///
/// - `key`: The state key of the matching calculation builder. Default:
///   `"math-once-calculation"`.
///
/// Use `reset()` to clear the entire default builder state. The function
/// renders no output.
#let reset(key: "math-once-calculation") = (_engine.reset)(
  key: key,
)

/// Clear selected or all stored values while preserving functions and unit
/// configuration. Values from `initial-state` are restored instead of removed.
#let reset-variables(..names, key: "math-once-calculation") = (_engine.reset-variables)(
  ..names,
  key: key,
)

/// Clear selected or all stored scalar and vector function definitions.
#let reset-functions(..names, key: "math-once-calculation") = (_engine.reset-functions)(
  ..names,
  key: key,
)

/// Restore selected or all catalog unit names made available with `unload`.
/// Any stored variable using a restored unit name is removed.
#let restore-units(..names, key: "math-once-calculation") = (_engine.restore-units)(
  ..names,
  key: key,
)

/// Remove selected or all `rename-unit` relationships and restore their
/// original catalog unit spellings.
#let reset-unit-aliases(..names, key: "math-once-calculation") = (_engine.reset-unit-aliases)(
  ..names,
  key: key,
)

/// Temporarily make unit names available as calculation-builder variables.
///
/// - `names`: One or more known unit names as strings, raw text, or Typst math.
/// - `key`: The state key of the matching calculation builder. Default:
///   `"math-once-calculation"`.
///
/// The unload lasts until `restore-units(name)` restores that catalog spelling
/// or the complete state is cleared with `reset()`.
#let unload(..names, key: "math-once-calculation") = (_engine.unload)(
  ..names,
  key: key,
)

/// Move a unit name to a new alias until the matching reset.
///
/// - `from`: Active catalog unit name or alias.
/// - `to`: New alias. It must not already be an active unit or stored variable.
///   A catalog spelling made available with `unload` may be reused.
/// - `key`: State key of the matching calculation builder.
///
/// For example, `rename-unit($m$, $v$)` makes bare `m` available as a
/// variable and makes `v` mean metres. A later `rename-unit($v$, $"vme"$)`
/// moves that alias again. `reset-unit-aliases()` restores catalog spellings
/// without clearing unrelated values.
#let rename-unit(from, to, key: "math-once-calculation") = (_engine.rename-unit)(
  from,
  to,
  key: key,
)

/// Add a per-equation caption using an interface similar to `figure`.
///
/// - `body`: A Typst math equation, such as `$ E = m c^2 $`.
/// - `caption`: Optional caption shown below the equation. Default: `none`.
/// - `gap`: Space between the equation and caption. Default: `0.65em`.
/// - `supplement`: Optional reference and caption name. Default: `auto`.
///
/// The result remains a real `math.equation`, so a postfix label can be added
/// as `#equation($ ... $, caption: [...]) <label>` and referenced with `@label`.
#let equation(body, caption: none, gap: 0.65em, supplement: auto) = {
  if type(body) != content or body.func() != math.equation {
    panic("math-once equation: body must be a Typst math equation")
  }
  if caption == none and supplement == auto {
    return body
  }
  if caption != none and type(caption) not in (content, str) {
    panic("math-once equation: caption must be content, a string, or none")
  }
  if caption != none and not body.block {
    panic("math-once equation: captions require a block equation")
  }

  _make-equation(
    _captioned-body(body.body, caption, gap),
    body.block,
    supplement,
  )
}

/// Create a list of labelled, captioned equations with page numbers.
///
/// - `title`: Heading above the list. Default: `[List of Equations]`.
/// - `indent`: Outline indentation. Default: `auto`.
#let equation-outline(title: [List of Equations], indent: auto) = {
  show outline.entry: entry => {
    let equation = entry.element
    let caption = _equation-caption(equation)
    if caption == none or not equation.has("label") {
      none
    } else {
      entry.indented(
        ref(equation.label),
        [
          #caption
          #box(width: 1fr, entry.fill)
          #entry.page()
        ],
      )
    }
  }
  outline(
    title: title,
    target: math.equation.where(block: true),
    indent: indent,
  )
}

/// Number block equations only when they have a label, while keeping the
/// original equation elements intact so Typst references continue to work.
///
/// Use this as a document show rule: `#show: number-labelled-equations`.
///
/// - `body`: Document content supplied automatically by the show rule.
/// - `numbering`: Numbering pattern or function for labelled equations.
///   Default: `"(1)"`.
/// - `supplement`: Name placed before equation references. Default: `auto`.
/// - `captions`: Dictionary mapping label names to caption content.
///   Default: empty.
#let number-labelled-equations(
  body,
  numbering: "(1)",
  supplement: auto,
  captions: (:),
) = {
  if type(captions) != dictionary {
    panic("math-once number-labelled-equations: captions must be a dictionary")
  }
  set math.equation(numbering: numbering, supplement: supplement)
  show math.equation: equation => {
    if equation.block and not equation.has("label") and equation.numbering != none {
      counter(math.equation).update(value => calc.max(0, value - 1))
      math.equation(
        equation.body,
        block: true,
        numbering: none,
        number-align: equation.number-align,
        supplement: equation.supplement,
        alt: equation.alt,
      )
    } else if equation.block and equation.has("label") and str(equation.label) in captions {
      let caption = captions.at(str(equation.label))
      [
        #equation
        #align(center, text(size: 0.9em)[#ref(equation.label): #caption])
      ]
    } else if equation.block and equation.has("label") {
      [
        #_caption-label.update(equation.label)
        #equation
        #_caption-label.update(none)
      ]
    } else {
      equation
    }
  }
  body
}
