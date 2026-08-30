// Deutsche Fassung — erwartet cv/de.json im JSON-Resume-Format.
// Bauen (vom Repo-Root aus):
//   PDF:  typst compile --root . --pdf-standard ua-1,a-2a cv-typst/cv-de.typ CV_Toni_Barth_DE.pdf
//   HTML: typst compile --root . --features html --format html cv-typst/cv-de.typ resume-de.html
#import "/cv-typst/jsonresume.typ": cv, setup
#import "/cv-typst/locales.typ": locales

#let data = json("/cv/de.json")

#set document(
  title: data.basics.name + " — " + locales.de.doc-title-suffix,
  author: data.basics.name,
)
#set text(lang: "de")

#show: setup

#cv(data, lang: "de")
