// math-once: reusable calculations with a unit-aware evaluator.

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
  t:   (scale: 3600.0, dims: dim(time: 1)), // Danish "timer".
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
units.insert("t", (scale: 3600.0, dims: dim(time: 1)))
units.insert("timer", units.at("t"))
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

let quantity(si-value, dims: zero-dim, preferred: none, affine: none) = (
  si-value: si-value,
  dims: dims,
  preferred: preferred,
  affine: affine,
)

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

let is-dimensionless(q) = q.dims == zero-dim

let dimensions-name(dims) = {
  let known = (
    (dim(length: 1), "length"),
    (dim(mass: 1), "mass"),
    (dim(time: 1), "time"),
    (dim(length: 1, time: -1), "speed"),
    (dim(length: 1, time: -2), "acceleration"),
    (dim(length: 2), "area"),
    (dim(length: 3), "volume"),
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

let engineering-length-units = (
  ("Ym", 1e24), ("Zm", 1e21), ("Em", 1e18), ("Pm", 1e15),
  ("Tm", 1e12), ("Gm", 1e9), ("Mm", 1e6), ("km", 1e3),
  ("m", 1.0), ("mm", 1e-3), ("µm", 1e-6), ("nm", 1e-9),
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

let math-functions = ("sin", "cos", "tan")

// Convert the subset of Typst math supported by calculate back into parser input.
// This makes `$v = 902 / 3.6$` as useful as the raw form `` `v = 902 / 3.6` ``.
let math-items(value) = if value.has("children") { value.children } else { (value,) }

let math-source-part(value, parse) = {
  if repr(value.func()) == "space" { return "" }
  if value.func() == math.frac {
    return "(" + parse(value.num) + ")/(" + parse(value.denom) + ")"
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
  let variable-name = variable-symbol-name(token)
  if variable-name != none { variable-name }
  else if token in ("⋅", "∗", "×") { "*" }
  else if token in ("÷",) { "/" }
  else if token in ("−",) { "-" }
  else { token }
}

let math-source-body(body) = math-items(body).map(item => {
  if item == [#math.eq] { "=" } else { math-source-part(item, math-source-body) }
}).filter(item => item != "").join(" ")

let input-source(source) = if type(source) == content and source.func() == math.equation {
  math-source-body(source.body).trim()
} else {
  source-string(source)
}

let tokenize(source) = {
  let name = "[\\p{L}°℃℉ℏ₂☉]+(?:_[\\p{L}0-9°℃℉ℏ₂☉]+)*"
  let pattern = regex("(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?|" + name + "|[=()+*/^+\\-]")
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
let can-end(token) = is-number(token) or is-name(token) or token == ")"
let can-start(token) = is-number(token) or is-name(token) or token == "("

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

let render-tokens(tokens, scope: (:)) = {
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

  let source = tokens.map(token => {
    if is-name(token) {
      if token in math-functions {
        token
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
  }).join(" ")
  eval(source, mode: "math").body
}

let compact-unit-tokens(tokens) = {
  let result = ()
  let index = 0
  while index < tokens.len() {
    if (index + 2 < tokens.len()
      and tokens.at(index) == "("
      and is-name(tokens.at(index + 1))
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

let equivalent-tokens(left, right) = {
  left = compact-unit-tokens(left)
  right = compact-unit-tokens(right)
  if left.len() != right.len() { return false }
  for (left-token, right-token) in left.zip(right) {
    if is-number(left-token) and is-number(right-token) {
      if float(left-token) != float(right-token) { return false }
    } else if left-token != right-token {
      return false
    }
  }
  true
}

let result-tokens(result) = {
  let tokens = (str(result.value),)
  if result.unit != none { tokens += tokenize(result.unit) }
  tokens
}

let expand-variables(tokens, scope) = {
  let expanded = ()
  let changed = false
  for (index, token) in tokens.enumerate() {
    if is-name(token) and token in scope {
      if index > 0 and can-end(tokens.at(index - 1)) {
        expanded.push("*")
      }
      let item = scope.at(token)
      if type(item) == dictionary and "value" in item {
        expanded.push(str(item.value))
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

let normalize-scope(scope) = {
  let normalized = (:)
  for (name, item) in scope {
    if type(item) == dictionary and "si-value" in item and "dimensions" in item {
      normalized.insert(name, quantity(item.si-value, dims: item.dimensions, preferred: item.unit))
    } else if type(item) in (int, float, decimal) {
      normalized.insert(name, quantity(float(item)))
    } else {
      panic("math-once calculate: scope `" + name + "` must be a number or calculate result")
    }
  }
  normalized
}

let apply-op(op, left, right) = {
  if op == "+" or op == "-" {
    if left.dims != right.dims {
      panic(
        "math-once calculate: cannot " + if op == "+" { "add " } else { "subtract " }
        + dimensions-name(left.dims) + " and " + dimensions-name(right.dims),
      )
    }
    return quantity(
      if op == "+" { left.si-value + right.si-value } else { left.si-value - right.si-value },
      dims: left.dims,
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
      panic("math-once calculate: affine units must be multiplied by a plain number")
    }
    return quantity(
      left.si-value * right.si-value,
      dims: dims-add(left.dims, right.dims),
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
      panic("math-once calculate: affine units cannot be divided")
    }
    return quantity(
      left.si-value / right.si-value,
      dims: dims-add(left.dims, right.dims, factor: -1),
      preferred: if is-dimensionless(right) and right.preferred == none { left.preferred } else { none },
    )
  }
  if op == "^" {
    if left.affine != none {
      panic("math-once calculate: affine units cannot be raised to a power")
    }
    if not is-dimensionless(right) {
      panic("math-once calculate: exponent must be dimensionless")
    }
    let exponent = right.si-value
    if not is-dimensionless(left) and exponent != calc.round(exponent) {
      panic("math-once calculate: a unit may only be raised to an integer power")
    }
    return quantity(
      calc.pow(left.si-value, exponent),
      dims: dims-scale(left.dims, exponent),
    )
  }
  panic("math-once calculate: unsupported operator `" + op + "`")
}

let apply-function(name, argument) = {
  if not is-dimensionless(argument) {
    panic("math-once calculate: `" + name + "` requires a dimensionless angle")
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
    else { panic("math-once calculate: unsupported function `" + name + "`") },
  )
}

let parse(tokens, scope: (:)) = {
  let scope = normalize-scope(scope)
  let precedence = ("+": 1, "-": 1, "*": 2, "/": 2, "^": 3)

  let parse-expression(tokens, position, minimum: 0) = {
    if position >= tokens.len() {
      panic("math-once calculate: expected a number, variable, unit, or parenthesis")
    }

    let token = tokens.at(position)
    let left = none
    if token in math-functions {
      if position + 1 >= tokens.len() or tokens.at(position + 1) != "(" {
        panic("math-once calculate: `" + token + "` must be followed by parentheses")
      }
      let (argument, next) = parse-expression(tokens, position + 2)
      if next >= tokens.len() or tokens.at(next) != ")" {
        panic("math-once calculate: missing closing parenthesis after `" + token + "`")
      }
      left = apply-function(token, argument)
      position = next + 1
    } else if token == "+" or token == "-" {
      let (operand, next) = parse-expression(tokens, position + 1, minimum: 3)
      left = if token == "-" {
        quantity(-operand.si-value, dims: operand.dims, preferred: operand.preferred)
      } else {
        operand
      }
      position = next
    } else if token == "(" {
      let (inside, next) = parse-expression(tokens, position + 1)
      if next >= tokens.len() or tokens.at(next) != ")" {
        panic("math-once calculate: missing closing parenthesis")
      }
      left = inside
      position = next + 1
    } else if is-number(token) {
      left = quantity(float(token))
      position += 1
    } else if is-name(token) {
      if token in scope {
        left = scope.at(token)
      } else {
        let unit = resolve-unit(token)
        if unit != none {
          let offset = unit.at("offset", default: 0.0)
          let affine = if offset == 0.0 { none } else {
            (scale: unit.scale, offset: offset)
          }
          left = quantity(
            unit.scale + offset,
            dims: unit.dims,
            preferred: token,
            affine: affine,
          )
        } else {
          panic("math-once calculate: unknown variable or unit `" + token + "`")
        }
      }
      position += 1
    } else {
      panic("math-once calculate: unexpected token `" + token + "`")
    }

    while position < tokens.len() {
      let op = tokens.at(position)
      if op == ")" or op not in precedence { break }
      let op-precedence = precedence.at(op)
      if op-precedence < minimum { break }
      let next-minimum = if op == "^" { op-precedence } else { op-precedence + 1 }
      let (right, next) = parse-expression(tokens, position + 1, minimum: next-minimum)
      left = apply-op(op, left, right)
      position = next
    }
    (left, position)
  }

  let (result, position) = parse-expression(tokens, 0)
  if position != tokens.len() {
    panic("math-once calculate: unexpected token `" + tokens.at(position) + "`")
  }
  result
}

/// Evaluate a unit-aware expression containing numbers, units, variables,
/// `sin`, `cos`, `tan`, and the operators `+`, `-`, `*`, `/`, and `^`.
///
/// Use `to`, `=`, or the `unit` argument to request an output unit.
let calculate(source, digits: 4, scope: (:), unit: none, block: true) = {
  let source = input-source(source)
  let raw-tokens = tokenize(source)
  let depth = 0
  let conversion-index = none
  for (index, token) in raw-tokens.enumerate() {
    if token == "(" { depth += 1 }
    if token == ")" { depth -= 1 }
    if token in ("to", "=") and depth == 0 {
      if conversion-index != none { panic("math-once calculate: only one output-unit separator is allowed") }
      conversion-index = index
    }
  }
  if depth != 0 { panic("math-once calculate: unbalanced parentheses") }

  if conversion-index != none and unit != none {
    panic("math-once calculate: use only one of `to`, `=`, or `unit`")
  }

  let expression-tokens = if conversion-index == none { raw-tokens } else { raw-tokens.slice(0, conversion-index) }
  let target-tokens = if conversion-index != none {
    raw-tokens.slice(conversion-index + 1)
  } else if unit != none {
    compact-unit-tokens(tokenize(input-source(unit)))
  } else {
    none
  }
  if expression-tokens.len() == 0 { panic("math-once calculate: missing expression before output conversion") }
  if target-tokens != none and target-tokens.len() == 0 { panic("math-once calculate: missing output unit") }

  let result = parse(add-implicit-multiplication(expression-tokens), scope: scope)
  let output-unit = result.preferred
  let output-scale = 1.0
  let output-offset = 0.0
  if target-tokens != none {
    let target = parse(add-implicit-multiplication(target-tokens))
    if target.dims != result.dims {
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
        panic("math-once calculate: cannot convert " + dimensions-name(result.dims) + " to " + dimensions-name(target.dims))
      }
    }
    output-unit = target-tokens.join("")
    output-scale = if target.affine == none { target.si-value } else { target.affine.scale }
    output-offset = if target.affine == none { 0.0 } else { target.affine.offset }
  } else if output-unit == none and not is-dimensionless(result) {
    output-unit = canonical-unit(result.dims)
  } else if output-unit != none {
    let preferred = parse(add-implicit-multiplication(tokenize(output-unit)))
    output-scale = if preferred.affine == none { preferred.si-value } else { preferred.affine.scale }
    output-offset = if preferred.affine == none { 0.0 } else { preferred.affine.offset }
  }

  if target-tokens == none and result.dims == dim(length: 1) {
    let scaled-unit = auto-length-unit(result.si-value, output-unit)
    if scaled-unit != output-unit {
      output-unit = scaled-unit
      output-scale = resolve-unit(output-unit).scale
    }
  }

  let exact = (result.si-value - output-offset) / output-scale
  let value = calc.round(exact, digits: digits)
  let display-body = render-tokens(expression-tokens, scope: scope) + h(0.25em) + math.eq + h(0.25em) + str(value)
  if output-unit != none {
    let output-tokens = if target-tokens != none { target-tokens } else { tokenize(output-unit) }
    display-body += h(0.2em) + render-tokens(output-tokens)
  }

  (
    value: value,
    exact: exact,
    si-value: result.si-value,
    dimensions: result.dims,
    unit: output-unit,
    source: source,
    display: math.equation(display-body, block: block),
  )
}

/// Create a stateful equation runner with reusable variables.
///
/// Named expressions such as `v = 10 m/s` are stored and automatically made
/// available to later calls. Call the runner without an expression inside a
/// context block to retrieve its dictionary of results.
let calculation-builder(
  initial-state: (:),
  key: "math-once-calculation",
  digits: 4,
  block: true,
  supplement: auto,
) = {
  let variables = state(key, initial-state)

  (
    ..args,
    digits: digits,
    unit: none,
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
      return variables.get()
    }

    let source = input-source(source)
    let assignment = source.match(regex("^\\s*([A-Za-z]+(?:_[A-Za-z0-9]+)*)\\s*=\\s*(.+)$"))
    let name = if assignment == none { none } else { assignment.captures.at(0) }
    let expression = if assignment == none { source } else { assignment.captures.at(1) }

    if caption != none and not block {
      panic("math-once calculation-builder: captions require block: true")
    }
    if caption != none and type(caption) not in (content, str) {
      panic("math-once calculation-builder: caption must be content, a string, or none")
    }

    let equation-body = context {
      let current = variables.get()
      let result = calculate(expression, digits: digits, scope: current, unit: unit, block: block)

      if name != none {
        let tokens = expression-tokens(expression)
        let name-scope = current
        name-scope.insert(name, 0)
        let labelled-body = render-tokens((name,), scope: name-scope) + h(0.25em) + math.eq + h(0.25em) + render-tokens(tokens, scope: current)
        let (expanded, has-variables) = expand-variables(tokens, current)
        if has-variables {
          labelled-body += h(0.25em) + math.eq + h(0.25em) + render-tokens(expanded)
        }
        let last-visible-tokens = if has-variables { expanded } else { tokens }
        if not equivalent-tokens(last-visible-tokens, result-tokens(result)) {
          labelled-body += h(0.25em) + math.eq + h(0.25em) + str(result.value)
          if result.unit != none {
            labelled-body += h(0.2em) + render-tokens(tokenize(result.unit))
          }
        }
        result.insert("display", math.equation(labelled-body, block: block))
        result.insert("variable", name)
        variables.update(old => {
          old.insert(name, result)
          old
        })
      }

      result.display.body
    }
    let output = _make-equation(
      _captioned-body(equation-body, caption, gap),
      block,
      supplement,
    )
    if label == none { output } else { [#output #label] }
  }
}

(
  calculate: calculate,
  calculation-builder: calculation-builder,
)
}

/// Evaluate a dimensional, unit-aware expression.
///
/// - `source`: A trusted string, raw block, or Typst math equation containing
///   numbers, units, variables, parentheses, `sin`, `cos`, `tan`, `+`, `-`,
///   `*`, `/`, `^`, and optionally `to` or `=` for output conversion.
/// - `digits`: Decimal places used for the visible `value`. Default: `4`.
/// - `scope`: Numbers or earlier calculate results available as variables.
/// - `unit`: Optional requested output unit as a string, raw block, or Typst
///   math equation. This is an alternative to `to` or `=` in `source`.
/// - `block`: Whether the rendered equation is centered. Default: `true`.
///
/// Returns a dictionary with `display`, `value`, `exact`, `si-value`,
/// `dimensions`, `unit`, and `source`.
#let calculate(source, digits: 4, scope: (:), unit: none, block: true) = (_engine.calculate)(
  source,
  digits: digits,
  scope: scope,
  unit: unit,
  block: block,
)

/// Create a stateful calculator for sequences of equations.
///
/// - `initial-state`: Initial numeric values or calculate results. Default: empty.
/// - `key`: Typst state key. Give independent runners different keys.
/// - `digits`: Default decimal places for runner calls. Default: `4`.
/// - `block`: Whether runner equations are centered. Default: `true`.
/// - `supplement`: Optional reference and caption name. Default: `auto`.
///
/// The returned runner accepts zero or one string, raw block, or Typst math
/// equation plus the named `digits`, `unit`, `block`, `label`, `caption`, and
/// `gap`, and `supplement` overrides.
/// An assignment like `$v = 10 m/s$` stores `v`. Later equations show an extra
/// step with stored variable values substituted. A label can be written after
/// the call as `#runner(...) <name>` or passed with `label: <name>`. Calling
/// the runner without an expression returns its result dictionary and must
/// happen in a `context` block. `caption` adds text below a block equation;
/// `gap` controls the space above that caption.
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
          #link(equation.location(), caption)
          #box(width: 1fr, entry.fill)
          #link(equation.location(), entry.page())
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
