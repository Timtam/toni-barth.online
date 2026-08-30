// Lokaler Testserver ohne Abhängigkeiten: serviert dist/ und bildet exakt die
// Sprachweiche aus nginx/default.conf nach, damit der Accept-Language-Redirect
// auch ohne Docker/nginx erlebbar ist. Start: npm run preview:sprachweiche
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const dist = fileURLToPath(new URL('../dist/', import.meta.url));
const port = 8080;

const types = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.jpg': 'image/jpeg',
  '.png': 'image/png',
  '.ico': 'image/x-icon',
  '.txt': 'text/plain; charset=utf-8',
};

// Alte Nikola-URLs (lagen ohne Präfix): zweisprachige Seiten verhandeln die
// Sprache, nur-englische gehen fest nach /en/ (Spiegel von nginx/default.conf)
const legacyBilingual = /^\/(teaching|gear|contact|support|privacy-policy)(\/|$)/;
const legacyEnglishOnly = /^\/(music|resume)(\/|$)/;

createServer(async (req, res) => {
  let path;
  try {
    path = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
  } catch {
    res.writeHead(400).end('Bad request');
    return;
  }
  if (path.includes('..')) {
    res.writeHead(400).end('Bad request');
    return;
  }

  // Die Sprachweiche: nur auf der nackten Startseite
  if (path === '/') {
    const acceptLanguage = req.headers['accept-language'] ?? '';
    const target = /^de/i.test(acceptLanguage) ? '/de/' : '/en/';
    console.log(`302 / -> ${target} (Accept-Language: ${acceptLanguage || 'nicht gesetzt'})`);
    res.writeHead(302, { Location: target, Vary: 'Accept-Language' }).end();
    return;
  }

  if (legacyBilingual.test(path)) {
    const acceptLanguage = req.headers['accept-language'] ?? '';
    const prefix = /^de/i.test(acceptLanguage) ? '/de' : '/en';
    res.writeHead(302, { Location: prefix + path, Vary: 'Accept-Language' }).end();
    return;
  }
  if (legacyEnglishOnly.test(path)) {
    res.writeHead(301, { Location: '/en' + path }).end();
    return;
  }

  // Verzeichnis-URLs auf index.html abbilden (macht nginx genauso)
  if (!path.endsWith('/') && !extname(path)) {
    res.writeHead(301, { Location: path + '/' }).end();
    return;
  }
  if (path.endsWith('/')) path += 'index.html';

  try {
    const file = await readFile(join(dist, path));
    res
      .writeHead(200, {
        'Content-Type': types[extname(path)] ?? 'application/octet-stream',
      })
      .end(file);
  } catch {
    res
      .writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' })
      .end('404 – nicht gefunden');
  }
}).listen(port, () => {
  console.log(`Sprachweiche-Preview läuft auf http://localhost:${port}/`);
  console.log('Beenden mit Strg+C.');
});
