// @ts-check
import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';
import htmlValidate from 'astro-html-validate';

// https://astro.build/config
export default defineConfig({
  site: 'https://toni-barth.online',

  // The dev toolbar is a purely visual overlay (hover-activated, no
  // documented screen reader interaction). Its audit role is covered by
  // ESLint (jsx-a11y) and pa11y/axe as text output in the terminal.
  devToolbar: { enabled: false },

  integrations: [
    mdx(),
    // Generates /sitemap-index.xml (+ partial sitemaps) at build time,
    // including hreflang language alternates; referenced from
    // public/robots.txt.
    sitemap({
      i18n: {
        defaultLocale: 'en',
        locales: { en: 'en', de: 'de' },
      },
    }),
    // Validates every generated page at build time (broken markup damages
    // the accessibility tree); rules live in .htmlvalidate.json
    htmlValidate(),
  ],

  i18n: {
    locales: ['en', 'de'],
    defaultLocale: 'en',
    routing: {
      // Both languages get a URL prefix (/en/…, /de/…) so every language is
      // guaranteed to be firmly linkable. The root `/` stays a neutral entry
      // point: in production nginx performs the Accept-Language redirect
      // there, with src/pages/index.astro as the fallback.
      prefixDefaultLocale: true,
      redirectToDefaultLocale: false,
    },
  },
});
