# PT Champion Web Module Styling Migration Guide

This guide documents the comprehensive styling updates made to bring the web module in line with the iOS module's design system. These changes establish a consistent military-themed design language across both platforms.

## Table of Contents

1. [Overview](#overview)
2. [New Design Token System](#new-design-token-system)
3. [Updated Tailwind Configuration](#updated-tailwind-configuration)
4. [Component Updates](#component-updates)
5. [New Components](#new-components)
6. [Migration Guide](#migration-guide)
7. [Usage Examples](#usage-examples)
8. [Best Practices](#best-practices)

## Overview

The web module has been updated with:
- **Comprehensive design token system** matching iOS color schemes and spacing
- **Enhanced components** with loading states, animations, and haptic feedback
- **Military-themed UI elements** including corner-cut cards and specialized badges
- **Improved accessibility** with ARIA attributes and keyboard navigation
- **Responsive design patterns** with adaptive spacing and breakpoints

## New Design Token System

### File: `web/src/styles/design-tokens.css`

This file establishes CSS custom properties for consistent theming:

#### Color Tokens
```css
/* Base Colors */
--color-cream: #F4F1E6;
--color-cream-dark: #EDE9DB;
--color-deep-ops: #1E241E;
--color-brass-gold: #BFA24D;
--color-army-tan: #E0D4A6;
--color-olive-mist: #C9CCA6;
--color-command-black: #1E1E1E;
--color-tactical-gray: #4E5A48;

/* Semantic Colors */
--color-primary: var(--color-brass-gold);
--color-secondary: var(--color-army-tan);
--color-background: var(--color-cream);
--color-card-background: var(--color-cream-dark);
```

#### Typography Tokens
```css
--font-size-heading1: 40px;
--font-size-heading2: 32px;
--font-size-heading3: 26px;
--font-size-heading4: 22px;
--font-size-body: 16px;
--font-size-small: 14px;
--font-size-tiny: 12px;
```

#### Spacing Tokens
```css
--spacing-xs: 4px;
--spacing-sm: 8px;
--spacing-md: 16px;
--spacing-lg: 24px;
--spacing-xl: 32px;
--spacing-section: 32px;
--spacing-adaptive: /* Responsive */
```

#### Animation Tokens
```css
--animation-duration-fast: 100ms;
--animation-duration-base: 200ms;
--animation-duration-slow: 300ms;
--animation-easing-default: cubic-bezier(0.4, 0, 0.2, 1);
--animation-easing-spring: cubic-bezier(0.68, -0.55, 0.265, 1.55);
```

### Integration
Add to `main.tsx`:
```tsx
import './styles/design-tokens.css';
```

## Updated Tailwind Configuration

### File: `web/tailwind.config.cjs`

Key updates include:

1. **Colors linked to CSS variables**:
```js
colors: {
  'cream': 'var(--color-cream)',
  'brass-gold': 'var(--color-brass-gold)',
  // ... etc
}
```

2. **New animations**:
```js
animation: {
  "press": "press var(--animation-duration-fast)",
  "spring": "spring var(--animation-duration-slow)",
  // ... etc
}
```

3. **Responsive spacing**:
```js
spacing: {
  'adaptive': 'var(--spacing-adaptive)',
  // ... etc
}
```

## Component Updates

### Enhanced Button Component

**File**: `web/src/components/ui/button.tsx`

#### New Features:
- **Loading state** with spinner animation
- **Icon support** with proper sizing
- **Press animations** with haptic feedback
- **Audio feedback** using Web Audio API
- **Multiple variants**: primary, secondary, outline, ghost, destructive
- **Size variants**: small, medium, large, icon

#### Key Changes:
```tsx
interface ButtonProps {
  loading?: boolean
  icon?: React.ReactNode
  // ... other props
}

// Usage
<Button loading={isLoading} icon={<IconComponent />}>
  Submit
</Button>
```

### Enhanced Card Component

**File**: `web/src/components/ui/card.tsx`

#### New Features:
- **Military variant** with corner cuts
- **Interactive states** with press animations
- **Gradient backgrounds**
- **New composite components**: StatCard, QuickLinkCard, SectionCard, WelcomeCard
- **Enhanced variants**: standard, elevated, flat, highlight, military

#### Usage:
```tsx
// Military-style card
<Card variant="military">
  <CardContent>Military styled content</CardContent>
</Card>

// Stat card
<StatCard 
  title="Total Pushups" 
  value="150" 
  icon={<PushupIcon />} 
/>
```

## New Components

### 1. Military Card Background
**File**: `web/src/components/ui/military-card-background.tsx`

Provides the distinctive corner-cut military styling:
```tsx
<MilitaryCardBackground 
  cornerSize={15} 
  borderColor="var(--color-tactical-gray)"
/>
```

### 2. Label Component
**File**: `web/src/components/ui/label.tsx`

Form labels with variants and required indicators:
```tsx
<Label required variant="default">
  Username
</Label>
```

### 3. TextField Component
**File**: `web/src/components/ui/text-field.tsx`

Enhanced input component with:
- Label integration
- Error states
- Helper text
- Military variant

```tsx
<TextField
  label="Service Number"
  error={hasError}
  errorMessage="Invalid format"
  required
  fullWidth
/>
```

### 4. Section Container
**File**: `web/src/components/ui/section-container.tsx`

Layout components for consistent spacing:
```tsx
<SectionContainer spacing="large" padding="content">
  <HeroSection>Hero content</HeroSection>
  <ContentSection>Main content</ContentSection>
  <GridSection columns={{ sm: 1, md: 2, lg: 3 }}>
    Grid items
  </GridSection>
</SectionContainer>
```

### 5. Separator Component
**File**: `web/src/components/ui/separator.tsx`

Dividers with military styling:
```tsx
<Separator variant="gradient" />
<MilitarySeparator />
<BrassSeparator />
```

### 6. Badge Component
**File**: `web/src/components/ui/badge.tsx`

Status indicators with specialized variants:
```tsx
<Badge variant="military">ACTIVE DUTY</Badge>
<RankBadge rank="SGT" />
<StatusBadge status="active" />
<CountBadge count={42} />
```

### 7. Loading Indicator
**File**: `web/src/components/ui/loading-indicator.tsx`

Multiple loading animations:
```tsx
<LoadingIndicator variant="military" size="large" />
<LoadingOverlay fullScreen />
<SkeletonLoader variant="text" />
```

## Migration Guide

### Step 1: Update Imports

Replace old component imports:
```tsx
// Old
import { Button } from './components/Button'

// New
import { Button } from '@/components/ui/button'
```

### Step 2: Update Component Usage

#### Buttons
```tsx
// Old
<button className="btn-primary">Click</button>

// New
<Button variant="primary">Click</Button>
```

#### Cards
```tsx
// Old
<div className="card">Content</div>

// New
<Card variant="default">
  <CardContent>Content</CardContent>
</Card>
```

### Step 3: Replace Color Classes

```tsx
// Old
className="bg-yellow-600 text-gray-900"

// New
className="bg-brass-gold text-command-black"
```

### Step 4: Update Spacing

```tsx
// Old
className="p-4 m-2"

// New
className="p-content m-sm"
```

## Usage Examples

### Dashboard Layout
```tsx
import { SectionContainer, ContentSection } from '@/components/ui/section-container'
import { WelcomeCard, StatCard } from '@/components/ui/card'
import { Button } from '@/components/ui/button'

export function Dashboard() {
  return (
    <SectionContainer spacing="large">
      <ContentSection>
        <WelcomeCard 
          title="PT Champion"
          subtitle="Fitness Evaluation System"
        />
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-card-gap">
          <StatCard title="Push-ups" value="75" />
          <StatCard title="Sit-ups" value="82" />
          <StatCard title="Run Time" value="13:30" />
        </div>
        
        <Button variant="primary" fullWidth>
          Start Workout
        </Button>
      </ContentSection>
    </SectionContainer>
  )
}
```

### Form Example
```tsx
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { TextField } from '@/components/ui/text-field'
import { Button } from '@/components/ui/button'

export function LoginForm() {
  return (
    <Card variant="elevated">
      <CardHeader>
        <CardTitle>Sign In</CardTitle>
      </CardHeader>
      <CardContent>
        <form className="space-y-4">
          <TextField
            label="Service Number"
            required
            fullWidth
          />
          <TextField
            label="Password"
            type="password"
            required
            fullWidth
          />
          <Button variant="primary" fullWidth loading={isLoading}>
            Authenticate
          </Button>
        </form>
      </CardContent>
    </Card>
  )
}
```

### Military-Styled Component
```tsx
import { Card } from '@/components/ui/card'
import { MilitarySeparator } from '@/components/ui/separator'
import { RankBadge } from '@/components/ui/badge'

export function ServiceMemberCard({ member }) {
  return (
    <Card variant="military">
      <div className="flex justify-between items-center mb-4">
        <h3 className="font-heading text-lg uppercase">
          {member.name}
        </h3>
        <RankBadge rank={member.rank} />
      </div>
      
      <MilitarySeparator />
      
      <div className="mt-4 space-y-2">
        <p className="text-sm text-tactical-gray">
          Unit: {member.unit}
        </p>
        <p className="text-sm text-tactical-gray">
          MOS: {member.mos}
        </p>
      </div>
    </Card>
  )
}
```

## Best Practices

### 1. Use Design Tokens
Always use CSS variables or Tailwind classes that reference design tokens:
```tsx
// Good
className="text-brass-gold bg-cream"

// Avoid
className="text-[#BFA24D] bg-[#F4F1E6]"
```

### 2. Consistent Spacing
Use spacing tokens for consistent layouts:
```tsx
// Good
className="p-content space-y-section"

// Avoid
className="p-4 space-y-8"
```

### 3. Responsive Design
Leverage adaptive spacing and responsive utilities:
```tsx
<div className="p-adaptive grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
```

### 4. Accessibility
Always include proper ARIA attributes:
```tsx
<Button 
  aria-label="Submit form" 
  disabled={!isValid}
>
  Submit
</Button>
```

### 5. Loading States
Provide feedback for async operations:
```tsx
<Button loading={isSubmitting}>
  {isSubmitting ? 'Processing...' : 'Submit'}
</Button>
```

### 6. Component Composition
Build complex UIs using component composition:
```tsx
<Card variant="elevated">
  <CardHeader>
    <CardTitle>Mission Status</CardTitle>
    <CardAction>
      <IconButton size="sm">
        <MoreIcon />
      </IconButton>
    </CardAction>
  </CardHeader>
  <CardContent>
    {/* Content */}
  </CardContent>
</Card>
```

## Dark Mode Support

The design tokens include dark mode support:
```css
[data-theme="dark"] {
  --color-background: var(--color-deep-ops);
  --color-card-background: var(--color-command-black);
  --color-text-primary: var(--color-cream);
  /* ... etc */
}
```

To enable dark mode, add `data-theme="dark"` to the root element.

## Performance Considerations

1. **CSS Variables** are computed at runtime, providing flexibility but with minimal performance impact
2. **Tailwind Purging** ensures only used classes are included in production
3. **Component Lazy Loading** can be implemented for heavy components:
```tsx
const MilitaryCard = lazy(() => import('./components/ui/card'))
```

## Troubleshooting

### Common Issues

1. **Colors not applying**: Ensure design-tokens.css is imported before other styles
2. **Animations not working**: Check that animation utilities are properly configured in Tailwind
3. **TypeScript errors**: Ensure all component props interfaces are properly exported

### Debug Helpers

Add these classes for debugging layout issues:
```tsx
// Show element boundaries
className="debug-border"

// Show spacing
className="debug-spacing"
```

## Future Enhancements

Planned improvements include:
- Additional animation presets
- More loading indicator variants
- Enhanced form validation components
- Data visualization components matching military theme
- Expanded icon set

## Resources

- [iOS Module Reference](../ios/)
- [Design Tokens Source](../design-tokens/)
- [PT Champion Style Guide](../docs/STYLE_GUIDE.md)
