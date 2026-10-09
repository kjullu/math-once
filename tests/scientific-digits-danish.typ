#import "../math-once.typ": *

// Regression from issue #9: Danish formatting and the preceding exercises.
#set text(region: "DK", lang: "da", font: "Libertinus Serif", ligatures: false)
#set page(footer: context {
  let i = counter(page).get().first()
  let n = counter(page).final().first()
  align(center)[Side #i ud af #n]
})
#show link: underline
#show link: set text(blue)
#show math.ast: math.dot
#show math.equation: it => {
  show ".": ","
  it
}
#set math.equation(numbering: none)
#show: body => context {
  let ligninger-med-label = query(math.equation.where(block: true))
    .filter(eq => eq.has("label"))
    .map(eq => eq.label)
    .dedup()
  if ligninger-med-label.len() > 0 {
    show selector.or(..ligninger-med-label): set math.equation(numbering: "(1)")
    body
  } else {
    body
  }
}
#show: number-labelled-equations.with(supplement: [Ligning])
#let eq = calculation-builder()

#unload($F$)
== a) Bestem det kraftmoment, der kræves for at spænde fælden.
Kraftmomentet $M$ afhænger både af kraften $F$ og armen $r$, som er afstanden mellem genstandens rotationsakse og punktet, hvor kraften virker:
$ M = r dot F dot sin(theta) $
hvor $r$ er radius, $F$ kraften og $theta$ er vinklen mellem radius og kraft.
Vi kan så sætte vores tal:
#eq($ r := 4 "cm" $)
#eq($ F := 8 "N" $)
#eq($ theta := 90 degree $)
Vi kan så indsætte det i formlen:
#eq($ M := r dot F dot sin(theta) $, unit: $"N"m$)
*Så musefælden får et kraftmoment på cirka #eq($M$, result-only: true, show-unit: false, digits: 1) newton meter*
\
*Bøjlen er lavet af en kraftig ståltråd, som vejer 0,120 gram pr cm.*
#reset()
#unload($m$, $d$, $L$)
== b) Bestem diameteren af ståltråden.
Jeg bruger cylinderformlen til at finde diameteren:
$ V = m/rho = pi (d/2)^2 L $
Jeg isolere så $d$
$ m/rho = pi (d/2)^2 L $
$ m/(rho pi L) = (d/2)^2 $
$ sqrt(m/(rho pi L)) = d/2 $
$ 2 dot sqrt(m/(rho pi L)) = d $
Så sætter jeg mit givende og fundet info:
#eq($ rho := 7.9 g/"cm"^3 $, show-result: false)
#text([Der bruges rustfrit ståls densitet på $7.9 g/"cm"^3$, da ståls densitet ikke kunne findes i bogen.], size: 8pt)
#eq($ L := 4 "cm" $)
#eq($ m := 0.120 g/"cm" * L $, unit: "g")
#text([Der ganges med L da den er 4 cm lang.], size: 8pt)
Så indsætter jeg det i min fundne formel:
#eq($ d := 2 dot sqrt(m/(rho pi L)) $)
*Ståltråden har derfor en diameter på cirka #eq($d$, result-only: true, show-unit: false, digits: 1) millimeter.*
#reset()
#unload($L$, $m$)
== c) Bestem en tilnærmet værdi for bøjlens inertimoment. Forklar hvilke tilnærmelser du har gjort.
Jeg splitter stangen op i 2 dele. Del 1 består af de 2 homogene stange, altså dem som er fastgjort til fjederen. Del 2 består af den horisontale tråd, den som rammer musen.
=== Del 1
Da dette består af 2 homogene stange bruges deres formel:
$ I_"ver" = 1/3 m L^2 $
Vi kan så indsætte vores info:
#eq($ L := 4 "cm" $)
#eq($ m := L dot 0.120 g/"cm" $, unit: "g", digits: 3)
#eq($ I_"ver" := 1/3 dot m dot L^2 $)
=== Del 2
Da dette er en horisontal stang, er alle dens punkter omtrent lige langt fra aksen, det vil sige at dens formel bliver:
$ I_"hor" = m L^2 $
Vi sætter så vores info:
#eq($ L := 4 "cm" $)
#eq($ m := L dot 0.120 g/"cm" $, unit: "g", digits: 3)
#eq($ I_"hor" := m dot L^2 $)
=== Samlet
Jeg sætter så alt dette sammen, med mit 2 $I_"ver"$ og vores $I_"hor"$:
#eq($ 2 dot I_"ver" + I_"hor" $)
*Vores inertimoment bliver derfor #eq($2 dot I_"ver" + I_"hor"$, result-only: true, digits: 8)*

#context {
  let result = calculate($2 dot I_"ver" + I_"hor"$, scope: eq(), digits: 8)
  assert("[1.28000000]" in repr(result.display.body).split("[=]").last())
  assert(calc.abs(result.exact - 1.28e-6) < 1e-20)
}
