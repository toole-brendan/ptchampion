# PT Champion Web vs. iOS – UI Gap Analysis (2025-05-11)

This document captures the *current* delta between the SwiftUI implementation (``ios/``) and the React / Tailwind implementation (``web/``).  It will guide the subsequent sprints that bring the web experience to full design-parity with iOS.

## Methodology
* Catalogued all SwiftUI screens and major components under ``ios/ptchampion``.  
* Catalogued all React pages and components under ``web/src``.  
* Compared features, data flows, and visual treatments side-by-side using the latest Figma references.

---
## Screen-Level Parity Matrix
| Area / Screen | iOS Status | Web Status | Gap Notes |
|---------------|-----------|-----------|-----------|
| **Authentication** | Complete (`LoginView`, `RegistrationView`) | Present but older styles (`pages/auth/*`) | Needs new typography, brass-on-cream palette, error messaging, and social login buttons |
| **Dashboard** | Complete (`DashboardView`) | Present (`pages/Dashboard.tsx`) but minimal styling | Add Greeting header, QuickLink cards, metric `StatCard`s, offline sync banner |
| **Exercise Trackers** (Push-up, Pull-up, Sit-up, Run) | Complete with HUD overlay & CV feedback (`Views/Workouts/*`) | Functional but UI sparse (`pages/exercises/*`) | Implement overlay HUD, timer, rep counter, posture feedback, heart-rate chip |
| **Bluetooth / Device Scanning** | Complete (`DeviceScanningView`) | Prototype modal only (`components/DeviceScanning*`) | Build full scan list, connection state chips, empty/error states |
| **History List** | Complete (charts & streaks) | Basic table (`pages/History.tsx`) | Add inf. scroll, styled streak view, tabs for Week/Month/Year |
| **History Detail** | Complete (`WorkoutDetailView`) | Present (`pages/HistoryDetail.tsx`) | Align chart colors, typography, add share/export buttons |
| **Leaderboards** | Complete (`LeaderboardView`) | Present (`pages/Leaderboard.tsx`) but basic | Add local/global toggle, shimmer placeholders, row medals styling |
| **Profile** | Complete (Preferences, AppInfo, MoreActions) | Basic (`pages/Profile.tsx`) | Add preferences toggles, legal links, sign-out card, shareable stats badge |
| **Settings** | Complete (`SettingsView`) | Not present | Requires new page; many feature flag toggles already exist in data layer |
| **Offline Sync Indicator** | Present (`OfflineSyncStatusView`) | Missing | Add banner component hooked to React Query sync queue |

## Component-Level Gaps
* **Typography** – web still falls back to Tailwind defaults; needs Bebas Neue / Montserrat pairing and weight mappings.
* **Color Tokens** – manual duplication in ``theme.css``; will switch to *generated* CSS vars from `design-tokens` build.
* **Cards & Shadows** – iOS uses specific elevation levels; map these to Tailwind box-shadows (`card`, `card-md`, `card-lg`).
* **Spacing & Radius** – iOS `ThemeManager` defines an 8-pt grid and radius scale; ensure Tailwind `spacing` & `borderRadius` mirror.
* **Animation** – Count-up, slide, shimmer effects exist on iOS; only accordion + count-up partly ported.
* **Dark Mode** – Supported on iOS; Tailwind variables already scoped under `.dark`, but components untested.

## Non-Web Features to De-scope
* **Apple HealthKit / Health-related permissions** – iOS-only.
* **Apple Vision-specific body detection** – Web uses MediaPipe; already abstracted via hooks.
* **Bluetooth Core / BLE background scanning** – limited in browsers; keep best-effort implementation but document reduced reliability.

---
### Next Actions (for Setup & Design Foundations)
1. **Token pipeline** – finish Style Dictionary build to output `build/web/variables.css`; auto-run via `design-tokens/install-web.sh`.
2. **Tailwind alignment** – update `web/tailwind.config.cjs` to pull palette & spacing directly from generated vars.
3. **Global layouts** – finalise `<MobileLayout/>`, `<DesktopLayout/>`, `<Header/>`, and bottom-nav component skeletons.

*Document owner:* @brendantoole  |  *Last updated:* 2025-05-11 