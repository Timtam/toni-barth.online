# Baut die Astro-Site (site/) und liefert sie über nginx aus.
# Die CV-Artefakte (PDF/UA-1 + eingebettetes Resume-HTML) werden vor dem
# Docker-Build erzeugt (cv-typst/build.sh, siehe GitHub-Workflow) und liegen
# dann in site/public bzw. site/src/generated im Build-Kontext.
FROM node:24-alpine AS builder

WORKDIR /app

COPY site/package.json site/package-lock.json ./
# --omit=dev: ESLint & Co. werden im Image nicht gebraucht;
# --legacy-peer-deps wegen des eslint-plugin-jsx-a11y-Peer-Konflikts.
RUN npm ci --omit=dev --legacy-peer-deps

COPY site/ .
RUN npm run build

FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html

# nginx-Konfiguration inkl. Accept-Language-Sprachweiche auf / und
# Redirects der alten URL-Pfade
COPY nginx/default.conf /etc/nginx/conf.d/
