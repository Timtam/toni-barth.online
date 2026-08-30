# toni-barth.online

Monorepo der persönlichen Website von Toni Barth.

- **`site/`** — die Website (Astro 7, zweisprachig en/de, statisch, ohne
  Client-JavaScript, screenreader-first). Siehe `site/README.md`.
- **`cv-typst/`** — Typst-Template, das aus `cv/en.json` (JSON Resume) den
  Lebenslauf als PDF/UA-1+PDF/A-2a **und** als semantisches HTML für die
  Website rendert. Siehe `cv-typst/README.md`.
- **`cv/`** — die CV-Daten (`en.json`, künftig `de.json`). Die übrigen Dateien
  dort stammen aus dem alten jsonresume/WeasyPrint-Weg und können weg.
- **`nginx/` + `Dockerfile`** — Deployment: statischer Build hinter nginx,
  inklusive Accept-Language-Sprachweiche auf `/` und Redirects der alten
  URL-Pfade. Gebaut und gepusht vom Workflow in `.github/workflows/`.

Bis August 2026 basierte die Site auf Nikola; die Astro-Migration samt
Begründung (Screenreader-Tauglichkeit) ist in der Git-Historie und den
README-Dateien dokumentiert.
