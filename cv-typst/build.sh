#!/usr/bin/env bash
# Builds the CV from cv/<lang>.json into both target formats:
#   PDF (PDF/UA-1 + PDF/A-2a) -> site/public/
#   HTML (semantic)           -> site/src/generated/ (embedded by /en/resume/)
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p site/src/generated

typst compile --root . --font-path cv-typst/fonts --pdf-standard ua-1,a-2a \
  cv-typst/cv-en.typ site/public/CV_Toni_Barth.pdf
typst compile --root . --font-path cv-typst/fonts --features html --format html \
  cv-typst/cv-en.typ site/src/generated/resume-en.html
echo "EN: built PDF + HTML."

if [ -f cv/de.json ]; then
  typst compile --root . --font-path cv-typst/fonts --pdf-standard ua-1,a-2a \
    cv-typst/cv-de.typ site/public/CV_Toni_Barth_DE.pdf
  typst compile --root . --font-path cv-typst/fonts --features html --format html \
    cv-typst/cv-de.typ site/src/generated/resume-de.html
  echo "DE: built PDF + HTML."
else
  echo "DE skipped (cv/de.json does not exist yet)."
fi
