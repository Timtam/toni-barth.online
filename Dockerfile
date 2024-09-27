FROM node:20-alpine AS cv

WORKDIR /app

ENV CHROME_BIN="/usr/bin/chromium-browser" \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD="true"

RUN apk update \
    && apk upgrade \
    && apk add --no-cache \
    chromium

COPY cv/* .

RUN npm i --only=dev

RUN npm run render -- en.json --output en.html --theme jsonresume-theme-kendall && \
    npm run html-to-pdf -- en.html en.pdf

FROM python:3.12 AS builder

# Copy the whole repository into Docker container
COPY toni-barth.online/ . 

# copy pre-built resume

COPY --from=cv /app/en.html ./pages/resume.html
COPY --from=cv /app/en.pdf ./files/CV_Toni_Barth.pdf

# Build the blog
RUN pip install nikola jinja2 \
    && nikola build

FROM nginx:alpine

# Copy output to the default nginx directory
COPY --from=builder output /usr/share/nginx/html

# Copy nginx host configuration
COPY nginx/default.conf /etc/nginx/conf.d/
