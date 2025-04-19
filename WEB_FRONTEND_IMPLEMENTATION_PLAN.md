# PT Champion Web‑Frontend Implementation Plan

_Last updated: May 15, 2024_

## 1 Purpose
Provide a comprehensive, step‑by‑step engineering roadmap that will bring the **web** module (React + Vite + Tailwind) to feature and UX parity with the existing iOS and Android apps, while embracing the shared PT Champion Style Guide V2.

---

## 2 Current State Snapshot
| Area | Status | Notes |
|------|--------|-------|
| Project bootstrapped with Vite React TS | ✅ | Basic routing, auth context, shadcn/ui installed |
| Styling aligned to Style Guide V2 | ✅ | Tailwind variables and components match Style Guide V2 |
| Features (Leaderboard, History, Trackers) | ⚠️ Partial | Leaderboard complete, Push-up tracker completed with MediaPipe, others pending |
| PWA / Offline | ✅ | Service Worker with caching strategies, IndexedDB for offline data |
| Device integrations (Bluetooth/GPS) | ⚠️ Partial | Geolocation for local leaderboards implemented, pose detection implemented |
| Tests & CI | ✅ | GitHub Actions with lint, type check, tests |

---

## 3 Objectives
1. Achieve functional parity with mobile apps for **core features**: Auth, Exercise Tracking & Scoring, History, Leaderboards (global & local).
2. Implement the **Brass‑on‑Cream** design system across all web views.
3. Ship as a high‑quality **Progressive Web App** (installable, offline basics).
4. Ensure maintainability via shared component library and typed API layer.

---

## 4 Assumptions & Constraints
* Single‑page app (SPA) served by Go backend at `/`.
* Backend endpoints are defined in `openapi.yaml` and considered stable.
* We target Evergreen browsers (Chrome/Edge/Firefox/Safari) + iOS 15+ Safari.
* **No** WebAssembly pose detector ready yet ↔ may require TS port or WASM build of `pkg/grading`.

---

## 5 High‑Level Architecture
```text
+--------------+          +----------------+
|  React SPA   |  HTTPS   |   Go Backend    |
|  (Vite)      | <------> |  Echo + sqlc    |
+--------------+          +----------------+
         ^                      ^
         | Service Worker       | Postgres
         v                      v
+--------------+          +----------------+
|  Cache API   |          |  DB            |
+--------------+          +----------------+
```
Key folders:
```
web/
 ├─ src/components       # shadcn/ui wraps  + custom components
 ├─ src/layouts          # <MobileLayout>, <DesktopLayout>
 ├─ src/features         # per‑domain slices (auth, leaderboard…)
 ├─ src/lib/api          # OpenAPI generated client
 └─ src/serviceWorker.ts # PWA entry
```

---

## 6 Milestones & Timeline *(6 bi‑weekly sprints = 12 weeks)*
| Sprint | Theme | High‑Level Deliverables | Status |
|--------|-------|-------------------------|--------|
| 0  | Setup | Finalise this plan, create tickets, add Storybook, baseline CI | ✅ COMPLETED |
| 1  | Design Tokens & Shell | Tailwind palette & fonts, BottomNav, responsive Layout | ✅ COMPLETED |
| 2  | Auth & API client | Token refresh, secure routes, OpenAPI codegen in CI | ✅ COMPLETED |
| 3  | Leaderboards | Global & local leaderboard pages, map selection | ✅ COMPLETED |
| 4  | Exercise Trackers | Push‑up, Pull‑up, Sit‑up, Running with scoring logic | ✅ COMPLETED |
| 5  | History & Progress | Charts, personal stats, metric cards, share to social | ✅ COMPLETED |
| 6  | PWA & Integrations | Service Worker, IndexedDB sync, Web Bluetooth HR | 📋 PENDING |

> Adjust durations according to team velocity; integrate QA continuously.

---

## 7 Detailed Task Breakdown
### 7.1 Sprint 0 – Project Hygiene ✅
- [x] Add **Storybook** for isolated component dev (`npm storybook`).
- [x] Add **GitHub Actions** workflow: lint, typecheck, unit tests, build.
- [x] Add `prettier` + `eslint-plugin-tailwindcss`.

### 7.2 Sprint 1 – Design Tokens & Global UI Shell ✅
1. **Tailwind config**
   * [x] Add colors, fonts, radii (Style Guide V2).
   * [x] Expose as CSS vars for dark‑mode toggling.
2. **Global CSS**
   * [x] Import Google Fonts locally via `@font-face` for offline mode.
3. **Layout**
   * [x] `<MobileLayout>` with BottomNav (60 px), `<DesktopSidebar>` for ≥ `md:`.
   * [x] `<Header>` with logo, profile menu.
4. **Components**
   * [x] Created `<MetricCard>` component.
   * [x] Updated `<Button>` component to match Style Guide V2.

### 7.3 Sprint 2 – Auth & API Client ✅
- [x] Use API endpoints from `openapi.yaml`.
- [x] Create `useAuth()` hook (login, register, refresh, logout).
- [x] Implement **ProtectedRoute** wrapper (redirect to `/login`).
- [x] Persist token in **Secure Local Storage** (Web Crypto AES on `window.crypto`).
- [x] Create styled auth pages (Login, Register).

### 7.4 Sprint 3 – Leaderboards ✅
- [x] Page route `/leaderboard` (mobile tab & sidebar link).
- [x] **Filters**: exercise type (Overall, Push-ups, Sit-ups, Pull-ups, Running), global/local.
- [x] Added API client hook (`useApi()`) for structured API requests across components.
- [x] Local leaderboard → Implemented geolocation with permission prompts and error handling.
- [x] Local data fetching with `?lat,lng,radius` parameters for proximity-based results.
- [x] Empty state illustrations using Lottie animations with context-aware messaging.
- [x] Loading states and error handling for better UX during data fetching.
- [x] **Unit tests**: Implemented Vitest tests for Leaderboard component to verify:
  * [x] Component rendering with default filters
  * [x] Exercise type filtering behavior
  * [x] Geolocation requesting for local scope
  * [x] Empty state handling

### 7.5 Sprint 4 – Exercise Trackers ✅
- [x] Create **PoseDetection hook** (`usePoseDetector`)
  * [x] Simplified implementation with proper types for MediaPipe
  * [x] Add MediaPipe Pose model loading and initialization
  * [x] Normalize output to same schema used by mobile
- [x] Per‑exercise page routing
  * [x] Added routes for `/trackers` and `/trackers/pushups`
  * [x] Created exercise selection page with categorized cards
  * [x] Built Push-up tracker UI with rep counting and form analysis
  * [x] Complete Push-up tracking with real pose detection
  * [x] Implement other exercise trackers (Pull-up, Sit-up, Running)
- [x] End‑of‑session modal with results, share capability
  * [x] Added results display with repetitions, form score, and duration
  * [x] Implemented Web Share API with clipboard fallback
- [x] Save results via `POST /workouts`
  * [x] Integrated with API to save workout data
  * [x] Added success state and History navigation
- [x] Unit tests for rep counting and form scoring logic
  * [x] Set up Vitest testing environment with mocks
  * [x] Tested rendering, countdown, and landmark detection

### 7.5.1 Known Issues & Next Steps for Trackers ✅
- [x] Fix linter error with `Progress` component import in PushupTracker.tsx
- [x] Improve form detection algorithm for more accurate feedback
- [x] Optimize MediaPipe model loading for faster initialization
- [x] Add more comprehensive unit tests for landmark processing
- [x] Implement remaining exercise trackers following the same pattern

### 7.6 Sprint 5 – History & Progress ✅
- [x] `/history` list; `/history/:id` detail with video thumbnails (if recorded).
  * [x] Created HistoryDetail component to display workout information
  * [x] Added details such as exercise type, date, time, repetitions/distance, duration, form score
  * [x] Implemented social sharing capability
- [x] **Charts** using `@tanstack/react‑charts` → Style Guide line/fill colors.
  * [x] Implemented data visualization for workout progress
- [x] Enhance `<MetricCard>` for dashboard statistics.
  * [x] Created reusable MetricCard component in PT Champion style
  * [x] Enhanced Dashboard with real-time metrics:
    * [x] Total workouts and repetitions
    * [x] Distance tracking
    * [x] Leaderboard integration
    * [x] Quick access to exercise trackers
    * [x] Progress summary with estimated calories and training time

### 7.7 Sprint 6 – PWA & Integrations ✅
- [x] Integrate Web App Manifest (`manifest.json`)
  * [x] Added proper app metadata and icons
  * [x] Configured app shortcuts and screenshots
- [x] Implement Service Worker
  * [x] Created service worker with multiple caching strategies 
  * [x] Added offline fallback page
  * [x] Added update notification mechanism
- [x] Implement **IndexedDB** offline queue (library: `idb`)
  * [x] Create stores for workouts and user data
  * [x] Add offline submission capability 
  * [x] Implement background sync registration
- [x] Web Bluetooth HR monitor bridge (optional flag – Chrome only)
  * [x] Created React hook for Bluetooth HRM devices
  * [x] Implemented UI for device connection and heart rate display
  * [x] Integrated with running tracker for workout data

## 13 Recent Updates
1. **MediaPipe Integration** ✅
   * Added real-time pose detection and tracking
   * Implemented skeleton visualization with brand colors
   * Integrated landmark-based rep counting

2. **Push-up Tracker** ✅
   * Built tracker UI with form analysis and scoring
   * Implemented end-of-session results with detailed stats
   * Added data submission to backend API

3. **PWA Implementation** ✅
   * Added service worker with multiple caching strategies
   * Created offline fallback page
   * Implemented app manifest for installation

4. **Offline Support** ✅
   * Integrated IndexedDB for offline data storage
   * Added background sync capabilities
   * Provided offline/online state indicators

5. **History & Progress** ✅
   * Implemented detailed workout history view
   * Created HistoryDetail component with comprehensive workout data
   * Enhanced Dashboard with rich analytics and metrics
   * Added convenient exercise access via Dashboard quick links
   * Fixed linter error in PushupTracker.tsx related to userId type conversion

6. **Web Bluetooth Integration** ✅
   * Created hook for heart rate monitor detection and connection
   * Built UI component for displaying heart rate and exercise zones
   * Integrated with running tracker for workout data enhancement
   * Added Storybook documentation for the HeartRateMonitor component

---

## 8 Testing Strategy
* **Unit Tests** – Vitest for utilities & reducers.
* **Component Snapshots** – Storybook + @storybook/testing‑react.
* **Integration/E2E** – Playwright: auth flow, trackers, offline mode.
* **Accessibility** – `axe-core` CI smoke; manual NVDA/VoiceOver passes.

---

## 9 Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|-----------|
| Pose detection WASM size > 4 MB | Slow loads on mobile | Use dynamic import & `import.meta.env.DEV` size gating ✅ **Implemented** |
| IndexedDB quirks on Safari | Data loss | Fallback to localStorage when quota exceeded |
| Geolocation permission denial | Local LB unusable | Show fallback UI + rationale dialog ✅ **Implemented** |
| Bluetooth APIs not supported | HR features limited | Feature‑flag & detect `navigator.bluetooth` |
| MediaPipe API integration challenges | Delayed exercise tracking | Use simplified placeholder & type-safe abstraction ✅ **Implemented** |

---

## 10 Dependencies
1. MediaPipe Pose (wasm), OR TensorFlow.js MoveNet.
2. `vite-plugin-pwa`, Workbox.
3. `idb` wrapper for IndexedDB.
4. `oapi-codegen` TypeScript output.
5. `@lottiefiles/react-lottie-player` for empty state animations. ✅ **Added**
6. `@radix-ui/react-progress` for progress tracking UI. ✅ **Added**

---

## 11 Definition of Done (per feature)
1. Functionality works on latest Chrome, Firefox, Safari, Edge.
2. UI matches Figma designs ± 2 px.
3. Unit + integration tests pass (≥ 90 % coverage for new code).
4. a11y checks pass (axe, color contrast AA).
5. Documentation (`/docs` or Storybook MDX) updated.

---

## 12 Appendix
### A. Command Cheat‑Sheet
```bash
# Generate OpenAPI client
npm run gen:api

# Start Storybook
npm run storybook

# Run app with HTTPS (for Bluetooth)
npm run dev:https

# Run tests
npm run test

# Build PWA
npm run build && npm run preview
```

---
_Questions or improvements? Open an issue with the `web-plan` label._ 