// Local test server without dependencies: serves dist/ and mirrors the
// language switch from nginx/default.conf exactly, so the Accept-Language
// redirect can be experienced without Docker/nginx.
// Start: npm run preview:language-switch
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

// Old Nikola URLs (used to live without a prefix): bilingual pages negotiate
// the language, English-only ones go straight to /en/ (mirror of
// nginx/default.conf)
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

  // The language switch: only on the bare start page
  if (path === '/') {
    const acceptLanguage = req.headers['accept-language'] ?? '';
    const target = /^de/i.test(acceptLanguage) ? '/de/' : '/en/';
    console.log(`302 / -> ${target} (Accept-Language: ${acceptLanguage || 'not set'})`);
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

  // Map directory URLs to index.html (nginx does the same)
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
      .end('404 - not found');
  }
}).listen(port, () => {
  console.log(`Language-switch preview running at http://localhost:${port}/`);
  console.log('Stop with Ctrl+C.');
});
