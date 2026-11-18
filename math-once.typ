// Faster math input and calculation pipeline (0.50.0)
// Reusable calculations with a unit-aware evaluator.

#import "@preview/typcas:0.2.3": cas

// Convert a dictionary or an array of (name, value) pairs to a dictionary.
// Returns none for anything else.
#let _pairs-to-dict(value) = if type(value) == dictionary {
  value
} else if type(value) == array and value.all(pair => type(pair) == array and pair.len() == 2 and type(pair.first()) == str) {
  value.to-dict()
}

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

  let scope-dict = _pairs-to-dict(scope)
  if scope-dict == none {
    panic("math-once evaluate-code: `scope:` must be a dictionary of values, such as `scope: (v: 12)`, not " + repr(scope))
  }
  let evaluation-scope = (:)
  for (name, item) in scope-dict {
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

// Shared option checks. Each returns an error message, or none when valid.
#let _unit-option-error(unit) = if type(unit) == bool {
  "`unit:` selects an output unit, such as `unit: $m$`, and cannot be a boolean; to hide the unit, use `show-unit: false` instead of `unit: " + repr(unit) + "`"
} else if unit == none or type(unit) == str or (type(unit) == content and unit.func() in (raw, math.equation)) {
  none
} else {
  "`unit:` must be an output unit, such as `unit: $m$`, or none, not " + repr(unit)
}
#let _key-option-error(key) = if type(key) != str {
  "`key:` must be a string naming the builder state, not " + repr(key)
}
#let _supplement-option-error(supplement) = if supplement != auto and supplement != none and type(supplement) not in (content, str, function) {
  "`supplement:` must be auto, none, content, a string, or a function, not " + repr(supplement)
}
#let _gap-option-error(gap) = if gap != none and type(gap) not in (length, ratio, relative, fraction) {
  "`gap:` must be a length, such as `gap: 0.65em`, a relative length, a fraction, or none, not " + repr(gap)
}
#let _label-option-error(label-value) = if label-value != none and type(label-value) != label {
  "`label:` must be a label in angle brackets, such as `label: <speed>`, or none, not " + repr(label-value)
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
units.insert("degrees", units.deg)
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
  (names: ("degree", "degrees", "deg", "°"), scale: 0.01745329252, dims: dim()),
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
for name in ("degree", "degrees", "deg", "°") {
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

// Resolve the finite prefix catalog once, preserving the first matching prefix.
let prefixed-units = {
  let resolved = (:)
  for (prefix, factor) in prefixes {
    for base in prefixable {
      let unit = units.at(base)
      let name = prefix + base
      if name not in resolved and unit.at("offset", default: 0.0) == 0.0 {
        resolved.insert(name, (scale: factor * unit.scale, dims: unit.dims, offset: 0.0))
      }
    }
  }
  for (prefix, factor) in binary-prefixes {
    for base in binary-prefixable {
      let unit = units.at(base)
      let name = prefix + base
      if name not in resolved {
        resolved.insert(name, (scale: factor * unit.scale, dims: unit.dims, offset: 0.0))
      }
    }
  }
  resolved
}

let resolve-unit(name) = units.at(name, default: prefixed-units.at(name, default: none))

let resolve-unit-with-aliases(name, aliases: (:)) = {
  if name in aliases { resolve-unit(aliases.at(name)) } else { resolve-unit(name) }
}

let quantity(si-value, dims: zero-dim, preferred: none, affine: none, affine-kind: none, opaque: (:)) = (
  si-value: si-value,
  dims: dims,
  preferred: preferred,
  affine: affine,
  affine-kind: affine-kind,
  opaque: opaque,
)

let calculation-failure(message) = (error: message)
let is-calculation-failure(value) = type(value) == dictionary and "error" in value
let calculation-fail(message, soft: false) = if soft {
  calculation-failure(message)
} else {
  panic("math-once calculate: " + message)
}

// Floats overflow to infinity (and then to NaN) instead of failing, and Typst's
// own comparisons and rounding stop compilation on those values.
let is-finite-number(value) = not (float.is-nan(float(value)) or float.is-infinite(float(value)))
let overflow-message = "the result is too large to calculate"

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
    (dim(length: -2, mass: -1, time: 2), "1/J"),
    (dim(length: 2, mass: 1, time: -3), "W"),
    (dim(time: 1, current: 1), "C"),
    (dim(length: 2, mass: 1, time: -3, current: -1), "V"),
    (dim(length: -2, mass: -1, time: 4, current: 2), "F"),
    (dim(length: 2, mass: 1, time: -3, current: -2), "Ω"),
    (dim(length: -2, mass: -1, time: 3, current: 2), "S"),
    (dim(length: 2, mass: 1, time: -2, current: -1), "Wb"),
    (dim(mass: 1, time: -2, current: -1), "T"),
    (dim(length: 2, mass: 1, time: -2, current: -2), "H"),
    (dim(length: -2, luminosity: 1), "lx"),
    (dim(time: -1, amount: 1), "kat"),
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

let ambiguous-unit(dims) = {
  let known = (
    (dim(time: -1), ("Hz", "Bq", "1/s")),
    (dim(length: 2, time: -2), ("Gy", "Sv", "m^2/s^2")),
    (dim(length: 2, mass: 1, time: -2), ("J", "Nm", "kg*m^2/s^2")),
    (dim(luminosity: 1), ("cd", "lm")),
  )
  for (candidate, choices) in known {
    if dims == candidate {
      return choices
    }
  }
  none
}

let ambiguous-unit-message(ambiguity) = {
  let choices = ambiguity.map(choice => "`$" + choice + "$`")
  let suggestion = if choices.len() == 2 {
    choices.join(" or ")
  } else {
    choices.slice(0, -1).join(", ") + ", or " + choices.last()
  }
  "ambiguous unit; specify `unit:` as " + suggestion
}

let unit-kind-name(q) = {
  let physical = dimensions-name(q.dims)
  let physical = if physical == "incompatible dimensions" {
    "dimensions `" + canonical-unit(q.dims) + "`"
  } else {
    physical + " (`" + canonical-unit(q.dims) + "`)"
  }
  if q.opaque.len() > 0 and q.dims != zero-dim {
    "custom unit `" + q.opaque.keys().join(" ") + "` with " + physical
  } else if q.opaque.len() > 0 {
    "custom unit `" + q.opaque.keys().join(" ") + "`"
  } else {
    physical
  }
}

let canonical-opaque-unit(opaque, dims: zero-dim) = {
  let numerator = ()
  let denominator = ()
  for (name, exponent) in opaque {
    let magnitude = calc.abs(exponent)
    let part = name + if magnitude == 1 { "" } else { "^" + str(magnitude) }
    if exponent > 0 { numerator.push(part) } else { denominator.push(part) }
  }
  if dims != zero-dim {
    let physical = canonical-unit(dims).split("/")
    if physical.first() != "1" { numerator += physical.first().split(" ") }
    if physical.len() > 1 { denominator += physical.at(1).split(" ") }
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

let sized-output-unit(dims, size, opaque: (:), notation: none) = {
  if opaque.len() == 0 and dims == dim(length: 1) {
    for (unit, scale) in engineering-length-units {
      if calc.abs(scale - size) <= calc.max(calc.abs(scale), calc.abs(size)) * 1e-12 { return unit }
    }
  }
  let base-unit = if opaque.len() > 0 {
    canonical-opaque-unit(opaque, dims: dims)
  } else {
    canonical-unit(dims)
  }
  let expression = scientific-size-expression(size, notation: notation)
  if expression != none {
    expression + " " + base-unit
  } else {
    "(" + str(size) + ") " + base-unit
  }
}

let sized-requested-unit(dims, unit, unit-scale, size, opaque: (:), notation: none) = {
  let scale = unit-scale * size
  let familiar = sized-output-unit(dims, scale, opaque: opaque)
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
  panic("math-once calculate: expression must be a string, raw text, or math equation, such as `$v := 10 m/s$`, not " + repr(source))
}

// BEGIN GENERATED TYPST SYMBOL CATALOG
// Generated from codex 0.2.0's sym.txt for Typst 0.14.2.
// 1100 canonical named paths; regenerate with tools/generate-symbol-catalog.py.
let typst-symbol-catalog = (
  "wj": "⁠",
  "zwj": "‍",
  "zwnj": "‌",
  "zws": "​",
  "lrm": "‎",
  "rlm": "‏",
  "space": " ",
  "space.nobreak": " ",
  "space.nobreak.narrow": " ",
  "space.en": " ",
  "space.quad": " ",
  "space.third": " ",
  "space.quarter": " ",
  "space.sixth": " ",
  "space.med": " ",
  "space.fig": " ",
  "space.punct": " ",
  "space.thin": " ",
  "space.hair": " ",
  "paren.l": "(",
  "paren.l.flat": "⟮",
  "paren.l.closed": "⦇",
  "paren.l.stroked": "⦅",
  "paren.r": ")",
  "paren.r.flat": "⟯",
  "paren.r.closed": "⦈",
  "paren.r.stroked": "⦆",
  "paren.t": "⏜",
  "paren.b": "⏝",
  "brace.l": "{",
  "brace.l.stroked": "⦃",
  "brace.r": "}",
  "brace.r.stroked": "⦄",
  "brace.t": "⏞",
  "brace.b": "⏟",
  "bracket.l": "[",
  "bracket.l.tick.t": "⦍",
  "bracket.l.tick.b": "⦏",
  "bracket.l.stroked": "⟦",
  "bracket.r": "]",
  "bracket.r.tick.t": "⦐",
  "bracket.r.tick.b": "⦎",
  "bracket.r.stroked": "⟧",
  "bracket.t": "⎴",
  "bracket.b": "⎵",
  "shell.l": "❲",
  "shell.l.stroked": "⟬",
  "shell.l.filled": "⦗",
  "shell.r": "❳",
  "shell.r.stroked": "⟭",
  "shell.r.filled": "⦘",
  "shell.t": "⏠",
  "shell.b": "⏡",
  "bag.l": "⟅",
  "bag.r": "⟆",
  "mustache.l": "⎰",
  "mustache.r": "⎱",
  "bar.v": "|",
  "bar.v.double": "‖",
  "bar.v.triple": "⦀",
  "bar.v.broken": "¦",
  "bar.v.o": "⦶",
  "bar.h": "―",
  "fence.l": "⧘",
  "fence.l.double": "⧚",
  "fence.r": "⧙",
  "fence.r.double": "⧛",
  "fence.dotted": "⦙",
  "chevron.l": "⟨",
  "chevron.l.curly": "⧼",
  "chevron.l.dot": "⦑",
  "chevron.l.closed": "⦉",
  "chevron.l.double": "⟪",
  "chevron.r": "⟩",
  "chevron.r.curly": "⧽",
  "chevron.r.dot": "⦒",
  "chevron.r.closed": "⦊",
  "chevron.r.double": "⟫",
  "ceil.l": "⌈",
  "ceil.r": "⌉",
  "floor.l": "⌊",
  "floor.r": "⌋",
  "corner.l.t": "⌜",
  "corner.l.b": "⌞",
  "corner.r.t": "⌝",
  "corner.r.b": "⌟",
  "amp": "&",
  "amp.inv": "⅋",
  "ast.op": "∗",
  "ast.op.o": "⊛",
  "ast.basic": "*︎",
  "ast.low": "⁎",
  "ast.double": "⁑",
  "ast.triple": "⁂",
  "ast.square": "⧆",
  "at": "@",
  "backslash": "\\",
  "backslash.o": "⦸",
  "backslash.not": "⧷",
  "co": "℅",
  "colon": ":",
  "colon.currency": "₡",
  "colon.double": "∷",
  "colon.tri": "⁝",
  "colon.tri.op": "⫶",
  "colon.eq": "≔",
  "colon.double.eq": "⩴",
  "comma": ",",
  "comma.inv": "⸲",
  "comma.rev": "⹁",
  "dagger": "†",
  "dagger.double": "‡",
  "dagger.triple": "⹋",
  "dagger.l": "⸶",
  "dagger.r": "⸷",
  "dagger.inv": "⸸",
  "dash.en": "–",
  "dash.em": "—",
  "dash.em.two": "⸺",
  "dash.em.three": "⸻",
  "dash.fig": "‒",
  "dash.colon": "∹",
  "dash.o": "⊝",
  "dash.wave": "〜",
  "dash.wave.double": "〰︎",
  "dot.op": "⋅",
  "dot.basic": ".",
  "dot.c": "·",
  "dot.o": "⊙",
  "dot.o.big": "⨀",
  "dot.square": "⊡",
  "dot.double": "¨",
  "dot.triple": "⃛",
  "dot.quad": "⃜",
  "excl": "!",
  "excl.double": "‼︎",
  "excl.inv": "¡",
  "excl.quest": "⁉︎",
  "quest": "?",
  "quest.double": "⁇",
  "quest.excl": "⁈",
  "quest.inv": "¿",
  "interrobang": "‽",
  "interrobang.inv": "⸘",
  "hash": "#︎",
  "hyph": "‐",
  "hyph.minus": "-",
  "hyph.nobreak": "‑",
  "hyph.point": "‧",
  "hyph.soft": "­",
  "numero": "№",
  "percent": "%",
  "permille": "‰",
  "permyriad": "‱",
  "pilcrow": "¶",
  "pilcrow.rev": "⁋",
  "section": "§",
  "semi": ";",
  "semi.inv": "⸵",
  "semi.rev": "⁏",
  "slash": "/",
  "slash.o": "⊘",
  "slash.double": "⫽",
  "slash.triple": "⫻",
  "slash.big": "⧸",
  "dots.h.c": "⋯",
  "dots.h": "…",
  "dots.v": "⋮",
  "dots.down": "⋱",
  "dots.up": "⋰",
  "tilde.op": "∼",
  "tilde.basic": "~",
  "tilde.dot": "⩪",
  "tilde.eq": "≃",
  "tilde.eq.not": "≄",
  "tilde.eq.rev": "⋍",
  "tilde.equiv": "≅",
  "tilde.equiv.not": "≇",
  "tilde.nequiv": "≆",
  "tilde.not": "≁",
  "tilde.rev": "∽",
  "tilde.rev.equiv": "≌",
  "tilde.triple": "≋",
  "acute": "´",
  "acute.double": "˝",
  "breve": "˘",
  "caret": "‸",
  "caron": "ˇ",
  "hat": "^",
  "diaer": "¨",
  "grave": "`",
  "macron": "¯",
  "quote.double": "\"",
  "quote.single": "'",
  "quote.l.double": "“",
  "quote.l.single": "‘",
  "quote.r.double": "”",
  "quote.r.single": "’",
  "quote.chevron.l.double": "«",
  "quote.chevron.l.single": "‹",
  "quote.chevron.r.double": "»",
  "quote.chevron.r.single": "›",
  "quote.high.double": "‟",
  "quote.high.single": "‛",
  "quote.low.double": "„",
  "quote.low.single": "‚",
  "prime": "′",
  "prime.rev": "‵",
  "prime.double": "″",
  "prime.double.rev": "‶",
  "prime.triple": "‴",
  "prime.triple.rev": "‷",
  "prime.quad": "⁗",
  "plus": "+",
  "plus.o": "⊕",
  "plus.o.l": "⨭",
  "plus.o.r": "⨮",
  "plus.o.arrow": "⟴",
  "plus.o.big": "⨁",
  "plus.dot": "∔",
  "plus.double": "⧺",
  "plus.minus": "±",
  "plus.square": "⊞",
  "plus.triangle": "⨹",
  "plus.triple": "⧻",
  "minus": "−",
  "minus.o": "⊖",
  "minus.dot": "∸",
  "minus.plus": "∓",
  "minus.square": "⊟",
  "minus.tilde": "≂",
  "minus.triangle": "⨺",
  "div": "÷",
  "div.o": "⨸",
  "div.slanted.o": "⦼",
  "times": "×",
  "times.big": "⨉",
  "times.o": "⊗",
  "times.o.l": "⨴",
  "times.o.r": "⨵",
  "times.o.hat": "⨶",
  "times.o.big": "⨂",
  "times.div": "⋇",
  "times.three.l": "⋋",
  "times.three.r": "⋌",
  "times.l": "⋉",
  "times.r": "⋊",
  "times.square": "⊠",
  "times.triangle": "⨻",
  "ratio": "∶",
  "eq": "=",
  "eq.star": "≛",
  "eq.o": "⊜",
  "eq.colon": "≕",
  "eq.dots": "≑",
  "eq.dots.down": "≒",
  "eq.dots.up": "≓",
  "eq.def": "≝",
  "eq.delta": "≜",
  "eq.equi": "≚",
  "eq.est": "≙",
  "eq.gt": "⋝",
  "eq.lt": "⋜",
  "eq.m": "≞",
  "eq.not": "≠",
  "eq.prec": "⋞",
  "eq.quest": "≟",
  "eq.succ": "⋟",
  "eq.triple": "≡",
  "eq.triple.not": "≢",
  "eq.quad": "≣",
  "gt": ">",
  "gt.o": "⧁",
  "gt.dot": "⋗",
  "gt.approx": "⪆",
  "gt.double": "≫",
  "gt.eq": "≥",
  "gt.eq.slant": "⩾",
  "gt.eq.lt": "⋛",
  "gt.eq.not": "≱",
  "gt.equiv": "≧",
  "gt.lt": "≷",
  "gt.lt.not": "≹",
  "gt.neq": "⪈",
  "gt.napprox": "⪊",
  "gt.nequiv": "≩",
  "gt.not": "≯",
  "gt.ntilde": "⋧",
  "gt.tilde": "≳",
  "gt.tilde.not": "≵",
  "gt.tri": "⊳",
  "gt.tri.eq": "⊵",
  "gt.tri.eq.not": "⋭",
  "gt.tri.not": "⋫",
  "gt.triple": "⋙",
  "gt.triple.nested": "⫸",
  "lt": "<",
  "lt.o": "⧀",
  "lt.dot": "⋖",
  "lt.approx": "⪅",
  "lt.double": "≪",
  "lt.eq": "≤",
  "lt.eq.slant": "⩽",
  "lt.eq.gt": "⋚",
  "lt.eq.not": "≰",
  "lt.equiv": "≦",
  "lt.gt": "≶",
  "lt.gt.not": "≸",
  "lt.neq": "⪇",
  "lt.napprox": "⪉",
  "lt.nequiv": "≨",
  "lt.not": "≮",
  "lt.ntilde": "⋦",
  "lt.tilde": "≲",
  "lt.tilde.not": "≴",
  "lt.tri": "⊲",
  "lt.tri.eq": "⊴",
  "lt.tri.eq.not": "⋬",
  "lt.tri.not": "⋪",
  "lt.triple": "⋘",
  "lt.triple.nested": "⫷",
  "approx": "≈",
  "approx.eq": "≊",
  "approx.not": "≉",
  "prec": "≺",
  "prec.approx": "⪷",
  "prec.curly.eq": "≼",
  "prec.curly.eq.not": "⋠",
  "prec.double": "⪻",
  "prec.eq": "⪯",
  "prec.equiv": "⪳",
  "prec.napprox": "⪹",
  "prec.neq": "⪱",
  "prec.nequiv": "⪵",
  "prec.not": "⊀",
  "prec.ntilde": "⋨",
  "prec.tilde": "≾",
  "succ": "≻",
  "succ.approx": "⪸",
  "succ.curly.eq": "≽",
  "succ.curly.eq.not": "⋡",
  "succ.double": "⪼",
  "succ.eq": "⪰",
  "succ.equiv": "⪴",
  "succ.napprox": "⪺",
  "succ.neq": "⪲",
  "succ.nequiv": "⪶",
  "succ.not": "⊁",
  "succ.ntilde": "⋩",
  "succ.tilde": "≿",
  "equiv": "≡",
  "equiv.not": "≢",
  "smt": "⪪",
  "smt.eq": "⪬",
  "lat": "⪫",
  "lat.eq": "⪭",
  "prop": "∝",
  "original": "⊶",
  "image": "⊷",
  "asymp": "≍",
  "asymp.not": "≭",
  "emptyset": "∅",
  "emptyset.arrow.r": "⦳",
  "emptyset.arrow.l": "⦴",
  "emptyset.bar": "⦱",
  "emptyset.circle": "⦲",
  "emptyset.rev": "⦰",
  "nothing": "∅",
  "nothing.arrow.r": "⦳",
  "nothing.arrow.l": "⦴",
  "nothing.bar": "⦱",
  "nothing.circle": "⦲",
  "nothing.rev": "⦰",
  "without": "∖",
  "complement": "∁",
  "in": "∈",
  "in.not": "∉",
  "in.rev": "∋",
  "in.rev.not": "∌",
  "in.rev.small": "∍",
  "in.small": "∊",
  "subset": "⊂",
  "subset.dot": "⪽",
  "subset.double": "⋐",
  "subset.eq": "⊆",
  "subset.eq.not": "⊈",
  "subset.eq.sq": "⊑",
  "subset.eq.sq.not": "⋢",
  "subset.neq": "⊊",
  "subset.not": "⊄",
  "subset.sq": "⊏",
  "subset.sq.neq": "⋤",
  "supset": "⊃",
  "supset.dot": "⪾",
  "supset.double": "⋑",
  "supset.eq": "⊇",
  "supset.eq.not": "⊉",
  "supset.eq.sq": "⊒",
  "supset.eq.sq.not": "⋣",
  "supset.neq": "⊋",
  "supset.not": "⊅",
  "supset.sq": "⊐",
  "supset.sq.neq": "⋥",
  "union": "∪",
  "union.arrow": "⊌",
  "union.big": "⋃",
  "union.dot": "⊍",
  "union.dot.big": "⨃",
  "union.double": "⋓",
  "union.minus": "⩁",
  "union.or": "⩅",
  "union.plus": "⊎",
  "union.plus.big": "⨄",
  "union.sq": "⊔",
  "union.sq.big": "⨆",
  "union.sq.double": "⩏",
  "inter": "∩",
  "inter.and": "⩄",
  "inter.big": "⋂",
  "inter.dot": "⩀",
  "inter.double": "⋒",
  "inter.sq": "⊓",
  "inter.sq.big": "⨅",
  "inter.sq.double": "⩎",
  "infinity": "∞",
  "infinity.bar": "⧞",
  "infinity.incomplete": "⧜",
  "infinity.tie": "⧝",
  "oo": "∞",
  "partial": "∂",
  "gradient": "∇",
  "nabla": "∇",
  "sum": "∑",
  "sum.integral": "⨋",
  "product": "∏",
  "product.co": "∐",
  "integral": "∫",
  "integral.arrow.hook": "⨗",
  "integral.ccw": "⨑",
  "integral.cont": "∮",
  "integral.cont.ccw": "∳",
  "integral.cont.cw": "∲",
  "integral.cw": "∱",
  "integral.dash": "⨍",
  "integral.dash.double": "⨎",
  "integral.double": "∬",
  "integral.quad": "⨌",
  "integral.inter": "⨙",
  "integral.slash": "⨏",
  "integral.square": "⨖",
  "integral.surf": "∯",
  "integral.times": "⨘",
  "integral.triple": "∭",
  "integral.union": "⨚",
  "integral.vol": "∰",
  "laplace": "∆",
  "forall": "∀",
  "exists": "∃",
  "exists.not": "∄",
  "top": "⊤",
  "bot": "⊥",
  "not": "¬",
  "and": "∧",
  "and.big": "⋀",
  "and.curly": "⋏",
  "and.dot": "⟑",
  "and.double": "⩓",
  "or": "∨",
  "or.big": "⋁",
  "or.curly": "⋎",
  "or.dot": "⟇",
  "or.double": "⩔",
  "xor": "⊕",
  "xor.big": "⨁",
  "models": "⊧",
  "forces": "⊩",
  "forces.not": "⊮",
  "therefore": "∴",
  "because": "∵",
  "qed": "∎",
  "mapsto": "↦",
  "mapsto.long": "⟼",
  "compose": "∘",
  "compose.o": "⊚",
  "convolve": "∗",
  "convolve.o": "⊛",
  "multimap": "⊸",
  "multimap.double": "⧟",
  "tiny": "⧾",
  "miny": "⧿",
  "divides": "∣",
  "divides.not": "∤",
  "divides.not.rev": "⫮",
  "divides.struck": "⟊",
  "wreath": "≀",
  "angle": "∠",
  "angle.acute": "⦟",
  "angle.arc": "∡",
  "angle.arc.rev": "⦛",
  "angle.azimuth": "⍼",
  "angle.obtuse": "⦦",
  "angle.rev": "⦣",
  "angle.right": "∟",
  "angle.right.rev": "⯾",
  "angle.right.arc": "⊾",
  "angle.right.dot": "⦝",
  "angle.right.square": "⦜",
  "angle.s": "⦞",
  "angle.spatial": "⟀",
  "angle.spheric": "∢",
  "angle.spheric.rev": "⦠",
  "angle.spheric.t": "⦡",
  "angzarr": "⍼",
  "parallel": "∥",
  "parallel.struck": "⫲",
  "parallel.o": "⦷",
  "parallel.eq": "⋕",
  "parallel.equiv": "⩨",
  "parallel.not": "∦",
  "parallel.slanted.eq": "⧣",
  "parallel.slanted.eq.tilde": "⧤",
  "parallel.slanted.equiv": "⧥",
  "parallel.tilde": "⫳",
  "perp": "⟂",
  "perp.o": "⦹",
  "earth": "🜨",
  "earth.alt": "♁",
  "jupiter": "♃",
  "mars": "♂︎",
  "mercury": "☿",
  "neptune": "♆",
  "neptune.alt": "⯉",
  "saturn": "♄",
  "sun": "☉",
  "uranus": "⛢",
  "uranus.alt": "♅",
  "venus": "♀︎",
  "diameter": "⌀",
  "interleave": "⫴",
  "interleave.big": "⫼",
  "interleave.struck": "⫵",
  "join": "⨝",
  "join.r": "⟖",
  "join.l": "⟕",
  "join.l.r": "⟗",
  "hourglass.stroked": "⧖",
  "hourglass.filled": "⧗",
  "degree": "°",
  "smash": "⨳",
  "power.standby": "⏻",
  "power.on": "⏽",
  "power.off": "⭘",
  "power.on.off": "⏼",
  "power.sleep": "⏾",
  "smile": "⌣",
  "frown": "⌢",
  "afghani": "؋",
  "baht": "฿",
  "bitcoin": "₿",
  "cedi": "₵",
  "cent": "¢",
  "currency": "¤",
  "dollar": "$",
  "dong": "₫",
  "dorome": "߾",
  "dram": "֏",
  "euro": "€",
  "guarani": "₲",
  "hryvnia": "₴",
  "kip": "₭",
  "lari": "₾",
  "lira": "₺",
  "manat": "₼",
  "naira": "₦",
  "pataca": "$",
  "peso": "$",
  "peso.philippine": "₱",
  "pound": "£",
  "riel": "៛",
  "ruble": "₽",
  "rupee.indian": "₹",
  "rupee.generic": "₨",
  "rupee.tamil": "௹",
  "rupee.wancho": "𞋿",
  "shekel": "₪",
  "som": "⃀",
  "taka": "৳",
  "taman": "߿",
  "tenge": "₸",
  "togrog": "₮",
  "won": "₩",
  "yen": "¥",
  "yuan": "¥",
  "ballot": "☐",
  "ballot.cross": "☒",
  "ballot.check": "☑︎",
  "ballot.check.heavy": "🗹",
  "checkmark": "✓",
  "checkmark.light": "🗸",
  "checkmark.heavy": "✔︎",
  "crossmark": "✗",
  "crossmark.heavy": "✘",
  "floral": "❦",
  "floral.l": "☙",
  "floral.r": "❧",
  "refmark": "※",
  "cc": "🅭",
  "cc.by": "🅯",
  "cc.nc": "🄏",
  "cc.nd": "⊜",
  "cc.public": "🅮",
  "cc.sa": "🄎",
  "cc.zero": "🄍",
  "copyright": "©︎",
  "copyright.sound": "℗",
  "copyleft": "🄯",
  "trademark": "™︎",
  "trademark.registered": "®︎",
  "trademark.service": "℠",
  "maltese": "✠",
  "suit.club.filled": "♣︎",
  "suit.club.stroked": "♧",
  "suit.diamond.filled": "♦︎",
  "suit.diamond.stroked": "♢",
  "suit.heart.filled": "♥︎",
  "suit.heart.stroked": "♡",
  "suit.spade.filled": "♠︎",
  "suit.spade.stroked": "♤",
  "note.up": "🎜",
  "note.down": "🎝",
  "note.whole": "𝅝",
  "note.half": "𝅗𝅥",
  "note.quarter": "𝅘𝅥",
  "note.quarter.alt": "♩",
  "note.eighth": "𝅘𝅥𝅮",
  "note.eighth.alt": "♪",
  "note.eighth.beamed": "♫",
  "note.sixteenth": "𝅘𝅥𝅯",
  "note.sixteenth.beamed": "♬",
  "note.grace": "𝆕",
  "note.grace.slash": "𝆔",
  "rest.whole": "𝄻",
  "rest.multiple": "𝄺",
  "rest.multiple.measure": "𝄩",
  "rest.half": "𝄼",
  "rest.quarter": "𝄽",
  "rest.eighth": "𝄾",
  "rest.sixteenth": "𝄿",
  "natural": "♮",
  "natural.t": "𝄮",
  "natural.b": "𝄯",
  "flat": "♭",
  "flat.t": "𝄬",
  "flat.b": "𝄭",
  "flat.double": "𝄫",
  "flat.quarter": "𝄳",
  "sharp": "♯",
  "sharp.t": "𝄰",
  "sharp.b": "𝄱",
  "sharp.double": "𝄪",
  "sharp.quarter": "𝄲",
  "bullet": "•",
  "bullet.op": "∙",
  "bullet.o": "⦿",
  "bullet.stroked": "◦",
  "bullet.stroked.o": "⦾",
  "bullet.hole": "◘",
  "bullet.hyph": "⁃",
  "bullet.tri": "‣",
  "bullet.l": "⁌",
  "bullet.r": "⁍",
  "circle.stroked": "○",
  "circle.stroked.tiny": "∘",
  "circle.stroked.small": "⚬",
  "circle.stroked.big": "◯",
  "circle.filled": "●",
  "circle.filled.tiny": "⦁",
  "circle.filled.small": "∙",
  "circle.filled.big": "⬤",
  "circle.dotted": "◌",
  "ellipse.stroked.h": "⬭",
  "ellipse.stroked.v": "⬯",
  "ellipse.filled.h": "⬬",
  "ellipse.filled.v": "⬮",
  "triangle.stroked.t": "△",
  "triangle.stroked.b": "▽",
  "triangle.stroked.r": "▷",
  "triangle.stroked.l": "◁",
  "triangle.stroked.bl": "◺",
  "triangle.stroked.br": "◿",
  "triangle.stroked.tl": "◸",
  "triangle.stroked.tr": "◹",
  "triangle.stroked.small.t": "▵",
  "triangle.stroked.small.b": "▿",
  "triangle.stroked.small.r": "▹",
  "triangle.stroked.small.l": "◃",
  "triangle.stroked.rounded": "🛆",
  "triangle.stroked.nested": "⟁",
  "triangle.stroked.dot": "◬",
  "triangle.filled.t": "▲",
  "triangle.filled.b": "▼",
  "triangle.filled.r": "▶︎",
  "triangle.filled.l": "◀︎",
  "triangle.filled.bl": "◣",
  "triangle.filled.br": "◢",
  "triangle.filled.tl": "◤",
  "triangle.filled.tr": "◥",
  "triangle.filled.small.t": "▴",
  "triangle.filled.small.b": "▾",
  "triangle.filled.small.r": "▸",
  "triangle.filled.small.l": "◂",
  "square.stroked": "□",
  "square.stroked.tiny": "▫︎",
  "square.stroked.small": "◽︎",
  "square.stroked.medium": "◻︎",
  "square.stroked.big": "⬜︎",
  "square.stroked.dotted": "⬚",
  "square.stroked.rounded": "▢",
  "square.filled": "■",
  "square.filled.tiny": "▪︎",
  "square.filled.small": "◾︎",
  "square.filled.medium": "◼︎",
  "square.filled.big": "⬛︎",
  "rect.stroked.h": "▭",
  "rect.stroked.v": "▯",
  "rect.filled.h": "▬",
  "rect.filled.v": "▮",
  "penta.stroked": "⬠",
  "penta.filled": "⬟",
  "hexa.stroked": "⬡",
  "hexa.filled": "⬢",
  "diamond.stroked": "◇",
  "diamond.stroked.small": "⋄",
  "diamond.stroked.medium": "⬦",
  "diamond.stroked.dot": "⟐",
  "diamond.filled": "◆",
  "diamond.filled.medium": "⬥",
  "diamond.filled.small": "⬩",
  "lozenge.stroked": "◊",
  "lozenge.stroked.small": "⬫",
  "lozenge.stroked.medium": "⬨",
  "lozenge.filled": "⧫",
  "lozenge.filled.small": "⬪",
  "lozenge.filled.medium": "⬧",
  "parallelogram.stroked": "▱",
  "parallelogram.filled": "▰",
  "star.op": "⋆",
  "star.stroked": "☆",
  "star.filled": "★",
  "arrow.r": "→",
  "arrow.r.long.bar": "⟼",
  "arrow.r.bar": "↦",
  "arrow.r.curve": "⤷",
  "arrow.r.turn": "⮎",
  "arrow.r.dashed": "⇢",
  "arrow.r.dotted": "⤑",
  "arrow.r.double": "⇒",
  "arrow.r.double.bar": "⤇",
  "arrow.r.double.long": "⟹",
  "arrow.r.double.long.bar": "⟾",
  "arrow.r.double.not": "⇏",
  "arrow.r.double.struck": "⤃",
  "arrow.r.filled": "➡︎",
  "arrow.r.hook": "↪︎",
  "arrow.r.long": "⟶",
  "arrow.r.long.squiggly": "⟿",
  "arrow.r.loop": "↬",
  "arrow.r.not": "↛",
  "arrow.r.quad": "⭆",
  "arrow.r.squiggly": "⇝",
  "arrow.r.stop": "⇥",
  "arrow.r.stroked": "⇨",
  "arrow.r.struck": "⇸",
  "arrow.r.dstruck": "⇻",
  "arrow.r.tail": "↣",
  "arrow.r.tail.struck": "⤔",
  "arrow.r.tail.dstruck": "⤕",
  "arrow.r.tilde": "⥲",
  "arrow.r.triple": "⇛",
  "arrow.r.twohead": "↠",
  "arrow.r.twohead.bar": "⤅",
  "arrow.r.twohead.struck": "⤀",
  "arrow.r.twohead.dstruck": "⤁",
  "arrow.r.twohead.tail": "⤖",
  "arrow.r.twohead.tail.struck": "⤗",
  "arrow.r.twohead.tail.dstruck": "⤘",
  "arrow.r.open": "⇾",
  "arrow.r.wave": "↝",
  "arrow.l": "←",
  "arrow.l.bar": "↤",
  "arrow.l.curve": "⤶",
  "arrow.l.turn": "⮌",
  "arrow.l.dashed": "⇠",
  "arrow.l.dotted": "⬸",
  "arrow.l.double": "⇐",
  "arrow.l.double.bar": "⤆",
  "arrow.l.double.long": "⟸",
  "arrow.l.double.long.bar": "⟽",
  "arrow.l.double.not": "⇍",
  "arrow.l.double.struck": "⤂",
  "arrow.l.filled": "⬅︎",
  "arrow.l.hook": "↩︎",
  "arrow.l.long": "⟵",
  "arrow.l.long.bar": "⟻",
  "arrow.l.long.squiggly": "⬳",
  "arrow.l.loop": "↫",
  "arrow.l.not": "↚",
  "arrow.l.quad": "⭅",
  "arrow.l.squiggly": "⇜",
  "arrow.l.stop": "⇤",
  "arrow.l.stroked": "⇦",
  "arrow.l.struck": "⇷",
  "arrow.l.dstruck": "⇺",
  "arrow.l.tail": "↢",
  "arrow.l.tail.struck": "⬹",
  "arrow.l.tail.dstruck": "⬺",
  "arrow.l.tilde": "⭉",
  "arrow.l.triple": "⇚",
  "arrow.l.twohead": "↞",
  "arrow.l.twohead.bar": "⬶",
  "arrow.l.twohead.struck": "⬴",
  "arrow.l.twohead.dstruck": "⬵",
  "arrow.l.twohead.tail": "⬻",
  "arrow.l.twohead.tail.struck": "⬼",
  "arrow.l.twohead.tail.dstruck": "⬽",
  "arrow.l.open": "⇽",
  "arrow.l.wave": "↜",
  "arrow.t": "↑",
  "arrow.t.bar": "↥",
  "arrow.t.curve": "⤴︎",
  "arrow.t.turn": "⮍",
  "arrow.t.dashed": "⇡",
  "arrow.t.double": "⇑",
  "arrow.t.filled": "⬆︎",
  "arrow.t.quad": "⟰",
  "arrow.t.stop": "⤒",
  "arrow.t.stroked": "⇧",
  "arrow.t.struck": "⤉",
  "arrow.t.dstruck": "⇞",
  "arrow.t.triple": "⤊",
  "arrow.t.twohead": "↟",
  "arrow.b": "↓",
  "arrow.b.bar": "↧",
  "arrow.b.curve": "⤵︎",
  "arrow.b.turn": "⮏",
  "arrow.b.dashed": "⇣",
  "arrow.b.double": "⇓",
  "arrow.b.filled": "⬇︎",
  "arrow.b.quad": "⟱",
  "arrow.b.stop": "⤓",
  "arrow.b.stroked": "⇩",
  "arrow.b.struck": "⤈",
  "arrow.b.dstruck": "⇟",
  "arrow.b.triple": "⤋",
  "arrow.b.twohead": "↡",
  "arrow.l.r": "↔︎",
  "arrow.l.r.double": "⇔",
  "arrow.l.r.double.long": "⟺",
  "arrow.l.r.double.not": "⇎",
  "arrow.l.r.double.struck": "⤄",
  "arrow.l.r.filled": "⬌",
  "arrow.l.r.long": "⟷",
  "arrow.l.r.not": "↮",
  "arrow.l.r.stroked": "⬄",
  "arrow.l.r.struck": "⇹",
  "arrow.l.r.dstruck": "⇼",
  "arrow.l.r.open": "⇿",
  "arrow.l.r.wave": "↭",
  "arrow.t.b": "↕︎",
  "arrow.t.b.double": "⇕",
  "arrow.t.b.filled": "⬍",
  "arrow.t.b.stroked": "⇳",
  "arrow.tr": "↗︎",
  "arrow.tr.double": "⇗",
  "arrow.tr.filled": "⬈",
  "arrow.tr.hook": "⤤",
  "arrow.tr.stroked": "⬀",
  "arrow.br": "↘︎",
  "arrow.br.double": "⇘",
  "arrow.br.filled": "⬊",
  "arrow.br.hook": "⤥",
  "arrow.br.stroked": "⬂",
  "arrow.tl": "↖︎",
  "arrow.tl.double": "⇖",
  "arrow.tl.filled": "⬉",
  "arrow.tl.hook": "⤣",
  "arrow.tl.stroked": "⬁",
  "arrow.bl": "↙︎",
  "arrow.bl.double": "⇙",
  "arrow.bl.filled": "⬋",
  "arrow.bl.hook": "⤦",
  "arrow.bl.stroked": "⬃",
  "arrow.tl.br": "⤡",
  "arrow.tr.bl": "⤢",
  "arrow.ccw": "↺",
  "arrow.ccw.half": "↶",
  "arrow.cw": "↻",
  "arrow.cw.half": "↷",
  "arrow.zigzag": "↯",
  "arrows.rr": "⇉",
  "arrows.ll": "⇇",
  "arrows.tt": "⇈",
  "arrows.bb": "⇊",
  "arrows.lr": "⇆",
  "arrows.lr.stop": "↹",
  "arrows.rl": "⇄",
  "arrows.tb": "⇅",
  "arrows.bt": "⇵",
  "arrows.rrr": "⇶",
  "arrows.lll": "⬱",
  "arrowhead.t": "⌃",
  "arrowhead.b": "⌄",
  "harpoon.rt": "⇀",
  "harpoon.rt.bar": "⥛",
  "harpoon.rt.stop": "⥓",
  "harpoon.rb": "⇁",
  "harpoon.rb.bar": "⥟",
  "harpoon.rb.stop": "⥗",
  "harpoon.lt": "↼",
  "harpoon.lt.bar": "⥚",
  "harpoon.lt.stop": "⥒",
  "harpoon.lb": "↽",
  "harpoon.lb.bar": "⥞",
  "harpoon.lb.stop": "⥖",
  "harpoon.tl": "↿",
  "harpoon.tl.bar": "⥠",
  "harpoon.tl.stop": "⥘",
  "harpoon.tr": "↾",
  "harpoon.tr.bar": "⥜",
  "harpoon.tr.stop": "⥔",
  "harpoon.bl": "⇃",
  "harpoon.bl.bar": "⥡",
  "harpoon.bl.stop": "⥙",
  "harpoon.br": "⇂",
  "harpoon.br.bar": "⥝",
  "harpoon.br.stop": "⥕",
  "harpoon.lt.rt": "⥎",
  "harpoon.lb.rb": "⥐",
  "harpoon.lb.rt": "⥋",
  "harpoon.lt.rb": "⥊",
  "harpoon.tl.bl": "⥑",
  "harpoon.tr.br": "⥏",
  "harpoon.tl.br": "⥍",
  "harpoon.tr.bl": "⥌",
  "harpoons.rtrb": "⥤",
  "harpoons.blbr": "⥥",
  "harpoons.bltr": "⥯",
  "harpoons.lbrb": "⥧",
  "harpoons.ltlb": "⥢",
  "harpoons.ltrb": "⇋",
  "harpoons.ltrt": "⥦",
  "harpoons.rblb": "⥩",
  "harpoons.rtlb": "⇌",
  "harpoons.rtlt": "⥨",
  "harpoons.tlbr": "⥮",
  "harpoons.tltr": "⥣",
  "tack.r": "⊢",
  "tack.r.not": "⊬",
  "tack.r.long": "⟝",
  "tack.r.short": "⊦",
  "tack.r.double": "⊨",
  "tack.r.double.not": "⊭",
  "tack.l": "⊣",
  "tack.l.long": "⟞",
  "tack.l.short": "⫞",
  "tack.l.double": "⫤",
  "tack.t": "⊥",
  "tack.t.big": "⟘",
  "tack.t.double": "⫫",
  "tack.t.short": "⫠",
  "tack.b": "⊤",
  "tack.b.big": "⟙",
  "tack.b.double": "⫪",
  "tack.b.short": "⫟",
  "tack.l.r": "⟛",
  "alpha": "α",
  "beta": "β",
  "beta.alt": "ϐ",
  "chi": "χ",
  "delta": "δ",
  "digamma": "ϝ",
  "epsilon": "ε",
  "epsilon.alt": "ϵ",
  "epsilon.alt.rev": "϶",
  "eta": "η",
  "gamma": "γ",
  "iota": "ι",
  "iota.inv": "℩",
  "kappa": "κ",
  "kappa.alt": "ϰ",
  "lambda": "λ",
  "mu": "μ",
  "nu": "ν",
  "omega": "ω",
  "omicron": "ο",
  "phi": "φ",
  "phi.alt": "ϕ",
  "pi": "π",
  "pi.alt": "ϖ",
  "psi": "ψ",
  "rho": "ρ",
  "rho.alt": "ϱ",
  "sigma": "σ",
  "sigma.alt": "ς",
  "tau": "τ",
  "theta": "θ",
  "theta.alt": "ϑ",
  "upsilon": "υ",
  "xi": "ξ",
  "zeta": "ζ",
  "Alpha": "Α",
  "Beta": "Β",
  "Chi": "Χ",
  "Delta": "Δ",
  "Digamma": "Ϝ",
  "Epsilon": "Ε",
  "Eta": "Η",
  "Gamma": "Γ",
  "Iota": "Ι",
  "Kappa": "Κ",
  "Lambda": "Λ",
  "Mu": "Μ",
  "Nu": "Ν",
  "Omega": "Ω",
  "Omega.inv": "℧",
  "Omicron": "Ο",
  "Phi": "Φ",
  "Pi": "Π",
  "Psi": "Ψ",
  "Rho": "Ρ",
  "Sigma": "Σ",
  "Tau": "Τ",
  "Theta": "Θ",
  "Theta.alt": "ϴ",
  "Upsilon": "Υ",
  "Xi": "Ξ",
  "Zeta": "Ζ",
  "sha": "ш",
  "Sha": "Ш",
  "aleph": "א",
  "beth": "ב",
  "gimel": "ג",
  "daleth": "ד",
  "AA": "𝔸",
  "BB": "𝔹",
  "CC": "ℂ",
  "DD": "𝔻",
  "EE": "𝔼",
  "FF": "𝔽",
  "GG": "𝔾",
  "HH": "ℍ",
  "II": "𝕀",
  "JJ": "𝕁",
  "KK": "𝕂",
  "LL": "𝕃",
  "MM": "𝕄",
  "NN": "ℕ",
  "OO": "𝕆",
  "PP": "ℙ",
  "QQ": "ℚ",
  "RR": "ℝ",
  "SS": "𝕊",
  "TT": "𝕋",
  "UU": "𝕌",
  "VV": "𝕍",
  "WW": "𝕎",
  "XX": "𝕏",
  "YY": "𝕐",
  "ZZ": "ℤ",
  "angstrom": "Å",
  "ell": "ℓ",
  "planck": "ħ",
  "Re": "ℜ",
  "Im": "ℑ",
  "dotless.i": "ı",
  "dotless.j": "ȷ",
  "die.six": "⚅",
  "die.five": "⚄",
  "die.four": "⚃",
  "die.three": "⚂",
  "die.two": "⚁",
  "die.one": "⚀",
  "errorbar.square.stroked": "⧮",
  "errorbar.square.filled": "⧯",
  "errorbar.diamond.stroked": "⧰",
  "errorbar.diamond.filled": "⧱",
  "errorbar.circle.stroked": "⧲",
  "errorbar.circle.filled": "⧳",
  "gender.female": "♀︎",
  "gender.female.double": "⚢",
  "gender.female.male": "⚤",
  "gender.intersex": "⚥",
  "gender.male": "♂︎",
  "gender.male.double": "⚣",
  "gender.male.female": "⚤",
  "gender.male.stroke": "⚦",
  "gender.male.stroke.t": "⚨",
  "gender.male.stroke.r": "⚩",
  "gender.neuter": "⚲",
  "gender.trans": "⚧︎",
)
let typst-symbol-values = (
  "⁠": "wj",
  "‍": "zwj",
  "‌": "zwnj",
  "​": "zws",
  "‎": "lrm",
  "‏": "rlm",
  " ": "space",
  "\u{a0}": "space.nobreak",
  " ": "space.nobreak.narrow",
  " ": "space.en",
  " ": "space.quad",
  " ": "space.third",
  " ": "space.quarter",
  " ": "space.sixth",
  " ": "space.med",
  " ": "space.fig",
  " ": "space.punct",
  " ": "space.thin",
  " ": "space.hair",
  "(": "paren.l",
  "⟮": "paren.l.flat",
  "⦇": "paren.l.closed",
  "⦅": "paren.l.stroked",
  ")": "paren.r",
  "⟯": "paren.r.flat",
  "⦈": "paren.r.closed",
  "⦆": "paren.r.stroked",
  "⏜": "paren.t",
  "⏝": "paren.b",
  "{": "brace.l",
  "⦃": "brace.l.stroked",
  "}": "brace.r",
  "⦄": "brace.r.stroked",
  "⏞": "brace.t",
  "⏟": "brace.b",
  "[": "bracket.l",
  "⦍": "bracket.l.tick.t",
  "⦏": "bracket.l.tick.b",
  "⟦": "bracket.l.stroked",
  "]": "bracket.r",
  "⦐": "bracket.r.tick.t",
  "⦎": "bracket.r.tick.b",
  "⟧": "bracket.r.stroked",
  "⎴": "bracket.t",
  "⎵": "bracket.b",
  "❲": "shell.l",
  "⟬": "shell.l.stroked",
  "⦗": "shell.l.filled",
  "❳": "shell.r",
  "⟭": "shell.r.stroked",
  "⦘": "shell.r.filled",
  "⏠": "shell.t",
  "⏡": "shell.b",
  "⟅": "bag.l",
  "⟆": "bag.r",
  "⎰": "mustache.l",
  "⎱": "mustache.r",
  "|": "bar.v",
  "‖": "bar.v.double",
  "⦀": "bar.v.triple",
  "¦": "bar.v.broken",
  "⦶": "bar.v.o",
  "―": "bar.h",
  "⧘": "fence.l",
  "⧚": "fence.l.double",
  "⧙": "fence.r",
  "⧛": "fence.r.double",
  "⦙": "fence.dotted",
  "⟨": "chevron.l",
  "⧼": "chevron.l.curly",
  "⦑": "chevron.l.dot",
  "⦉": "chevron.l.closed",
  "⟪": "chevron.l.double",
  "⟩": "chevron.r",
  "⧽": "chevron.r.curly",
  "⦒": "chevron.r.dot",
  "⦊": "chevron.r.closed",
  "⟫": "chevron.r.double",
  "⌈": "ceil.l",
  "⌉": "ceil.r",
  "⌊": "floor.l",
  "⌋": "floor.r",
  "⌜": "corner.l.t",
  "⌞": "corner.l.b",
  "⌝": "corner.r.t",
  "⌟": "corner.r.b",
  "&": "amp",
  "⅋": "amp.inv",
  "∗": "ast.op",
  "⊛": "ast.op.o",
  "*︎": "ast.basic",
  "⁎": "ast.low",
  "⁑": "ast.double",
  "⁂": "ast.triple",
  "⧆": "ast.square",
  "@": "at",
  "\\": "backslash",
  "⦸": "backslash.o",
  "⧷": "backslash.not",
  "℅": "co",
  ":": "colon",
  "₡": "colon.currency",
  "∷": "colon.double",
  "⁝": "colon.tri",
  "⫶": "colon.tri.op",
  "≔": "colon.eq",
  "⩴": "colon.double.eq",
  ",": "comma",
  "⸲": "comma.inv",
  "⹁": "comma.rev",
  "†": "dagger",
  "‡": "dagger.double",
  "⹋": "dagger.triple",
  "⸶": "dagger.l",
  "⸷": "dagger.r",
  "⸸": "dagger.inv",
  "–": "dash.en",
  "—": "dash.em",
  "⸺": "dash.em.two",
  "⸻": "dash.em.three",
  "‒": "dash.fig",
  "∹": "dash.colon",
  "⊝": "dash.o",
  "〜": "dash.wave",
  "〰︎": "dash.wave.double",
  "⋅": "dot.op",
  ".": "dot.basic",
  "·": "dot.c",
  "⊙": "dot.o",
  "⨀": "dot.o.big",
  "⊡": "dot.square",
  "¨": "dot.double",
  "⃛": "dot.triple",
  "⃜": "dot.quad",
  "!": "excl",
  "‼︎": "excl.double",
  "¡": "excl.inv",
  "⁉︎": "excl.quest",
  "?": "quest",
  "⁇": "quest.double",
  "⁈": "quest.excl",
  "¿": "quest.inv",
  "‽": "interrobang",
  "⸘": "interrobang.inv",
  "#︎": "hash",
  "‐": "hyph",
  "-": "hyph.minus",
  "‑": "hyph.nobreak",
  "‧": "hyph.point",
  "­": "hyph.soft",
  "№": "numero",
  "%": "percent",
  "‰": "permille",
  "‱": "permyriad",
  "¶": "pilcrow",
  "⁋": "pilcrow.rev",
  "§": "section",
  ";": "semi",
  "⸵": "semi.inv",
  "⁏": "semi.rev",
  "/": "slash",
  "⊘": "slash.o",
  "⫽": "slash.double",
  "⫻": "slash.triple",
  "⧸": "slash.big",
  "⋯": "dots.h.c",
  "…": "dots.h",
  "⋮": "dots.v",
  "⋱": "dots.down",
  "⋰": "dots.up",
  "∼": "tilde.op",
  "~": "tilde.basic",
  "⩪": "tilde.dot",
  "≃": "tilde.eq",
  "≄": "tilde.eq.not",
  "⋍": "tilde.eq.rev",
  "≅": "tilde.equiv",
  "≇": "tilde.equiv.not",
  "≆": "tilde.nequiv",
  "≁": "tilde.not",
  "∽": "tilde.rev",
  "≌": "tilde.rev.equiv",
  "≋": "tilde.triple",
  "´": "acute",
  "˝": "acute.double",
  "˘": "breve",
  "‸": "caret",
  "ˇ": "caron",
  "^": "hat",
  "`": "grave",
  "¯": "macron",
  "\"": "quote.double",
  "'": "quote.single",
  "“": "quote.l.double",
  "‘": "quote.l.single",
  "”": "quote.r.double",
  "’": "quote.r.single",
  "«": "quote.chevron.l.double",
  "‹": "quote.chevron.l.single",
  "»": "quote.chevron.r.double",
  "›": "quote.chevron.r.single",
  "‟": "quote.high.double",
  "‛": "quote.high.single",
  "„": "quote.low.double",
  "‚": "quote.low.single",
  "′": "prime",
  "‵": "prime.rev",
  "″": "prime.double",
  "‶": "prime.double.rev",
  "‴": "prime.triple",
  "‷": "prime.triple.rev",
  "⁗": "prime.quad",
  "+": "plus",
  "⊕": "plus.o",
  "⨭": "plus.o.l",
  "⨮": "plus.o.r",
  "⟴": "plus.o.arrow",
  "⨁": "plus.o.big",
  "∔": "plus.dot",
  "⧺": "plus.double",
  "±": "plus.minus",
  "⊞": "plus.square",
  "⨹": "plus.triangle",
  "⧻": "plus.triple",
  "−": "minus",
  "⊖": "minus.o",
  "∸": "minus.dot",
  "∓": "minus.plus",
  "⊟": "minus.square",
  "≂": "minus.tilde",
  "⨺": "minus.triangle",
  "÷": "div",
  "⨸": "div.o",
  "⦼": "div.slanted.o",
  "×": "times",
  "⨉": "times.big",
  "⊗": "times.o",
  "⨴": "times.o.l",
  "⨵": "times.o.r",
  "⨶": "times.o.hat",
  "⨂": "times.o.big",
  "⋇": "times.div",
  "⋋": "times.three.l",
  "⋌": "times.three.r",
  "⋉": "times.l",
  "⋊": "times.r",
  "⊠": "times.square",
  "⨻": "times.triangle",
  "∶": "ratio",
  "=": "eq",
  "≛": "eq.star",
  "⊜": "eq.o",
  "≕": "eq.colon",
  "≑": "eq.dots",
  "≒": "eq.dots.down",
  "≓": "eq.dots.up",
  "≝": "eq.def",
  "≜": "eq.delta",
  "≚": "eq.equi",
  "≙": "eq.est",
  "⋝": "eq.gt",
  "⋜": "eq.lt",
  "≞": "eq.m",
  "≠": "eq.not",
  "⋞": "eq.prec",
  "≟": "eq.quest",
  "⋟": "eq.succ",
  "≡": "eq.triple",
  "≢": "eq.triple.not",
  "≣": "eq.quad",
  ">": "gt",
  "⧁": "gt.o",
  "⋗": "gt.dot",
  "⪆": "gt.approx",
  "≫": "gt.double",
  "≥": "gt.eq",
  "⩾": "gt.eq.slant",
  "⋛": "gt.eq.lt",
  "≱": "gt.eq.not",
  "≧": "gt.equiv",
  "≷": "gt.lt",
  "≹": "gt.lt.not",
  "⪈": "gt.neq",
  "⪊": "gt.napprox",
  "≩": "gt.nequiv",
  "≯": "gt.not",
  "⋧": "gt.ntilde",
  "≳": "gt.tilde",
  "≵": "gt.tilde.not",
  "⊳": "gt.tri",
  "⊵": "gt.tri.eq",
  "⋭": "gt.tri.eq.not",
  "⋫": "gt.tri.not",
  "⋙": "gt.triple",
  "⫸": "gt.triple.nested",
  "<": "lt",
  "⧀": "lt.o",
  "⋖": "lt.dot",
  "⪅": "lt.approx",
  "≪": "lt.double",
  "≤": "lt.eq",
  "⩽": "lt.eq.slant",
  "⋚": "lt.eq.gt",
  "≰": "lt.eq.not",
  "≦": "lt.equiv",
  "≶": "lt.gt",
  "≸": "lt.gt.not",
  "⪇": "lt.neq",
  "⪉": "lt.napprox",
  "≨": "lt.nequiv",
  "≮": "lt.not",
  "⋦": "lt.ntilde",
  "≲": "lt.tilde",
  "≴": "lt.tilde.not",
  "⊲": "lt.tri",
  "⊴": "lt.tri.eq",
  "⋬": "lt.tri.eq.not",
  "⋪": "lt.tri.not",
  "⋘": "lt.triple",
  "⫷": "lt.triple.nested",
  "≈": "approx",
  "≊": "approx.eq",
  "≉": "approx.not",
  "≺": "prec",
  "⪷": "prec.approx",
  "≼": "prec.curly.eq",
  "⋠": "prec.curly.eq.not",
  "⪻": "prec.double",
  "⪯": "prec.eq",
  "⪳": "prec.equiv",
  "⪹": "prec.napprox",
  "⪱": "prec.neq",
  "⪵": "prec.nequiv",
  "⊀": "prec.not",
  "⋨": "prec.ntilde",
  "≾": "prec.tilde",
  "≻": "succ",
  "⪸": "succ.approx",
  "≽": "succ.curly.eq",
  "⋡": "succ.curly.eq.not",
  "⪼": "succ.double",
  "⪰": "succ.eq",
  "⪴": "succ.equiv",
  "⪺": "succ.napprox",
  "⪲": "succ.neq",
  "⪶": "succ.nequiv",
  "⊁": "succ.not",
  "⋩": "succ.ntilde",
  "≿": "succ.tilde",
  "⪪": "smt",
  "⪬": "smt.eq",
  "⪫": "lat",
  "⪭": "lat.eq",
  "∝": "prop",
  "⊶": "original",
  "⊷": "image",
  "≍": "asymp",
  "≭": "asymp.not",
  "∅": "emptyset",
  "⦳": "emptyset.arrow.r",
  "⦴": "emptyset.arrow.l",
  "⦱": "emptyset.bar",
  "⦲": "emptyset.circle",
  "⦰": "emptyset.rev",
  "∖": "without",
  "∁": "complement",
  "∈": "in",
  "∉": "in.not",
  "∋": "in.rev",
  "∌": "in.rev.not",
  "∍": "in.rev.small",
  "∊": "in.small",
  "⊂": "subset",
  "⪽": "subset.dot",
  "⋐": "subset.double",
  "⊆": "subset.eq",
  "⊈": "subset.eq.not",
  "⊑": "subset.eq.sq",
  "⋢": "subset.eq.sq.not",
  "⊊": "subset.neq",
  "⊄": "subset.not",
  "⊏": "subset.sq",
  "⋤": "subset.sq.neq",
  "⊃": "supset",
  "⪾": "supset.dot",
  "⋑": "supset.double",
  "⊇": "supset.eq",
  "⊉": "supset.eq.not",
  "⊒": "supset.eq.sq",
  "⋣": "supset.eq.sq.not",
  "⊋": "supset.neq",
  "⊅": "supset.not",
  "⊐": "supset.sq",
  "⋥": "supset.sq.neq",
  "∪": "union",
  "⊌": "union.arrow",
  "⋃": "union.big",
  "⊍": "union.dot",
  "⨃": "union.dot.big",
  "⋓": "union.double",
  "⩁": "union.minus",
  "⩅": "union.or",
  "⊎": "union.plus",
  "⨄": "union.plus.big",
  "⊔": "union.sq",
  "⨆": "union.sq.big",
  "⩏": "union.sq.double",
  "∩": "inter",
  "⩄": "inter.and",
  "⋂": "inter.big",
  "⩀": "inter.dot",
  "⋒": "inter.double",
  "⊓": "inter.sq",
  "⨅": "inter.sq.big",
  "⩎": "inter.sq.double",
  "∞": "infinity",
  "⧞": "infinity.bar",
  "⧜": "infinity.incomplete",
  "⧝": "infinity.tie",
  "∂": "partial",
  "∇": "gradient",
  "∑": "sum",
  "⨋": "sum.integral",
  "∏": "product",
  "∐": "product.co",
  "∫": "integral",
  "⨗": "integral.arrow.hook",
  "⨑": "integral.ccw",
  "∮": "integral.cont",
  "∳": "integral.cont.ccw",
  "∲": "integral.cont.cw",
  "∱": "integral.cw",
  "⨍": "integral.dash",
  "⨎": "integral.dash.double",
  "∬": "integral.double",
  "⨌": "integral.quad",
  "⨙": "integral.inter",
  "⨏": "integral.slash",
  "⨖": "integral.square",
  "∯": "integral.surf",
  "⨘": "integral.times",
  "∭": "integral.triple",
  "⨚": "integral.union",
  "∰": "integral.vol",
  "∆": "laplace",
  "∀": "forall",
  "∃": "exists",
  "∄": "exists.not",
  "⊤": "top",
  "⊥": "bot",
  "¬": "not",
  "∧": "and",
  "⋀": "and.big",
  "⋏": "and.curly",
  "⟑": "and.dot",
  "⩓": "and.double",
  "∨": "or",
  "⋁": "or.big",
  "⋎": "or.curly",
  "⟇": "or.dot",
  "⩔": "or.double",
  "⊧": "models",
  "⊩": "forces",
  "⊮": "forces.not",
  "∴": "therefore",
  "∵": "because",
  "∎": "qed",
  "↦": "mapsto",
  "⟼": "mapsto.long",
  "∘": "compose",
  "⊚": "compose.o",
  "⊸": "multimap",
  "⧟": "multimap.double",
  "⧾": "tiny",
  "⧿": "miny",
  "∣": "divides",
  "∤": "divides.not",
  "⫮": "divides.not.rev",
  "⟊": "divides.struck",
  "≀": "wreath",
  "∠": "angle",
  "⦟": "angle.acute",
  "∡": "angle.arc",
  "⦛": "angle.arc.rev",
  "⍼": "angle.azimuth",
  "⦦": "angle.obtuse",
  "⦣": "angle.rev",
  "∟": "angle.right",
  "⯾": "angle.right.rev",
  "⊾": "angle.right.arc",
  "⦝": "angle.right.dot",
  "⦜": "angle.right.square",
  "⦞": "angle.s",
  "⟀": "angle.spatial",
  "∢": "angle.spheric",
  "⦠": "angle.spheric.rev",
  "⦡": "angle.spheric.t",
  "∥": "parallel",
  "⫲": "parallel.struck",
  "⦷": "parallel.o",
  "⋕": "parallel.eq",
  "⩨": "parallel.equiv",
  "∦": "parallel.not",
  "⧣": "parallel.slanted.eq",
  "⧤": "parallel.slanted.eq.tilde",
  "⧥": "parallel.slanted.equiv",
  "⫳": "parallel.tilde",
  "⟂": "perp",
  "⦹": "perp.o",
  "🜨": "earth",
  "♁": "earth.alt",
  "♃": "jupiter",
  "♂︎": "mars",
  "☿": "mercury",
  "♆": "neptune",
  "⯉": "neptune.alt",
  "♄": "saturn",
  "☉": "sun",
  "⛢": "uranus",
  "♅": "uranus.alt",
  "♀︎": "venus",
  "⌀": "diameter",
  "⫴": "interleave",
  "⫼": "interleave.big",
  "⫵": "interleave.struck",
  "⨝": "join",
  "⟖": "join.r",
  "⟕": "join.l",
  "⟗": "join.l.r",
  "⧖": "hourglass.stroked",
  "⧗": "hourglass.filled",
  "°": "degree",
  "⨳": "smash",
  "⏻": "power.standby",
  "⏽": "power.on",
  "⭘": "power.off",
  "⏼": "power.on.off",
  "⏾": "power.sleep",
  "⌣": "smile",
  "⌢": "frown",
  "؋": "afghani",
  "฿": "baht",
  "₿": "bitcoin",
  "₵": "cedi",
  "¢": "cent",
  "¤": "currency",
  "$": "dollar",
  "₫": "dong",
  "߾": "dorome",
  "֏": "dram",
  "€": "euro",
  "₲": "guarani",
  "₴": "hryvnia",
  "₭": "kip",
  "₾": "lari",
  "₺": "lira",
  "₼": "manat",
  "₦": "naira",
  "₱": "peso.philippine",
  "£": "pound",
  "៛": "riel",
  "₽": "ruble",
  "₹": "rupee.indian",
  "₨": "rupee.generic",
  "௹": "rupee.tamil",
  "𞋿": "rupee.wancho",
  "₪": "shekel",
  "⃀": "som",
  "৳": "taka",
  "߿": "taman",
  "₸": "tenge",
  "₮": "togrog",
  "₩": "won",
  "¥": "yen",
  "☐": "ballot",
  "☒": "ballot.cross",
  "☑︎": "ballot.check",
  "🗹": "ballot.check.heavy",
  "✓": "checkmark",
  "🗸": "checkmark.light",
  "✔︎": "checkmark.heavy",
  "✗": "crossmark",
  "✘": "crossmark.heavy",
  "❦": "floral",
  "☙": "floral.l",
  "❧": "floral.r",
  "※": "refmark",
  "🅭": "cc",
  "🅯": "cc.by",
  "🄏": "cc.nc",
  "🅮": "cc.public",
  "🄎": "cc.sa",
  "🄍": "cc.zero",
  "©︎": "copyright",
  "℗": "copyright.sound",
  "🄯": "copyleft",
  "™︎": "trademark",
  "®︎": "trademark.registered",
  "℠": "trademark.service",
  "✠": "maltese",
  "♣︎": "suit.club.filled",
  "♧": "suit.club.stroked",
  "♦︎": "suit.diamond.filled",
  "♢": "suit.diamond.stroked",
  "♥︎": "suit.heart.filled",
  "♡": "suit.heart.stroked",
  "♠︎": "suit.spade.filled",
  "♤": "suit.spade.stroked",
  "🎜": "note.up",
  "🎝": "note.down",
  "𝅝": "note.whole",
  "𝅗𝅥": "note.half",
  "𝅘𝅥": "note.quarter",
  "♩": "note.quarter.alt",
  "𝅘𝅥𝅮": "note.eighth",
  "♪": "note.eighth.alt",
  "♫": "note.eighth.beamed",
  "𝅘𝅥𝅯": "note.sixteenth",
  "♬": "note.sixteenth.beamed",
  "𝆕": "note.grace",
  "𝆔": "note.grace.slash",
  "𝄻": "rest.whole",
  "𝄺": "rest.multiple",
  "𝄩": "rest.multiple.measure",
  "𝄼": "rest.half",
  "𝄽": "rest.quarter",
  "𝄾": "rest.eighth",
  "𝄿": "rest.sixteenth",
  "♮": "natural",
  "𝄮": "natural.t",
  "𝄯": "natural.b",
  "♭": "flat",
  "𝄬": "flat.t",
  "𝄭": "flat.b",
  "𝄫": "flat.double",
  "𝄳": "flat.quarter",
  "♯": "sharp",
  "𝄰": "sharp.t",
  "𝄱": "sharp.b",
  "𝄪": "sharp.double",
  "𝄲": "sharp.quarter",
  "•": "bullet",
  "∙": "bullet.op",
  "⦿": "bullet.o",
  "◦": "bullet.stroked",
  "⦾": "bullet.stroked.o",
  "◘": "bullet.hole",
  "⁃": "bullet.hyph",
  "‣": "bullet.tri",
  "⁌": "bullet.l",
  "⁍": "bullet.r",
  "○": "circle.stroked",
  "⚬": "circle.stroked.small",
  "◯": "circle.stroked.big",
  "●": "circle.filled",
  "⦁": "circle.filled.tiny",
  "⬤": "circle.filled.big",
  "◌": "circle.dotted",
  "⬭": "ellipse.stroked.h",
  "⬯": "ellipse.stroked.v",
  "⬬": "ellipse.filled.h",
  "⬮": "ellipse.filled.v",
  "△": "triangle.stroked.t",
  "▽": "triangle.stroked.b",
  "▷": "triangle.stroked.r",
  "◁": "triangle.stroked.l",
  "◺": "triangle.stroked.bl",
  "◿": "triangle.stroked.br",
  "◸": "triangle.stroked.tl",
  "◹": "triangle.stroked.tr",
  "▵": "triangle.stroked.small.t",
  "▿": "triangle.stroked.small.b",
  "▹": "triangle.stroked.small.r",
  "◃": "triangle.stroked.small.l",
  "🛆": "triangle.stroked.rounded",
  "⟁": "triangle.stroked.nested",
  "◬": "triangle.stroked.dot",
  "▲": "triangle.filled.t",
  "▼": "triangle.filled.b",
  "▶︎": "triangle.filled.r",
  "◀︎": "triangle.filled.l",
  "◣": "triangle.filled.bl",
  "◢": "triangle.filled.br",
  "◤": "triangle.filled.tl",
  "◥": "triangle.filled.tr",
  "▴": "triangle.filled.small.t",
  "▾": "triangle.filled.small.b",
  "▸": "triangle.filled.small.r",
  "◂": "triangle.filled.small.l",
  "□": "square.stroked",
  "▫︎": "square.stroked.tiny",
  "◽︎": "square.stroked.small",
  "◻︎": "square.stroked.medium",
  "⬜︎": "square.stroked.big",
  "⬚": "square.stroked.dotted",
  "▢": "square.stroked.rounded",
  "■": "square.filled",
  "▪︎": "square.filled.tiny",
  "◾︎": "square.filled.small",
  "◼︎": "square.filled.medium",
  "⬛︎": "square.filled.big",
  "▭": "rect.stroked.h",
  "▯": "rect.stroked.v",
  "▬": "rect.filled.h",
  "▮": "rect.filled.v",
  "⬠": "penta.stroked",
  "⬟": "penta.filled",
  "⬡": "hexa.stroked",
  "⬢": "hexa.filled",
  "◇": "diamond.stroked",
  "⋄": "diamond.stroked.small",
  "⬦": "diamond.stroked.medium",
  "⟐": "diamond.stroked.dot",
  "◆": "diamond.filled",
  "⬥": "diamond.filled.medium",
  "⬩": "diamond.filled.small",
  "◊": "lozenge.stroked",
  "⬫": "lozenge.stroked.small",
  "⬨": "lozenge.stroked.medium",
  "⧫": "lozenge.filled",
  "⬪": "lozenge.filled.small",
  "⬧": "lozenge.filled.medium",
  "▱": "parallelogram.stroked",
  "▰": "parallelogram.filled",
  "⋆": "star.op",
  "☆": "star.stroked",
  "★": "star.filled",
  "→": "arrow.r",
  "⤷": "arrow.r.curve",
  "⮎": "arrow.r.turn",
  "⇢": "arrow.r.dashed",
  "⤑": "arrow.r.dotted",
  "⇒": "arrow.r.double",
  "⤇": "arrow.r.double.bar",
  "⟹": "arrow.r.double.long",
  "⟾": "arrow.r.double.long.bar",
  "⇏": "arrow.r.double.not",
  "⤃": "arrow.r.double.struck",
  "➡︎": "arrow.r.filled",
  "↪︎": "arrow.r.hook",
  "⟶": "arrow.r.long",
  "⟿": "arrow.r.long.squiggly",
  "↬": "arrow.r.loop",
  "↛": "arrow.r.not",
  "⭆": "arrow.r.quad",
  "⇝": "arrow.r.squiggly",
  "⇥": "arrow.r.stop",
  "⇨": "arrow.r.stroked",
  "⇸": "arrow.r.struck",
  "⇻": "arrow.r.dstruck",
  "↣": "arrow.r.tail",
  "⤔": "arrow.r.tail.struck",
  "⤕": "arrow.r.tail.dstruck",
  "⥲": "arrow.r.tilde",
  "⇛": "arrow.r.triple",
  "↠": "arrow.r.twohead",
  "⤅": "arrow.r.twohead.bar",
  "⤀": "arrow.r.twohead.struck",
  "⤁": "arrow.r.twohead.dstruck",
  "⤖": "arrow.r.twohead.tail",
  "⤗": "arrow.r.twohead.tail.struck",
  "⤘": "arrow.r.twohead.tail.dstruck",
  "⇾": "arrow.r.open",
  "↝": "arrow.r.wave",
  "←": "arrow.l",
  "↤": "arrow.l.bar",
  "⤶": "arrow.l.curve",
  "⮌": "arrow.l.turn",
  "⇠": "arrow.l.dashed",
  "⬸": "arrow.l.dotted",
  "⇐": "arrow.l.double",
  "⤆": "arrow.l.double.bar",
  "⟸": "arrow.l.double.long",
  "⟽": "arrow.l.double.long.bar",
  "⇍": "arrow.l.double.not",
  "⤂": "arrow.l.double.struck",
  "⬅︎": "arrow.l.filled",
  "↩︎": "arrow.l.hook",
  "⟵": "arrow.l.long",
  "⟻": "arrow.l.long.bar",
  "⬳": "arrow.l.long.squiggly",
  "↫": "arrow.l.loop",
  "↚": "arrow.l.not",
  "⭅": "arrow.l.quad",
  "⇜": "arrow.l.squiggly",
  "⇤": "arrow.l.stop",
  "⇦": "arrow.l.stroked",
  "⇷": "arrow.l.struck",
  "⇺": "arrow.l.dstruck",
  "↢": "arrow.l.tail",
  "⬹": "arrow.l.tail.struck",
  "⬺": "arrow.l.tail.dstruck",
  "⭉": "arrow.l.tilde",
  "⇚": "arrow.l.triple",
  "↞": "arrow.l.twohead",
  "⬶": "arrow.l.twohead.bar",
  "⬴": "arrow.l.twohead.struck",
  "⬵": "arrow.l.twohead.dstruck",
  "⬻": "arrow.l.twohead.tail",
  "⬼": "arrow.l.twohead.tail.struck",
  "⬽": "arrow.l.twohead.tail.dstruck",
  "⇽": "arrow.l.open",
  "↜": "arrow.l.wave",
  "↑": "arrow.t",
  "↥": "arrow.t.bar",
  "⤴︎": "arrow.t.curve",
  "⮍": "arrow.t.turn",
  "⇡": "arrow.t.dashed",
  "⇑": "arrow.t.double",
  "⬆︎": "arrow.t.filled",
  "⟰": "arrow.t.quad",
  "⤒": "arrow.t.stop",
  "⇧": "arrow.t.stroked",
  "⤉": "arrow.t.struck",
  "⇞": "arrow.t.dstruck",
  "⤊": "arrow.t.triple",
  "↟": "arrow.t.twohead",
  "↓": "arrow.b",
  "↧": "arrow.b.bar",
  "⤵︎": "arrow.b.curve",
  "⮏": "arrow.b.turn",
  "⇣": "arrow.b.dashed",
  "⇓": "arrow.b.double",
  "⬇︎": "arrow.b.filled",
  "⟱": "arrow.b.quad",
  "⤓": "arrow.b.stop",
  "⇩": "arrow.b.stroked",
  "⤈": "arrow.b.struck",
  "⇟": "arrow.b.dstruck",
  "⤋": "arrow.b.triple",
  "↡": "arrow.b.twohead",
  "↔︎": "arrow.l.r",
  "⇔": "arrow.l.r.double",
  "⟺": "arrow.l.r.double.long",
  "⇎": "arrow.l.r.double.not",
  "⤄": "arrow.l.r.double.struck",
  "⬌": "arrow.l.r.filled",
  "⟷": "arrow.l.r.long",
  "↮": "arrow.l.r.not",
  "⬄": "arrow.l.r.stroked",
  "⇹": "arrow.l.r.struck",
  "⇼": "arrow.l.r.dstruck",
  "⇿": "arrow.l.r.open",
  "↭": "arrow.l.r.wave",
  "↕︎": "arrow.t.b",
  "⇕": "arrow.t.b.double",
  "⬍": "arrow.t.b.filled",
  "⇳": "arrow.t.b.stroked",
  "↗︎": "arrow.tr",
  "⇗": "arrow.tr.double",
  "⬈": "arrow.tr.filled",
  "⤤": "arrow.tr.hook",
  "⬀": "arrow.tr.stroked",
  "↘︎": "arrow.br",
  "⇘": "arrow.br.double",
  "⬊": "arrow.br.filled",
  "⤥": "arrow.br.hook",
  "⬂": "arrow.br.stroked",
  "↖︎": "arrow.tl",
  "⇖": "arrow.tl.double",
  "⬉": "arrow.tl.filled",
  "⤣": "arrow.tl.hook",
  "⬁": "arrow.tl.stroked",
  "↙︎": "arrow.bl",
  "⇙": "arrow.bl.double",
  "⬋": "arrow.bl.filled",
  "⤦": "arrow.bl.hook",
  "⬃": "arrow.bl.stroked",
  "⤡": "arrow.tl.br",
  "⤢": "arrow.tr.bl",
  "↺": "arrow.ccw",
  "↶": "arrow.ccw.half",
  "↻": "arrow.cw",
  "↷": "arrow.cw.half",
  "↯": "arrow.zigzag",
  "⇉": "arrows.rr",
  "⇇": "arrows.ll",
  "⇈": "arrows.tt",
  "⇊": "arrows.bb",
  "⇆": "arrows.lr",
  "↹": "arrows.lr.stop",
  "⇄": "arrows.rl",
  "⇅": "arrows.tb",
  "⇵": "arrows.bt",
  "⇶": "arrows.rrr",
  "⬱": "arrows.lll",
  "⌃": "arrowhead.t",
  "⌄": "arrowhead.b",
  "⇀": "harpoon.rt",
  "⥛": "harpoon.rt.bar",
  "⥓": "harpoon.rt.stop",
  "⇁": "harpoon.rb",
  "⥟": "harpoon.rb.bar",
  "⥗": "harpoon.rb.stop",
  "↼": "harpoon.lt",
  "⥚": "harpoon.lt.bar",
  "⥒": "harpoon.lt.stop",
  "↽": "harpoon.lb",
  "⥞": "harpoon.lb.bar",
  "⥖": "harpoon.lb.stop",
  "↿": "harpoon.tl",
  "⥠": "harpoon.tl.bar",
  "⥘": "harpoon.tl.stop",
  "↾": "harpoon.tr",
  "⥜": "harpoon.tr.bar",
  "⥔": "harpoon.tr.stop",
  "⇃": "harpoon.bl",
  "⥡": "harpoon.bl.bar",
  "⥙": "harpoon.bl.stop",
  "⇂": "harpoon.br",
  "⥝": "harpoon.br.bar",
  "⥕": "harpoon.br.stop",
  "⥎": "harpoon.lt.rt",
  "⥐": "harpoon.lb.rb",
  "⥋": "harpoon.lb.rt",
  "⥊": "harpoon.lt.rb",
  "⥑": "harpoon.tl.bl",
  "⥏": "harpoon.tr.br",
  "⥍": "harpoon.tl.br",
  "⥌": "harpoon.tr.bl",
  "⥤": "harpoons.rtrb",
  "⥥": "harpoons.blbr",
  "⥯": "harpoons.bltr",
  "⥧": "harpoons.lbrb",
  "⥢": "harpoons.ltlb",
  "⇋": "harpoons.ltrb",
  "⥦": "harpoons.ltrt",
  "⥩": "harpoons.rblb",
  "⇌": "harpoons.rtlb",
  "⥨": "harpoons.rtlt",
  "⥮": "harpoons.tlbr",
  "⥣": "harpoons.tltr",
  "⊢": "tack.r",
  "⊬": "tack.r.not",
  "⟝": "tack.r.long",
  "⊦": "tack.r.short",
  "⊨": "tack.r.double",
  "⊭": "tack.r.double.not",
  "⊣": "tack.l",
  "⟞": "tack.l.long",
  "⫞": "tack.l.short",
  "⫤": "tack.l.double",
  "⟘": "tack.t.big",
  "⫫": "tack.t.double",
  "⫠": "tack.t.short",
  "⟙": "tack.b.big",
  "⫪": "tack.b.double",
  "⫟": "tack.b.short",
  "⟛": "tack.l.r",
  "α": "alpha",
  "β": "beta",
  "ϐ": "beta.alt",
  "χ": "chi",
  "δ": "delta",
  "ϝ": "digamma",
  "ε": "epsilon",
  "ϵ": "epsilon.alt",
  "϶": "epsilon.alt.rev",
  "η": "eta",
  "γ": "gamma",
  "ι": "iota",
  "℩": "iota.inv",
  "κ": "kappa",
  "ϰ": "kappa.alt",
  "λ": "lambda",
  "μ": "mu",
  "ν": "nu",
  "ω": "omega",
  "ο": "omicron",
  "φ": "phi",
  "ϕ": "phi.alt",
  "π": "pi",
  "ϖ": "pi.alt",
  "ψ": "psi",
  "ρ": "rho",
  "ϱ": "rho.alt",
  "σ": "sigma",
  "ς": "sigma.alt",
  "τ": "tau",
  "θ": "theta",
  "ϑ": "theta.alt",
  "υ": "upsilon",
  "ξ": "xi",
  "ζ": "zeta",
  "Α": "Alpha",
  "Β": "Beta",
  "Χ": "Chi",
  "Δ": "Delta",
  "Ϝ": "Digamma",
  "Ε": "Epsilon",
  "Η": "Eta",
  "Γ": "Gamma",
  "Ι": "Iota",
  "Κ": "Kappa",
  "Λ": "Lambda",
  "Μ": "Mu",
  "Ν": "Nu",
  "Ω": "Omega",
  "℧": "Omega.inv",
  "Ο": "Omicron",
  "Φ": "Phi",
  "Π": "Pi",
  "Ψ": "Psi",
  "Ρ": "Rho",
  "Σ": "Sigma",
  "Τ": "Tau",
  "Θ": "Theta",
  "ϴ": "Theta.alt",
  "Υ": "Upsilon",
  "Ξ": "Xi",
  "Ζ": "Zeta",
  "ш": "sha",
  "Ш": "Sha",
  "א": "aleph",
  "ב": "beth",
  "ג": "gimel",
  "ד": "daleth",
  "𝔸": "AA",
  "𝔹": "BB",
  "ℂ": "CC",
  "𝔻": "DD",
  "𝔼": "EE",
  "𝔽": "FF",
  "𝔾": "GG",
  "ℍ": "HH",
  "𝕀": "II",
  "𝕁": "JJ",
  "𝕂": "KK",
  "𝕃": "LL",
  "𝕄": "MM",
  "ℕ": "NN",
  "𝕆": "OO",
  "ℙ": "PP",
  "ℚ": "QQ",
  "ℝ": "RR",
  "𝕊": "SS",
  "𝕋": "TT",
  "𝕌": "UU",
  "𝕍": "VV",
  "𝕎": "WW",
  "𝕏": "XX",
  "𝕐": "YY",
  "ℤ": "ZZ",
  "Å": "angstrom",
  "ℓ": "ell",
  "ħ": "planck",
  "ℜ": "Re",
  "ℑ": "Im",
  "ı": "dotless.i",
  "ȷ": "dotless.j",
  "⚅": "die.six",
  "⚄": "die.five",
  "⚃": "die.four",
  "⚂": "die.three",
  "⚁": "die.two",
  "⚀": "die.one",
  "⧮": "errorbar.square.stroked",
  "⧯": "errorbar.square.filled",
  "⧰": "errorbar.diamond.stroked",
  "⧱": "errorbar.diamond.filled",
  "⧲": "errorbar.circle.stroked",
  "⧳": "errorbar.circle.filled",
  "⚢": "gender.female.double",
  "⚤": "gender.female.male",
  "⚥": "gender.intersex",
  "⚣": "gender.male.double",
  "⚦": "gender.male.stroke",
  "⚨": "gender.male.stroke.t",
  "⚩": "gender.male.stroke.r",
  "⚲": "gender.neuter",
  "⚧︎": "gender.trans",
)
// END GENERATED TYPST SYMBOL CATALOG

let math-symbol-prefix = "\u{E000}"
let math-symbol-suffix = "\u{E001}"

let symbol-by-name(name) = {
  let value = typst-symbol-catalog.at(name, default: none)
  if value == none { none } else { (name: name, value: value) }
}

let symbol-by-value(value) = {
  let name = typst-symbol-values.at(value, default: none)
  if name == none { none } else { (name: name, value: value) }
}

let math-symbol-token(name, fallback: false) = {
  math-symbol-prefix + (if fallback { ":" } else { "" }) + name + math-symbol-suffix
}

let is-math-symbol(token) = {
  token.starts-with(math-symbol-prefix) and token.ends-with(math-symbol-suffix)
}

let math-symbol-payload(token) = token.slice(
  math-symbol-prefix.len(),
  token.len() - math-symbol-suffix.len(),
)

let normalized-symbol(name, value: none) = {
  if name == "plus" { "+" }
  else if name == "minus" { "-" }
  else if name == "times" { "×" }
  else if name in ("dot.op", "ast.op") { "*" }
  else if name == "div" { "/" }
  else if name in ("bullet", "bullet.op") { math-symbol-token("bullet") }
  else if name == "eq" { "=" }
  else if name == "plus.minus" { "±" }
  else if name == "minus.plus" { "∓" }
  else { math-symbol-token(name) }
}

let normalized-symbol-value(value) = {
  if value == "+" { return "+" }
  if value == "−" { return "-" }
  if value == "×" { return "×" }
  if value in ("⋅", "∗") { return "*" }
  if value == "÷" { return "/" }
  if value == "=" { return "=" }
  if value == "±" { return "±" }
  if value == "∓" { return "∓" }
  let entry = symbol-by-value(value)
  if entry == none { math-symbol-token(value, fallback: true) }
  else { normalized-symbol(entry.name) }
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

let variable-symbol-names = variable-symbols.pairs().map(((name, value)) => (value, name)).to-dict()
let variable-symbol-name(symbol) = variable-symbol-names.at(symbol, default: none)

let cas-functions = ("simplify", "diff", "integrate", "solve", "factor", "limit", "taylor")
let rounding-functions = ("floor", "ceil", "round")
let trigonometric-functions = ("sin", "cos", "tan")
let inverse-trigonometric-functions = ("asin", "acos", "atan")
let inverse-trigonometric-aliases = ("arcsin", "arccos", "arctan")
let inverse-trigonometric-names = inverse-trigonometric-functions + inverse-trigonometric-aliases
let math-functions = trigonometric-functions + inverse-trigonometric-names + ("atan2", "sqrt", "root", "abs", "ln", "log") + rounding-functions
let structure-functions = ("vec", "matrix", "mat")
let source-functions = math-functions + cas-functions + structure-functions
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
let subscript-pattern = regex("^[\\p{L}0-9]+$")
let variable-symbol-pattern = regex("^[\\p{L}°℃℉ℏ₂☉]+(?:_[\\p{L}0-9°℃℉ℏ₂☉]+)*$")
let letters-pattern = regex("^[\\p{L}]+$")
let number-pattern = regex("^(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?$")
let leading-zeros-pattern = regex("^0+")
let leading-letter-pattern = regex("^\\p{L}")
let name-pattern = regex("^[\\p{L}°℃℉ℏ₂☉][\\p{L}0-9°℃℉ℏ₂☉]*(?:_[\\p{L}0-9°℃℉ℏ₂☉]+)*$")
let exponent-marker-pattern = regex("[eE]")
let function-definition-pattern = regex("^\\s*([A-Za-z]+(?:_[A-Za-z0-9]+)*)\\s*\\(([^()]*)\\)\\s*:=\\s*(.+)$")
let integer-pattern = regex("^[0-9]+$")
let whitespace-pattern = regex("\\s+")
let scientific-pattern = regex(
      "^(?:([0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)\\*)?10\\^\\(?(-?[0-9]+)\\)?$",
    )
let quoted-text-pattern = regex("\"([^\"]*)\"")
let assignment-pattern = regex("^\\s*(?:\"([A-Za-z]+(?:_[A-Za-z0-9]+)*)\"|([A-Za-z]+(?:_[A-Za-z0-9]+)*))\\s*(:?=)\\s*(.+)$")
let reset-name-pattern = regex("^[A-Za-z]+(?:_[A-Za-z0-9]+)*$")
let source-space = [ ].func()
let source-sequence = $a b$.body.func()
// Only a sequence is a list of items. A lone `vec(...)` also has children, and
// treating those as items would turn the vector into a product.
let math-items(value) = if value.func() == source-sequence { value.children } else { (value,) }
let source-symbol = $alpha$.body.func()
let source-equals = [#math.eq]
let source-log = [log]
let vector-point-pattern = regex("^\\p{Lu}( \\p{Lu})+$")
// Content carries source spans. Cache the spelling rules independently of
// those spans so identical symbols in different equations share conversion.

let math-source-text(token, plain-text, symbol, preserve-text) = {
  if token.starts-with(text-unit-prefix) and token.ends-with(text-unit-suffix) {
    return token
  }
  if (plain-text
    and preserve-text != false
    and variable-symbol-pattern in token
    and token not in source-functions
    and (preserve-text == true or resolve-unit(token) != none)) {
    return "\"" + token + "\""
  }
  let variable-name = variable-symbol-name(token)
  if variable-name != none { variable-name }
  else if token == "≔" { ":=" }
  else if token == "|" { "|" }
  else if token in ("⋅", "∗") { "*" }
  else if token in ("÷",) { "/" }
  else if token in ("−",) { "-" }
  else if token in ("(", ")", ",", ";", "+", "-", "*", "×", "/", "^", "=") { token }
  else if token in ("°", "℃", "℉", "ℏ", "₂", "☉") { token }
  else if (symbol
    and resolve-unit(token) == none
    and (symbol-by-value(token) != none or letters-pattern not in token)) {
    normalized-symbol-value(token)
  }
  else { token }
}

// Parse a whole math body or a single element whose function is already
// known. Attachment bases use the element rules, with their text unquoted.
let math-source(value, preserve-text, part: none) = {
  let func = if part == none { value.func() } else { part }
  if func == source-space { return "" }
  if func == text or func == source-symbol {
    return math-source-text(value.text.trim(), func == text, func == source-symbol,
      if part == none { preserve-text } else { false })
  }
  if part == none or func == source-sequence {
    let items = if func == source-sequence { value.children } else { (value,) }
    let parts = ()
    let index = 0
    while index < items.len() {
      let item = items.at(index)
      index += 1
      let item-func = item.func()
      if item-func == source-space { continue }
      let part = if (item-func == math.attach and item.has("b")
        and item.base.func() == math.op and item.base.text == source-log) {
        if item.has("t") or item.has("tr") or item.has("tl") or item.has("br") or item.has("bl") {
          panic("math-once calculate: `log_b` supports only a base subscript")
        }
        // Typst reads `log_a(x)` as the subscript `a(x)`.
        let base-items = math-items(item.b)
        if base-items.len() >= 2 and base-items.last().func() == math.lr {
          let base = base-items.slice(0, -1).map(part => math-source(part, preserve-text))
            .filter(part => part != "").join(" ")
          "log((" + math-source(base-items.last(), preserve-text) + "),(" + base + "))"
        } else {
          while index < items.len() and items.at(index).func() == source-space { index += 1 }
          if index >= items.len() {
            panic("math-once calculate: `log_b` must be followed by an argument")
          }
          let argument = items.at(index)
          index += 1
          ("log((" + math-source(argument, preserve-text)
            + "),(" + math-source(item.b, preserve-text) + "))")
        }
      } else if item-func == text or item-func == source-symbol {
        math-source-text(item.text.trim(), item-func == text, item-func == source-symbol, preserve-text)
      } else if item == source-equals {
        "="
      } else if item.has("text") and type(item.text) == str {
        math-source-text(item.text.trim(), item-func == text, item-func == source-symbol, preserve-text)
      } else {
        math-source(item, preserve-text, part: item-func)
      }
      if part != "" { parts.push(part) }
    }
    return if parts.len() == 0 { "" } else { parts.join(" ") }
  }
  if func == math.accent {
    // Only the arrow is a vector name. Other accents would silently become one.
    if value.accent != "\u{20d7}" {
      panic("math-once calculate: only the `arrow` accent is supported in variable names")
    }
    let base = math-source(value.base, preserve-text)
    // Point names such as `arrow(A B)` form one vector name, `arrow_AB`.
    if vector-point-pattern in base { base = base.replace(" ", "") }
    return "arrow_" + base
  }
  if func == math.vec {
    return "vec(" + value.children.map(child => math-source(child, preserve-text)).join(",") + ")"
  }
  if func == math.mat {
    return "matrix(" + value.rows.map(row => row.map(child => math-source(child, preserve-text)).join(",")).join(";") + ")"
  }
  if func == math.frac {
    return "(" + math-source(value.num, preserve-text) + ")/(" + math-source(value.denom, preserve-text) + ")"
  }
  if func == math.root {
    return if value.has("index") {
      "root(" + math-source(value.index, preserve-text) + "," + math-source(value.radicand, preserve-text) + ")"
    } else {
      "sqrt(" + math-source(value.radicand, preserve-text) + ")"
    }
  }
  if func == math.attach {
    // A prime or a corner attachment would otherwise be dropped, so that `x'`
    // silently read and overwrote `x`.
    if value.has("tr") or value.has("tl") or value.has("br") or value.has("bl") {
      panic("math-once calculate: primes and corner attachments are not supported in variable names")
    }
    let base = math-source(value.base, preserve-text, part: value.base.func())
    if value.has("b") {
      let subscript = math-source(value.b, preserve-text)
      if (subscript.len() >= 2
        and subscript.starts-with("\"")
        and subscript.ends-with("\"")) {
        subscript = subscript.slice(1, subscript.len() - 1)
      }
      if subscript-pattern not in subscript {
        panic("math-once calculate: variable subscripts must contain only letters or digits")
      }
      base += "_" + subscript
    }
    if value.has("t") {
      return base + "^(" + math-source(value.t, preserve-text) + ")"
    }
    return base
  }
  if func == math.lr {
    let parts = math-items(value.body)
    if parts.len() >= 3 {
      let left = parts.first()
      let right = parts.last()
      let left-text = if left.has("text") { left.text.trim() } else { "" }
      let right-text = if right.has("text") { right.text.trim() } else { "" }
      let rounding = if left-text == "⌊" and right-text == "⌋" {
        "floor"
      } else if left-text == "⌈" and right-text == "⌉" {
        "ceil"
      } else if left-text == "⌊" and right-text == "⌉" {
        "round"
      } else {
        none
      }
      if rounding != none {
        let inner = parts.slice(1, parts.len() - 1).map(part => math-source(part, preserve-text))
          .filter(part => part != "").join(" ")
        return rounding + "(" + inner + ")"
      }
    }
    return math-source(value.body, preserve-text)
  }
  if func == math.op {
    return math-source(value.text, preserve-text)
  }
  if not value.has("text") {
    panic("math-once calculate: unsupported Typst math element `" + repr(func) + "`")
  }

  math-source-text(value.text.trim(), func == text, func == source-symbol, false)
}

let input-source(source, preserve-text: false) = if type(source) == content and source.func() == math.equation {
  math-source(source.body, preserve-text).trim()
} else {
  source-string(source)
}

// Regexes are compiled once here; building one costs about 1.6 ms per call.
let tokenize-name = "[\\p{L}°℃℉ℏ₂☉][\\p{L}0-9°℃℉ℏ₂☉]*(?:_[\\p{L}0-9°℃℉ℏ₂☉]+)*"
let tokenize-symbolic = "⟦[^⟦⟧]+⟧"
let tokenize-math-symbol = math-symbol-prefix + "[^" + math-symbol-prefix + math-symbol-suffix + "]+" + math-symbol-suffix
let tokenize-dotted-name = "[A-Za-z][A-Za-z0-9]*(?:\\.[A-Za-z0-9]+)+"
let tokenize-raw-symbol = "[\\p{S}\\p{P}]\\p{M}*"
let tokenize-pattern = regex("(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?|" + tokenize-symbolic + "|" + tokenize-math-symbol + "|\"" + tokenize-name + "\"|" + tokenize-dotted-name + "|" + tokenize-name + "|:=|[=(),;+*/^+\\-]|" + tokenize-raw-symbol)
let tokenize-raw-only = regex("^" + tokenize-raw-symbol + "$")
// Cache symbol normalization by token rather than by the entire expression.
let normalized-token(token) = {
  let entry = typst-symbol-catalog.at(token, default: none)
  if (token.starts-with(math-symbol-prefix) and token.ends-with(math-symbol-suffix)) {
    token
  } else if entry != none and token not in variable-symbols and resolve-unit(token) == none and token not in source-functions {
    normalized-symbol(token, value: entry)
  } else if (tokenize-raw-only in token
    and resolve-unit(token) == none
    and token not in ("=", "(", ")", ",", ";", "+", "-", "*", "×", "/", "^", "|")) {
    normalized-symbol-value(token)
  } else {
    token
  }
}

// The ASCII subset avoids building the Unicode matcher's large scratch space
// for ordinary equations. Non-ASCII input keeps the complete tokenizer.
let non-ascii-pattern = regex("[^\\x00-\\x7f]")
let ascii-token-name = "[A-Za-z][A-Za-z0-9]*(?:_[A-Za-z0-9]+)*"
let ascii-tokenize-pattern = regex("(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?|\"" + ascii-token-name + "\"|" + tokenize-dotted-name + "|" + ascii-token-name + "|:=|[[:punct:]]")

let token-matches(source) = source.matches(if non-ascii-pattern in source { tokenize-pattern } else { ascii-tokenize-pattern })

let tokenize(source) = {
  let tokens = ()
  let cursor = 0
  for found in token-matches(source) {
    if source.slice(cursor, found.start).trim() != "" {
      panic("math-once calculate: unsupported syntax near `" + source.slice(cursor, found.start) + "`")
    }
    tokens.push(normalized-token(found.text))
    cursor = found.end
  }
  if source.slice(cursor).trim() != "" {
    panic("math-once calculate: unsupported syntax near `" + source.slice(cursor) + "`")
  }
  if tokens.len() == 0 { panic("math-once calculate: expression must not be empty") }
  tokens
}

let is-number(token) = number-pattern in token
// Count written decimal places, including trailing zeros and scientific notation.
let input-decimal-places(token) = {
  let parts = token.replace("E", "e").split("e")
  let mantissa = parts.first()
  let places = if "." in mantissa { mantissa.split(".").last().len() } else { 0 }
  let exponent = if parts.len() > 1 { int(parts.last()) } else { 0 }
  calc.max(0, places - exponent)
}

let whole-number-pattern = regex("^[0-9]+$")
let multiplication-operators = ("*", "×", "/")

// Drop the numeric literals that describe the formula rather than a measured
// input, so both automatic precision modes count only the remaining tokens:
// - every literal inside an exponent, including parenthesized ones such as
//   `s^(2)`, because powers describe the operation or unit;
// - whole-number factors such as the `1` and `3` in `1/3 * m * L^2` or the `2`
//   in `2 x`, because formula constants are exact. A whole number followed by a
//   unit, such as `12 "m"`, is a measurement, and one that is added,
//   subtracted, or stands alone, such as in `1 + 3.456`, still counts.
let precision-tokens(tokens, scope: (:), aliases: (:), unloaded: ()) = {
  let is-unit-token(token) = ((token.len() >= 2 and token.starts-with("\"") and token.ends-with("\""))
    or (token.starts-with(text-unit-prefix) and token.ends-with(text-unit-suffix))
    or (name-pattern in token and token not in scope and token not in unloaded
      and resolve-unit-with-aliases(token, aliases: aliases) != none))
  let exact-factor(index) = {
    let after = index + 1
    if after < tokens.len() and is-unit-token(tokens.at(after)) { return false }
    // Look through unary signs and parentheses around the literal alone, as
    // in `(1)/(3)`, `x / (-2)`, or `-(2) * v`.
    let before = index - 1
    while before >= 0 {
      let token = tokens.at(before)
      if token in ("+", "-") and (before == 0 or tokens.at(before - 1) in ("(", "+", "-", ",", ";", "=", ..multiplication-operators)) {
        before -= 1
      } else if token == "(" and after < tokens.len() and tokens.at(after) == ")" {
        // A function argument such as the `30` in `sin(30)` is an input.
        if before > 0 and name-pattern in tokens.at(before - 1) { return false }
        before -= 1
        after += 1
      } else {
        break
      }
    }
    // A whole number times or per a unit is a measurement too: `(12) m`,
    // `( 3 ) * m` from a stored function body, `3 / s`, `12 * (m^2)`, or
    // `"kg" * 3`. A unit after another value belongs to that value, so the 12
    // in `1.5 m * 12` is a count.
    if after < tokens.len() and is-unit-token(tokens.at(after)) { return false }
    if after + 1 < tokens.len() and tokens.at(after) in multiplication-operators {
      let operand = after + 1
      while operand < tokens.len() and tokens.at(operand) == "(" { operand += 1 }
      if operand < tokens.len() and is-unit-token(tokens.at(operand)) { return false }
    }
    if before >= 1 and tokens.at(before) in multiplication-operators {
      let unit-index = before - 1
      while unit-index >= 0 and tokens.at(unit-index) == ")" { unit-index -= 1 }
      // Step over the unit's power, as in `m^2`, `m^(2)`, or `m^-2`.
      let probe = unit-index
      while probe >= 0 and (number-pattern in tokens.at(probe) or tokens.at(probe) in ("(", "+", "-")) { probe -= 1 }
      if probe >= 1 and probe < unit-index and tokens.at(probe) == "^" {
        unit-index = probe - 1
        while unit-index >= 0 and tokens.at(unit-index) == ")" { unit-index -= 1 }
      }
      if unit-index >= 0 and is-unit-token(tokens.at(unit-index)) {
        let previous = unit-index - 1
        while previous >= 0 and tokens.at(previous) == "(" { previous -= 1 }
        let owned = (previous >= 0 and (number-pattern in tokens.at(previous) or tokens.at(previous) == ")"
          or (name-pattern in tokens.at(previous) and not is-unit-token(tokens.at(previous)))))
        if not owned { return false }
      }
    }
    if before >= 0 and tokens.at(before) in multiplication-operators { return true }
    if after >= tokens.len() { return false }
    let next = tokens.at(after)
    // Implicit multiplication: `2 x`, `3 (x + 1)`, or `1/(3 m)`.
    (next in multiplication-operators or next == "("
      or (name-pattern in next and not is-unit-token(next)))
  }
  let kept = ()
  let exponent-end = -1
  for (index, token) in tokens.enumerate() {
    if token == "^" and index >= exponent-end {
      let next = index + 1
      while next < tokens.len() and tokens.at(next) in ("+", "-") { next += 1 }
      // A function exponent such as `abs(2)` includes its argument list.
      if next + 1 < tokens.len() and leading-letter-pattern in tokens.at(next) and tokens.at(next + 1) == "(" { next += 1 }
      if next < tokens.len() and tokens.at(next) == "(" {
        let depth = 0
        while next < tokens.len() {
          if tokens.at(next) == "(" { depth += 1 }
          if tokens.at(next) == ")" { depth -= 1 }
          if depth == 0 { break }
          next += 1
        }
      }
      exponent-end = next + 1
      continue
    }
    if index < exponent-end and (number-pattern in token) { continue }
    if whole-number-pattern in token and exact-factor(index) { continue }
    kept.push(token)
  }
  kept
}

// Leading zeros are placeholders; written trailing zeros express precision.
let input-significant-digits(token) = {
  let mantissa = token.replace("E", "e").split("e").first().replace(".", "")
  let meaningful = mantissa.replace(leading-zeros-pattern, "")
  calc.max(1, meaningful.len())
}

// Both results are stored even when the caller selected a fixed precision,
// since a later equation can use either precision mode.
let input-precision(tokens, scope) = {
  let places = ()
  let significant = ()
  for token in tokens {
    if number-pattern in token {
      places.push(input-decimal-places(token))
      significant.push(input-significant-digits(token))
    } else if token in scope {
      let item = scope.at(token)
      if type(item) in (int, float, decimal) {
        places.push(input-decimal-places(str(item)))
        significant.push(input-significant-digits(str(calc.abs(item))))
      } else if type(item) == dictionary and "exact" in item and not item.at("exact-constant", default: false) {
        places.push(if "input-digits" in item { item.input-digits }
          else if "digits" in item { item.digits }
          else { input-decimal-places(str(item.exact)) })
        significant.push(if "input-significant-digits" in item { item.input-significant-digits }
          else { input-significant-digits(str(calc.abs(item.exact))) })
      }
    }
  }
  (if places.len() == 0 { 4 } else { calc.min(..places) },
    if significant.len() == 0 { 4 } else { calc.min(..significant) })
}

let valid-auto-digits(auto-digits) = auto-digits in ("decimal", "significant")
let auto-digits-message = "auto-digits must be decimal or significant"
// Typst's rounding only takes whole numbers of places; anything else would stop
// compilation with an internal type error.
let valid-digits(digits) = (digits == none or digits == auto or type(digits) == int
  or (type(digits) == dictionary and digits.keys() == ("significant",)
    and (digits.significant == auto or type(digits.significant) == int)))
let digits-message = "digits must be auto or a whole number"

// Unset digits (`none`) follow the rounding mode: significant mode rounds
// automatically, decimal mode keeps the long-standing default of 4 places.
let default-digits(digits, auto-digits) = if digits != none { digits } else if auto-digits == "significant" { auto } else { 4 }

// Carry the automatic mode through scalar, paired, and structure evaluation.
let automatic-precision(digits, auto-digits) = {
  if not valid-auto-digits(auto-digits) { panic("math-once: " + auto-digits-message) }
  if not valid-digits(digits) { panic("math-once: " + digits-message) }
  let digits = default-digits(digits, auto-digits)
  if digits == auto and auto-digits == "significant" { (significant: auto) } else { digits }
}

let is-name(token) = name-pattern in token
let is-quoted-unit(token) = token.starts-with("\"") and token.ends-with("\"") and token.len() >= 2
let quoted-unit-name(token) = token.slice(1, token.len() - 1)
let is-text-unit(token) = token.starts-with(text-unit-prefix) and token.ends-with(text-unit-suffix) and token.len() >= 2
let text-unit-name(token) = token.slice(text-unit-prefix.len(), token.len() - text-unit-suffix.len())
// Spelled-out ohm units, including prefixed forms such as `kohm`, display as Ω.
let unit-display-name(name) = if name.ends-with("ohm") and resolve-unit(name) != none {
  name.slice(0, name.len() - 3) + "Ω"
} else {
  name
}
let multiplication-atom(token) = (
  number-pattern in token or name-pattern in token
  or (token.starts-with("\"") and token.ends-with("\"") and token.len() >= 2)
  or (token.starts-with(text-unit-prefix) and token.ends-with(text-unit-suffix) and token.len() >= 2)
)
let can-end(token) = token == ")" or multiplication-atom(token)
let can-start(token) = token == "(" or multiplication-atom(token)

let add-implicit-multiplication(tokens) = {
  let result = ()
  let previous = none
  let previous-can-end = false
  for token in tokens {
    let atom = multiplication-atom(token)
    if (previous-can-end and (atom or token == "(")
      and not (token == "(" and previous in source-functions)) {
      result.push("*")
    }
    result.push(token)
    previous = token
    previous-can-end = atom or token == ")"
  }
  result
}

let degree-tokens = ("deg", "degree", "degrees", "°", "\"deg\"", "\"degree\"", "\"degrees\"", "\"°\"")
let is-degree-token(token, scope: (:), aliases: (:)) = {
  if token not in degree-tokens { return false }
  let name = if token.starts-with("\"") { quoted-unit-name(token) } else { token }
  name not in scope and name not in aliases
}

let unit-gap(tokens, aliases: (:)) = {
  if tokens.len() > 0 and is-degree-token(tokens.first(), aliases: aliases) { h(0em) } else { h(0.2em) }
}

// Convert scalar absolute-value bars to the evaluator's abs(...) function.
// A bar can only open where an operand is expected, which leaves conditional,
// divisibility, determinant, and other infix bar notation display-only.
let absolute-value-tokens(tokens) = {
  if "|" not in tokens { return tokens }
  let result = ()
  let depth = 0
  let expects-operand = true
  for token in tokens {
    if token == "|" {
      if depth > 0 and not expects-operand {
        result.push(")")
        depth -= 1
        expects-operand = false
      } else if expects-operand {
        result.push("abs")
        result.push("(")
        depth += 1
        expects-operand = true
      } else {
        return none
      }
    } else {
      result.push(token)
      expects-operand = token in ("(", ",", "+", "-", "*", "×", "/", "^", "=", ":=")
    }
  }
  if depth == 0 { result } else { none }
}

let rendered-operator-names = cas-functions + inverse-trigonometric-names + ("atan2",)
let point-name-pattern = regex("^[A-Z]{2,}$")
let plain-display-number-pattern = regex("^[+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)$")

// Rewrite `log(x, b)` as `log _ (b) (x)` so the base renders as a subscript.
let subscript-log-tokens(tokens) = {
  // Drop redundant outer parentheses, e.g. `((32))` from `log_4(32)`.
  let unwrap(part) = {
    while part.len() >= 2 and part.first() == "(" and part.last() == ")" {
      let depth = 0
      let whole = true
      for (position, token) in part.enumerate() {
        if token == "(" { depth += 1 }
        if token == ")" { depth -= 1 }
        if depth == 0 and position < part.len() - 1 { whole = false; break }
      }
      if not whole { break }
      part = part.slice(1, part.len() - 1)
    }
    part
  }
  let result = ()
  let index = 0
  while index < tokens.len() {
    if tokens.at(index) == "log" and tokens.at(index + 1, default: none) == "(" {
      let depth = 0
      let comma = none
      let close = none
      for position in range(index + 1, tokens.len()) {
        let token = tokens.at(position)
        if token == "(" { depth += 1 }
        else if token == ")" {
          depth -= 1
          if depth == 0 { close = position; break }
        } else if token == "," and depth == 1 and comma == none { comma = position }
      }
      if comma != none and close != none {
        let inner = subscript-log-tokens(tokens.slice(index + 2, comma))
        let base = subscript-log-tokens(tokens.slice(comma + 1, close))
        result += ("log", "_", "(") + unwrap(base) + (")", "(") + unwrap(inner) + (")",)
        index = close + 1
        continue
      }
    }
    result.push(tokens.at(index))
    index += 1
  }
  result
}

// These atoms have exactly the same content trees as their math source, so
// common products do not need to invoke the math source compiler.
let native-number-pattern = regex("^[0-9]+(?:\\.[0-9]+)?$")
let native-variable-part(part) = if part in variable-symbols {
  source-symbol(variable-symbols.at(part))
} else if part.len() == 1 and number-pattern not in part {
  source-symbol(part)
} else { text(part) }
let native-variable(token) = {
  let parts = token.split("_")
  if parts.len() > 2 or parts.any(part => number-pattern in part and exponent-marker-pattern in part) { return none }
  if parts.len() == 2 {
    return math.attach(native-variable-part(parts.first()), b: native-variable-part(parts.last()))
  }
  if token in variable-symbols { source-symbol(variable-symbols.at(token)) } else { text(token) }
}
let native-atom(token, variable, alias) = {
  if native-number-pattern in token { return text(token) }
  if token == "*" { return source-symbol("⋅") }
  if token in degree-tokens or token in source-functions or token.starts-with("arrow_") { return none }
  if is-quoted-unit(token) {
    let name = quoted-unit-name(token)
    if resolve-unit(name) == none { return none }
    return math.upright(text(unit-display-name(name)))
  }
  if name-pattern not in token { return none }
  if alias { return math.upright(text(token)) }
  if variable { return native-variable(token) }
  if token in ("meter", "metre") { return math.upright(text("m")) }
  if resolve-unit(token) != none { return math.upright(text(unit-display-name(token))) }
  native-variable(token)
}

let native-power(base, exponent) = if base.func() == math.attach {
  math.attach(base.base, b: base.b, t: exponent)
} else { math.attach(base, t: exponent) }

let render-tokens(tokens, scope: (:), aliases: (:)) = {
  if tokens.len() == 1 and native-number-pattern in tokens.first() {
    return text(tokens.first())
  }
  if tokens.len() == 1 and plain-display-number-pattern in tokens.first() {
    return eval(tokens.first(), mode: "math").body
  }
  if (tokens.len() == 3 and tokens.at(1) in ("/", "^")
    and not (tokens.at(1) == "^" and "_" in tokens.last())) {
    let left = native-atom(tokens.first(), tokens.first() in scope, tokens.first() in aliases)
    let right = native-atom(tokens.last(), tokens.last() in scope, tokens.last() in aliases)
    if left != none and right != none {
      return if tokens.at(1) == "/" { math.frac(left, right) } else { native-power(left, right) }
    }
  }
  if (tokens.len() == 5 and tokens.at(1) == "/" and tokens.at(3) == "^"
    and "_" not in tokens.last()) {
    let atoms = ()
    for index in (0, 2, 4) {
      let token = tokens.at(index)
      atoms.push(native-atom(token, token in scope, token in aliases))
    }
    if atoms.all(atom => atom != none) {
      return math.frac(atoms.first(), native-power(atoms.at(1), atoms.last()))
    }
  }
  if tokens.len() == 1 {
    let token = tokens.first()
    let atom = native-atom(token, token in scope, token in aliases)
    if atom != none { return atom }
  }
  let native = []
  let simple = true
  for (index, token) in tokens.enumerate() {
    let atom = native-atom(token, token in scope, token in aliases)
    if atom == none { simple = false; break }
    if index > 0 { native += [ ] }
    native += atom
  }
  if simple and tokens.len() > 0 { return native }
  // Give magnitudes real paired delimiters so they scale with column vectors.
  // Leave unpaired/infix bars (such as a conditional) untouched.
  let absolute = absolute-value-tokens(tokens)
  if absolute != none { tokens = absolute }
  if "log" in tokens { tokens = subscript-log-tokens(tokens) }
  let absolute-opens = ()
  let absolute-closes = ()
  let parentheses = ()
  for (index, token) in (if "abs" in tokens { tokens } else { () }).enumerate() {
    if token == "(" {
      let magnitude = tokens.at(index - 1, default: none) == "abs"
      parentheses.push(magnitude)
      if magnitude { absolute-opens.push(index) }
    } else if token == ")" and parentheses.len() > 0 {
      if parentheses.pop() { absolute-closes.push(index) }
    }
  }
  let render-variable(token) = if "_" in token {
    let parts = token.split("_")
    let render-part(part) = if part in variable-symbols {
      part
    } else if part.len() == 1 or (number-pattern in part) {
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

  let rendered = ()
  for (index, token) in tokens.enumerate() {
    rendered.push(if index in absolute-opens {
      "lr(|"
    } else if index in absolute-closes {
      "|)"
    } else if token == "abs" and index + 1 in absolute-opens {
      ""
    } else if (token.starts-with(math-symbol-prefix) and token.ends-with(math-symbol-suffix)) {
      let payload = math-symbol-payload(token)
      if payload.starts-with(":") {
        "class(\"normal\", " + repr(payload.slice(1)) + ")"
      } else {
        payload
      }
    } else if (token.starts-with(text-unit-prefix) and token.ends-with(text-unit-suffix) and token.len() >= 2) {
      "upright(\"" + text-unit-name(token) + "\")"
    } else if (token in degree-tokens and (if token.starts-with("\"") { token.slice(1, token.len() - 1) } else { token }) not in scope and (if token.starts-with("\"") { token.slice(1, token.len() - 1) } else { token }) not in aliases) {
      "degree"
    } else if (token.starts-with("\"") and token.ends-with("\"") and token.len() >= 2) {
      let name = quoted-unit-name(token)
      let symbol-tokens = tokenize(name)
      if resolve-unit(name) == none and name in variable-symbols {
        name
      } else if (symbol-tokens.len() == 1 and is-math-symbol(symbol-tokens.first())) {
        render-tokens(symbol-tokens, scope: scope, aliases: aliases)
      } else {
        "upright(\"" + unit-display-name(name) + "\")"
      }
    } else if (name-pattern in token) {
      if (token in rendered-operator-names
        and index + 1 < tokens.len()
        and tokens.at(index + 1) == "(") {
        "op(\"" + token + "\")"
      } else if token in math-functions {
        token
      } else if token == "vec" {
        "vec"
      } else if token in ("matrix", "mat") {
        "mat"
      } else if token.starts-with("arrow_") {
        let name = token.slice(6)
        let parts = name.split("_")
        // Draw point names such as `AB` as italic letters under one arrow.
        if point-name-pattern in parts.first() and parts.first() not in variable-symbols {
          let points = parts.first().clusters().join(" ")
          let rest = parts.slice(1)
          "arrow(" + points + ")" + if rest.len() > 0 { "_" + render-variable(rest.join("_")) } else { "" }
        } else {
          "arrow(" + render-variable(parts.first()) + ")" + if parts.len() > 1 {
            "_" + render-variable(parts.slice(1).join("_"))
          } else { "" }
        }
      } else if token in aliases {
        "upright(\"" + token + "\")"
      } else if token in scope {
        render-variable(token)
      } else if token == "degree" {
        "degree"
      } else if token in ("meter", "metre") {
        "upright(\"m\")"
      } else if resolve-unit(token) != none {
        "upright(\"" + unit-display-name(token) + "\")"
      } else {
        render-variable(token)
      }
    } else if token == "*" {
      "dot"
    } else if token == "±" {
      "plus.minus"
    } else if token == "∓" {
      "minus.plus"
    } else if (number-pattern in token) and exponent-marker-pattern in token {
      // Written scientific notation renders as a coefficient times a power of ten.
      let (mantissa, exponent) = token.replace("E", "e").split("e")
      let power = mantissa + " dot 10^(" + str(int(exponent)) + ")"
      // Group it where Typst math would otherwise split the product.
      let neighbors = (tokens.at(index - 1, default: none), tokens.at(index + 1, default: none))
      if neighbors.any(item => item in ("/", "^")) { "(" + power + ")" } else { power }
    } else {
      token
    })
  }
  let source = ""
  for (index, item) in rendered.enumerate() {
    if item == "" { continue }
    if (source != "" and not source.ends-with("lr(|") and item != "|)" and item != "_" and not source.ends-with("_")
      and not (index > 0 and index not in absolute-opens and tokens.at(index - 1) in source-functions and tokens.at(index) == "(")) {
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

// Typst math fractions wrap their numerator, denominator, and exponents in
// grouping that is absent from the calculator's unit string. Remove only
// grouping that cannot change the value before comparing the two forms.
let comparable-unit-tokens(tokens) = {
  let result = ()
  let index = 0
  while index < tokens.len() {
    if tokens.at(index) == "(" {
      let depth = 1
      let closing = index + 1
      while closing < tokens.len() and depth > 0 {
        if tokens.at(closing) == "(" { depth += 1 }
        if tokens.at(closing) == ")" { depth -= 1 }
        closing += 1
      }
      if depth != 0 {
        result.push(tokens.at(index))
        index += 1
        continue
      }
      let inner = comparable-unit-tokens(tokens.slice(index + 1, closing - 1))
      let atomic = inner.len() == 1 and (
        is-number(inner.first())
        or is-name(inner.first())
        or is-quoted-unit(inner.first())
        or is-text-unit(inner.first())
      )
      let atomic-power = (inner.len() == 3
        and (is-name(inner.first()) or is-quoted-unit(inner.first()) or is-text-unit(inner.first()))
        and inner.at(1) == "^"
        and is-number(inner.at(2)))
      if atomic or atomic-power {
        result += inner
      } else {
        result.push("(")
        result += inner
        result.push(")")
      }
      index = closing
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

// `bullet` is the dot product operator for vectors, not a display-only symbol.
let dot-product-token = math-symbol-prefix + "bullet" + math-symbol-suffix
let cross-product-message = "`times` (cross product) requires two vectors with three components"
let dot-product-message = "`bullet` (dot product) requires two vectors with the same number of components"
let is-display-only-token(token) = (token.starts-with(math-symbol-prefix) and token.ends-with(math-symbol-suffix) and token != dot-product-token) or token == "|"

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
  let matched = source.match(function-definition-pattern)
  if matched == none { return none }
  let parameters = matched.captures.at(1).split(",").map(item => item.trim())
  if parameters.len() == 0 or parameters.any(item => not (name-pattern in item)) {
    return none
  }
  let body = matched.captures.at(2).trim()
  let body-tokens = tokenize(body)
  let vector = body-tokens.len() >= 3 and body-tokens.first() == "vec" and body-tokens.at(1) == "(" and body-tokens.last() == ")"
  let matrix = body-tokens.len() >= 3 and body-tokens.first() in ("matrix", "mat") and body-tokens.at(1) == "(" and body-tokens.last() == ")"
  (
    function: true,
    name: matched.captures.at(0),
    parameters: parameters,
    body: body,
    body-tokens: body-tokens,
    vector: vector,
    matrix: matrix,
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

let expand-function-calls(tokens, scope, stack: (), depth: 0) = {
  if depth > 64 {
    return calculation-failure("stored function expansion exceeded 64 nested calls")
  }
  if "(" not in tokens { return (tokens, false) }
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
      let paren-depth = 1
      let closing = index + 2
      while closing < tokens.len() and paren-depth > 0 {
        if tokens.at(closing) == "(" { paren-depth += 1 }
        if tokens.at(closing) == ")" { paren-depth -= 1 }
        closing += 1
      }
      if paren-depth != 0 { return calculation-failure("missing closing parenthesis in function call") }
      let arguments = split-top-level(tokens.slice(index + 2, closing - 1))
      if token in stack {
        return calculation-failure(
          "recursive stored function cycle: " + (stack + (token,)).join(" -> "),
        )
      }
      let expanded-arguments = ()
      for argument in arguments {
        let expanded-argument = expand-function-calls(
          argument,
          scope,
          stack: stack,
          depth: depth + 1,
        )
        if (type(expanded-argument) == dictionary and "error" in expanded-argument) { return expanded-argument }
        expanded-arguments.push(expanded-argument.first())
      }
      let expanded = substitute-function(definition, expanded-arguments)
      if (type(expanded) == dictionary and "error" in expanded) { return expanded }
      let nested = expand-function-calls(
        expanded,
        scope,
        stack: stack + (token,),
        depth: depth + 1,
      )
      if (type(nested) == dictionary and "error" in nested) { return nested }
      result.push("(")
      result += nested.first()
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

let is-vector-result(result) = type(result) == dictionary and result.at("vector", default: false)
let is-matrix-result(result) = type(result) == dictionary and result.at("matrix", default: false)
let is-structure-result(result) = type(result) == dictionary and (result.at("vector", default: false) or result.at("matrix", default: false))

let numeric-scope(scope) = {
  let result = (:)
  for (name, value) in scope {
    let unloaded-marker = type(value) == dictionary and value.at("unloaded", default: false) and "si-value" not in value
    let unit-alias = type(value) == dictionary and value.at("unit-alias", default: false)
    let initial-state-marker = type(value) == dictionary and value.at("initial-state-marker", default: false)
    let stored-function = type(value) == dictionary and value.at("function", default: false)
    let symbolic-result = type(value) == dictionary and value.at("symbolic", default: false)
    let structure-result = (type(value) == dictionary and (value.at("vector", default: false) or value.at("matrix", default: false)))
    if (not unloaded-marker
      and not unit-alias
      and not initial-state-marker
      and not stored-function
      and not symbolic-result
      and not structure-result) {
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

let complete-structure-call(tokens) = {
  let depth = 0
  for (index, token) in tokens.slice(1).enumerate() {
    if token == "(" { depth += 1 }
    if token == ")" { depth -= 1 }
    if depth == 0 and index < tokens.len() - 2 { return false }
  }
  depth == 0
}

let vector-components(tokens) = {
  tokens = unwrap-tokens(tokens)
  if (tokens.len() >= 3
  and tokens.first() == "vec"
  and tokens.at(1) == "("
  and tokens.last() == ")"
  and complete-structure-call(tokens)) {
    split-top-level(tokens.slice(2, tokens.len() - 1))
  } else {
    none
  }
}

let matrix-rows(tokens) = {
  tokens = unwrap-tokens(tokens)
  if (tokens.len() >= 3
  and tokens.first() in ("matrix", "mat")
  and tokens.at(1) == "("
  and tokens.last() == ")"
  and complete-structure-call(tokens)) {
    split-top-level(tokens.slice(2, tokens.len() - 1), separator: ";")
      .map(row => split-top-level(row))
  } else {
    none
  }
}

let vector-result(components, source: none) = (
  vector: true,
  components: components,
  values: components.map(component => component.value),
  source: source,
)

let matrix-result(rows, source: none) = (
  matrix: true,
  rows: rows,
  values: rows.map(row => row.map(cell => cell.value)),
  shape: (rows.len(), if rows.len() == 0 { 0 } else { rows.first().len() }),
  source: source,
)

// Intermediate values have no requested unit. When their dimension has several
// names, such as J and Nm, store them in base SI units so later steps convert.
let intermediate-calculation(calculate-fn, source, ..args) = {
  let named = args.named()
  let result = calculate-fn(source, ..named)
  if ((type(result) == dictionary and "error" in result)
    and named.at("unit", default: none) == none
    and result.error.starts-with("ambiguous unit")) {
    for fallback in ("1/s", "m^2/s^2", "kg*m^2/s^2", "cd") {
      named.insert("unit", fallback)
      let retry = calculate-fn(source, ..named)
      if not (type(retry) == dictionary and "error" in retry) { return retry }
    }
  }
  result
}

// `unit` and `size` apply to the final result: a scalar, or each component or
// cell of a vector or matrix. Intermediate results use base SI units.
let structure-operation(calculate-fn, left, operator, right, digits, aliases, unit: none, size: none, final: true) = {
  let left-vector = (type(left) == dictionary and left.at("vector", default: false))
  let right-vector = (type(right) == dictionary and right.at("vector", default: false))
  let left-matrix = (type(left) == dictionary and left.at("matrix", default: false))
  let right-matrix = (type(right) == dictionary and right.at("matrix", default: false))
  let left-structure = left-vector or left-matrix
  let right-structure = right-vector or right-matrix

  let finish(source, scope) = {
    if final {
      calculate-fn(source, digits: digits, scope: scope, unit: unit, size: size, block: false, aliases: aliases, soft: true)
    } else {
      intermediate-calculation(calculate-fn, source, digits: digits, scope: scope, block: false, aliases: aliases, soft: true)
    }
  }
  let combine(a, op, b) = finish("mathonceleft " + op + " mathonceright", (mathonceleft: a, mathonceright: b))
  let structure(result) = {
    if final and (unit != none or size != none) { result.insert("unit-applied", true) }
    result
  }
  let sum-of-products(left-items, right-items) = {
    let scope = (:)
    let terms = ()
    for (index, (a, b)) in left-items.zip(right-items).enumerate() {
      scope.insert("mathoncel" + str(index), a)
      scope.insert("mathoncer" + str(index), b)
      terms.push("mathoncel" + str(index) + " * mathoncer" + str(index))
    }
    finish(terms.join(" + "), scope)
  }

  // `times` is the cross product only between two vectors.
  if operator == "×" and not (left-vector and right-vector) { operator = "*" }

  // A dot product yields a scalar that later operators may combine further.
  if not left-structure and not right-structure and operator in ("+", "-", "*", "/", "^") {
    return combine(left, operator, right)
  }
  if operator == "^" {
    return calculation-failure("vectors and matrices cannot be raised to a power")
  }

  if operator == dot-product-token {
    if not (left-vector and right-vector) or left.components.len() != right.components.len() {
      return calculation-failure(dot-product-message)
    }
    return sum-of-products(left.components, right.components)
  }

  if operator == "×" {
    if left.components.len() != 3 or right.components.len() != 3 {
      return calculation-failure(cross-product-message)
    }
    let scope = (:)
    for index in range(3) {
      scope.insert("mathoncel" + str(index), left.components.at(index))
      scope.insert("mathoncer" + str(index), right.components.at(index))
    }
    // Each component is one calculation so `unit:` can name its output unit.
    let components = ()
    for (i, j) in ((1, 2), (2, 0), (0, 1)) {
      let result = finish(
        "mathoncel" + str(i) + " * mathoncer" + str(j) + " - mathoncel" + str(j) + " * mathoncer" + str(i),
        scope,
      )
      if (type(result) == dictionary and "error" in result) { return result }
      components.push(result)
    }
    return structure(vector-result(components))
  }

  if operator in ("+", "-") {
    if left-vector and right-vector {
      if left.components.len() != right.components.len() {
        return calculation-failure("vectors must have the same number of components")
      }
      let components = ()
      for (a, b) in left.components.zip(right.components) {
        let result = combine(a, operator, b)
        if (type(result) == dictionary and "error" in result) { return result }
        components.push(result)
      }
      return structure(vector-result(components))
    }
    if left-matrix and right-matrix {
      if left.shape != right.shape {
        return calculation-failure("matrices must have the same shape")
      }
      let rows = ()
      for (left-row, right-row) in left.rows.zip(right.rows) {
        let row = ()
        for (a, b) in left-row.zip(right-row) {
          let result = combine(a, operator, b)
          if (type(result) == dictionary and "error" in result) { return result }
          row.push(result)
        }
        rows.push(row)
      }
      return structure(matrix-result(rows))
    }
    return calculation-failure("`" + operator + "` requires two vectors or two matrices of the same kind")
  }

  if operator == "/" {
    if not left-structure or right-structure {
      return calculation-failure("only a vector or matrix divided by a scalar is supported")
    }
    if left-vector {
      let components = ()
      for component in left.components {
        let result = combine(component, "/", right)
        if (type(result) == dictionary and "error" in result) { return result }
        components.push(result)
      }
      return structure(vector-result(components))
    }
    let rows = ()
    for source-row in left.rows {
      let row = ()
      for cell in source-row {
        let result = combine(cell, "/", right)
        if (type(result) == dictionary and "error" in result) { return result }
        row.push(result)
      }
      rows.push(row)
    }
    return structure(matrix-result(rows))
  }

  if operator != "*" {
    return calculation-failure("structural values support only `+`, `-`, `*`, and `/`")
  }

  if not left-structure and right-structure {
    if right-vector {
      let components = ()
      for component in right.components {
        let result = combine(left, "*", component)
        if (type(result) == dictionary and "error" in result) { return result }
        components.push(result)
      }
      return structure(vector-result(components))
    }
    let rows = ()
    for source-row in right.rows {
      let row = ()
      for cell in source-row {
        let result = combine(left, "*", cell)
        if (type(result) == dictionary and "error" in result) { return result }
        row.push(result)
      }
      rows.push(row)
    }
    return structure(matrix-result(rows))
  }

  if left-structure and not right-structure {
    if left-vector {
      let components = ()
      for component in left.components {
        let result = combine(component, "*", right)
        if (type(result) == dictionary and "error" in result) { return result }
        components.push(result)
      }
      return structure(vector-result(components))
    }
    let rows = ()
    for source-row in left.rows {
      let row = ()
      for cell in source-row {
        let result = combine(cell, "*", right)
        if (type(result) == dictionary and "error" in result) { return result }
        row.push(result)
      }
      rows.push(row)
    }
    return structure(matrix-result(rows))
  }

  if left-vector and right-vector {
    return calculation-failure("vector multiplication with `*` is ambiguous; use `bullet` for the dot product or `times` for the cross product")
  }

  if left-matrix and right-vector {
    if left.shape.last() != right.components.len() {
      return calculation-failure("matrix columns must match vector components")
    }
    let components = ()
    for row in left.rows {
      let result = sum-of-products(row, right.components)
      if (type(result) == dictionary and "error" in result) { return result }
      components.push(result)
    }
    return structure(vector-result(components))
  }

  if left-vector and right-matrix {
    if left.components.len() != right.shape.first() {
      return calculation-failure("vector components must match matrix rows")
    }
    let components = ()
    for column in range(right.shape.last()) {
      let result = sum-of-products(left.components, right.rows.map(row => row.at(column)))
      if (type(result) == dictionary and "error" in result) { return result }
      components.push(result)
    }
    return structure(vector-result(components))
  }

  if left.shape.last() != right.shape.first() {
    return calculation-failure("left matrix columns must match right matrix rows")
  }
  let rows = ()
  for left-row in left.rows {
    let row = ()
    for column in range(right.shape.last()) {
      let result = sum-of-products(left-row, right.rows.map(source-row => source-row.at(column)))
      if (type(result) == dictionary and "error" in result) { return result }
      row.push(result)
    }
    rows.push(row)
  }
  structure(matrix-result(rows))
}

let top-level-structure-operator(tokens) = {
  let depth = 0
  let best-precedence = 99
  let best-index = none
  for (index, token) in tokens.enumerate() {
    if token == "(" { depth += 1 }
    if token == ")" { depth -= 1 }
    let unary = index == 0 or tokens.at(index - 1) in ("(", ",", ";", "+", "-", "*", "×", "/", "^", dot-product-token)
    if depth == 0 and token in ("+", "-", "*", "×", "/", "^", dot-product-token) and not unary {
      let precedence = if token in ("+", "-") { 1 } else if token == "^" { 3 } else { 2 }
      // Powers are right-associative, so the first top-level `^` splits.
      if precedence < best-precedence or (precedence <= best-precedence and token != "^") {
        best-precedence = precedence
        best-index = index
      }
    }
  }
  best-index
}

let evaluate-structure(calculate-fn, tokens, digits, scope, aliases, unloaded, strict-units: false, unit: none, size: none, final: true, implicit: false) = {
  // A user-supplied scope can contain an entry named "*". When it does,
  // check inserted multiplication tokens for structures too.
  if implicit and "*" in scope {
    tokens = add-implicit-multiplication(tokens)
    implicit = false
  }
  let has-structure = dot-product-token in tokens
  if not has-structure {
    for token in tokens {
      if token in ("vec", "mat", "matrix") { has-structure = true; break }
      let item = scope.at(token, default: none)
      if type(item) == dictionary and (item.at("vector", default: false) or item.at("matrix", default: false)) {
        has-structure = true
        break
      }
    }
  }
  if not has-structure { return none }
  if implicit { tokens = add-implicit-multiplication(tokens) }
  tokens = unwrap-tokens(tokens)
  let scalar-scope = numeric-scope(scope)
  let components = vector-components(tokens)
  if components != none {
    if components.len() == 0 or components.any(component => component.len() == 0) {
      return calculation-failure("a vector must contain at least one component")
    }
    let results = ()
    for component in components {
      let result = calculate-fn(
        component.join(" "),
        digits: digits,
        scope: scalar-scope,
        block: false,
        unloaded: unloaded,
        aliases: aliases,
        strict-units: strict-units,
        soft: true,
      )
      if (type(result) == dictionary and "error" in result) { return result }
      if result.at("alternatives", default: false) {
        return calculation-failure("paired plus/minus results are not supported inside a vector")
      }
      results.push(result)
    }
    return vector-result(results, source: tokens.join(" "))
  }

  let rows = matrix-rows(tokens)
  if rows != none {
    if rows.len() == 0 or rows.any(row => row.len() == 0) {
      return calculation-failure("a matrix must contain at least one cell")
    }
    if rows.any(row => row.any(cell => cell.len() == 0)) {
      return calculation-failure("matrix cells must not be empty")
    }
    let columns = rows.first().len()
    if rows.any(row => row.len() != columns) {
      return calculation-failure("all matrix rows must have the same number of cells")
    }
    let result-rows = ()
    for source-row in rows {
      let result-row = ()
      for cell in source-row {
        let result = calculate-fn(
          cell.join(" "),
          digits: digits,
          scope: scalar-scope,
          block: false,
          unloaded: unloaded,
          aliases: aliases,
          strict-units: strict-units,
          soft: true,
        )
        if (type(result) == dictionary and "error" in result) { return result }
        if result.at("alternatives", default: false) {
          return calculation-failure("paired plus/minus results are not supported inside a matrix")
        }
        result-row.push(result)
      }
      result-rows.push(result-row)
    }
    return matrix-result(result-rows, source: tokens.join(" "))
  }

  if tokens.len() == 1 {
    let stored = scope.at(tokens.first(), default: none)
    if (type(stored) == dictionary and (stored.at("vector", default: false) or stored.at("matrix", default: false))) { return stored }
  }

  let operator-index = top-level-structure-operator(tokens)
  if operator-index != none {
    let left-tokens = tokens.slice(0, operator-index)
    let right-tokens = tokens.slice(operator-index + 1)
    let left = evaluate-structure(calculate-fn, left-tokens, digits, scope, aliases, unloaded, strict-units: strict-units, final: false)
    if (type(left) == dictionary and "error" in left) { return left }
    let right = evaluate-structure(calculate-fn, right-tokens, digits, scope, aliases, unloaded, strict-units: strict-units, final: false)
    if (type(right) == dictionary and "error" in right) { return right }
    if left == none and right == none { return none }
    if left == none {
      left = intermediate-calculation(
        calculate-fn, left-tokens.join(" "), digits: digits, scope: scalar-scope, block: false,
        unloaded: unloaded, aliases: aliases, strict-units: strict-units, soft: true,
      )
      if (type(left) == dictionary and "error" in left) { return left }
    }
    if right == none {
      right = intermediate-calculation(
        calculate-fn, right-tokens.join(" "), digits: digits, scope: scalar-scope, block: false,
        unloaded: unloaded, aliases: aliases, strict-units: strict-units, soft: true,
      )
      if (type(right) == dictionary and "error" in right) { return right }
    }
    // A bare whole number that scales a vector or matrix, as in `v * 2`, is an
    // exact constant just like the `2` in the scalar product `2 * x`.
    if tokens.at(operator-index) in multiplication-operators {
      let constant(side-tokens) = {
        let inner = side-tokens
        while inner.len() >= 2 {
          if inner.len() >= 3 and inner.first() == "(" and inner.last() == ")" {
            inner = inner.slice(1, -1)
          } else if inner.first() in ("+", "-") {
            inner = inner.slice(1)
          } else {
            break
          }
        }
        inner.len() == 1 and whole-number-pattern in inner.first()
      }
      if type(left) == dictionary and "exact" in left and constant(left-tokens) { left.insert("exact-constant", true) }
      if type(right) == dictionary and "exact" in right and constant(right-tokens) { right.insert("exact-constant", true) }
    }
    return structure-operation(
      calculate-fn, left, tokens.at(operator-index), right, digits, aliases, unit: unit, size: size, final: final,
    )
  }

  // Evaluate vector-derived scalar arguments before applying scalar functions.
  if tokens.len() >= 4 and tokens.first() in math-functions and tokens.first() not in ("atan2", "root", "log") and tokens.at(1) == "(" and tokens.last() == ")" {
    let argument-tokens = unwrap-tokens(tokens.slice(1))
    if argument-tokens != tokens.slice(1) {
      let argument = evaluate-structure(calculate-fn, argument-tokens, digits, scope, aliases, unloaded, strict-units: strict-units, final: false)
      if (type(argument) == dictionary and "error" in argument) { return argument }
      if (type(argument) == dictionary and argument.at("matrix", default: false)) {
        return calculation-failure(tokens.first() + " requires a scalar" + if tokens.first() == "abs" { " or vector, not a matrix" } else { ", not a matrix" })
      }
      if (type(argument) == dictionary and argument.at("vector", default: false)) and tokens.first() == "abs" {
        let component-scope = (:)
        let terms = ()
        for (index, component) in argument.components.enumerate() {
          let name = "mathoncenorm" + str(index)
          component-scope.insert(name, component)
          terms.push(name + "^2")
        }
        let source = "sqrt(" + terms.join(" + ") + ")"
        return if final {
          calculate-fn(
            source, digits: digits, scope: component-scope, unit: unit, size: size,
            block: false, aliases: aliases, strict-units: strict-units, soft: true,
          )
        } else {
          intermediate-calculation(
            calculate-fn, source, digits: digits, scope: component-scope,
            block: false, aliases: aliases, strict-units: strict-units, soft: true,
          )
        }
      }
      if argument != none and not (type(argument) == dictionary and (argument.at("vector", default: false) or argument.at("matrix", default: false))) {
        let source = tokens.first() + "(mathonceargument)"
        return if final {
          calculate-fn(
            source, digits: digits, scope: (mathonceargument: argument), unit: unit, size: size,
            block: false, aliases: aliases, strict-units: strict-units, soft: true,
          )
        } else {
          intermediate-calculation(
            calculate-fn, source, digits: digits, scope: (mathonceargument: argument),
            block: false, aliases: aliases, strict-units: strict-units, soft: true,
          )
        }
      }
    }
  }

  if tokens.len() > 1 and tokens.first() == "-" {
    let inner = evaluate-structure(calculate-fn, tokens.slice(1), digits, scope, aliases, unloaded, strict-units: strict-units, final: false)
    if (type(inner) == dictionary and "error" in inner) { return inner }
    if inner != none {
      let minus-one = calculate-fn("-1", digits: digits, block: false, soft: true)
      return structure-operation(calculate-fn, minus-one, "*", inner, digits, aliases, unit: unit, size: size, final: final)
    }
  }

  if dot-product-token in tokens {
    return calculation-failure(dot-product-message)
  }
  if tokens.any(token => is-structure-result(scope.at(token, default: none))) {
    return calculation-failure("vectors and matrices support only `+`, `-`, `*`, `bullet`, `times`, and scalar division")
  }
  none
}

let paired-sign-branches(tokens) = (
  tokens.map(token => if token == "±" { "+" } else if token == "∓" { "-" } else { token }),
  tokens.map(token => if token == "±" { "-" } else if token == "∓" { "+" } else { token }),
)

let calculate-expanded(calculate-fn, tokens, digits, scope, unit, size, block, unloaded, aliases, strict-units: false, render: true) = {
  let result = evaluate-structure(
    calculate-fn,
    tokens,
    digits,
    scope,
    aliases,
    unloaded,
    strict-units: strict-units,
    unit: unit,
    size: size,
    implicit: true,
  )
  if result == none {
    return calculate-fn(
      tokens.join(" "),
      digits: digits,
      scope: numeric-scope(scope),
      unit: unit,
      size: size,
      block: block,
      unloaded: unloaded,
      aliases: aliases,
      strict-units: strict-units,
      soft: true,
      render: render,
      prepared-tokens: tokens,
    )
  }
  if (type(result) == dictionary and "error" in result) { return result }
  if ((type(result) == dictionary and (result.at("vector", default: false) or result.at("matrix", default: false))) and (unit != none or size != none)
    and not result.at("unit-applied", default: false)) {
    return calculation-failure("unit and size are not supported for a whole vector or matrix result")
  }
  if type(result) == dictionary and "unit-applied" in result { let _ = result.remove("unit-applied") }
  result
}

let equivalent-tokens(left, right) = {
  left = comparable-unit-tokens(left)
  right = comparable-unit-tokens(right)
  if left.len() != right.len() { return false }
  for (left-token, right-token) in left.zip(right) {
    if (number-pattern in left-token) and (number-pattern in right-token) {
      if float(left-token) != float(right-token) { return false }
    } else if (left-token.starts-with("\"") and left-token.ends-with("\"") and left-token.len() >= 2) and quoted-unit-name(left-token) == right-token {
      continue
    } else if (right-token.starts-with("\"") and right-token.ends-with("\"") and right-token.len() >= 2) and quoted-unit-name(right-token) == left-token {
      continue
    } else if left-token != right-token {
      return false
    }
  }
  true
}

// Keep very large and very small displayed values readable. Calculations still
// retain and use their complete exact value; this only changes equation output.
let display-number-tokens(value, exact: none, digits: none, significant-digits: none) = {
  if exact == none { exact = value }
  let magnitude = calc.abs(float(exact))
  if significant-digits != none {
    // Use the rounded magnitude, including carry into the next decade.
    let rounded-magnitude = calc.abs(float(value))
    digits = if rounded-magnitude == 0 { significant-digits - 1 } else {
      significant-digits - 1 - int(calc.floor(calc.log(rounded-magnitude, base: 10)))
    }
  }
  if magnitude == 0 or (magnitude >= 0.0001 and magnitude < 1000000000) {
    let rendered = str(value)
    // Ignore a few floating-point ulps from unit conversion or arithmetic.
    // Only real rounding should force trailing decimal places.
    let rounding-noise = calc.max(calc.abs(value), magnitude) * 8.881784197001252e-16
    if digits != none and digits > 0 and (significant-digits != none or calc.abs(value - exact) > rounding-noise) {
      let decimal-places = if "." in rendered { rendered.split(".").last().len() } else { 0 }
      if decimal-places < digits {
        rendered += if decimal-places == 0 { "." } else { "" }
        rendered += range(digits - decimal-places).map(_ => "0").join()
      }
    }
    return (rendered,)
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

  // Scientific output applies display precision to the coefficient. Bare
  // values without a precision setting retain the ten-decimal noise guard.
  let coefficient-digits = if significant-digits != none { significant-digits - 1 } else if digits == none { 10 } else { digits }
  if significant-digits != none { digits = coefficient-digits }
  let coefficient = calc.round(normalized, digits: coefficient-digits)
  if calc.abs(coefficient) >= 10 {
    coefficient /= 10
    exponent += 1
  }
  // Keep the requested coefficient precision visible even for exact values.
  let rendered = str(coefficient)
  if digits != none and digits > 0 {
    let decimal-places = if "." in rendered { rendered.split(".").last().len() } else { 0 }
    if decimal-places < digits {
      rendered += if decimal-places == 0 { "." } else { "" }
      rendered += range(digits - decimal-places).map(_ => "0").join()
    }
  }
  let exponent-tokens = if exponent < 0 {
    ("-", str(-exponent))
  } else {
    (str(exponent),)
  }
  (rendered, "*", "10", "^", "(") + exponent-tokens + (")",)
}

let is-scientific-size-unit(unit) = unit != none and "10^(" in unit
let result-unit-source(result) = result.at("unit-source", default: result.unit)

let result-tokens(result) = {
  let tokens = display-number-tokens(
    result.value,
    exact: result.at("exact", default: result.value),
    digits: result.at("digits", default: none),
    significant-digits: result.at("significant-digits", default: none),
  )
  let unit = result-unit-source(result)
  if unit != none {
    if is-scientific-size-unit(unit) { tokens.push("*") }
    tokens += tokenize(unit)
  }
  tokens
}

// Retokenize displayed components so negative values use the same separate
// minus and number tokens as the written expression.
let structure-equivalent(tokens, result) = {
  if (type(result) == dictionary and result.at("vector", default: false)) {
    let components = vector-components(tokens)
    return (components != none
      and components.len() == result.components.len()
      and components.zip(result.components).all(((tokens, component)) =>
        equivalent-tokens(tokens, tokenize(result-tokens(component).join(" ")))))
  }
  if (type(result) == dictionary and result.at("matrix", default: false)) {
    let rows = matrix-rows(tokens)
    return (rows != none
      and rows.len() == result.rows.len()
      and rows.zip(result.rows).all(((tokens-row, result-row)) =>
        tokens-row.len() == result-row.len()
        and tokens-row.zip(result-row).all(((tokens, cell)) =>
          equivalent-tokens(tokens, tokenize(result-tokens(cell).join(" "))))))
  }
  false
}

let render-result(result, aliases: (:), show-unit: true) = {
  if result.at("alternatives", default: false) {
    return result.branches.map(branch => render-result(branch, aliases: aliases, show-unit: show-unit)).join(
      h(0.25em) + render-tokens((math-symbol-token("or"),)) + h(0.25em),
    )
  }
  if result.at("vector", default: false) {
    let children = result.components.map(component => render-result(component, aliases: aliases, show-unit: show-unit))
    return math.vec(..children)
  }
  if result.at("matrix", default: false) {
    let rows = result.rows.map(row => row.map(cell => render-result(cell, aliases: aliases, show-unit: show-unit)))
    return math.mat(..rows)
  }
  let unit = result-unit-source(result)
  if show-unit and is-scientific-size-unit(unit) {
    render-tokens(
      display-number-tokens(
        result.value,
        exact: result.at("exact", default: result.value),
        digits: result.at("digits", default: none),
        significant-digits: result.at("significant-digits", default: none),
      ) + ("*",) + tokenize(unit),
      aliases: aliases,
    )
  } else {
    let body = render-tokens(display-number-tokens(
      result.value,
      exact: result.at("exact", default: result.value),
      digits: result.at("digits", default: none),
      significant-digits: result.at("significant-digits", default: none),
    ))
    if show-unit and unit != none {
      body += unit-gap(tokenize(unit), aliases: aliases) + render-tokens(tokenize(unit), aliases: aliases)
    }
    body
  }
}

let built-in-constants = (e: calc.e, pi: calc.pi)
let is-built-in-constant(name) = name in built-in-constants

// A built-in constant still holding its standard value (not an unloaded and
// reassigned name) stays a symbol unless constants are substituted.
let kept-constant(token, scope, substitute-constants) = (
  not substitute-constants
  and token in built-in-constants
  and type(scope.at(token, default: none)) != dictionary
)

let expand-variables(tokens, scope, substitute-constants: false) = {
  if scope.len() == 0 { return (tokens, false) }
  let expanded = ()
  let changed = false
  for (index, token) in tokens.enumerate() {
    if token not in scope or name-pattern not in token {
      expanded.push(token)
      continue
    }
    let item = scope.at(token)
    if (not kept-constant(token, scope, substitute-constants)
      and not (type(item) == dictionary and (
        (item.at("unloaded", default: false) and "si-value" not in item)
        or item.at("unit-alias", default: false)
        or item.at("symbolic", default: false)
        or item.at("vector", default: false)
        or item.at("matrix", default: false)
        or item.at("function", default: false)
      ))) {
      let previous = tokens.at(index - 1, default: none)
      let implicit-product = index > 0 and can-end(previous)
      if implicit-product {
        expanded.push("*")
      }
      let substituted = if type(item) == dictionary and "value" in item {
        let value-tokens = display-number-tokens(
          item.value,
          exact: item.at("exact", default: item.value),
          digits: item.at("digits", default: none),
          significant-digits: item.at("significant-digits", default: none),
        )
        let item-unit = result-unit-source(item)
        if item-unit != none { value-tokens += tokenize(item-unit) }
        value-tokens
      } else {
        (str(item),)
      }
      // Group a value where the written equation would otherwise read
      // differently: `x^2` with x = -3 is (-3)^2, not -3^2, and a value with
      // a unit or a power of ten is one base, exponent, or denominator.
      // Typst writes negative numbers with the Unicode minus sign.
      let negative = substituted.first().starts-with("-") or substituted.first().starts-with("\u{2212}")
      let compound = substituted.len() > 1
      let follows-operator = index > 0 and previous in ("+", "-", "*", "×", "/", "^")
      if ((negative or compound)
        and (tokens.at(index + 1, default: none) == "^"
          or (compound and tokens.at(index + 1, default: none) == "/")
          or (index > 0 and previous in ("/", "^"))
          or (negative and (follows-operator or implicit-product)))) {
        substituted = ("(",) + substituted + (")",)
      }
      expanded += substituted
      if (index + 1 < tokens.len()
        and can-start(tokens.at(index + 1))
        and not (is-name(tokens.at(index + 1))
          and tokens.at(index + 1) in scope
          and not kept-constant(tokens.at(index + 1), scope, substitute-constants))) {
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
let is-symbolic-result(item) = type(item) == dictionary and item.at("symbolic", default: false)
let is-symbolic-expression(item) = is-symbolic-result(item) and item.at("symbolic-kind", default: none) == "expression"
let is-renamed-unit(item) = is-unloaded(item) and type(item) == dictionary and item.at("renamed-unit", default: false)
let initial-state-marker-name = "math-once--initial-state"
let is-initial-state-marker(item) = type(item) == dictionary and item.at("initial-state-marker", default: false)
let is-stored-variable(item) = (
  not is-unloaded-marker(item)
  and not (type(item) == dictionary and item.at("unit-alias", default: false))
  and not (type(item) == dictionary and item.at("function", default: false))
  and not is-initial-state-marker(item)
)

// Recognize the deliberately small, task-oriented CAS surface accepted by the
// builder. CAS expressions are dimensionless; unit-aware arithmetic continues
// to use the native evaluator below.
let symbolic-call(tokens) = {
  if (tokens.len() < 3
    or tokens.first() not in cas-functions
    or tokens.at(1) != "("
    or tokens.last() != ")") { return none }

  let depth = 0
  for (index, token) in tokens.slice(1).enumerate() {
    if token == "(" { depth += 1 }
    if token == ")" { depth -= 1 }
    if depth < 0 or (depth == 0 and index < tokens.len() - 2) { return none }
  }
  if depth != 0 { return none }

  (
    operation: tokens.first(),
    arguments: split-top-level(tokens.slice(2, tokens.len() - 1)),
    tokens: tokens,
  )
}

let symbolic-token-name(token) = if (token.starts-with("\"") and token.ends-with("\"") and token.len() >= 2) {
  quoted-unit-name(token)
} else {
  token
}

let symbolic-source(tokens) = {
  let normalized = tokens.map(symbolic-token-name)
  let result = ()
  for (index, token) in normalized.enumerate() {
    if (index > 0
      and can-end(normalized.at(index - 1))
      and can-start(token)
      and not (is-name(normalized.at(index - 1)) and token == "(")) {
      result.push("*")
    }
    result.push(token)
  }
  result.join(" ")
}

let symbolic-name-argument(tokens, operation) = {
  if tokens.len() != 1 or not is-name(symbolic-token-name(tokens.first())) {
    return calculation-failure(operation + ": the variable must be a single name")
  }
  symbolic-token-name(tokens.first())
}

let symbolic-expression(tokens, scope) = {
  if tokens.len() == 0 {
    return calculation-failure("CAS arguments must not be empty")
  }

  let names = tokens.map(symbolic-token-name)
  let expression = cas.parse(symbolic-source(tokens))
  for (name, item) in scope {
    if name not in names { continue }

    let replacement = none
    if is-symbolic-expression(item) {
      replacement = item.expression
    } else if is-symbolic-result(item) {
      return calculation-failure(
        "`" + name + "` is a set of solutions and cannot be used as one expression",
      )
    } else if type(item) in (int, float) {
      replacement = item
    } else if type(item) == decimal {
      replacement = float(item)
    } else if type(item) == dictionary and "exact" in item {
      if (item.at("dimensions", default: zero-dim) != zero-dim
        or item.at("custom-units", default: (:)).len() > 0
        or item.at("unit", default: none) != none) {
        return calculation-failure(
          "`" + name + "` has a unit; CAS expressions must be dimensionless",
        )
      }
      replacement = float(item.exact)
    }

    if replacement != none {
      let substituted = cas.substitute(expression, name, replacement)
      if not cas.ok(substituted) {
        return calculation-failure("CAS substitution failed: " + cas.error-message(substituted))
      }
      expression = cas.expr-of(substituted)
    }
  }
  expression
}

let symbolic-result(call, scope) = {
  let operation = call.operation
  let arguments = call.arguments
  let expected = if operation in ("simplify",) {
    "one expression"
  } else if operation in ("diff", "integrate") {
    "an expression and a variable"
  } else if operation == "solve" {
    "an expression and a variable, or a left side, right side, and variable"
  } else if operation == "factor" {
    "an expression and optionally a variable"
  } else if operation == "limit" {
    "an expression, a variable, and a target"
  } else {
    "an expression, a variable, a center, and a non-negative integer order"
  }
  let valid-arity = if operation == "simplify" { arguments.len() == 1 }
    else if operation in ("diff", "integrate") { arguments.len() == 2 }
    else if operation == "solve" { arguments.len() in (2, 3) }
    else if operation == "factor" { arguments.len() in (1, 2) }
    else if operation == "limit" { arguments.len() == 3 }
    else { arguments.len() == 4 }
  if not valid-arity or arguments.any(argument => argument.len() == 0) {
    return calculation-failure(operation + " expects " + expected)
  }

  let input = symbolic-expression(arguments.first(), scope)
  if (type(input) == dictionary and "error" in input) { return input }

  let result = if operation == "simplify" {
    cas.simplify(input)
  } else if operation in ("diff", "integrate") {
    let variable = symbolic-name-argument(arguments.at(1), operation)
    if (type(variable) == dictionary and "error" in variable) { return variable }
    if operation == "diff" { cas.diff(input, variable) } else { cas.integrate(input, variable) }
  } else if operation == "solve" {
    let variable-tokens = arguments.last()
    let variable = symbolic-name-argument(variable-tokens, operation)
    if (type(variable) == dictionary and "error" in variable) { return variable }
    let right = if arguments.len() == 3 {
      symbolic-expression(arguments.at(1), scope)
    } else {
      0
    }
    if (type(right) == dictionary and "error" in right) { return right }
    cas.solve(input, rhs: right, var: variable)
  } else if operation == "factor" {
    let variable = if arguments.len() == 2 {
      symbolic-name-argument(arguments.at(1), operation)
    } else {
      "x"
    }
    if (type(variable) == dictionary and "error" in variable) { return variable }
    cas.factor(input, variable)
  } else if operation == "limit" {
    let variable = symbolic-name-argument(arguments.at(1), operation)
    if (type(variable) == dictionary and "error" in variable) { return variable }
    let target = symbolic-expression(arguments.at(2), scope)
    if (type(target) == dictionary and "error" in target) { return target }
    cas.limit(input, variable, target)
  } else {
    let variable = symbolic-name-argument(arguments.at(1), operation)
    if (type(variable) == dictionary and "error" in variable) { return variable }
    let center = symbolic-expression(arguments.at(2), scope)
    if (type(center) == dictionary and "error" in center) { return center }
    let order-source = symbolic-source(arguments.at(3))
    if integer-pattern not in order-source {
      return calculation-failure("taylor: the order must be a non-negative integer")
    }
    cas.taylor(input, variable, center, int(order-source))
  }

  if not cas.ok(result) {
    return calculation-failure("CAS " + operation + " failed: " + cas.error-message(result))
  }
  let roots = cas.roots-of(result)
  let expression = cas.expr-of(result)
  if operation != "solve" and expression == none {
    return calculation-failure("CAS " + operation + " returned no expression")
  }
  (
    symbolic: true,
    symbolic-kind: if operation == "solve" { "roots" } else { "expression" },
    expression: expression,
    roots: roots,
    operation: operation,
    source: symbolic-source(call.tokens),
    restrictions: result.at("restrictions", default: ()),
    warnings: result.at("warnings", default: ()),
  )
}

let render-symbolic-result(result) = {
  if result.symbolic-kind == "expression" {
    return cas.display(result.expression)
  }
  if result.roots.len() == 0 { return math.emptyset }
  let body = []
  for (index, root) in result.roots.enumerate() {
    if index > 0 { body += math.comma + h(0.25em) }
    body += cas.display(root)
  }
  body
}

let state-initial-values(scope) = {
  let marker = scope.at(initial-state-marker-name, default: none)
  if marker != none and is-initial-state-marker(marker) { marker.values } else { (:) }
}

let builder-initial-state(initial) = {
  let result = (:)
  for (name, value) in built-in-constants { result.insert(name, value) }
  for (name, value) in initial { result.insert(name, value) }
  result.insert(initial-state-marker-name, (
    initial-state-marker: true,
    values: result,
  ))
  result
}

// One persistent state lets stable writers be emitted before layout begins.
// A full reset writes a constant initial value, so later equations can reuse
// their calculations even when an earlier section changes.
// Content caches its hash, unlike a nested dictionary passed repeatedly to
// state callbacks. Only library-created stored entries use this representation.
let state-entry(item) = {
  if type(item) == content and item.func() == metadata {
    let payload = item.value
    if type(payload) == dictionary and payload.at("math-once--packed-entry", default: false) == true {
      return payload.entry
    }
  }
  item
}
let packed-entry(item) = if type(item) == dictionary and "display" in item and "variable" in item {
  metadata((math-once--packed-entry: true, entry: item))
} else { item }
let unpack-state(scope) = {
  let result = (:)
  for (name, item) in scope { result.insert(name, state-entry(item)) }
  result
}
let pack-state(scope) = {
  let result = (:)
  for (name, item) in scope { result.insert(name, packed-entry(item)) }
  result
}
let builder-state(key, initial: (:)) = state("math-once-state:" + key, builder-initial-state(initial))
let update-state(variables, update) = variables.update(old => pack-state(update(unpack-state(old))))

// Clear the write status only when an assignment fails. A successful write
// can reuse the current marker when the previous assignment also succeeded.
let failed-store(old, marker) = {
  marker.insert("last-write", false)
  old.insert(initial-state-marker-name, marker)
  old
}

let unit-aliases(scope) = {
  let aliases = (:)
  for (name, item) in scope {
    if (type(item) == dictionary and item.at("unit-alias", default: false)) { aliases.insert(name, item.original) }
  }
  aliases
}

// Memoize only the unit spelling, never the stored result or builder state.
let referenced-unit-tokens(unit) = token-matches(unit).map(found => found.text)

// Follow only names reachable from this equation. Function bodies are resolved
// against the current state at each call, not captured when defined. Visiting
// each name once also bounds cycles; expand-function-calls reports those later.
let scope-names(tokens) = tokens.filter(token => name-pattern in token or (token.starts-with("\"") and token.ends-with("\"")))

// Strip scalar layout data before following dependencies. Structures retain
// their display field because direct copies preserve the public key order.
// This helper is keyed by one entry so repeated references share the work.
let scope-entry(item) = {
  let item = state-entry(item)
  if type(item) != dictionary { return (item, ()) }
  if ("display" in item and not item.at("vector", default: false)
    and not item.at("matrix", default: false)) {
    let _ = item.remove("display")
  }
  let pending = ()
  if item.at("function", default: false) {
    pending = scope-names(item.body-tokens)
  } else if item.at("unit-alias", default: false) {
    pending = (item.original,)
  } else {
    let values = (item,)
    while values.len() > 0 {
      let value = values.pop()
      if type(value) == dictionary and value.at("vector", default: false) {
        values += value.components
      } else if type(value) == dictionary and value.at("matrix", default: false) {
        for row in value.rows { values += row }
      } else if "unit" in value {
        let unit = value.at("unit-source", default: value.unit)
        if type(unit) == str { pending += scope-names(referenced-unit-tokens(unit)) }
      }
    }
  }
  (item, pending)
}

let referenced-scope(tokens, scope) = {
  let selected = (:)
  let seen = (:)
  // Validate user-supplied initial values first. Built-in constants are
  // already valid and only need to be included when actually referenced.
  let marker = scope.at(initial-state-marker-name, default: none)
  let initial = if type(marker) == dictionary and marker.at("initial-state-marker", default: false) { marker.values } else { (:) }
  let pending = initial.keys().filter(name => name not in built-in-constants) + scope-names(tokens)
  let index = 0
  while index < pending.len() {
    let token = pending.at(index)
    index += 1
    let quoted = token.starts-with("\"") and token.ends-with("\"") and token.len() >= 2
    let name = if quoted { token.slice(1, token.len() - 1) } else { token }
    if name in seen { continue }
    seen.insert(name, true)
    if quoted and name == "Omega" { pending.push("Ω") }
    if name not in scope { continue }
    let item = scope.at(name)
    let (item, dependencies) = scope-entry(item)
    selected.insert(name, item)
    pending += dependencies
  }
  selected
}

let missing-variables(tokens, scope, unloaded, aliases: (:)) = {
  let missing = ()
  for token in tokens {
    if ((name-pattern in token)
      and token not in source-functions
      and token != "to"
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
    if type(item) == dictionary and (
      (item.at("unloaded", default: false) == true and "si-value" not in item)
      or item.at("unit-alias", default: false)
      or item.at("initial-state-marker", default: false)
      or item.at("function", default: false)
      or item.at("symbolic", default: false)) { continue }
    if resolve-unit(name) != none and not (type(item) == dictionary and item.at("unloaded", default: false) == true) {
      panic(
        "math-once calculate: `" + name
        + "` is a unit name and cannot be used as a variable",
      )
    }
    if type(item) == dictionary and "si-value" in item and "dimensions" in item {
      normalized.insert(name, quantity(
        item.si-value,
        dims: item.dimensions,
        preferred: item.at("unit-source", default: item.unit),
        affine-kind: item.at("affine-kind", default: none),
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
    let left-kind = left.affine-kind
    let right-kind = right.affine-kind
    // A plain Kelvin/Rankine quantity has no offset marker. In subtraction,
    // treat an unmarked temperature as an absolute value; stored differences
    // retain their explicit classification.
    if op == "-" and left.dims == dim(temperature: 1) and left.opaque.len() == 0 {
      if left-kind == none { left-kind = "absolute" }
      if right-kind == none { right-kind = "absolute" }
    }
    let result-kind = none
    if left-kind == "absolute" and right-kind == "absolute" {
      if op == "+" {
        return calculation-fail("absolute affine temperatures cannot be added", soft: soft)
      }
      result-kind = "difference"
    } else if left-kind == "absolute" and right-kind == "difference" {
      result-kind = "absolute"
    } else if left-kind == "difference" and right-kind == "absolute" {
      if op == "-" {
        return calculation-fail("a temperature difference cannot subtract an absolute temperature", soft: soft)
      }
      result-kind = "absolute"
    } else if left-kind == "difference" or right-kind == "difference" {
      result-kind = "difference"
    } else if left-kind == "absolute" or right-kind == "absolute" {
      result-kind = "absolute"
    }
    return quantity(
      if op == "+" { left.si-value + right.si-value } else { left.si-value - right.si-value },
      dims: left.dims,
      opaque: left.opaque,
      preferred: if left.preferred != none { left.preferred } else { right.preferred },
      affine-kind: result-kind,
    )
  }
  if op == "*" {
    if right.affine != none and is-dimensionless(left) and left.preferred == none {
      return quantity(
        left.si-value * right.affine.scale + right.affine.offset,
        dims: right.dims,
        preferred: right.preferred,
        affine-kind: "absolute",
      )
    }
    if left.affine != none and is-dimensionless(right) and right.preferred == none {
      return quantity(
        right.si-value * left.affine.scale + left.affine.offset,
        dims: left.dims,
        preferred: left.preferred,
        affine-kind: "absolute",
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
      } else if is-dimensionless(left) and left.preferred == none {
        right.preferred
      } else if is-dimensionless(right) and right.preferred == none {
        left.preferred
      } else {
        none
      },
      affine-kind: if left.affine-kind != none and is-dimensionless(right) {
        left.affine-kind
      } else if right.affine-kind != none and is-dimensionless(left) {
        right.affine-kind
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
      affine-kind: if is-dimensionless(right) and right.preferred == none { left.affine-kind } else { none },
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
    if left.si-value < 0 and exponent != calc.round(exponent) {
      return calculation-fail("a negative base requires an integer exponent; use root for real odd roots", soft: soft)
    }
    if left.si-value == 0 and exponent < 0 {
      return calculation-fail("cannot raise zero to a negative power", soft: soft)
    }
    if left.si-value == 0 and exponent == 0 {
      return calculation-fail("zero to the power of zero is undefined", soft: soft)
    }
    return quantity(
      calc.pow(left.si-value, exponent),
      dims: dims-scale(left.dims, exponent),
      opaque: opaque-scale(left.opaque, exponent),
    )
  }
  calculation-fail("unsupported operator `" + op + "`", soft: soft)
}

let special-angle-sines = (
  0.0,
  (calc.sqrt(6) - calc.sqrt(2)) / 4,
  0.5,
  calc.sqrt(2) / 2,
  calc.sqrt(3) / 2,
  (calc.sqrt(6) + calc.sqrt(2)) / 4,
  1.0,
  (calc.sqrt(6) + calc.sqrt(2)) / 4,
  calc.sqrt(3) / 2,
  calc.sqrt(2) / 2,
  0.5,
  (calc.sqrt(6) - calc.sqrt(2)) / 4,
  0.0,
  -(calc.sqrt(6) - calc.sqrt(2)) / 4,
  -0.5,
  -calc.sqrt(2) / 2,
  -calc.sqrt(3) / 2,
  -(calc.sqrt(6) + calc.sqrt(2)) / 4,
  -1.0,
  -(calc.sqrt(6) + calc.sqrt(2)) / 4,
  -calc.sqrt(3) / 2,
  -calc.sqrt(2) / 2,
  -0.5,
  -(calc.sqrt(6) - calc.sqrt(2)) / 4,
)

let special-angle-tangents = (
  0.0,
  2 - calc.sqrt(3),
  calc.sqrt(3) / 3,
  1.0,
  calc.sqrt(3),
  2 + calc.sqrt(3),
  0.0,
  -(2 + calc.sqrt(3)),
  -calc.sqrt(3),
  -1.0,
  -calc.sqrt(3) / 3,
  -(2 - calc.sqrt(3)),
  0.0,
  2 - calc.sqrt(3),
  calc.sqrt(3) / 3,
  1.0,
  calc.sqrt(3),
  2 + calc.sqrt(3),
  0.0,
  -(2 + calc.sqrt(3)),
  -calc.sqrt(3),
  -1.0,
  -calc.sqrt(3) / 3,
  -(2 - calc.sqrt(3)),
)

// Exact values for angles within 0.000000001 degrees of a multiple of 15
// degrees; the entry at index k is the value at a reduced angle of 15k
// degrees in [0, 360). Returns none for angles that are not special, so
// ordinary floating-point evaluation can take over.
let special-angle-value(name, angle, soft: false) = {
  let reduced = calc.rem(calc.rem(angle * 180 / calc.pi, 360) + 360, 360)
  let step = calc.round(reduced / 15)
  if not (calc.abs(step * 15 - reduced) <= 0.000000001) {
    return none
  }
  let index = int(calc.rem(step, 24))
  if name == "sin" {
    special-angle-sines.at(index)
  } else if name == "cos" {
    special-angle-sines.at(int(calc.rem(6 - index + 24, 24)))
  } else if name == "tan" {
    if index == 6 or index == 18 {
      calculation-fail("`tan` is undefined at odd multiples of 90 degrees", soft: soft)
    } else {
      special-angle-tangents.at(index)
    }
  }
}

let apply-logarithm(name, argument, base, soft: false) = {
  if not is-dimensionless(argument) {
    return calculation-fail("`" + name + "` requires a dimensionless number", soft: soft)
  }
  if argument.si-value <= 0 {
    return calculation-fail("`" + name + "` requires a positive number", soft: soft)
  }
  if not is-dimensionless(base) or base.si-value <= 0 or base.si-value == 1 {
    return calculation-fail("`log` requires a positive, dimensionless base other than 1", soft: soft)
  }
  quantity(calc.ln(argument.si-value) / calc.ln(base.si-value))
}

let apply-function(name, argument, soft: false) = {
  if name == "ln" {
    return apply-logarithm(name, argument, quantity(calc.e), soft: soft)
  }
  let canonical-name = if name == "arcsin" { "asin" }
    else if name == "arccos" { "acos" }
    else if name == "arctan" { "atan" }
    else { name }
  if not is-dimensionless(argument) {
    let requirement = if canonical-name in inverse-trigonometric-functions {
      "a dimensionless number"
    } else {
      "a dimensionless angle"
    }
    return calculation-fail("`" + name + "` requires " + requirement, soft: soft)
  }
  if canonical-name in ("asin", "acos") and calc.abs(argument.si-value) > 1 {
    return calculation-fail("`" + name + "` requires a value from -1 to 1", soft: soft)
  }
  if canonical-name in inverse-trigonometric-functions {
    let angle = if canonical-name == "asin" { calc.asin(argument.si-value) }
      else if canonical-name == "acos" { calc.acos(argument.si-value) }
      else { calc.atan(argument.si-value) }
    return quantity(angle.rad(), preferred: "degree")
  }
  let angle = if argument.preferred == none {
    argument.si-value * calc.pi / 180
  } else {
    argument.si-value
  }
  let special = special-angle-value(name, angle, soft: soft)
  if (type(special) == dictionary and "error" in special) {
    return special
  }
  quantity(
    if special != none { special }
    else if name == "sin" { calc.sin(angle) }
    else if name == "cos" { calc.cos(angle) }
    else if name == "tan" { calc.tan(angle) }
    else { calculation-fail("unsupported function `" + name + "`", soft: soft) },
  )
}

let apply-atan2(y, x, soft: false) = {
  if y.dims != x.dims or y.opaque != x.opaque {
    return calculation-fail("`atan2` requires compatible y and x values", soft: soft)
  }
  if y.si-value == 0 and x.si-value == 0 {
    return calculation-fail("`atan2` is undefined when y and x are both zero", soft: soft)
  }
  quantity(calc.atan2(x.si-value, y.si-value).rad(), preferred: "degree")
}

let apply-rounding(name, argument, preferred-unit: none, soft: false) = {
  let scale = if preferred-unit == none { 1.0 }
    else if preferred-unit.affine == none { preferred-unit.si-value }
    else { preferred-unit.affine.scale }
  let offset = if (preferred-unit == none or preferred-unit.affine == none
    or argument.affine-kind == "difference") { 0.0 }
    else { preferred-unit.affine.offset }
  let value = (argument.si-value - offset) / scale
  // Floats this large are already whole numbers and do not fit Typst's integers.
  let rounded = if calc.abs(value) >= 9007199254740992.0 { value }
    else if name == "floor" { calc.floor(value) }
    else if name == "ceil" { calc.ceil(value) }
    else if name == "round" { calc.round(value) }
    else { return calculation-fail("unsupported rounding function `" + name + "`", soft: soft) }
  quantity(
    rounded * scale + offset,
    dims: argument.dims,
    preferred: argument.preferred,
    affine-kind: argument.affine-kind,
    opaque: argument.opaque,
  )
}

let apply-absolute(argument) = quantity(
  calc.abs(argument.si-value),
  dims: argument.dims,
  preferred: argument.preferred,
  affine-kind: argument.affine-kind,
  opaque: argument.opaque,
)

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
  if radicand.si-value == 0 and degree < 0 {
    return calculation-fail("cannot take a negative-index root of zero", soft: soft)
  }
  let magnitude = calc.pow(calc.abs(radicand.si-value), 1 / degree)
  quantity(
    if radicand.si-value < 0 { -magnitude } else { magnitude },
    dims: dims-scale(radicand.dims, 1 / degree),
    opaque: opaque-scale(radicand.opaque, 1 / degree),
  )
}

// Reuse literal atoms without capturing an expression's variable scope.
// Anything ambiguous stays with the complete parser below.
let simple-quantity(token, aliases, unloaded) = {
  if number-pattern in token {
    let value = float(token)
    return if is-finite-number(value) { quantity(value) } else { none }
  }
  if token in math-functions or token in unloaded { return none }
  let quoted = token.len() >= 2 and token.starts-with("\"") and token.ends-with("\"")
  if not quoted and name-pattern not in token { return none }
  let name = if quoted { quoted-unit-name(token) } else { token }
  if quoted and name == "Omega" { name = "Ω" }
  let unit = resolve-unit(aliases.at(name, default: name))
  if unit == none { return none }
  let offset = unit.at("offset", default: 0.0)
  quantity(unit.scale + offset, dims: unit.dims, preferred: name,
    affine: if offset == 0.0 { none } else { (scale: unit.scale, offset: offset) })
}

let parse(tokens, scope: (:), unloaded: (), aliases: (:), custom-units: false, override-opaque: false, strict-units: false, soft: false) = {
  // `times` is the cross product only between two vectors.
  if "×" in tokens { tokens = tokens.map(token => if token == "×" { "*" } else { token }) }
  let scope = normalize-scope(scope)
  if override-opaque {
    for (name, item) in scope {
      if item.opaque.len() > 0 {
        scope.insert(name, quantity(item.si-value))
      }
    }
  }
  let precedence = ("+": 1, "-": 1, "*": 2, "/": 2, "^": 3)

  // Flat scalar expressions need no recursive parser closure. Scope
  // validation above still runs, including unused user-supplied initial values.
  if tokens.len() == 1 or (tokens.len() == 3 and tokens.at(1) in precedence) {
    let atoms = ()
    let simple = true
    for index in (if tokens.len() == 1 { (0,) } else { (0, 2) }) {
      let token = tokens.at(index)
      let atom = if (name-pattern in token and token not in math-functions and token in scope) {
        scope.at(token)
      } else if token in scope {
        // Quoted names can prefer either a unit or a variable.
        none
      } else { simple-quantity(token, aliases, unloaded) }
      if atom == none { simple = false; break }
      atoms.push(atom)
    }
    if simple {
      if atoms.len() == 1 { return atoms.first() }
      let result = apply-op(tokens.at(1), atoms.first(), atoms.last(), soft: soft)
      if type(result) == dictionary and "error" in result { return result }
      if not is-finite-number(result.si-value) { return calculation-fail(overflow-message, soft: soft) }
      return result
    }
  }

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
      if (type(first) == dictionary and "error" in first) { return (first, next) }
      if token == "log" and (next >= tokens.len() or tokens.at(next) != ",") {
        // Like qalc, a bare `log(x)` is ambiguous between base e and base 10.
        return (calculation-fail("`log(x)` without a base is ambiguous; use `ln(x)`, `log_10(x)`, or `log_b(x)`", soft: soft), next)
      }
      if token in ("root", "atan2", "log") {
        if next >= tokens.len() or tokens.at(next) != "," {
          let arguments = if token == "root" { "an index and a radicand" } else { "y and x arguments" }
          return (calculation-fail("`" + token + "` requires " + arguments, soft: soft), next)
        }
        let (second, closing) = parse-expression(tokens, next + 1)
        if (type(second) == dictionary and "error" in second) { return (second, closing) }
        if closing >= tokens.len() or tokens.at(closing) != ")" {
          return (calculation-fail("missing closing parenthesis after `" + token + "`", soft: soft), closing)
        }
        left = if token == "root" {
          apply-root(first, second, soft: soft)
        } else if token == "log" {
          apply-logarithm(token, first, second, soft: soft)
        } else {
          apply-atan2(first, second, soft: soft)
        }
        if (type(left) == dictionary and "error" in left) { return (left, closing + 1) }
        position = closing + 1
      } else {
        if next >= tokens.len() or tokens.at(next) != ")" {
          return (calculation-fail("missing closing parenthesis after `" + token + "`", soft: soft), next)
        }
        left = if token == "sqrt" {
          apply-root(quantity(2.0), first, soft: soft)
        } else if token == "abs" {
          apply-absolute(first)
        } else if token in rounding-functions {
          let preferred-unit = none
          if first.preferred != none and first.opaque.len() == 0 {
            preferred-unit = parse(
              add-implicit-multiplication(tokenize(first.preferred)),
              aliases: aliases, custom-units: true, strict-units: strict-units, soft: soft,
            )
            if (type(preferred-unit) == dictionary and "error" in preferred-unit) { return (preferred-unit, next + 1) }
          }
          apply-rounding(token, first, preferred-unit: preferred-unit, soft: soft)
        } else {
          apply-function(token, first, soft: soft)
        }
        if (type(left) == dictionary and "error" in left) { return (left, next + 1) }
        position = next + 1
      }
    } else if token == "+" or token == "-" {
      let (operand, next) = parse-expression(tokens, position + 1, minimum: 3)
      if (type(operand) == dictionary and "error" in operand) { return (operand, next) }
      left = if token == "-" {
        quantity(
          -operand.si-value,
          dims: operand.dims,
          preferred: operand.preferred,
          affine-kind: operand.affine-kind,
          opaque: operand.opaque,
        )
      } else {
        operand
      }
      position = next
    } else if token == "(" {
      let (inside, next) = parse-expression(tokens, position + 1)
      if (type(inside) == dictionary and "error" in inside) { return (inside, next) }
      if next >= tokens.len() or tokens.at(next) != ")" {
        return (calculation-fail("missing closing parenthesis", soft: soft), next)
      }
      left = inside
      position = next + 1
    } else if (number-pattern in token) {
      left = quantity(float(token))
      if not is-finite-number(left.si-value) {
        return (calculation-fail("the number `" + token + "` is too large to calculate", soft: soft), position + 1)
      }
      position += 1
    } else if (name-pattern in token) or (token.starts-with("\"") and token.ends-with("\"") and token.len() >= 2) or (token.starts-with(text-unit-prefix) and token.ends-with(text-unit-suffix) and token.len() >= 2) {
      let symbolic = (token.starts-with(text-unit-prefix) and token.ends-with(text-unit-suffix) and token.len() >= 2)
      let quoted = (token.starts-with("\"") and token.ends-with("\"") and token.len() >= 2)
      let unit-name = if symbolic { text-unit-name(token) } else if quoted { quoted-unit-name(token) } else { token }
      if quoted and unit-name == "Omega" { unit-name = "Ω" }
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
        } else if quoted and custom-units and strict-units {
          return (
            calculation-fail(
              "unknown unit `" + unit-name + "`; use text-unit for a display-only label",
              soft: soft,
            ),
            position + 1,
          )
        } else if quoted and custom-units {
          // Preserve the legacy unit: behavior: an unknown quoted output name
          // is a dimensionless label. text-unit is the unambiguous form.
          left = quantity(1.0, preferred: token)
        } else if quoted and override-opaque {
          // An explicit physical unit: overrides unknown input-unit labels.
          left = quantity(1.0)
        } else if quoted and strict-units {
          return (
            calculation-fail(
              "unknown unit `" + unit-name + "`; strict-units rejects opaque custom units",
              soft: soft,
            ),
            position + 1,
          )
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
      if (type(right) == dictionary and "error" in right) { return (right, next) }
      left = apply-op(op, left, right, soft: soft)
      if (type(left) == dictionary and "error" in left) { return (left, next) }
      if not is-finite-number(left.si-value) {
        return (calculation-fail(overflow-message, soft: soft), next)
      }
      position = next
    }
    (left, position)
  }

  let (result, position) = parse-expression(tokens, 0)
  if (type(result) == dictionary and "error" in result) { return result }
  if position != tokens.len() {
    return calculation-fail("unexpected token `" + tokens.at(position) + "`", soft: soft)
  }
  result
}

let parse-output-unit(tokens, aliases, strict-units, soft: false) = parse(
  add-implicit-multiplication(tokens),
  aliases: aliases,
  custom-units: true,
  strict-units: strict-units,
  soft: soft,
)

let normalize-size(size, soft: false) = {
  if size == none { return none }
  let notation = none
  let value = if type(size) in (int, float, decimal) {
    float(size)
  } else if type(size) == str or (type(size) == content and size.func() in (raw, math.equation)) {
    let source = input-source(size)
    let parsed = parse(add-implicit-multiplication(tokenize(source)), soft: soft)
    if (type(parsed) == dictionary and "error" in parsed) { return parsed }
    if not is-dimensionless(parsed) {
      return calculation-fail("size must not contain a physical unit", soft: soft)
    }
    let compact = source.replace(whitespace-pattern, "")
    let scientific = compact.match(scientific-pattern)
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
    return calculation-fail("size must be a positive number, a string, or a math expression, such as `size: $2 dot 10^3$`, not " + repr(size), soft: soft)
  }
  if value <= 0 {
    return calculation-fail("size must be greater than zero", soft: soft)
  }
  if not is-finite-number(value) {
    return calculation-fail("size is too large", soft: soft)
  }
  (value: value, notation: notation)
}

let normalize-math-unit-tokens(tokens) = {
  let tokens = tokens.map(token => if token == "Omega" { "Ω" } else { token })
  let normalized = ()
  let position = 0
  while position < tokens.len() {
    let token = tokens.at(position)
    let next = tokens.at(position + 1, default: none)
    let combined = if token == "°" and next in ("C", "F", "R") {
      token + next
    } else if token == "mu" and next != none {
      "µ" + next
    } else {
      none
    }
    if combined != none and resolve-unit(combined) != none {
      normalized.push(combined)
      position += 2
    } else {
      normalized.push(token)
      position += 1
    }
  }
  normalized
}

/// Evaluate a unit-aware expression containing numbers, units, variables,
/// `sin`, `cos`, `tan`, `asin`/`arcsin`, `acos`/`arccos`, `atan`/`arctan`,
/// `atan2`, `ln`, `log_b`, `abs`, `floor`, `ceil`, `round`, absolute-value bars,
/// and the operators `+`, `-`, `*`, `/`, `^`, `±`, and `∓`.
///
/// Use `to`, `=`, or the `unit` argument to request an output unit.
/// `render: false` leaves `display` empty for callers that render their own.
let calculate(source, digits: 4, scope: (:), unit: none, size: none, block: true, unloaded: (), aliases: (:), strict-units: false, soft: false, render: true, prepared-tokens: none) = {
  if type(strict-units) != bool {
    return calculation-fail("strict-units must be a boolean", soft: soft)
  }
  let normalized-size = normalize-size(size, soft: soft)
  if (type(normalized-size) == dictionary and "error" in normalized-size) { return normalized-size }
  let size = if normalized-size == none { none } else { normalized-size.value }
  let size-notation = if normalized-size == none { none } else { normalized-size.notation }
  // Preserve quoted Typst math text so `"m"` remains an explicit metre even
  // when the bare name `m` has been unloaded for use as a variable.
  let source-is-math = type(source) == content and source.func() == math.equation
  let source = if prepared-tokens == none { input-source(source, preserve-text: true) } else { source }
  let raw-tokens = if prepared-tokens == none { tokenize(source) } else { prepared-tokens }
  let absolute-tokens = absolute-value-tokens(raw-tokens)
  if absolute-tokens != none { raw-tokens = absolute-tokens }
  if dot-product-token in raw-tokens {
    return calculation-fail(dot-product-message, soft: soft)
  }
  if raw-tokens.any(is-display-only-token) {
    return calculation-fail(
      "display-only mathematical symbols cannot be evaluated as one numeric value",
      soft: soft,
    )
  }
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
    let tokens = raw-tokens.slice(conversion-index + 1)
    if source-is-math { normalize-math-unit-tokens(tokens) } else { tokens }
  } else if unit != none {
    let tokens = compact-unit-tokens(tokenize(input-source(unit, preserve-text: true)))
    if type(unit) == content and unit.func() == math.equation {
      normalize-math-unit-tokens(tokens)
    } else {
      tokens
    }
  } else {
    none
  }
  if expression-tokens.len() == 0 { return calculation-fail("missing expression before output conversion", soft: soft) }
  if target-tokens != none and target-tokens.len() == 0 { return calculation-fail("missing output unit", soft: soft) }

  if expression-tokens.any(token => token in ("±", "∓")) {
    let branches = ()
    for branch-tokens in paired-sign-branches(raw-tokens) {
      let branch = calculate(
        branch-tokens.join(" "),
        digits: digits,
        scope: scope,
        unit: unit,
        size: size,
        block: false,
        unloaded: unloaded,
        aliases: aliases,
        strict-units: strict-units,
        soft: true,
      )
      if (type(branch) == dictionary and "error" in branch) {
        return calculation-fail(branch.error, soft: soft)
      }
      branches.push(branch)
    }
    let result = (
      alternatives: true,
      branches: branches,
      values: branches.map(branch => branch.value),
      exacts: branches.map(branch => branch.exact),
      si-values: branches.map(branch => branch.si-value),
      units: branches.map(branch => branch.unit),
      source: source,
    )
    let body = render-tokens(expression-tokens, scope: scope, aliases: aliases)
    body += h(0.25em) + math.eq + h(0.25em) + render-result(result, aliases: aliases)
    result.insert("display", math.equation(body, block: block))
    return result
  }

  let result = parse(
    add-implicit-multiplication(expression-tokens),
    scope: scope,
    unloaded: unloaded,
    aliases: aliases,
    override-opaque: unit != none,
    strict-units: strict-units,
    soft: soft,
  )
  if (type(result) == dictionary and "error" in result) { return result }
  let output-unit = result.preferred
  let output-scale = 1.0
  let output-offset = 0.0
  if target-tokens != none {
    let target = parse-output-unit(target-tokens, aliases, strict-units, soft: soft)
    if (type(target) == dictionary and "error" in target) { return target }
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
          affine-kind: if target.affine == none { none } else { "absolute" },
        )
      } else {
        let precedence-hint = if "/" in expression-tokens {
          "; check parentheses around compound denominators"
        } else {
          ""
        }
        return calculation-fail(
          "cannot convert " + unit-kind-name(result) + " to " + unit-kind-name(target)
          + precedence-hint,
          soft: soft,
        )
      }
    }
    // Keep quotes on custom labels so a stored preferred unit can be parsed again.
    output-unit = target-tokens.map(token => if (token.starts-with("\"") and token.ends-with("\"") and token.len() >= 2) and resolve-unit(quoted-unit-name(token)) != none {
      quoted-unit-name(token)
    } else { token }).join("")
    output-scale = if target.affine == none { target.si-value } else { target.affine.scale }
    output-offset = if target.affine == none or result.affine-kind == "difference" { 0.0 } else { target.affine.offset }
  } else if output-unit == none and result.opaque.len() > 0 {
    output-unit = canonical-opaque-unit(result.opaque, dims: result.dims)
  } else if output-unit == none and not is-dimensionless(result) {
    let ambiguity = ambiguous-unit(result.dims)
    if ambiguity != none {
      return calculation-fail(ambiguous-unit-message(ambiguity), soft: soft)
    }
    output-unit = canonical-unit(result.dims)
  } else if output-unit != none and result.opaque.len() == 0 {
    let preferred = parse-output-unit(tokenize(output-unit), aliases, strict-units)
    output-scale = if preferred.affine == none { preferred.si-value } else { preferred.affine.scale }
    output-offset = if preferred.affine == none or result.affine-kind == "difference" { 0.0 } else { preferred.affine.offset }
  }

  if size != none {
    if is-dimensionless(result) {
      return calculation-fail("size requires a result with a physical unit", soft: soft)
    }
    if output-offset != 0 {
      return calculation-fail("size cannot scale an affine output unit", soft: soft)
    }
    if target-tokens == none {
      output-unit = sized-output-unit(
        result.dims,
        size,
        opaque: result.opaque,
        notation: size-notation,
      )
      output-scale = size
    } else {
      output-unit = sized-requested-unit(
        result.dims,
        output-unit,
        output-scale,
        size,
        opaque: result.opaque,
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
  if not is-finite-number(exact) or not is-finite-number(result.si-value) {
    return calculation-fail(overflow-message, soft: soft)
  }
  let counted-tokens = precision-tokens(expression-tokens, scope: scope, aliases: aliases, unloaded: unloaded)
  let (input-digits, input-significant) = input-precision(counted-tokens, scope)
  let significant = if type(digits) == dictionary { digits.significant } else { none }
  if significant == auto { significant = input-significant }
  if significant != none {
    digits = if exact == 0 { significant - 1 } else {
      significant - 1 - int(calc.floor(calc.log(calc.abs(float(exact)), base: 10)))
    }
  } else if digits == auto { digits = input-digits }
  let value = calc.round(exact, digits: digits)
  let display = if render {
    let scientific-output = is-scientific-size-unit(output-unit)
    let display-body = render-tokens(expression-tokens, scope: scope, aliases: aliases) + h(0.25em) + math.eq + h(0.25em)
    if output-unit != none {
      let output-tokens = if target-tokens != none { target-tokens } else { tokenize(output-unit) }
      if scientific-output {
        display-body += render-tokens(
          display-number-tokens(value, exact: exact, digits: digits, significant-digits: significant) + ("*",) + output-tokens,
          aliases: aliases,
        )
      } else {
        let rendered-value = render-tokens(display-number-tokens(value, exact: exact, digits: digits, significant-digits: significant))
        display-body += rendered-value + unit-gap(output-tokens, aliases: aliases) + render-tokens(output-tokens, aliases: aliases)
      }
    } else {
      display-body += render-tokens(display-number-tokens(value, exact: exact, digits: digits, significant-digits: significant))
    }
    math.equation(display-body, block: block)
  }

  let public-unit = if output-unit == none {
    none
  } else if text-unit-prefix not in output-unit {
    // Custom labels keep their quotes internally; expose the plain name.
    output-unit.replace(quoted-text-pattern, found => found.captures.first())
  } else {
    tokenize(output-unit).map(token => if is-text-unit(token) { text-unit-name(token) } else if is-quoted-unit(token) {
      quoted-unit-name(token)
    } else { token }).join("")
  }
  (
    value: value,
    exact: exact,
    si-value: result.si-value,
    dimensions: result.dims,
    custom-units: result.opaque,
    affine-kind: result.affine-kind,
    unit: public-unit,
    unit-source: output-unit,
    size: size,
    digits: digits,
    input-digits: input-digits,
    // Keep significant-figure precision so later significant-mode calls can reuse it.
    input-significant-digits: if significant == none { input-significant } else { significant },
    ..if significant == none { (:) } else { (significant-digits: significant) },
    source: source,
    display: display,
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
  digits: none,
  auto-digits: "decimal",
  block: auto,
  supplement: auto,
  strict: false,
  strict-units: false,
  substitute-constants: false,
) = {
  let initial-state-dict = _pairs-to-dict(initial-state)
  if initial-state-dict == none {
    panic("math-once calculation-builder: `initial-state:` must be a dictionary of starting values, such as `initial-state: (g: 9.82)`, not " + repr(initial-state))
  }
  let initial-state = initial-state-dict
  let key-error = _key-option-error(key)
  if key-error != none { panic("math-once calculation-builder: " + key-error) }
  let supplement-error = _supplement-option-error(supplement)
  if supplement-error != none { panic("math-once calculation-builder: " + supplement-error) }
  if not valid-auto-digits(auto-digits) {
    panic("math-once calculation-builder: " + auto-digits-message)
  }
  if not valid-digits(digits) {
    panic("math-once calculation-builder: " + digits-message)
  }
  if block != auto and type(block) != bool {
    panic("math-once calculation-builder: block must be auto or a boolean")
  }
  if type(strict) != bool {
    panic("math-once calculation-builder: strict must be a boolean")
  }
  if type(strict-units) != bool {
    panic("math-once calculation-builder: strict-units must be a boolean")
  }
  if type(substitute-constants) != bool {
    panic("math-once calculation-builder: substitute-constants must be a boolean")
  }
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
    if is-built-in-constant(name) {
      panic(
        "math-once calculation-builder: `" + name
        + "` is a built-in constant; use unload before assigning it",
      )
    }
  }
  let builder-error(message) = if strict {
    panic("math-once calculation-builder: " + message)
  } else {
    text(fill: red, [math-once: #message.])
  }

  // The functions below are defined once per builder. Each runner call
  // describes its equation with a small `spec` dictionary instead of creating
  // its own closures over the runner's local variables.

  // Names used by the output unit. The unit is parsed only where evaluation
  // reads it, so a malformed unit on a call that never evaluates (a missing
  // variable, a function definition, display-only math) stays ignored.
  let unit-scope-tokens(unit) = {
    let unit-source = if type(unit) == str { unit } else if type(unit) == content and unit.func() == raw {
      unit.text
    } else if type(unit) == content and unit.func() == math.equation {
      input-source(unit, preserve-text: true)
    } else { "" }
    let candidates = token-matches(unit-source).map(found => found.text)
    if type(unit) == content and unit.func() == math.equation {
      candidates += normalize-math-unit-tokens(candidates)
    }
    candidates
  }

  // State names that unit tokens can select in referenced-scope. When none
  // of them is stored, adding the unit tokens leaves the scope unchanged.
  let unit-state-names(unit-tokens) = {
    let names = ()
    for token in unit-tokens {
      if is-quoted-unit(token) {
        let unit-name = quoted-unit-name(token)
        names.push(unit-name)
        if unit-name == "Omega" { names.push("Ω") }
      } else {
        names.push(token)
      }
    }
    names
  }

  // Share assignment rendering between context output and state updates.
  let assignment-body(spec, result, current, aliases) = {
    let tokens = spec.tokens
    let name-scope = current
    name-scope.insert(spec.name, 0)
    let labelled-body = render-tokens((spec.name,), scope: name-scope, aliases: aliases) + h(0.25em) + math.eq + h(0.25em) + render-tokens(tokens, scope: current, aliases: aliases)
    if spec.show-result {
      let (expanded, has-variables) = if spec.show-substitution {
        expand-variables(tokens, current, substitute-constants: substitute-constants)
      } else { (tokens, false) }
      if has-variables and spec.show-substitution {
        labelled-body += h(0.25em) + math.eq + h(0.25em) + render-tokens(expanded, aliases: aliases)
      }
      let last-visible-tokens = if has-variables and spec.show-substitution { expanded } else { tokens }
      let structure-result = (type(result) == dictionary
        and (result.at("vector", default: false) or result.at("matrix", default: false)))
      if ((structure-result and not structure-equivalent(last-visible-tokens, result))
        or result.at("alternatives", default: false)
        or (not structure-result
          and not equivalent-tokens(last-visible-tokens, result-tokens(result)))) {
        labelled-body += h(0.25em) + math.eq + h(0.25em) + render-result(result, aliases: aliases, show-unit: spec.show-unit)
      }
    }
    let visible-body = if spec.result-only {
      render-result(result, aliases: aliases, show-unit: spec.show-unit)
    } else {
      labelled-body
    }
    visible-body
  }

  // Evaluate a stored assignment into the entry that the state keeps. The
  // update and the context output share these inner call sites, so the same
  // inputs reuse one memoized calculation and display.
  let stored-entry(spec, scope, aliases, unloaded, tokens, preserve-target: false) = {
    // A completed assignment is in later state reads but not in its own
    // writer's input. It cannot affect an expression that never uses its name.
    if (spec.name not in tokens and ("\"" + spec.name + "\"") not in tokens
      and not preserve-target and spec.name in scope) {
      let _ = scope.remove(spec.name)
    }
    let result = calculate-expanded(
      calculate,
      tokens,
      spec.precision,
      scope,
      spec.unit,
      spec.size,
      spec.block,
      unloaded,
      aliases,
      strict-units: strict-units,
      render: false,
    )
    if type(result) == dictionary and "error" in result { return result }
    result.insert("display", math.equation(assignment-body(spec, result, scope, aliases), block: spec.block))
    result.insert("variable", spec.name)
    if spec.name in unloaded { result.insert("unloaded", true) }
    result
  }

  // Keep the update function identical when missing inputs become available.
  // Changing recovery writes to captured-result writes requires another layout pass.
  let store-assignment(spec, old) = {
    let marker = old.at(initial-state-marker-name)
    // Paired signs and display-only symbols never emit this update.
    if spec.has-paired-sign or spec.has-display-symbol {
      return failed-store(old, marker)
    }
    let name = spec.name
    let target = state-entry(old.at(name, default: none))
    let target-is-dictionary = type(target) == dictionary
    if ((resolve-unit(name) != none or is-built-in-constant(name)
        or (target-is-dictionary and target.at("unit-alias", default: false)))
      and not (target-is-dictionary and target.at("unloaded", default: false) == true)) {
      return failed-store(old, marker)
    }
    // Inline selection here to avoid hashing the entire growing state again
    // as an argument to referenced-scope. The traversal matches that helper.
    let update-scope = {
      let scope = old
      let names = spec.scope-names
      let selected = (:)
      let seen = (:)
      // Validate user-supplied initial values first, as in referenced-scope.
      let marker = scope.at(initial-state-marker-name, default: none)
      let initial = if type(marker) == dictionary and marker.at("initial-state-marker", default: false) { marker.values } else { (:) }
      let pending = initial.keys().filter(name => name not in built-in-constants) + names
      let index = 0
      while index < pending.len() {
        let token = pending.at(index)
        index += 1
        let quoted = token.starts-with("\"") and token.ends-with("\"") and token.len() >= 2
        let name = if quoted { token.slice(1, token.len() - 1) } else { token }
        if name in seen { continue }
        seen.insert(name, true)
        if quoted and name == "Omega" { pending.push("Ω") }
        if name not in scope { continue }
        let item = scope.at(name)
        let (item, dependencies) = scope-entry(item)
        selected.insert(name, item)
        pending += dependencies
      }
      selected
    }
    let update-aliases = (:)
    let update-unloaded = ()
    for (stored-name, item) in update-scope {
      if type(item) == dictionary {
        if item.at("unit-alias", default: false) { update-aliases.insert(stored-name, item.original) }
        if item.at("unloaded", default: false) == true { update-unloaded.push(stored-name) }
      }
    }
    let update-expansion = expand-function-calls(spec.evaluation-tokens, update-scope)
    if type(update-expansion) == dictionary and "error" in update-expansion {
      return failed-store(old, marker)
    }
    let update-tokens = update-expansion.first()
    let update-missing = missing-variables(spec.tokens, update-scope, update-unloaded, aliases: update-aliases)
    if update-missing.len() > 0 {
      return failed-store(old, marker)
    }
    let update-unit-tokens = if spec.unit == none { () } else { unit-scope-tokens(spec.unit) }
    let update-rescope = false
    if update-unit-tokens.len() > 0 {
      for unit-name in unit-state-names(update-unit-tokens) {
        if unit-name in old { update-rescope = true; break }
      }
    }
    if update-rescope {
      update-scope = referenced-scope(spec.scope-tokens + update-unit-tokens, old)
      update-aliases = (:)
      update-unloaded = ()
      for (stored-name, item) in update-scope {
        if type(item) == dictionary {
          if item.at("unit-alias", default: false) { update-aliases.insert(stored-name, item.original) }
          if item.at("unloaded", default: false) == true { update-unloaded.push(stored-name) }
        }
      }
    }
    let entry = stored-entry(spec, update-scope, update-aliases, update-unloaded, update-tokens, preserve-target: name in marker.values)
    if type(entry) == dictionary and "error" in entry {
      return failed-store(old, marker)
    }
    old.insert(name, packed-entry(entry))
    if not marker.at("last-write", default: false) {
      marker.insert("last-write", true)
      old.insert(initial-state-marker-name, marker)
    }
    old
  }

  let store-function(spec, old) = {
    let parsed-function = spec.parsed-function
    let target = old.at(parsed-function.name, default: none)
    let target-is-dictionary = type(target) == dictionary
    if ((target-is-dictionary and target.at("unit-alias", default: false))
      or ((is-built-in-constant(parsed-function.name)
        or resolve-unit(parsed-function.name) != none)
        and not (target-is-dictionary and target.at("unloaded", default: false) == true))) {
      return old
    }
    old.insert(parsed-function.name, parsed-function)
    old
  }

  // Render the equation against the state at the caller's context. With
  // `update: none`, the caller emits the state update itself.
  let equation-content(spec, variables, update) = {
    let name = spec.name
    let source = spec.source
    let tokens = spec.tokens
    let evaluation-tokens = spec.evaluation-tokens
    let scope-tokens = spec.scope-tokens
    let parsed-function = spec.parsed-function
    let stores-result = spec.stores-result
    let calculated-assignment = spec.calculated-assignment
    let display-only = spec.display-only
    let full-symbolic-scope = spec.full-symbolic-scope
    let has-absolute-bars = spec.has-absolute-bars
    let has-paired-sign = spec.has-paired-sign
    let has-display-symbol = spec.has-display-symbol
    let result-only = spec.result-only
    let show-result = spec.show-result
    let show-substitution = spec.show-substitution
    let show-unit = spec.show-unit
    let unit = spec.unit
    let size = spec.size
    let block = spec.block
    let full-current = variables.get()
    // As in store-assignment, select entries before calling memoized helpers.
    let current = if full-symbolic-scope { unpack-state(full-current) } else {
      let scope = full-current
      let names = spec.scope-names
      let selected = (:)
      let seen = (:)
      // Validate user-supplied initial values first, as in referenced-scope.
      let marker = scope.at(initial-state-marker-name, default: none)
      let initial = if type(marker) == dictionary and marker.at("initial-state-marker", default: false) { marker.values } else { (:) }
      let pending = initial.keys().filter(name => name not in built-in-constants) + names
      let index = 0
      while index < pending.len() {
        let token = pending.at(index)
        index += 1
        let quoted = token.starts-with("\"") and token.ends-with("\"") and token.len() >= 2
        let name = if quoted { token.slice(1, token.len() - 1) } else { token }
        if name in seen { continue }
        seen.insert(name, true)
        if quoted and name == "Omega" { pending.push("Ω") }
        if name not in scope { continue }
        let item = scope.at(name)
        let (item, dependencies) = scope-entry(item)
        selected.insert(name, item)
        pending += dependencies
      }
      selected
    }
    let aliases = (:)
    let unloaded = ()
    for (stored-name, item) in current {
      if type(item) == dictionary {
        if item.at("unit-alias", default: false) { aliases.insert(stored-name, item.original) }
        if item.at("unloaded", default: false) == true { unloaded.push(stored-name) }
      }
    }
    if parsed-function != none {
      if result-only {
        builder-error("a function definition has no calculated result to show by itself")
        return
      }
      let function-name-is-unloaded = parsed-function.name in unloaded
      let reserved-function-name = (parsed-function.name in aliases
        or (is-built-in-constant(parsed-function.name) and not function-name-is-unloaded)
        or (resolve-unit(parsed-function.name) != none and not function-name-is-unloaded))
      update-state(variables, update)
      if reserved-function-name {
        builder-error("`" + parsed-function.name + "` is a reserved unit or constant name and cannot be used as a function")
        return
      }
      render-tokens(tokenize(source.replace(":=", "=")), scope: current, aliases: aliases)
      return
    }
    let assignment-is-unloaded = stores-result and name != none and name in unloaded
    let illegal-assignment = (stores-result
      and name != none
      and (resolve-unit(name) != none or name in aliases or is-built-in-constant(name))
      and not assignment-is-unloaded)
    let reserved-name-kind = if name != none and is-built-in-constant(name) {
      "a built-in constant"
    } else {
      "a unit name"
    }
    if has-paired-sign and stores-result and not illegal-assignment {
      builder-error("plus/minus expressions have two paired results and cannot be stored as one value")
      return
    }
    if has-display-symbol {
      if illegal-assignment {
        builder-error("`" + name + "` is " + reserved-name-kind + " and cannot be used as a variable")
      } else if stores-result {
        builder-error("display-only mathematical symbols cannot be stored as one numeric value")
      } else if result-only {
        builder-error("a display-only expression has no calculated result to show by itself")
      } else {
        let visible-tokens = if calculated-assignment {
          tokenize(source)
        } else {
          tokens
        }
        render-tokens(visible-tokens, scope: current, aliases: aliases)
      }
      return
    }
    let cas-call = spec.cas-call
    if cas-call != none and cas-call.operation in current {
      let operation = current.at(cas-call.operation)
      if type(operation) == dictionary and operation.at("function", default: false) {
        cas-call = none
      }
    }
    if cas-call != none {
      let illegal-symbolic-assignment = (stores-result
        and name != none
        and (name in aliases or is-built-in-constant(name)))
      if illegal-symbolic-assignment {
        builder-error("`" + name + "` is " + reserved-name-kind + " and cannot be used as a variable")
        return
      }
      if unit != none or size != none {
        builder-error("symbolic calculations do not accept unit or size")
        return
      }

      let result = symbolic-result(cas-call, current)
      if type(result) == dictionary and "error" in result {
        builder-error(result.error)
        return
      }

      let written = render-tokens(evaluation-tokens, scope: current, aliases: aliases)
      let labelled-body = if name != none {
        let name-scope = current
        name-scope.insert(name, 0)
        (render-tokens((name,), scope: name-scope, aliases: aliases)
          + h(0.25em) + math.eq + h(0.25em) + written)
      } else {
        written
      }
      if (name == none or not stores-result or show-result) {
        labelled-body += h(0.25em) + math.eq + h(0.25em) + render-symbolic-result(result)
      }
      if result-only {
        labelled-body = render-symbolic-result(result)
      }

      if stores-result {
        result.insert("display", math.equation(labelled-body, block: block))
        result.insert("variable", name)
        update-state(variables, old => {
          old.insert(name, result)
          old
        })
        result.display.body
      } else {
        labelled-body
      }
      return
    }
    let function-expansion = if display-only { (evaluation-tokens, false) } else { expand-function-calls(evaluation-tokens, current) }
    let function-error = if type(function-expansion) == dictionary and "error" in function-expansion { function-expansion.error } else { none }
    let calculation-tokens = if function-error == none { function-expansion.first() } else { tokens }
    let missing = if display-only { () } else { missing-variables(tokens, current, unloaded, aliases: aliases) }
    let evaluates = not (illegal-assignment or display-only or missing.len() > 0 or function-error != none)
    if evaluates and unit != none and not full-symbolic-scope {
      let unit-tokens = unit-scope-tokens(unit)
      let rescope = false
      for unit-name in unit-state-names(unit-tokens) {
        if unit-name in full-current { rescope = true; break }
      }
      if rescope {
        current = referenced-scope(scope-tokens + unit-tokens, full-current)
        aliases = (:)
        unloaded = ()
        for (stored-name, item) in current {
          if type(item) == dictionary {
            if item.at("unit-alias", default: false) { aliases.insert(stored-name, item.original) }
            if item.at("unloaded", default: false) == true { unloaded.push(stored-name) }
          }
        }
      }
    }
    let result = if not evaluates { none } else if stores-result {
      stored-entry(spec, current, aliases, unloaded, calculation-tokens, preserve-target: name in full-current.at(initial-state-marker-name).values)
    } else {
      calculate-expanded(
        calculate,
        calculation-tokens,
        spec.precision,
        current,
        unit,
        size,
        block,
        unloaded,
        aliases,
        strict-units: strict-units,
        render: false,
      )
    }
    let calculation-error = if type(result) == dictionary and "error" in result { result.error } else { none }
    let unresolved-absolute = (has-absolute-bars
      and (missing.len() > 0 or function-error != none or calculation-error != none))

    if illegal-assignment {
      if update != none and not has-paired-sign { update-state(variables, update) }
      builder-error("`" + name + "` is " + reserved-name-kind + " and cannot be used as a variable")
    } else if unresolved-absolute and stores-result {
      if update != none { update-state(variables, update) }
      builder-error("a non-numeric absolute-value expression cannot be stored as one value")
    } else if unresolved-absolute {
      let visible-tokens = if calculated-assignment { tokenize(source) } else { tokens }
      render-tokens(visible-tokens, scope: current, aliases: aliases)
    } else if missing.len() > 0 and stores-result {
      // Contextual state reads lag behind updates during layout. Queue a
      // second evaluation against the state seen by the update itself so a
      // chain of stored assignments can advance without one layout pass per
      // dependency.
      if update != none { update-state(variables, update) }
      builder-error("`" + missing.first() + "` is not set")
    } else if missing.len() > 0 and result-only {
      builder-error("`" + missing.first() + "` is not set, so there is no result to show")
    } else if missing.len() > 0 and (calculated-assignment or has-paired-sign) {
      // Preserve ordinary symbolic equations when their right-hand side
      // cannot be evaluated from known variables, numbers, and units.
      render-tokens(tokenize(source), scope: current, aliases: aliases)
    } else if missing.len() > 0 {
      builder-error("`" + missing.first() + "` is not set")
    } else if function-error != none {
      if update != none and stores-result { update-state(variables, update) }
      builder-error(function-error)
    } else if calculation-error != none {
      if update != none and stores-result { update-state(variables, update) }
      builder-error(calculation-error)
    } else if display-only {
      if result-only {
        builder-error("a display-only equation has no calculated result to show by itself")
      } else {
        render-tokens(tokens, scope: current, aliases: aliases)
      }
    } else if name != none {
      if stores-result {
        // stored-entry already rendered the display and marked an unloaded name.
        if update != none { update-state(variables, update) }
        result.display.body
      } else {
        assignment-body(spec, result, current, aliases)
      }
    } else {
      if result-only {
        return render-result(result, aliases: aliases, show-unit: show-unit)
      }
      let labelled-body = render-tokens(tokens, scope: current, aliases: aliases)
      if (show-substitution
        and function-expansion.last()
        and vector-components(calculation-tokens) == none
        and matrix-rows(calculation-tokens) == none) {
        labelled-body += h(0.25em) + math.eq + h(0.25em) + render-tokens(calculation-tokens, scope: numeric-scope(current), aliases: aliases)
      }
      let (expanded, has-variables) = if spec.show-substitution {
        expand-variables(tokens, current, substitute-constants: substitute-constants)
      } else { (tokens, false) }
      if has-variables and show-substitution {
        labelled-body += h(0.25em) + math.eq + h(0.25em) + render-tokens(expanded, aliases: aliases)
      }
      let last-visible-tokens = if has-variables and show-substitution { expanded } else { tokens }
      if ((is-structure-result(result) and not structure-equivalent(last-visible-tokens, result))
        or result.at("alternatives", default: false)
        or (not is-structure-result(result)
          and not equivalent-tokens(last-visible-tokens, result-tokens(result)))) {
        labelled-body += h(0.25em) + math.eq + h(0.25em) + render-result(result, aliases: aliases, show-unit: show-unit)
      }
      labelled-body
    }
  }

  let variables = builder-state(key, initial: initial-state)
  let runner-options = (
    "digits", "auto-digits", "unit", "size", "show-result", "show-substitution",
    "show-unit", "result-only", "hidden", "block", "label", "caption", "gap", "supplement",
  )
  (
    ..args,
    digits: digits,
    auto-digits: auto-digits,
    unit: none,
    size: none,
    show-result: true,
    show-substitution: true,
    show-unit: true,
    result-only: false,
    hidden: false,
    block: block,
    label: none,
    caption: none,
    gap: 0.65em,
    supplement: supplement,
  ) => {
    if args.pos().len() > 1 {
      panic("math-once calculate: the runner accepts at most one expression")
    }
    if type(result-only) != bool {
      panic("math-once calculation-builder: result-only must be a boolean")
    }
    if not valid-digits(digits) {
      panic("math-once calculation-builder: " + digits-message)
    }
    if type(show-substitution) != bool {
      panic("math-once calculation-builder: show-substitution must be a boolean")
    }
    if type(show-unit) != bool {
      panic("math-once calculation-builder: show-unit must be a boolean")
    }
    let unknown = args.named().keys()
    if unknown.len() > 0 {
      panic(
        "math-once calculation-builder: unknown option `" + unknown.first() + ":`; the options are "
        + runner-options.map(option => "`" + option + ":`").join(", "),
      )
    }
    let unit-error = _unit-option-error(unit)
    if unit-error != none { panic("math-once calculation-builder: " + unit-error) }
    if type(show-result) != bool {
      panic("math-once calculation-builder: show-result must be a boolean")
    }
    for error in (_label-option-error(label), _gap-option-error(gap), _supplement-option-error(supplement)) {
      if error != none { panic("math-once calculation-builder: " + error) }
    }
    if type(hidden) != bool {
      panic("math-once calculation-builder: hidden must be a boolean")
    }
    if not valid-auto-digits(auto-digits) {
      return builder-error(auto-digits-message)
    }
    let source = args.pos().at(0, default: none)
    if source == none {
      let visible = (:)
      for (name, value) in unpack-state(variables.get()) {
        if (not is-unloaded-marker(value)
          and not is-unit-alias(value)
          and not is-initial-state-marker(value)
          and not is-built-in-constant(name)) {
          visible.insert(name, value)
        }
      }
      return visible
    }

    let source-block = if type(source) == content and source.func() == math.equation {
      source.block
    } else {
      none
    }
    if block != auto and type(block) != bool {
      panic("math-once calculation-builder: block must be auto or a boolean")
    }
    let block = if block == auto {
      if result-only { false } else if source-block == none { true } else { source-block }
    } else {
      block
    }
    let source = input-source(source, preserve-text: true)
    let assignment = source.match(assignment-pattern)
    let stores-result = assignment != none and assignment.captures.at(2) == ":="
    let parsed-function = if assignment == none { function-definition(source) } else { none }
    let name = if assignment == none {
      none
    } else if assignment.captures.at(0) != none {
      assignment.captures.at(0)
    } else {
      assignment.captures.at(1)
    }
    let expression = if assignment == none { source } else { assignment.captures.at(3) }
    let display-tokens = if assignment == none { tokenize(source) } else { none }
    let display-only = display-tokens != none and "=" in display-tokens

    if hidden and (not stores-result or parsed-function != none) {
      panic("math-once calculation-builder: hidden requires a stored scalar, vector, or matrix assignment")
    }
    if hidden and (caption != none or label != none) {
      panic("math-once calculation-builder: hidden cannot be combined with caption or label")
    }

    if caption != none and not block {
      panic("math-once calculation-builder: captions require block: true")
    }
    if caption != none and type(caption) not in (content, str) {
      panic("math-once calculation-builder: caption must be content, a string, or none")
    }

    // The assignment grammar already validated its left-hand side. Tokenize
    // its expression once and reuse those tokens for scope selection too.
    let evaluation-tokens = if assignment == none { display-tokens } else { tokenize(expression) }
    let scope-tokens = if assignment == none { display-tokens } else {
      let name-token = if assignment.captures.at(0) != none { "\"" + name + "\"" } else { name }
      (normalized-token(name-token),) + evaluation-tokens
    }
    // CAS substitutions follow dictionary insertion order. Keep that order and
    // its complete scope until substitution can be made order-independent.
    let symbolic = symbolic-call(evaluation-tokens)
    let full-symbolic-scope = symbolic != none
    // The written and evaluated tokens do not depend on the state, so derive
    // them once here instead of in every layout pass. The written tokens are
    // those of expression-tokens(expression): the evaluation tokens before a
    // top-level conversion.
    let tokens = if display-only { display-tokens } else {
      let written = evaluation-tokens
      let depth = 0
      for (index, token) in evaluation-tokens.enumerate() {
        if token == "(" { depth += 1 }
        if token == ")" { depth -= 1 }
        if token in ("to", "=") and depth == 0 {
          written = evaluation-tokens.slice(0, index)
          break
        }
      }
      written
    }
    let has-absolute-bars = "|" in evaluation-tokens
    let absolute-evaluation-tokens = absolute-value-tokens(evaluation-tokens)
    if absolute-evaluation-tokens != none { evaluation-tokens = absolute-evaluation-tokens }
    let cas-call = if display-only { none } else if absolute-evaluation-tokens == none { symbolic } else {
      symbolic-call(evaluation-tokens)
    }
    let has-paired-sign = "±" in evaluation-tokens or "∓" in evaluation-tokens
    // Only bars and math-symbol tokens can be display-only.
    let has-display-symbol = false
    for token in evaluation-tokens {
      if (token == "|" or token.starts-with(math-symbol-prefix)) and is-display-only-token(token) {
        has-display-symbol = true
        break
      }
    }
    let spec = (
      source: source,
      name: name,
      stores-result: stores-result,
      calculated-assignment: assignment != none and not stores-result,
      display-only: display-only,
      parsed-function: parsed-function,
      scope-tokens: scope-tokens,
      scope-names: scope-names(scope-tokens),
      evaluation-tokens: evaluation-tokens,
      tokens: tokens,
      full-symbolic-scope: full-symbolic-scope,
      cas-call: cas-call,
      has-absolute-bars: has-absolute-bars,
      has-paired-sign: has-paired-sign,
      has-display-symbol: has-display-symbol,
      precision: automatic-precision(digits, auto-digits),
      unit: unit,
      size: size,
      block: block,
      show-result: show-result,
      show-substitution: show-substitution,
      show-unit: show-unit,
      result-only: result-only,
    )
    // Created once here, the update stays identical in every layout pass.
    let update = if parsed-function != none {
      store-function.with(spec)
    } else if stores-result {
      store-assignment.with(spec)
    } else {
      none
    }
    // A stored numeric assignment always emits store-assignment. Once the
    // update has run, the state after it holds the finished display, so the
    // equation reads that instead of evaluating and rendering it again.
    let reads-stored-display = (stores-result
      and parsed-function == none
      and not full-symbolic-scope
      and cas-call == none
      and not has-paired-sign
      and not has-display-symbol)
    let equation-body = if reads-stored-display {
      [#variables.update(update)#context {
        // A new context initially reads the final state. Wait for its own
        // location before reading the status of the immediately preceding write.
        if query(here()).len() == 0 { return [] }
        let current = variables.get()
        let written = current.at(initial-state-marker-name).at("last-write", default: false)
        if written {
          state-entry(current.at(name)).display.body
        } else {
          equation-content(spec, variables, none)
        }
      }]
    } else {
      context equation-content(spec, variables, update)
    }
    // Avoid memoizing helpers over a context that captures the runner scope.
    let body = if caption == none { equation-body } else { _captioned-body(equation-body, caption, gap) }
    let output = if supplement == auto {
      math.equation(body, block: block)
    } else {
      math.equation(body, block: block, supplement: supplement)
    }
    if hidden {
      box(width: 0pt, height: 0pt, place(hide[#output]))
    } else if label == none {
      output
    } else {
      [#output #label]
    }
  }
}

// Normalize a reset or unload argument to a builder state name.
let state-name(value, action) = {
  if not (type(value) == str or (type(value) == content and value.func() in (raw, math.equation))) {
    panic("math-once " + action + ": names must be strings or math, such as `$m$`, not " + repr(value))
  }
  let name = input-source(value).trim()
  if reset-name-pattern not in name {
    panic(
      "math-once " + action
      + ": names must contain letters and optional letter or number subscripts",
    )
  }
  name
}

/// Clear the complete calculation-builder state.
let reset(key: "math-once-calculation") = {
  let key-error = _key-option-error(key)
  if key-error != none { panic("math-once reset: " + key-error) }
  builder-state(key).update(builder-initial-state((:)))
}

/// Clear selected or all stored values while preserving builder configuration.
let reset-variables(..names, key: "math-once-calculation") = {
  let key-error = _key-option-error(key)
  if key-error != none { panic("math-once reset-variables: " + key-error) }
  let selected = names.pos().map(value => state-name(value, "reset-variables"))
  context {
    let variables = builder-state(key)
    update-state(variables, old => {
      let initial = state-initial-values(old)
      let kept = old
      let targets = if selected.len() == 0 { old.keys() } else { selected }
      for name in targets {
        let item = kept.at(name, default: none)
        if item == none or is-stored-variable(item) {
          if item != none and is-unloaded(item) {
            let marker = (unloaded: true)
            if name in unit-aliases(old).values() { marker.insert("renamed-unit", true) }
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
}

/// Clear selected or all stored function definitions.
let reset-functions(..names, key: "math-once-calculation") = {
  let key-error = _key-option-error(key)
  if key-error != none { panic("math-once reset-functions: " + key-error) }
  let selected = names.pos().map(value => state-name(value, "reset-functions"))
  context {
    let variables = builder-state(key)
    update-state(variables, old => {
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
}

/// Restore selected or all unit names made available with unload.
let restore-units(..names, key: "math-once-calculation") = {
  let key-error = _key-option-error(key)
  if key-error != none { panic("math-once restore-units: " + key-error) }
  let selected = names.pos().map(value => state-name(value, "restore-units"))
  context {
    let variables = builder-state(key)
    update-state(variables, old => {
      let kept = old
      for (name, value) in old {
        if (is-unloaded(value)
          and name not in unit-aliases(old).values()
          and (selected.len() == 0 or name in selected)) {
          if is-built-in-constant(name) {
            kept.insert(name, built-in-constants.at(name))
          } else {
            let _ = kept.remove(name)
          }
        }
      }
      kept
    })
  }
}

/// Remove selected or all rename-unit relationships.
let reset-unit-aliases(..names, key: "math-once-calculation") = {
  let key-error = _key-option-error(key)
  if key-error != none { panic("math-once reset-unit-aliases: " + key-error) }
  let selected = names.pos().map(value => state-name(value, "reset-unit-aliases"))
  context {
    let variables = builder-state(key)
    update-state(variables, old => {
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
          } else if name in unit-aliases(old).values() {
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
}

/// Temporarily make unit names available as builder variable names.
let unload(..names, key: "math-once-calculation") = {
  let key-error = _key-option-error(key)
  if key-error != none { panic("math-once unload: " + key-error) }
  let selected = names.pos().map(value => state-name(value, "unload"))
  if selected.len() == 0 {
    panic("math-once unload: pass at least one unit name")
  }
  context {
    let variables = builder-state(key)
    update-state(variables, old => {
      for name in selected {
        if is-built-in-constant(name) {
          old.insert(name, (unloaded: true))
        } else if resolve-unit(name) == none {
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
}

/// Move an active unit spelling to a new alias until reset.
let rename-unit(from, to, key: "math-once-calculation") = {
  let key-error = _key-option-error(key)
  if key-error != none { panic("math-once rename-unit: " + key-error) }
  let from = state-name(from, "rename-unit")
  let to = state-name(to, "rename-unit")
  let rename-info(old) = {
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

    (aliases, original, error)
  }
  let rename(old) = {
    let (aliases, original, error) = rename-info(old)
    if error != none { return old }
    if from in aliases { let _ = old.remove(from) }
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
  }
  context {
    let variables = builder-state(key)
    let (_, _, error) = rename-info(unpack-state(variables.get()))
    update-state(variables, rename)

    if error != none {
      align(center, text(fill: red, [math-once: #error.]))
    }
  }
}

(
  calculate: calculate,
  automatic-precision: automatic-precision,
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
///   numbers, units, variables, parentheses, `sin`, `cos`, `tan`,
///   `asin`/`arcsin`, `acos`/`arccos`, `atan`/`arctan`, `atan2`, `ln`, `log_b`, `abs`,
///   `floor`, `ceil`, `round`, absolute-value bars, `+`, `-`, `*`, `/`, `^`,
///   `±`, `∓`, and optionally `to` or `=` for output conversion.
/// - `digits`: Decimal places, or `auto` for automatic input precision.
///   Default: `4`, or `auto` when `auto-digits` is "significant".
/// - `auto-digits`: How `digits: auto` counts input precision: "decimal"
///   for decimal places or "significant" for significant figures.
///   Default: "decimal".
/// - `scope`: Numbers or earlier calculate results available as variables.
///   Unit names are reserved and cannot be used as variable names. Stateful
///   calculation builders also reserve their built-in `e` and `pi` constants.
/// - `unit`: Optional requested output unit as a string, raw block, or Typst
///   math equation. This is an alternative to `to` or `=` in `source`.
/// - `size`: Optional positive SI scale for the displayed result. For example,
///   `$10^(-6)$` displays a length in micrometres. It may be combined with the
///   named `unit` argument, but not with `to` or `=` inside the source.
/// - `block`: Whether the rendered equation is centered. Default: `true`.
/// - `strict-units`: Reject unknown quoted units instead of treating them as
///   opaque custom units. Default: `false`.
///
/// Returns a dictionary with `display`, `value`, `exact`, `si-value`,
/// `dimensions`, `unit`, `size`, and `source`.
/// A paired-sign expression instead returns `alternatives: true`, `display`,
/// and tuples named `branches`, `values`, `exacts`, `si-values`, and `units`.
#let calculate(source, digits: none, auto-digits: "decimal", scope: (:), unit: none, size: none, block: true, strict-units: false) = {
  let unit-error = _unit-option-error(unit)
  if unit-error != none { panic("math-once calculate: " + unit-error) }
  let scope-dict = _pairs-to-dict(scope)
  if scope-dict == none {
    panic("math-once calculate: `scope:` must be a dictionary of values, such as `scope: (v: 12)`, not " + repr(scope))
  }
  let scope = scope-dict
  if type(block) != bool {
    panic("math-once calculate: block must be a boolean")
  }
  (_engine.calculate)(
    source,
    digits: (_engine.automatic-precision)(digits, auto-digits),
    scope: scope,
    unit: unit,
    size: size,
    block: block,
    strict-units: strict-units,
  )
}

/// Create a stateful calculator for sequences of equations.
///
/// - `initial-state`: Initial numeric values or calculate results. Unit names
///   are reserved and cannot be used as keys. Default: empty.
/// - `key`: Typst state key. Give independent runners different keys.
/// - `digits`: Default decimal places for runner calls, or `auto`. Default:
///   `4`, or `auto` when `auto-digits` is "significant".
/// - `auto-digits`: How `digits: auto` counts input precision: "decimal"
///   for decimal places or "significant" for significant figures. Fixed
///   integer `digits` settings are unchanged. Default: "decimal".
/// - `block`: `auto` follows Typst math input (`$x$` inline, `$ x $` block)
///   and keeps raw/string input centered. A boolean forces the layout.
///   Default: `auto`.
/// - `supplement`: Optional reference and caption name. Default: `auto`.
/// - `strict`: Panic on calculation errors instead of rendering them in red.
///   Default: `false`.
/// - `strict-units`: Reject unknown quoted units instead of treating them as
///   opaque custom units. Default: `false`.
/// - `substitute-constants`: Show the numeric values of the built-in constants
///   `pi` and `e` in the substituted step instead of their symbols.
///   Default: `false`.
///
/// The returned runner accepts zero or one string, raw block, or Typst math
/// equation plus the named `digits`, `auto-digits`, `unit`, `size`, `show-result`,
/// `show-substitution`, `show-unit`, `result-only`, `hidden`, `block`, `label`, `caption`,
/// `gap`, and `supplement` overrides.
/// Set `show-result: false` on a `:=` definition to store the exact calculated
/// value while showing only the written definition.
/// Scalar, vector, and matrix functions can also be stored with `:=`, such as
/// `$f(x) := x + 1$`, `$arrow(s)(t) := vec(t, t^2)$`, and
/// `$M(t) := mat(t, 0; 0, t)$`, then evaluated by calling them.
/// Stored vectors and matrices support matching-shape addition and subtraction,
/// scalar multiplication and division, matrix multiplication, and matrix-vector
/// products. Use Typst's built-in `mat` for matrices.
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
  digits: none,
  auto-digits: "decimal",
  block: auto,
  supplement: auto,
  strict: false,
  strict-units: false,
  substitute-constants: false,
) = (_engine.calculation-builder)(
  initial-state: initial-state,
  key: key,
  digits: digits,
  auto-digits: auto-digits,
  block: block,
  supplement: supplement,
  strict: strict,
  strict-units: strict-units,
  substitute-constants: substitute-constants,
)

/// Reset all builder state, or explicitly select categories and names.
/// `true` selects a whole category; an array selects names; `false` and empty
/// arrays do nothing. With all options `auto`, clear the complete state.
/// Units include unloaded built-in constants e and pi. Focused resets preserve
/// initial-state. Combined operations run variables, functions, units, aliases.
#let reset(
  key: "math-once-calculation",
  variables: auto,
  functions: auto,
  units: auto,
  aliases: auto,
) = {
  let selections = (variables, functions, units, aliases)
  let categories = ("variables", "functions", "units", "aliases")
  // Validate every selection before emitting any state updates.
  for (category, selection) in categories.zip(selections) {
    if selection != auto and type(selection) != bool and type(selection) != array {
      panic("math-once reset: " + category + " must be auto, a boolean, or an array of names")
    }
  }
  if selections.all(value => value == auto) {
    (_engine.reset)(key: key)
  } else {
    let operations = (
      _engine.reset-variables, _engine.reset-functions,
      _engine.restore-units, _engine.reset-unit-aliases,
    )
    for (operation, selection) in operations.zip(selections) {
      if selection == true {
        operation(key: key)
      } else if type(selection) == array and selection.len() > 0 {
        operation(..selection, key: key)
      }
    }
  }
}

/// Temporarily make unit names available as calculation-builder variables.
///
/// - `names`: One or more known unit names as strings, raw text, or Typst math.
/// - `key`: The state key of the matching calculation builder. Default:
///   `"math-once-calculation"`.
///
/// The unload lasts until `reset(units: (name,))` restores that catalog spelling
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
/// moves that alias again. `reset(aliases: true)` restores catalog spellings
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
  for error in (_gap-option-error(gap), _supplement-option-error(supplement)) {
    if error != none { panic("math-once equation: " + error) }
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
  if indent != auto and type(indent) not in (length, ratio, relative, function) {
    panic("math-once equation-outline: `indent:` must be auto, a length, or a function, not " + repr(indent))
  }
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
  if numbering != none and type(numbering) not in (str, function) {
    panic("math-once number-labelled-equations: `numbering:` must be a pattern string such as `(1)`, a function, or none, not " + repr(numbering))
  }
  let supplement-error = _supplement-option-error(supplement)
  if supplement-error != none { panic("math-once number-labelled-equations: " + supplement-error) }
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

// Compatibility helpers retained for existing documents.
#let matrix = math.mat

/// Clear selected or all stored values while preserving functions and unit
/// configuration. Values from `initial-state` are restored instead of removed.
#let reset-variables(..names, key: "math-once-calculation") = (_engine.reset-variables)(
  ..names,
  key: key,
)

/// Clear selected or all stored scalar, vector, and matrix function definitions.
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
