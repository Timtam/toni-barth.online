import eslintPluginAstro from 'eslint-plugin-astro';

export default [
  { ignores: ['dist/', '.astro/', 'node_modules/'] },
  ...eslintPluginAstro.configs.recommended,
  // Ports the well-known jsx-a11y accessibility rules to .astro files
  // (strict variant). Errors appear as text in the terminal/editor.
  ...eslintPluginAstro.configs['jsx-a11y-strict'],
  {
    // Enable parsing TypeScript in .astro frontmatter
    files: ['**/*.astro'],
    languageOptions: {
      parserOptions: {
        parser: '@typescript-eslint/parser',
        extraFileExtensions: ['.astro'],
      },
    },
  },
];
