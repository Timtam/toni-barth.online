# toni-barth.online — Astro-Site

Die persönliche Website, gebaut mit Astro 7. Zweisprachig (Englisch unter
`/en/…`, Deutsch unter `/de/…`), komplett statisch, **null Client-JavaScript**,
mit Barrierefreiheit als Grundprinzip.

## Befehle

Alle Befehle laufen im Ordner `site/` und erzeugen reine Text-Ausgabe:

```
npm install        # einmalig: Abhängigkeiten installieren
npm run dev        # Dev-Server auf http://localhost:4321 (Strg+C zum Beenden)
npm run build      # statischen Build nach dist/ erzeugen
npm run preview    # den fertigen Build aus dist/ lokal servieren
npm run preview:sprachweiche  # dist/ mit nginx-artiger Sprachweiche (Port 8080)
npm run lint       # ESLint mit jsx-a11y-Barrierefreiheitsregeln (streng)
```

Tipp: `npx astro dev --background` startet den Dev-Server, ohne das Terminal zu
blockieren; `npx astro dev logs`, `... status` und `... stop` verwalten ihn.

## Barrierefreiheits-Grundsätze

- **Kein `<ClientRouter />`**: Jede Navigation ist ein echter Seitenladevorgang;
  der Browser sagt Titel nativ an und setzt den Fokus nativ zurück.
- **Dev-Toolbar deaktiviert** (`astro.config.mjs`): rein visuelles
  Hover-Overlay; Prüfungen laufen stattdessen über `npm run lint` als Text.
- **Layout** (`src/layouts/Base.astro`): Skip-Link als erstes Element, Landmarks
  (`header`/`nav`/`main`/`footer`), `aria-label` auf der Navigation,
  `aria-current="page"`, sichtbarer Fokus-Indikator, Dark Mode via
  `prefers-color-scheme`, korrektes `lang` pro Seite plus `hreflang`-Links.
- **Projekte-Untermenü** als natives `<details>`/`<summary>` — ohne Skript
  bedienbar.

## Struktur und i18n

- `src/pages/en/*.md` und `src/pages/de/*.md`: Inhalte als Markdown mit
  Frontmatter (`title`, optional `translation` = URL der Übersetzung; fehlt
  sie, führt der Sprachwechsler zur Startseite der anderen Sprache).
- `src/i18n.ts`: Navigation und UI-Texte beider Sprachen zentral.
- `src/pages/index.astro`: neutrale Sprachwahlseite unter `/` — der Fallback
  für Umgebungen ohne nginx. In Produktion leitet nginx `/` anhand von
  Accept-Language per 302 auf `/en/` bzw. `/de/` um (siehe
  `../nginx/default.conf`, die auch die Redirects der alten URL-Pfade enthält).
- `src/components/Audio.astro`: Audio-Einbindung (ersetzt den alten
  Nikola-Shortcode), genutzt in `src/pages/de/contributions.mdx`.
- `src/pages/en/resume.astro` + `src/generated/resume-en.html`: Der Lebenslauf
  wird von Typst aus `../cv/en.json` erzeugt (siehe `../cv-typst/README.md`)
  und hier eingebettet; das zugehörige PDF/UA-1 liegt unter
  `public/CV_Toni_Barth.pdf`.

## Deployment

Das Repo-Root enthält `Dockerfile` (Node-Builder → nginx) und
`nginx/default.conf` (Sprachweiche + Redirects). Der GitHub-Workflow
`.github/workflows/push_docker.yaml` baut bei jedem Push auf master zuerst das
CV (Typst 0.15.1, gepinnt), dann das Multi-Arch-Docker-Image und pusht es zu
Docker Hub.

## Prüf-Werkzeuge

`npm run lint` (ESLint + `eslint-plugin-astro`, Preset `jsx-a11y-strict`; das
Paket `eslint-plugin-jsx-a11y` braucht wegen eines veralteten
Peer-Dependency-Eintrags `npm install -D --legacy-peer-deps`). Für Voll-Scans
später ergänzbar: `pa11y-ci` über eine Sitemap oder Playwright mit
`@axe-core/playwright` — bewusst nicht vorinstalliert (eigener
Chromium-Download). Die beste Endkontrolle bleibt ein NVDA-Durchgang.
