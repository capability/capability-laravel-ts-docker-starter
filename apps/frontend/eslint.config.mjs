import js from '@eslint/js';
import prettier from 'eslint-config-prettier';
import globals from 'globals';
import pluginImport from 'eslint-plugin-import';

export default [
  js.configs.recommended,
  prettier,
  {
    files: ['**/*.{ts,tsx,js}'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: { ...globals.browser, ...globals.es2023 }
    },
    plugins: { import: pluginImport },
    rules: {
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      'import/order': ['warn', { 'newlines-between': 'always', alphabetize: { order: 'asc' } }]
    }
  }
];

