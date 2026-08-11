#import "../math-once.typ": calculate, qalc, qalc-builder

#set text(lang: "da")

= Skriv beregningen én gang

#let a = calculate(`902 / 3.6`, unit: `m/s`)
#a.display

Resultatet kan bruges som et almindeligt tal: #a.value.

#let b = calculate(`a * 2`, scope: (a: a), unit: a.unit, digits: 1)
#b.display

Den præcise, ikke-afrundede værdi er også gemt: #a.exact.

= Automatisk enhedsregning

#let fart = qalc(`10 m/s + 1 km/t`)
#fart.display

#let afstand = qalc(`fart * 2 s`, scope: (fart: fart), digits: 3)
#afstand.display

#qalc(`10 m/s to km/t`, digits: 2).display

#qalc(`(1 m/s + 2 m/s)`, unit: `km/h`, digits: 1).display

= Variabler som i eqrun

#let run = qalc-builder()
#run(`v = 10 m/s + 1 km/t`)
#run(`d = v * 2 s`, digits: 3)

#context {
  let svar = run()
  [Den gemte afstand er #svar.d.value #svar.d.unit.]
}
