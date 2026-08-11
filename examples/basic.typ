#import "../math-once.typ": evaluate-code, calculate, calculation-builder

#set text(lang: "da")

= Skriv beregningen én gang

#let a = evaluate-code(`902 / 3.6`, unit: `m/s`)
#a.display

Resultatet kan bruges som et almindeligt tal: #a.value.

#let b = evaluate-code(`a * 2`, scope: (a: a), unit: a.unit, digits: 1)
#b.display

Den præcise, ikke-afrundede værdi er også gemt: #a.exact.

= Automatisk enhedsregning

#let fart = calculate(`10 m/s + 1 km/t`)
#fart.display

#let afstand = calculate(`fart * 2 s`, scope: (fart: fart), digits: 3)
#afstand.display

#calculate(`10 m/s to km/t`, digits: 2).display

#calculate(`(1 m/s + 2 m/s)`, unit: `km/h`, digits: 1).display

= Genbrugelige variabler

#let run = calculation-builder()
#run(`v = 10 m/s + 1 km/t`)
#run(`x = v * 2 s`, digits: 3)

#context {
  let svar = run()
  [Den gemte afstand er #svar.x.value #svar.x.unit.]
}
