# Builds the CV from cv/<lang>.json into both target formats:
#   PDF (PDF/UA-1 + PDF/A-2a) -> site/public/
#   HTML (semantic)           -> site/src/generated/ (embedded by /en/resume/)
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

New-Item -ItemType Directory -Force site/src/generated | Out-Null

typst compile --root . --font-path cv-typst/fonts --pdf-standard ua-1,a-2a `
  cv-typst/cv-en.typ site/public/CV_Toni_Barth.pdf
typst compile --root . --font-path cv-typst/fonts --features html --format html `
  cv-typst/cv-en.typ site/src/generated/resume-en.html
Write-Output "EN: built PDF + HTML."

if (Test-Path cv/de.json) {
  typst compile --root . --font-path cv-typst/fonts --pdf-standard ua-1,a-2a `
    cv-typst/cv-de.typ site/public/CV_Toni_Barth_DE.pdf
  typst compile --root . --font-path cv-typst/fonts --features html --format html `
    cv-typst/cv-de.typ site/src/generated/resume-de.html
  Write-Output "DE: built PDF + HTML."
} else {
  Write-Output "DE skipped (cv/de.json does not exist yet)."
}
