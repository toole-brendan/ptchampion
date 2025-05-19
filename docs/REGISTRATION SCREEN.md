REGISTRATION SCREEN
==========================================

LAYOUT
------

+----------------------------------------------+
|                PT Champion                   |
|                                              |
|                                              |
|  [ Full name ]                               |
|  [ Email address ]                           |
|  [ Password        👁 ]                      |
|  [ Confirm password 👁 ]                     |
|                                              |
|  Role:  ● Military   ○ Civilian              |
|  ▸ If "Military" selected:                   |
|       [ Branch ▼ ]  [ Rank ▼ ]               |
|       [ Unit / Base (optional) ]             |
|                                              |
|  Group invite code   (?)  [____________]     |
|                                              |
|  Password strength  ▂▂▂▂▂ weak               |
|                                              |
|  ☐  I agree to the  Terms  &  Privacy Policy |
|                                              |
|  +-----------------------------------+       |
|  |   Create account                  |       |
|  +-----------------------------------+       |
|                                              |
|  Already have an account?  →  Log in         |
+----------------------------------------------+

Mobile: single scroll view; CTA stays above keyboard with safe-area insets
Web ≥ md breakpoint: 460px card


FIELD & COMPONENT DETAILS
-------------------------

FULL NAME
- Optional on web (many soldiers enter "Rank Last-name")
- Required on mobile to reduce empty leaderboards
- Autofocus if browser supplies OS name

EMAIL
- Realtime validation (regex + MX ping)
- Inline error in Safety-Orange

PASSWORD + CONFIRM
- Minimum 8 chars, 1 capital, 1 number
- Password meter bars (Army Green scale) animate as user types
- Eye toggle with 5s auto-re-hide

ROLE SELECTOR
- Two large radio cards
- Choosing "Military" reveals branch/rank dropdowns (pre-populated lists)
- If "Civilian" chosen, those inputs collapse with smooth 200ms height animation

GROUP INVITE CODE
- One-line field with tiny "?" tooltip explaining:
  "If you were given a unit/gym code, enter it to join that private leaderboard."
- No code? ignore

AGREEMENT CHECKBOX
- Link opens modal for ToS
- Button disabled until checked (tooltip on hover: "Please accept terms")

CREATE ACCOUNT BUTTON
- Army-green fill, white uppercase text, 100% width
- Disabled = 30% opacity
- On submit morphs into progress bar


MICRO-INTERACTIONS & VALIDATION FLOW
------------------------------------

REAL-TIME VALIDATION
- Red outline & message appear only after blur to avoid premature scolding
- Password meter text changes ("weak → fair → strong → champion") with upbeat tone

BRANCH/RANK PICKERS
- Large scroll-wheel (iOS) or Material dropdown (Android)
- Default = "Army / Specialist"
- Always includes "Other / N/A" so civilians picking Military by mistake aren't blocked

ON SUBMIT
- Client-side check → button morphs to slim 3px Army-green progress bar (300ms)
- If API returns error (email taken), whole card shakes horizontally 1×
- Inline message "Email already registered." appears in orange under email field

OFFLINE SUPPORT
- If device offline, CTA disabled
- Toast: "No internet. Try again when online or train in offline mode →"
- Clicking arrow jumps to offline onboarding (local account with later merge)

ACCESSIBILITY
- All form controls aria-labeled
- Contrast ≥ AA
- Keyboard navigation order top-to-bottom
- Auto-advancing focus when user taps "Next" on mobile keyboard


FAIR-DATA MESSAGING
------------------
Sub-footer copy (10pt center-aligned):
"We only rank workouts when you decide. All personal data encrypted at rest; see Security FAQ."