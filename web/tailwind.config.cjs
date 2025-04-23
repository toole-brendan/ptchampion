const defaultTheme = require('tailwindcss/defaultTheme')

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: {
        sans: ['Montserrat', ...defaultTheme.fontFamily.sans],
        heading: ['Bebas Neue', 'sans-serif'],
        mono: ['Roboto Mono', 'monospace'],
      },
      colors: {
        // PT Champion Style Guide V2 colors using CSS variables
        'cream': 'hsl(var(--color-cream))',
        'cream-dark': 'hsl(var(--color-cream-dark))',
        'deep-ops': 'hsl(var(--color-deep-ops))',
        'brass-gold': 'hsl(var(--color-brass-gold))',
        'army-tan': 'hsl(var(--color-army-tan))',
        'olive-mist': 'hsl(var(--color-olive-mist))',
        'command-black': 'hsl(var(--color-command-black))',
        'tactical-gray': 'hsl(var(--color-tactical-gray))',
        
        // shadcn/ui theme colors (mapped to CSS variables)
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
        card: '12px',
        panel: '16px',
      },
      boxShadow: {
        'card': '0 2px 4px rgba(0, 0, 0, 0.05)',
        'card-md': '0 4px 6px rgba(0, 0, 0, 0.07)',
        'card-lg': '0 6px 12px rgba(0, 0, 0, 0.1)',
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
        }
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
        "count-up": "count-up 1s ease-out forwards",
      },
      textShadow: {
        sm: '0 1px 2px var(--tw-shadow-color)',
        DEFAULT: '0 2px 4px var(--tw-shadow-color)',
        lg: '0 8px 16px var(--tw-shadow-color)',
        none: 'none',
      },
      spacing: {
        'section': '2rem',
        'card-gap': '1rem',
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

