// Englische Fassung. Bauen (vom Repo-Root aus):
//   PDF:  typst compile --root . --pdf-standard ua-1,a-2a cv-typst/cv-en.typ CV_Toni_Barth.pdf
//   HTML: typst compile --root . --features html --format html cv-typst/cv-en.typ resume-en.html
#import "/cv-typst/jsonresume.typ": cv, setup
#import "/cv-typst/locales.typ": locales

#let data = json("/cv/en.json")

#set document(
  title: data.basics.name + " — " + locales.en.doc-title-suffix,
  author: data.basics.name,
)
#set text(lang: "en")

#show: setup

#cv(data, lang: "en")
