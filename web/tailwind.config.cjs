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
        sans: ['Futura', 'Futura Fallback', ...defaultTheme.fontFamily.sans],
        semibold: ['Futura', 'Futura Fallback', 'sans-serif'],
        bold: ['Futura', 'Futura Fallback', 'sans-serif'],
        heading: ['Futura', 'Futura Fallback', 'sans-serif'],
        mono: ['Consolas', 'Monaco', 'Courier New', 'monospace'],
      },
      colors: {
        // Base PT Champion colors from CSS variables
        'cream': 'var(--color-cream)',
        'cream-dark': 'var(--color-cream-dark)',
        'cream-light': '#FAF8F1',
        'deep-ops': 'var(--color-deep-ops)',
        'brass-gold': 'var(--color-brass-gold)',
        'army-tan': 'var(--color-army-tan)',
        'olive-mist': 'var(--color-olive-mist)',
        'command-black': 'var(--color-command-black)',
        'tactical-gray': 'var(--color-tactical-gray)',
        'hunter-green': '#355E3B',
        'success': 'var(--color-success)',
        'warning': 'var(--color-warning)',
        'error': 'var(--color-error)',
        'info': 'var(--color-info)',
        
        // Semantic colors from CSS variables
        background: "var(--color-background)",
        foreground: "var(--color-text-primary)",
        primary: {
          DEFAULT: "var(--color-primary)",
          foreground: "var(--color-text-on-primary)",
        },
        secondary: {
          DEFAULT: "var(--color-secondary)",
          foreground: "var(--color-text-primary)",
        },
        destructive: {
          DEFAULT: "var(--color-error)",
          foreground: "#FFFFFF",
        },
        muted: {
          DEFAULT: "var(--color-olive-mist)",
          foreground: "var(--color-tactical-gray)",
        },
        accent: {
          DEFAULT: "var(--color-accent)",
          foreground: "var(--color-text-on-primary)",
        },
        card: {
          DEFAULT: "var(--color-card-background)",
          foreground: "var(--color-text-primary)",
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
        'card': 'var(--shadow-card)',
        'card-hover': 'var(--shadow-card-hover)',
        'button-primary': 'var(--shadow-button-primary)',
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
        'xl': 'var(--spacing-xl)',
        'section': 'var(--spacing-section)',
        'card-gap': 'var(--spacing-card-gap)',
        'content': 'var(--spacing-content-padding)',
        'item': 'var(--spacing-item)',
        'adaptive': 'var(--spacing-adaptive)',
        '15': '3.75rem', // 60px for stat card icons
        '18': '4.5rem',  // 72px for quick link icons
        '30': '7.5rem',  // 120px for separator lines
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
        },
        "pop": {
          "0%": { transform: "scale(1)" },
          "50%": { transform: "scale(1.1)" },
          "100%": { transform: "scale(1)" }
        },
        "float-up": {
          "0%": { transform: "translateY(0)" },
          "100%": { transform: "translateY(-4px)" }
        },
        "press": {
          "0%": { transform: "scale(1)" },
          "100%": { transform: "scale(var(--state-active-scale))" }
        },
        "spring": {
          "0%": { transform: "scale(1)" },
          "40%": { transform: "scale(0.97)" },
          "100%": { transform: "scale(1)" }
        },
        "fadeIn": {
          "0%": { opacity: "0", transform: "translateY(10px)" },
          "100%": { opacity: "1", transform: "translateY(0)" }
        }
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
        "count-up": "count-up 1s ease-out forwards",
        "shimmer": "shimmer 2s infinite linear",
        "card-hover": "card-hover 0.3s ease-out forwards",
        "pop": "pop 0.3s ease-out",
        "float-up": "float-up 0.3s ease-out forwards",
        "press": "press var(--animation-duration-fast) var(--animation-easing-default)",
        "spring": "spring var(--animation-duration-slow) var(--animation-easing-spring)",
        "fade-in": "fadeIn 0.4s ease-out forwards"
      },
      animationDelay: {
        '100': '100ms',
        '200': '200ms',
        '300': '300ms',
        '400': '400ms',
        '500': '500ms',
      },
      transitionDuration: {
        'fast': 'var(--animation-duration-fast)',
        'base': 'var(--animation-duration-base)',
        'slow': 'var(--animation-duration-slow)',
      },
      transitionTimingFunction: {
        'default': 'var(--animation-easing-default)',
        'spring': 'var(--animation-easing-spring)',
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
      
      // Add animation delay utilities
      const animationDelays = theme('animationDelay', {})
      const animationDelayUtilities = Object.entries(animationDelays).reduce(
        (acc, [key, value]) => {
          return {
            ...acc,
            [`.${e(`animation-delay-${key}`)}`]: {
              animationDelay: value,
            },
          }
        },
        {}
      )
      addUtilities(animationDelayUtilities)
    },
  ],
}
