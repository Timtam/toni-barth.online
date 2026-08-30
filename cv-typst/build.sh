#!/usr/bin/env bash
# Baut das CV aus cv/<lang>.json in beide Zielformate:
#   PDF (PDF/UA-1 + PDF/A-2a) -> site/public/
#   HTML (semantisch)         -> site/src/generated/ (bindet /en/resume/ ein)
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p site/src/generated

typst compile --root . --font-path cv-typst/fonts --pdf-standard ua-1,a-2a \
  cv-typst/cv-en.typ site/public/CV_Toni_Barth.pdf
typst compile --root . --font-path cv-typst/fonts --features html --format html \
  cv-typst/cv-en.typ site/src/generated/resume-en.html
echo "EN: PDF + HTML gebaut."

if [ -f cv/de.json ]; then
  typst compile --root . --font-path cv-typst/fonts --pdf-standard ua-1,a-2a \
    cv-typst/cv-de.typ site/public/CV_Toni_Barth_DE.pdf
  typst compile --root . --font-path cv-typst/fonts --features html --format html \
    cv-typst/cv-de.typ site/src/generated/resume-de.html
  echo "DE: PDF + HTML gebaut."
else
  echo "DE übersprungen (cv/de.json existiert noch nicht)."
fi
