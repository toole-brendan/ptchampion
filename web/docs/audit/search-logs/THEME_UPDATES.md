# Brass & Cream Design System Implementation

## Overview
This document outlines the implementation of the "Brass & Cream" design system for PT Champion web application. The design system emphasizes a cream background with brass accents, Futura typography, and military-inspired aesthetics.

## Color Palette
The palette includes:
- `cream`: #F4F1E6 - Light Background
- `cream-dark`: #EDE9DB - Slightly darker cream for panels
- `brass-gold`: #BFA24D - Accent/Highlight color
- `deep-ops`: #1E241E - Primary Dark Background
- `hunter-green`: #355E3B - Deep green-ish text (added for text contrast)
- `army-tan`: #E0D4A6 - Button/Text Highlight
- `olive-mist`: #C9CCA6 - Chart Fill
- `command-black`: #1E1E1E - Primary Text
- `tactical-gray`: #4E5A48 - Secondary Text

## Typography
- Primary Font: Futura (with appropriate fallbacks)
- Headings: Futura Bold with tracking-wide
- Body Text: Tactical gray color for muted text on cream background
- All elements have smooth color transitions (transition-colors duration-200) for a cinematic feel

## Implementation Details
The design system is implemented across:
1. `tailwind.config.cjs` - Contains all color definitions, typography, border radius, spacing, etc.
2. `src/index.css` - Global styles (@layer base) for typography, backgrounds, transitions
3. `src/components/ui/theme.css` - CSS variables for shadcn/ui component theming
4. `index.html` - Early CSS application via class attributes for a flash-free initial load

## Usage Guidelines
- Use `text-hunter-green` for primary text content
- Use `text-tactical-gray` for secondary or muted text content
- Use `bg-cream` for page backgrounds and `bg-cream-dark` for card backgrounds
- Buttons use `brass-gold` for primary actions
- All components should have smooth transitions for hover/focus states

## Updates Summary
1. Added `hunter-green` (#355E3B) to support design spec requirement for deep green text
2. Ensured consistent typographical scale throughout the application
3. Added global transition effects for better hover/focus interactions
4. Removed Inter font dependency in favor of self-hosted Futura
5. Updated Storybook stories to use cream backgrounds for consistent preview

Last Updated: May 2023 