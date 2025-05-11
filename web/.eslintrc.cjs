module.exports = {
  root: true,
  env: { browser: true, es2020: true },
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:react-hooks/recommended',
    'plugin:tailwindcss/recommended',
  ],
  ignorePatterns: ['dist', '.eslintrc.cjs'],
  parser: '@typescript-eslint/parser',
  plugins: ['react-refresh', '@typescript-eslint', 'tailwindcss'],
  rules: {
    'react-refresh/only-export-components': [
      'warn',
      { allowConstantExport: true },
    ],
    '@typescript-eslint/no-unused-vars': 'error',
    '@typescript-eslint/no-explicit-any': 'error',
  },
  overrides: [
    {
      // Disable no-explicit-any for d.ts files
      files: ["*.d.ts"],
      rules: {
        "@typescript-eslint/no-explicit-any": "off"
      }
    },
    {
      // Relax rules for backup directory
      files: ["backup/**/*.{ts,tsx}"],
      rules: {
        "@typescript-eslint/no-unused-vars": "warn",
        "react-hooks/exhaustive-deps": "warn",
      }
    }
  ],
    'tailwindcss/no-custom-classname': [
      'warn', 
      {
        'whitelist': [
          'bg-card-background',
          'filter-brass-gold',
          'focus:ring-ring',
          'focus:ring\\/',
          'text-md',
          'border-border',
          'border-border\\/',
          'border-input',
          'text-text-secondary',
          'bg-tactical-red',
          'hover:bg-tactical-red\\/90',
          'to-brass-gold\\/',
          'group-hover:to-brass-gold\\/',
          'animate-slide-in'
        ]
      }
    ],
    'tailwindcss/migration-from-tailwind-2': 'warn'
  },
} 