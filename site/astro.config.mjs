// @ts-check
import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';
import htmlValidate from 'astro-html-validate';

// https://astro.build/config
export default defineConfig({
  site: 'https://toni-barth.online',

  // Die Dev-Toolbar ist ein rein visuelles Overlay (hover-aktiviert, keine
  // dokumentierte Screenreader-Bedienung). Ihre Prüf-Funktion übernehmen
  // ESLint (jsx-a11y) und pa11y/axe als Text-Ausgabe im Terminal.
  devToolbar: { enabled: false },

  integrations: [
    mdx(),
    // Erzeugt beim Build /sitemap-index.xml (+ Teil-Sitemaps) inklusive
    // hreflang-Sprachalternativen; referenziert aus public/robots.txt.
    sitemap({
      i18n: {
        defaultLocale: 'en',
        locales: { en: 'en', de: 'de' },
      },
    }),
    // Validiert beim Build jede erzeugte Seite (kaputtes Markup beschädigt
    // den Accessibility-Tree); Regeln in .htmlvalidate.json
    htmlValidate(),
  ],

  i18n: {
    locales: ['en', 'de'],
    defaultLocale: 'en',
    routing: {
      // Beide Sprachen bekommen ein URL-Präfix (/en/…, /de/…), damit jede
      // Sprache garantiert fest verlinkbar ist. Die Wurzel `/` bleibt ein
      // neutraler Einstieg: in Produktion macht nginx dort den
      // Accept-Language-Redirect, als Fallback dient src/pages/index.astro.
      prefixDefaultLocale: true,
      redirectToDefaultLocale: false,
    },
  },
});
