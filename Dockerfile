# Builds the CV (Typst) and the Astro site, served by nginx.

# ---- CV stage: resume as PDF/UA-1+A-2a and semantic HTML -------------------
# Pinned to the build platform: the CV artifacts are architecture-independent,
# so in a multi-arch build Typst runs natively exactly once instead of once
# per target architecture under QEMU.
FROM --platform=$BUILDPLATFORM alpine:3.20 AS cv

# Pinned to the locally tested version: Typst's HTML export is officially
# experimental, so no unreviewed version jumps.
ARG TYPST_VERSION=0.15.1
ARG BUILDARCH

RUN apk add --no-cache bash curl xz
RUN case "$BUILDARCH" in \
      amd64) TYPST_ARCH=x86_64 ;; \
      arm64) TYPST_ARCH=aarch64 ;; \
      *) echo "Unsupported build architecture: $BUILDARCH" && exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-${TYPST_ARCH}-unknown-linux-musl.tar.xz" \
      | tar -xJ -C /usr/local/bin --strip-components=1 "typst-${TYPST_ARCH}-unknown-linux-musl/typst"

WORKDIR /app
COPY cv/ cv/
COPY cv-typst/ cv-typst/
# The template embeds the profile photo from the site's asset directory
# (single source shared with the web pages).
COPY site/src/assets/ site/src/assets/
RUN mkdir -p site/public site/src/generated && bash cv-typst/build.sh

# ---- Site builder ----------------------------------------------------------
FROM node:24-alpine AS builder

WORKDIR /app

COPY site/package.json site/package-lock.json ./
# --omit=dev: ESLint and friends are not needed inside the image;
# --legacy-peer-deps because of the eslint-plugin-jsx-a11y peer conflict.
RUN npm ci --omit=dev --legacy-peer-deps

COPY site/ .
# Lay the freshly built CV artifacts over any committed copies
COPY --from=cv /app/site/public/ public/
COPY --from=cv /app/site/src/generated/ src/generated/
RUN npm run build

FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html

# nginx configuration including the Accept-Language switch on / and
# redirects for the old URL paths
COPY nginx/default.conf /etc/nginx/conf.d/
