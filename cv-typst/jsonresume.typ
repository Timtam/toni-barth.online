// Custom CV template: renders a JSON Resume file (jsonresume.org, v1.0.0)
// as a semantic document that builds cleanly both as PDF/UA-1 (typst compile
// --pdf-standard ua-1,a-2a) and as HTML (--features html --format html).
// Deliberate accessibility design decisions:
//  - real, consecutive headings (sections = level 1, entries = level 2);
//    headings contain plain text only (no links/context expressions)
//  - no icon fonts, no layout tables, no absolute placement
//  - decorative rules are marked as artifacts in the PDF
//  - layout differences (e.g. right-aligned dates) exist only in the paged
//    target; the HTML target gets pure semantic flow

#import "locales.typ": locales

// ---- Design constants (only relevant for the paged target) -----------------
// Dark indigo, derived from the previous THEME_COLOR (#5670d4) but darkened
// for WCAG AA contrast on white (~9:1). Gray for metadata: 7.5:1.
#let accent = rgb("#2e3f8f")
#let subtle = rgb("#555555")

// basics.image names an image file (e.g. "/images/profile.jpg" or just
// "profile.jpg"); for the PDF the file name is resolved in site/src/assets —
// the single source from which Astro also derives the optimized web
// variants. Typst cannot fetch http(s) URLs — such values are ignored.
#let site-assets = "/site/src/assets"

// ---- Helpers for optional JSON fields --------------------------------------

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

// ---- Date formatting -------------------------------------------------------

// ISO date ("2021", "2021-07" or "2021-07-23") -> "July 2021"
#let fmt-date(loc, iso) = {
  if iso == none { return none }
  let parts = iso.split("-")
  if parts.len() == 1 { return parts.at(0) }
  let month = loc.months.at(int(parts.at(1)) - 1)
  month + " " + parts.at(0)
}

// Date range; missing end -> "present"/"heute"; no dates at all -> nothing
#let daterange(loc, start, end) = {
  if start == none and end == none { return none }
  let s = fmt-date(loc, start)
  let e = if end == none { loc.present } else { fmt-date(loc, end) }
  if s == none { e } else { s + " – " + e }
}

// Split a multi-line JSON string into paragraphs
#let paragraphs(text) = {
  text.split("\n").map(s => s.trim()).filter(s => s != "").join(parbreak())
}

// Join parts with " · " (none entries are dropped)
#let dotline(..parts) = {
  parts.pos().filter(p => p != none).join([ · ])
}

// Short, unique display text for a URL: domain plus path while that stays
// compact (e.g. "github.com/Timtam/ReaLackey"), otherwise just the domain
// (e.g. "thinkmind.org").
#let url-label(url) = {
  let stripped = url.split("//").at(1, default: url)
  if stripped.ends-with("/") { stripped = stripped.slice(0, stripped.len() - 1) }
  if stripped.starts-with("www.") { stripped = stripped.slice(4) }
  if stripped.len() <= 40 { stripped } else { stripped.split("/").at(0) }
}

// Link using url-label as its text instead of the raw URL
#let link-host(url) = link(url)[#url-label(url)]

// ---- Document setup (fonts, heading styles) --------------------------------

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

  // Auto-link URLs in running text (e.g. in summary fields). Trailing
  // punctuation (period, comma, closing paren, ...) stays outside the link.
  // Precondition: no explicit link shows a raw URL as its text (link-host
  // takes care of that), otherwise nested links would appear, which
  // PDF/UA-1 forbids.
  // In the PDF additionally wrapped in box(): prevents a line break inside
  // the link (fragmented link annotations get announced twice by screen
  // readers); the link moves to the next line as a whole instead.
  show regex("https?://[^\\s]+[^\\s.,:;)!?]"): it => context {
    if target() == "paged" { box(link(it.text)) } else { link(it.text) }
  }

  body
}

// ---- Building blocks -------------------------------------------------------

// Header area: name, job title, contact, profiles, address, photo
#let render-header(loc, b, is-html) = {
  let label = getstr(b, "label")

  // Contact as data tuples (label, link target, display value); link target
  // none = plain text. Assembled per output target below.
  let contact = ()
  let email = getstr(b, "email")
  if email != none { contact.push((loc.email, "mailto:" + email, email)) }
  let phone = getstr(b, "phone")
  if phone != none {
    // Non-breaking spaces in the displayed number prevent ugly line breaks
    // in the middle of the phone number.
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
    // In the HTML target the embedding page provides the H1; the name is
    // emitted as an emphasized paragraph. The photo is emitted as an <img>
    // with the website path (the asset lives in site/src/assets); position
    // and styling come from the embedding page's CSS (.resume-photo,
    // .resume-contact — see resume.astro) so the layout matches the PDF.
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
        // Compact two-column contact overview; semantically still a list
        // (only the bullet markers are hidden). In the PDF the label sits
        // outside the link (only the value is underlined/colored).
        // box() keeps every link on a single line: a link running across a
        // line break would otherwise split into two link annotations in the
        // PDF, which screen readers announce as two clickable links.
        let contact-lines = contact.map(c => {
          let (clabel, dest, value) = c
          if dest == none { [#value] } else { [#clabel: #box(link(dest)[#value])] }
        })
        block(above: 0.9em, {
          set text(size: 9.3pt)
          set list(marker: none, indent: 0pt, body-indent: 0pt, spacing: 0.55em)
          let half = calc.ceil(contact-lines.len() / 2)
          grid(
            // auto: left column as wide as its longest entry (the email
            // line) so nothing in it has to wrap
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

// One entry: heading (text only), meta line, optional details
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

// ---- Sections --------------------------------------------------------------

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
        // Keywords as a subtle tag line (also helps ATS parsers)
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

// ---- Main function ---------------------------------------------------------

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
