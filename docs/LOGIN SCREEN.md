LOGIN SCREEN
==========================

DESIGN GOALS
------------

1. INSTANT BRAND RECOGNITION
   Logo + wordmark in primary Army Green (#5D6532) at top
   Light-gray canvas (#F5F5F5) for contrast without heaviness

2. MILITARY-INSPIRED MINIMALISM
   Generous negative space
   Crisp sans-serif text
   Two accent colors only:
     - Army Green (#5D6532) for actions
     - Safety Orange (#E55353) for errors
   No photos, just subtle geometric/camo texture (5% opacity) on desktop

3. FAST FIRST INTERACTION
   Fields and primary button above fold on all devices
   Tab order and return key submit enabled

4. ACCESSIBILITY & TRUST
   Color contrast ratio ≥4.5:1
   Clear error messaging
   Password visibility toggle
   "Secure connection" lock icon + TLS footer copy
   Optional SSO buttons


LAYOUT (MOBILE & WEB)
---------------------

+---------------------------------------------+
|               PT Champion                   |  <- wordmark in Army Green, bold
|                                             |  <- tagline in 14pt medium-gray
|                                             |
|  [ Email address / Username ]               |  <- text field, left-aligned label
|  [ Password          👁 ]                   |  <- eye toggle shows/hides password
|                                             |
|  (🔒) Forgot password?                      |  <- tiny link, same line as field on web,
|                                             |     next line on mobile for tap-target
|  +------------------------------------+     |
|  |  LOG IN                            |     |  <- 100%-width primary button,
|  +------------------------------------+     |     Army Green background, white text,
|                                             |     48px tall mobile / 40px web
|  or                                         |
|  [ A ] [ G ] [ f ]                         |  <- optional SSO icons (Apple, Google,
|                                             |     Facebook) in monochrome outline
|  --------------------------------------     |
|  New here?  →  Create account               |  <- sign-up link
+---------------------------------------------+

*All content is centered vertically on phones and desktop*


VISUAL TREATMENTS
----------------

LOGO/WORDMARK
- Stencil-cut "PT" shield icon + "Champion" in DIN Condensed (or bold SF Pro)
- Maximum height: 48px to avoid crowding the form

INPUT FIELDS
- Flat, 1px #D7D7D7 border, 10px radius
- On focus: bottom border thickens to 2px Army Green (no glow)
- Placeholders in #999

PRIMARY BUTTON
- Army Green fill
- Uppercase "LOG IN" (system medium weight)
- 4px radius
- Subtle elevation on desktop (Material elevation 2)
- Ripple effect on Android
- Disabled state: 30% opacity fill

ERROR STATE
- Field border changes to Safety Orange
- 12pt caption under field: "• Incorrect password."
- Error toast at top of card with same color for unexpected issues
  ("Network offline, retry later")

SSO BUTTONS
- Outline style (1px Army Green stroke, transparent fill)
- Icon centered, no text for minimalism
- Tooltip on hover ("Login with Google")

DARK MODE
- Background: #121212
- Card: #202020
- Fields: #2A2A2A
- Text: #EFEFEF
- Primary button: Brighter Army Green variant for adequate contrast


MICRO-INTERACTIONS & UX POLISH
------------------------------

- Return/Enter submits when both fields non-empty
- Password toggle animates (300ms fade) between obscured •••• and plain text,
  auto-re-obscures after 5 seconds for security
- After successful login, button morphs into thin progress bar (Army Green)
  for 300ms before route change, keeping UI stable and communicating activity

ADAPTIVE LAYOUT
- Phones ≤600px: Full-width edge-to-edge card, everything stacked, bottom-nav hidden
- Tablets/desktop: 480px fixed-width card, centered vertically