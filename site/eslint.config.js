import eslintPluginAstro from 'eslint-plugin-astro';

export default [
  { ignores: ['dist/', '.astro/', 'node_modules/'] },
  ...eslintPluginAstro.configs.recommended,
  // Portiert die bekannten jsx-a11y-Barrierefreiheitsregeln auf .astro-Dateien
  // (strenge Variante). Fehler erscheinen als Text im Terminal/Editor.
  ...eslintPluginAstro.configs['jsx-a11y-strict'],
  {
    // TypeScript im Frontmatter der .astro-Dateien parsen können
    files: ['**/*.astro'],
    languageOptions: {
      parserOptions: {
        parser: '@typescript-eslint/parser',
        extraFileExtensions: ['.astro'],
      },
    },
  },
];
