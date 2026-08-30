// Eigenes CV-Template: rendert eine JSON-Resume-Datei (jsonresume.org, v1.0.0)
// als semantisches Dokument, das sowohl als PDF/UA-1 (typst compile
// --pdf-standard ua-1,a-2a) als auch als HTML (--features html --format html)
// sauber baut. Bewusste Design-Entscheidungen für Barrierefreiheit:
//  - echte, konsekutive Überschriften (Sektionen = Ebene 1, Einträge = Ebene 2),
//    Überschriften enthalten nur reinen Text (keine Links/Kontext-Ausdrücke)
//  - keine Icon-Fonts, keine Layout-Tabellen, keine absolute Platzierung
//  - dekorative Linien sind im PDF als Artefakt markiert
//  - Layout-Unterschiede (z. B. rechtsbündige Daten) nur im paged-Target;
//    das HTML-Target bekommt reinen semantischen Fluss

#import "locales.typ": locales

// ---- Design-Konstanten (nur fürs paged-Target relevant) --------------------
// Dunkles Indigo, an das bisherige THEME_COLOR (#5670d4) angelehnt, aber für
// WCAG-AA-Kontrast auf Weiß abgedunkelt (~9:1). Grau für Metadaten: 7,5:1.
#let accent = rgb("#2e3f8f")
#let subtle = rgb("#555555")

// basics.image nennt eine Bilddatei (z. B. "/images/profile.jpg" oder nur
// "profile.jpg"); fürs PDF wird der Dateiname in site/src/assets gesucht —
// dort liegt das Bild als einzige Quelle, aus der auch Astro die optimierten
// Web-Varianten erzeugt. http(s)-URLs kann Typst nicht laden — solche Werte
// werden ignoriert.
#let site-assets = "/site/src/assets"

// ---- Helfer für optionale JSON-Felder --------------------------------------

#let getstr(d, k) = {
  if k in d and type(d.at(k)) == str and d.at(k).trim() != "" {
    d.at(k).trim()
  } else { none }
}

#let getarr(d, k) = {
  if k in d and type(d.at(k)) == array and d.at(k).len() > 0 {
    d.at(k)
  } else { none }
}

// ---- Datumsformatierung ----------------------------------------------------

// ISO-Datum ("2021", "2021-07" oder "2021-07-23") -> "Juli 2021"
#let fmt-date(loc, iso) = {
  if iso == none { return none }
  let parts = iso.split("-")
  if parts.len() == 1 { return parts.at(0) }
  let month = loc.months.at(int(parts.at(1)) - 1)
  month + " " + parts.at(0)
}

// Zeitraum; fehlendes Ende -> "heute"/"present"; ganz ohne Daten -> nichts
#let daterange(loc, start, end) = {
  if start == none and end == none { return none }
  let s = fmt-date(loc, start)
  let e = if end == none { loc.present } else { fmt-date(loc, end) }
  if s == none { e } else { s + " – " + e }
}

// Mehrzeiligen JSON-String in Absätze aufteilen
#let paragraphs(text) = {
  text.split("\n").map(s => s.trim()).filter(s => s != "").join(parbreak())
}

// Teile mit " · " verbinden (none-Einträge fallen weg)
#let dotline(..parts) = {
  parts.pos().filter(p => p != none).join([ · ])
}

// Kurzer, eindeutiger Anzeigetext für eine URL: Domain samt Pfad, solange das
// kompakt bleibt (z. B. "github.com/Timtam/ReaLackey"), sonst nur die Domain
// (z. B. "thinkmind.org").
#let url-label(url) = {
  let stripped = url.split("//").at(1, default: url)
  if stripped.ends-with("/") { stripped = stripped.slice(0, stripped.len() - 1) }
  if stripped.starts-with("www.") { stripped = stripped.slice(4) }
  if stripped.len() <= 40 { stripped } else { stripped.split("/").at(0) }
}

// Link mit url-label als Linktext statt roher URL
#let link-host(url) = link(url)[#url-label(url)]

// ---- Dokument-Setup (Fonts, Überschriften-Stil) ----------------------------

#let setup(body) = {
  set text(
    font: ("Atkinson Hyperlegible", "Libertinus Serif"),
    size: 10pt,
  )
  set page(
    margin: (x: 1.8cm, top: 1.6cm, bottom: 1.8cm),
    numbering: "1 / 1",
    number-align: center,
  )
  set par(justify: false, leading: 0.62em)
  set list(spacing: 0.55em)

  show heading.where(level: 1): set text(size: 12pt, fill: accent)
  show heading.where(level: 2): set text(size: 10.5pt)
  show heading.where(level: 2): it => context {
    if target() == "paged" {
      v(0.9em, weak: true)
      it
    } else { it }
  }
  show heading.where(level: 1): it => context {
    if target() == "paged" {
      v(1.35em, weak: true)
      it
      pdf.artifact(block(above: 0.3em, below: 0em, line(length: 100%, stroke: 0.8pt + accent)))
      v(0.6em, weak: true)
    } else { it }
  }
  show link: it => context {
    if target() == "paged" { underline(text(fill: accent, it)) } else { it }
  }

  // URLs im Fließtext (z. B. in summary-Feldern) automatisch verlinken.
  // Satzzeichen am Ende (Punkt, Komma, schließende Klammer …) bleiben außen
  // vor. Voraussetzung: Kein bestehender Link zeigt eine rohe URL als
  // Linktext an (dafür sorgt link-host), sonst entstünden verschachtelte
  // Links, die PDF/UA-1 verbietet.
  // Im PDF zusätzlich in box(): verhindert Zeilenumbruch mitten im Link
  // (fragmentierte Link-Annotationen werden von Screenreadern doppelt
  // angesagt); der Link rutscht stattdessen als Ganzes auf die nächste Zeile.
  show regex("https?://[^\\s]+[^\\s.,:;)!?]"): it => context {
    if target() == "paged" { box(link(it.text)) } else { link(it.text) }
  }

  body
}

// ---- Bausteine -------------------------------------------------------------

// Kopfbereich: Name, Berufsbezeichnung, Kontakt, Profile, Anschrift, Foto
#let render-header(loc, b, is-html) = {
  let label = getstr(b, "label")

  // Kontakt als Daten-Tupel (Label, Linkziel, Anzeigewert); Linkziel none =
  // reiner Text. Zusammengesetzt wird pro Zielformat unten.
  let contact = ()
  let email = getstr(b, "email")
  if email != none { contact.push((loc.email, "mailto:" + email, email)) }
  let phone = getstr(b, "phone")
  if phone != none {
    // Geschützte Leerzeichen in der angezeigten Nummer verhindern hässliche
    // Zeilenumbrüche mitten in der Telefonnummer.
    contact.push((loc.phone, "tel:" + phone.replace(" ", ""), phone.replace(" ", "\u{a0}")))
  }
  let url = getstr(b, "url")
  if url != none { contact.push((loc.website, url, url-label(url))) }
  for p in b.at("profiles", default: ()) {
    let network = getstr(p, "network")
    let purl = getstr(p, "url")
    if network != none and purl != none {
      contact.push((network, purl, getstr(p, "username")))
    }
  }
  let location = b.at("location", default: (:))
  let city = {
    let plz-city = (getstr(location, "postalCode"), getstr(location, "city"))
      .filter(x => x != none).join(" ")
    let country = loc.country-names.at(
      getstr(location, "countryCode"), default: getstr(location, "countryCode"))
    (getstr(location, "address"), plz-city, country)
      .filter(x => x != none and x != "").join(", ")
  }
  if city != none and city != "" { contact.push((none, none, city)) }

  if is-html {
    // Im HTML-Target liefert die einbettende Seite die H1; der Name wird als
    // hervorgehobener Absatz ausgegeben. Das Foto wird als <img> mit dem
    // Website-Pfad emittiert (Asset liegt in site/public); Position und
    // Optik übernimmt das CSS der einbettenden Seite (.resume-photo,
    // .resume-contact — siehe resume.astro), damit das Layout dem PDF
    // entspricht.
    let img = getstr(b, "image")
    if img != none and not img.starts-with("http") {
      html.elem("img", attrs: (
        src: img,
        alt: loc.photo-alt-prefix + b.name,
        class: "resume-photo",
      ))
    }
    par(strong(b.name))
    if label != none { par(emph(label)) }
    if contact.len() > 0 {
      // Jeder Eintrag ist EIN Link mit dem Label im Linktext: ein Element,
      // eine Screenreader-Ansage (verhindert das Doppel-Vorlesen von
      // Listenzeile und Link), und alle Linknamen sind sprechend/eindeutig.
      html.elem("div", attrs: (class: "resume-contact"), list(..contact.map(c => {
        let (clabel, dest, value) = c
        if dest == none { [#value] } else { [#clabel: #link(dest)[#value]] }
      })))
    }
  } else {
    let text-part = {
      block(below: 0.4em, text(size: 25pt, weight: "bold", fill: accent, b.name))
      if label != none {
        block(text(size: 11pt, style: "italic", fill: subtle, label))
      }
      if contact.len() > 0 {
        // Kompakte zweispaltige Kontaktübersicht; bleibt semantisch eine
        // Liste (nur die Aufzählungszeichen sind ausgeblendet). Im PDF steht
        // das Label vor dem Link (nur der Wert ist unterstrichen/farbig).
        // box() hält jeden Link auf einer Zeile: Ein über den Zeilenumbruch
        // laufender Link zerfällt im PDF sonst in zwei Link-Annotationen,
        // die Screenreader als zwei anklickbare Links ansagen.
        let contact-lines = contact.map(c => {
          let (clabel, dest, value) = c
          if dest == none { [#value] } else { [#clabel: #box(link(dest)[#value])] }
        })
        block(above: 0.9em, {
          set text(size: 9.3pt)
          set list(marker: none, indent: 0pt, body-indent: 0pt, spacing: 0.55em)
          let half = calc.ceil(contact-lines.len() / 2)
          grid(
            // auto: linke Spalte so breit wie ihr längster Eintrag (die
            // E-Mail-Zeile), damit dort nichts umbrechen muss
            columns: (auto, 1fr),
            column-gutter: 2em,
            list(..contact-lines.slice(0, half)),
            if contact-lines.len() > half { list(..contact-lines.slice(half)) },
          )
        })
      }
    }
    let img = getstr(b, "image")
    let img-file = if img == none or img.starts-with("http") { none } else {
      site-assets + "/" + img.split("/").last()
    }
    if img-file != none {
      grid(
        columns: (1fr, auto),
        column-gutter: 1.4em,
        text-part,
        block(radius: 4pt, clip: true,
          image(img-file, alt: loc.photo-alt-prefix + b.name, width: 3.1cm)),
      )
    } else { text-part }
    pdf.artifact(block(above: 0.9em, below: 0em, line(length: 100%, stroke: 1.1pt + accent)))
    v(0.7em, weak: true)
  }
}

// Ein Eintrag: Überschrift (nur Text), Meta-Zeile, optionale Details
#let render-entry(loc, is-html, title, meta-parts, dates, ..details) = {
  heading(level: 2, title)
  let meta = dotline(..meta-parts)
  if is-html {
    par(dotline(meta, dates))
  } else {
    grid(
      columns: (1fr, auto),
      column-gutter: 1em,
      text(fill: subtle, meta),
      if dates != none { text(fill: subtle, style: "italic", dates) },
    )
  }
  for d in details.pos() {
    if d != none { d }
  }
  if not is-html { v(0.75em, weak: true) }
}

// ---- Sektionen -------------------------------------------------------------

#let render-work(loc, entries, is-html) = {
  heading(level: 1, loc.sections.work)
  for w in entries {
    let org = getstr(w, "name")
    let url = getstr(w, "url")
    render-entry(
      loc, is-html,
      getstr(w, "position"),
      (
        if org != none and url != none { link(url)[#org] } else { org },
        getstr(w, "location"),
      ),
      daterange(loc, getstr(w, "startDate"), getstr(w, "endDate")),
      {
        let summary = getstr(w, "summary")
        if summary != none { paragraphs(summary) }
      },
      {
        let highlights = getarr(w, "highlights")
        if highlights != none { list(..highlights) }
      },
    )
  }
}

#let render-volunteer(loc, entries, is-html) = {
  heading(level: 1, loc.sections.volunteer)
  for w in entries {
    let org = getstr(w, "organization")
    let url = getstr(w, "url")
    render-entry(
      loc, is-html,
      getstr(w, "position"),
      (if org != none and url != none { link(url)[#org] } else { org },),
      daterange(loc, getstr(w, "startDate"), getstr(w, "endDate")),
      {
        let summary = getstr(w, "summary")
        if summary != none { paragraphs(summary) }
      },
      {
        let highlights = getarr(w, "highlights")
        if highlights != none { list(..highlights) }
      },
    )
  }
}

#let render-education(loc, entries, is-html) = {
  heading(level: 1, loc.sections.education)
  for e in entries {
    let title = (getstr(e, "studyType"), getstr(e, "area"))
      .filter(x => x != none).join(", ")
    let score = getstr(e, "score")
    render-entry(
      loc, is-html,
      title,
      (getstr(e, "institution"),),
      daterange(loc, getstr(e, "startDate"), getstr(e, "endDate")),
      if score != none { par([#loc.final-grade: #score]) },
      {
        let courses = getarr(e, "courses")
        if courses != none { list(..courses) }
      },
    )
  }
}

#let render-awards(loc, entries, is-html) = {
  heading(level: 1, loc.sections.awards)
  for a in entries {
    render-entry(
      loc, is-html,
      getstr(a, "title"),
      (getstr(a, "awarder"),),
      fmt-date(loc, getstr(a, "date")),
      {
        let summary = getstr(a, "summary")
        if summary != none { paragraphs(summary) }
      },
    )
  }
}

#let render-certificates(loc, entries, is-html) = {
  heading(level: 1, loc.sections.certificates)
  for c in entries {
    let name = getstr(c, "name")
    let url = getstr(c, "url")
    render-entry(
      loc, is-html,
      name,
      (
        getstr(c, "issuer"),
        if url != none { link-host(url) },
      ),
      fmt-date(loc, getstr(c, "date")),
    )
  }
}

#let render-publications(loc, entries, is-html) = {
  heading(level: 1, loc.sections.publications)
  for p in entries {
    let url = getstr(p, "url")
    render-entry(
      loc, is-html,
      getstr(p, "name"),
      (
        getstr(p, "publisher"),
        if url != none { link-host(url) },
      ),
      fmt-date(loc, getstr(p, "releaseDate")),
      {
        let summary = getstr(p, "summary")
        if summary != none { paragraphs(summary) }
      },
    )
  }
}

#let render-projects(loc, entries, is-html) = {
  heading(level: 1, loc.sections.projects)
  for p in entries {
    let url = getstr(p, "url")
    let roles = getarr(p, "roles")
    render-entry(
      loc, is-html,
      getstr(p, "name"),
      (
        getstr(p, "entity"),
        if roles != none { roles.join(", ") },
        getstr(p, "type"),
        if url != none { link-host(url) },
      ),
      daterange(loc, getstr(p, "startDate"), getstr(p, "endDate")),
      {
        let desc = getstr(p, "description")
        if desc != none { paragraphs(desc) }
      },
      {
        let highlights = getarr(p, "highlights")
        if highlights != none { list(..highlights) }
      },
      {
        // Keywords als dezente Tag-Zeile (hilft auch ATS-Parsern)
        let keywords = getarr(p, "keywords")
        if keywords != none {
          if is-html {
            par(emph(keywords.join(", ")))
          } else {
            par(text(size: 9pt, fill: subtle, style: "italic", keywords.join(", ")))
          }
        }
      },
    )
  }
}

#let render-skills(loc, entries) = {
  heading(level: 1, loc.sections.skills)
  list(..entries.map(s => {
    let name = getstr(s, "name")
    let level = getstr(s, "level")
    let head = if level != none { [#name (#level)] } else { [#name] }
    let keywords = getarr(s, "keywords")
    if keywords != none { [#head: #keywords.join(", ")] } else { head }
  }))
}

#let render-languages(loc, entries) = {
  heading(level: 1, loc.sections.languages)
  list(..entries.map(l => {
    let code = getstr(l, "language")
    let name = loc.language-names.at(code, default: code)
    let fluency = getstr(l, "fluency")
    if fluency != none { [#name: #fluency] } else { [#name] }
  }))
}

#let render-interests(loc, entries) = {
  heading(level: 1, loc.sections.interests)
  list(..entries.map(i => {
    let name = getstr(i, "name")
    let keywords = getarr(i, "keywords")
    if keywords != none { [#name: #keywords.join(", ")] } else { [#name] }
  }))
}

#let render-references(loc, entries, is-html) = {
  heading(level: 1, loc.sections.references)
  for r in entries {
    render-entry(loc, is-html, getstr(r, "name"), (), none,
      {
        let reference = getstr(r, "reference")
        if reference != none { quote(block: true, paragraphs(reference)) }
      },
    )
  }
}

// ---- Hauptfunktion ---------------------------------------------------------

#let cv(data, lang: "en") = context {
  let loc = locales.at(lang)
  let is-html = target() == "html"
  let b = data.at("basics", default: (:))

  render-header(loc, b, is-html)

  let summary = getstr(b, "summary")
  if summary != none { paragraphs(summary) }

  let work = getarr(data, "work")
  if work != none { render-work(loc, work, is-html) }

  let volunteer = getarr(data, "volunteer")
  if volunteer != none { render-volunteer(loc, volunteer, is-html) }

  let education = getarr(data, "education")
  if education != none { render-education(loc, education, is-html) }

  let awards = getarr(data, "awards")
  if awards != none { render-awards(loc, awards, is-html) }

  let certificates = getarr(data, "certificates")
  if certificates != none { render-certificates(loc, certificates, is-html) }

  let publications = getarr(data, "publications")
  if publications != none { render-publications(loc, publications, is-html) }

  let projects = getarr(data, "projects")
  if projects != none { render-projects(loc, projects, is-html) }

  let skills = getarr(data, "skills")
  if skills != none { render-skills(loc, skills) }

  let languages = getarr(data, "languages")
  if languages != none { render-languages(loc, languages) }

  let interests = getarr(data, "interests")
  if interests != none { render-interests(loc, interests) }

  let references = getarr(data, "references")
  if references != none { render-references(loc, references, is-html) }
}
