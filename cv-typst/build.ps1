# Baut das CV aus cv/<lang>.json in beide Zielformate:
#   PDF (PDF/UA-1 + PDF/A-2a) -> site/public/
#   HTML (semantisch)         -> site/src/generated/ (bindet /en/resume/ ein)
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

New-Item -ItemType Directory -Force site/src/generated | Out-Null

typst compile --root . --font-path cv-typst/fonts --pdf-standard ua-1,a-2a `
  cv-typst/cv-en.typ site/public/CV_Toni_Barth.pdf
typst compile --root . --font-path cv-typst/fonts --features html --format html `
  cv-typst/cv-en.typ site/src/generated/resume-en.html
Write-Output "EN: PDF + HTML gebaut."

if (Test-Path cv/de.json) {
  typst compile --root . --font-path cv-typst/fonts --pdf-standard ua-1,a-2a `
    cv-typst/cv-de.typ site/public/CV_Toni_Barth_DE.pdf
  typst compile --root . --font-path cv-typst/fonts --features html --format html `
    cv-typst/cv-de.typ site/src/generated/resume-de.html
  Write-Output "DE: PDF + HTML gebaut."
} else {
  Write-Output "DE übersprungen (cv/de.json existiert noch nicht)."
}
