const defaultTheme = require('tailwindcss/defaultTheme')

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
  ],

  theme: {
    extend: {
      fontFamily: {
        sans: ['Helvetica Neue', 'Arial', ...defaultTheme.fontFamily.sans],
        semibold: ['Helvetica Neue', 'Arial', 'sans-serif'],
        bold: ['Helvetica Neue Bold', 'Arial Bold', 'sans-serif'],
        heading: ['Arial Black', 'Impact', 'Helvetica Neue Bold', 'sans-serif'],
        mono: ['Consolas', 'Monaco', 'Courier New', 'monospace'],
      },
      colors: {
        // Base PT Champion colors from iOS
        'cream': '#F4F1E6',
        'cream-dark': '#EDE9DB',
        'deep-ops': '#1E241E',
        'brass-gold': '#BFA24D',
        'army-tan': '#E0D4A6',
        'olive-mist': '#C9CCA6',
        'command-black': '#1E1E1E',
        'tactical-gray': '#4E5A48',
        'success': '#4CAF50',
        'warning': '#FF9800',
        'error': '#F44336',
        'info': '#2196F3',
        
        // Semantic colors matching iOS AppTheme
        background: "#F4F1E6",
        foreground: "#1E1E1E",
        primary: {
          DEFAULT: "#BFA24D",
          foreground: "#1E241E",
        },
        secondary: {
          DEFAULT: "#E0D4A6",
          foreground: "#1E1E1E",
        },
        destructive: {
          DEFAULT: "#F44336",
          foreground: "#FFFFFF",
        },
        muted: {
          DEFAULT: "#C9CCA6",
          foreground: "#4E5A48",
        },
        accent: {
          DEFAULT: "#BFA24D",
          foreground: "#1E241E",
        },
        card: {
          DEFAULT: "#EDE9DB",
          foreground: "#1E1E1E",
        },
      },
      borderRadius: {
        lg: "var(--radius-large)",
        md: "var(--radius-medium)",
        sm: "var(--radius-small)",
        card: 'var(--radius-card)',
        panel: 'var(--radius-panel)',
        button: 'var(--radius-button)',
        input: 'var(--radius-input)',
        badge: 'var(--radius-badge)',
        full: 'var(--radius-full)',
      },
      boxShadow: {
        'small': 'var(--shadow-small)',
        'medium': 'var(--shadow-medium)',
        'large': 'var(--shadow-large)',
      },
      fontSize: {
        'heading1': 'var(--font-size-heading1)',
        'heading2': 'var(--font-size-heading2)',
        'heading3': 'var(--font-size-heading3)',
        'heading4': 'var(--font-size-heading4)',
        'body': 'var(--font-size-body)',
        'small': 'var(--font-size-small)',
        'tiny': 'var(--font-size-tiny)',
      },
      spacing: {
        'xs': 'var(--spacing-xs)',
        'sm': 'var(--spacing-sm)',
        'md': 'var(--spacing-md)',
        'lg': 'var(--spacing-lg)',
        'section': 'var(--spacing-section)',
        'card-gap': 'var(--spacing-card-gap)',
        'content': 'var(--spacing-content-padding)',
        'item': 'var(--spacing-item)',
      },
      keyframes: {
        "accordion-down": {
          from: { height: 0 },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: 0 },
        },
        "count-up": {
          from: { opacity: 0.2, transform: 'translateY(4px)' },
          to: { opacity: 1, transform: 'translateY(0)' }
        },
        "shimmer": {
          "0%": { backgroundPosition: "-700px 0" },
          "100%": { backgroundPosition: "700px 0" }
        },
        "card-hover": {
          "0%": { borderColor: "rgba(191, 162, 77, 0.2)" },
          "100%": { borderColor: "rgba(191, 162, 77, 0.5)" }
        }
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
        "count-up": "count-up 1s ease-out forwards",
        "shimmer": "shimmer 2s infinite linear",
        "card-hover": "card-hover 0.3s ease-out forwards"
      },
      textShadow: {
        sm: '0 1px 2px var(--tw-shadow-color)',
        DEFAULT: '0 2px 4px var(--tw-shadow-color)',
        lg: '0 8px 16px var(--tw-shadow-color)',
        none: 'none',
      },
    },
  },
  plugins: [
    require("tailwindcss-animate"),
    function({ addUtilities, theme, e }) {
      const textShadows = theme('textShadow', {})
      const textShadowUtilities = Object.entries(textShadows).reduce(
        (acc, [key, value]) => {
          return {
            ...acc,
            [`.${e(`text-shadow${key === 'DEFAULT' ? '' : `-${key}`}`)}`]: {
              textShadow: value,
            },
          }
        },
        {}
      )
      addUtilities(textShadowUtilities)
    },
  ],
}

