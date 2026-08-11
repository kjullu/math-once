#import "../lib.typ": calculate

#set text(lang: "da")

= Skriv beregningen én gang

#let a = calculate(`902 / 3.6`, unit: `m/s`)
#a.display

Resultatet kan bruges som et almindeligt tal: #a.value.

#let b = calculate(`a * 2`, scope: (a: a), unit: a.unit, digits: 1)
#b.display

Den præcise, ikke-afrundede værdi er også gemt: #a.exact.
