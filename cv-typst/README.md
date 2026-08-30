# cv-typst — ein Template, zwei Formate

Eigenes Typst-Template, das die JSON-Resume-Datei (`cv/en.json`, Schema
jsonresume.org v1.0.0) als **eine Datenquelle** in beide Zielformate rendert:

- **PDF**: getaggt und validiert als **PDF/UA-1 + PDF/A-2a**
  → `site/public/CV_Toni_Barth.pdf` (alte URL `/CV_Toni_Barth.pdf` bleibt)
- **HTML**: rein semantisches Markup (h2-Sektionen, h3-Einträge, Listen,
  mailto-/tel-Links) → `site/src/generated/resume-en.html`, eingebettet
  von der Seite `/en/resume/` (`site/src/pages/en/resume.astro`)

Es gibt genau **einen** Parser (dieses Template); Astro bettet nur fertiges
HTML ein.

## Bauen

Vom Repo-Root aus, nach jeder Änderung an `cv/en.json`:

```
powershell cv-typst/build.ps1     # Windows
bash cv-typst/build.sh            # Linux / Docker
```

Danach ggf. `npm run build` in `site/`, damit die Site die neue
HTML-Fassung einbettet. Sobald `cv/de.json` existiert, baut das Skript
automatisch auch Deutsch (`CV_Toni_Barth_DE.pdf`, `resume-de.html` — dann noch
`site/src/pages/de/resume.astro` analog anlegen und den Nav-Eintrag in
`src/i18n.ts` ergänzen).

## Dateien

- `jsonresume.typ` — das Template: alle 13 JSON-Resume-Sektionen (basics, work,
  volunteer, education, awards, certificates, publications, skills, languages,
  interests, references, projects); leere Sektionen werden ausgelassen
- `locales.typ` — UI-Strings (en/de): Sektionstitel, Monatsnamen, „heute",
  Sprach- und Ländernamen. Neue Sprache = neuer Eintrag hier + `cv-<lang>.typ`
- `cv-en.typ` / `cv-de.typ` — Einstiegsdateien (setzen Dokumenttitel und
  `text(lang:)`, was PDF/UA-1 verlangt)
- `build.ps1` / `build.sh` — Build in die Astro-Zielorte

## Design-Entscheidungen (Barrierefreiheit)

- Echte, konsekutive Überschriften; Überschriften enthalten nur reinen Text
  (Links stehen in der Zeile darunter — das umgeht einen UA-1-Fehler, an dem
  z. B. das altacv-Template scheitert)
- Keine Icon-Fonts, keine Layout-Tabellen, keine absolute Platzierung
- Dekorative Trennlinien sind im PDF als Artefakt markiert (Screenreader
  überspringen sie)
- Im HTML-Target keine Layout-Tricks: Daten stehen im Fließtext („… · Juli
  2021 – heute"); nur das PDF bekommt rechtsbündige Datumsspalten
- Der Name ist bewusst **keine** Überschrift: Die einbettende Webseite liefert
  die H1, im PDF sind die Sektionen die H1-Ebene — in beiden Targets beginnt
  die Hierarchie damit korrekt
- Mehrzeilige JSON-Strings (z. B. `basics.summary`) werden an `\n` in echte
  Absätze getrennt
- URLs im Fließtext (etwa in `summary`-Feldern) werden per Regex-Show-Regel
  automatisch zu klickbaren Links; Satzzeichen am Ende bleiben außen vor.
  Damit dabei keine (UA-1-verbotenen) verschachtelten Links entstehen, zeigen
  alle explizit gesetzten Links ihre Domain als Text (`link-host`), nie die
  rohe URL — das gilt auch, wenn künftig neue Linkstellen dazukommen

## Gestaltung

- Schrift: **Atkinson Hyperlegible** (Braille Institute, OFL-lizenziert),
  liegt gevendort in `fonts/` — Builds brauchen `--font-path cv-typst/fonts`
  (in den Skripten enthalten). Fällt auf Libertinus Serif zurück, falls die
  Fonts fehlen.
- Farben: die Konstanten `accent` (dunkles Indigo, ans alte THEME_COLOR
  angelehnt, ~9:1 Kontrast) und `subtle` (Metadaten-Grau, 7,5:1) stehen ganz
  oben in `jsonresume.typ` — für einen anderen Look nur diese zwei Werte und
  ggf. die Schriftzeile in `setup()` ändern.
- Alle Gestaltung betrifft ausschließlich das paged-Target; das HTML bleibt
  unstyled-semantisch und erbt das CSS der einbettenden Seite.

## Bekannte Punkte

- Typsts HTML-Export ist offiziell **experimentell** (`--features html`,
  Typst 0.15.1). Das Format der Ausgabe kann sich mit Typst-Updates ändern —
  nach einem Typst-Update einmal `/en/resume/` gegenprüfen. Das Datenformat
  (JSON Resume) und das PDF sind davon unabhängig.
- Die Warnung „page set rule was ignored during HTML export" ist erwartbar und
  harmlos (Seitenränder betreffen nur das PDF).
- Empfohlene Endkontrolle des PDFs: veraPDF oder PAC (PDF Accessibility
  Checker) sowie ein NVDA-Durchgang in Acrobat — Typst validiert UA-1 beim
  Bauen, aber Lesefluss prüft nur ein Mensch.
- Deployment: Der CV-Build steckt im `Dockerfile` (eigene `cv`-Stage mit
  gepinntem Typst 0.15.1, führt `cv-typst/build.sh` aus) — jedes
  `docker build` erzeugt das CV frisch aus `cv/en.json`, ganz ohne
  Vorarbeit; der GitHub-Workflow baut nur noch das Image.
- Der alte Weg (`cv/themes/`, `cv/convert_to_pdf.py`, WeasyPrint — erzeugte
  ungetaggte PDFs) wird nicht mehr gebraucht, sobald dieser Weg produktiv ist.
