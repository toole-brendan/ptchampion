# PT Champion Roadmap
version: 0.1
last-updated: 2025-04-18
maintainer: @btoole

> **Purpose**   This roadmap translates the high‑level vision into time‑boxed, sprint‑sized work packages. All estimates are **ideal dev‑days** for a five‑person core team (2 BE, 1 WEB, 1 AND, 1 IOS) working in two‑week sprints.

## Legend
| Abbrev. | Role |
|---------|------|
| BE      | Backend (Go) engineer |
| WEB     | React/Tailwind engineer |
| AND     | Android engineer |
| IOS     | iOS engineer |
| QA      | Test / QA lead |
| DevOps  | Dev‑ops / shared infrastructure |
| DES     | Designer / UX |

## Phase 1 — Foundations & Quick Wins ( Sprints 1‑4 • 22 Apr → 14 Jun 2025 )

| ID  | Epic & Key Tasks | Owner | Est. (days) | Depends | Status |
|-----|------------------|-------|-------------|---------|--------|
| 1.1 | **MediaPipe Tasks Upgrade**<br/>• Replace legacy *PoseSolution* with *PoseLandmarker* in Android module<br/>• Update grading adapter to new landmark IDs | AND | 4 | — | ✅ Completed |
| 1.2 | **Tailwind Accessibility Patch**<br/>• Convert palette to CSS variables in `tailwind.config.cjs`<br/>• Darken brass‑gold by 20 % & add text‑shadow util<br/>• Regenerate shadcn/ui themes | WEB + DES | 2 | — | ✅ Completed |
| 1.3 | **PostGIS & Redis Leaderboard**<br/>• `CREATE EXTENSION postgis` + GIST index on `user_location`<br/>• Implement `K‑NN` query `(<->)`<br/>• Add Redis cache layer (5 min TTL) | BE | 3 | 1.4 | ✅ Completed |
| 1.4 | **Unified DB Migrations**<br/>• Move all *.sql* to `db/migrations`<br/>• Integrate *golang‑migrate* in CI<br/>• Block PRs without migrations | DevOps | 2 | — | ✅ Completed |
| 1.5 | **CI Matrix & OTEL MVP**<br/>• Add CI matrix (Go 1.22/1.23, Node 20, Xcode 15, AGP 8.4)<br/>• OTEL Echo middleware + Jaeger docker‑compose<br/>• Docs page "How to view traces" | DevOps | 4 | 1.4 | ✅ Completed |
| 1.6 | **Makefile / Dev‑container**<br/>• Root *Makefile* targets: `dev`, `test`, `deploy`<br/>• `.devcontainer.json` with Go, Node, Java, Android SDK | DevOps | 2 | 1.4 | ✅ Completed |
| 1.7 | **Synthetic Health‑Check Action**<br/>• GitHub Action calls `/healthz` + mock video upload every 6 h | DevOps | 1 | 1.5 | ✅ Completed |

**Exit Criteria**  
✔ Android build using *PoseLandmarker* ≥ 18 fps on Pixel 5   
✔ `/leaderboard/local` median latency ≤ 60 ms, p99 ≤ 300 ms   
✔ CI wall‑clock ≤ 15 min   
✔ A11y contrast issues resolved site‑wide

<details>
<summary>Phase 2 — Shared Logic & Feature Flags (Sprints 5‑8)</summary>

| ID  | Epic & Key Tasks | Owner | Est. (days) | Depends | Status |
|-----|------------------|-------|-------------|---------|--------|
| 2.1 | **Grading → WASM**<br/>• ✅ Refactor `internal/grading` API <br/>• ✅ Promote to `pkg/grading`<br/>• ✅ Build `cmd/wasm` (TinyGo) output & JS wrapper<br/>• ✅ JNI loader (Wasmtime) + iOS PoC (Wasmer-Swift) | BE + WEB + AND + IOS | 12 | 1.5 | ✅ Completed |
| 2.2 | **Global Feature Flags**<br/>• ✅ Evaluate Flagsmith self‑host<br/>• ✅ Add cache‑aware middleware & `/features` endpoint<br/>• ✅ Client wrappers (React Context, Kotlin object, Swift singleton)<br/>• ✅ Flag new grading formula, fine‑tuned model | BE + DevOps + Clients | 6 | 1.5 | ✅ Completed |
| 2.3 | **Observability Deep‑Dive**<br/>• Prometheus rules (CPU > 75 %, p99 > 500 ms)<br/>• Grafana dashboards<br/>• Pose fps histogram export | DevOps + AND | 3 | 1.5 | ⬜ Not Started |
| 2.4 | **Testing Automation**<br/>• Go table‑tests ≥ 80 % coverage on *grading*<br/>• Playwright smoke tests (login, exercise run) | QA + BE + WEB | 4 | 1.5 | ⬜ Not Started |

**Exit Criteria**  
✔ WASM grading returns identical scores across Go/JS/Android/iOS vectors   
✔ Flagsmith can disable "Fine‑tuned Push‑up" model *without redeploy*   
✔ CI gate enforces 80 % unit coverage on `pkg/grading`   
✔ Prom/Grafana accessible at `dev.<env>.ptchampion.com`

</details>

<details>
<summary>Phase 3 — Mobile & API Evolution (Sprints 9‑14)</summary>

| ID  | Epic & Key Tasks | Owner | Est. (days) | Notes | Status |
|-----|------------------|-------|-------------|-------|--------|
| 3.1 | **Android CameraX Pipeline**<br/>• Direct YUV feed to Tasks API via *SurfaceRequest*<br/>• Benchmark fps & battery | AND | 6 | — | ⬜ Not Started |
| 3.2 | **iOS Vision Holistic**<br/>• Replace MediaPipe with Vision‑kit<br/>• Live Activity rep counter | IOS | 8 | Requires Xcode 16 beta | ⬜ Not Started |
| 3.3 | **Health Connect & CoreData Sync**<br/>• VO₂ Max import<br/>• Offline queue (DataStore / CoreData) | AND + IOS | 5 | 2.1 | ⬜ Not Started |
| 3.4 | **GraphQL Edge Layer**<br/>• Deploy Hasura or `gqlgen`<br/>• Federated query *session→metrics→leaderboardDelta*<br/>• Auth via JWT `x-hasura-user-id` | BE | 6 | 1.5 | ⬜ Not Started |
| 3.5 | **Geo Leaderboard Scaling**<br/>• Implement H3 bucketting (1 km cells)<br/>• Nightly cron summarises to Redis hot set | BE + DevOps | 4 | 1.3 | ⬜ Not Started |
| 3.6 | **UX Onboarding & Dark‑mode**<br/>• Mission‑style tutorial screens<br/>• Night‑ops dark theme via CSS vars | DES + Clients | 4 | 1.2 | ⬜ Not Started |

**Exit Criteria**  
✔ Android & iOS apps process reps *offline* and sync later   
✔ GraphQL endpoint powers new mobile dashboard with single query   
✔ Dark‑mode toggle persists per‑device   
✔ Local leaderboard query ≤ 20 ms at 100 k users (load test)

</details>

<details>
<summary>Phase 4 — Advanced Features & Hardening (Sprints 15‑20)</summary>

| ID  | Epic & Key Tasks | Owner | Est. (days) | Depends | Status |
|-----|------------------|-------|-------------|---------|--------|
| 4.1 | **Event Sourcing Backbone**<br/>• `events` table + outbox pattern<br/>• Rewrite grading write‑path to publish events<br/>• CDC to ClickHouse for analytics | BE + DevOps | 8 | 3.4 | ⬜ Not Started |
| 4.2 | **Fine‑Tuned CV Models**<br/>• Collect dataset & label push‑up depth<br/>• Train & quantise TFLite INT8<br/>• Gate via feature flag | AND + ML Contractor | 10 | 2.2 | ⬜ Not Started |
| 4.3 | **Security Suite**<br/>• Short‑lived JWT + PKCE refresh flow<br/>• SAST (CodeQL) & dep scan<br/>• BLE spoofing mitigations ADR | DevOps + BE | 4 | 1.5 | ⬜ Not Started |
| 4.4 | **gRPC Landmark Streaming**<br/>• `LandmarkStream` bidirectional RPC<br/>• Benchmark < 50 ms RTT on LAN | BE + AND + IOS | 6 | 4.1 | ⬜ Not Started |
| 4.5 | **Team Challenges**<br/>• Squad CRUD & invite codes<br/>• Weekly ranking job<br/>• Push notifications (FCM/APNs) | BE + Clients | 6 | 3.5 | ⬜ Not Started |

**Exit Criteria**  
✔ Event log powers analytics dashboard   
✔ Fine‑tuned model raises push‑up accuracy +7 pp & can be disabled via flag   
✔ Pen‑test passes OWASP MSTG baseline   
✔ First platoon pilot of *Team Challenge* feature

</details>

### Stretch / 2026+ Backlog

• WebAssembly SIMD + threads build for browser real‑time inference  
• Fully offline PWA installable fallback  
• Multi‑tenant gyms with custom scoring tables

---

## iOS TestFlight Distribution Guide

Follow these steps to get the PT Champion iOS app into TestFlight for internal or external testers.

### 1. Prerequisites

1. Apple Developer Program membership (Individual or Org).
2. Bundle ID registered in App Store Connect (e.g. `com.ptchampion.app`).
3. App‑specific passwords or *App Store Connect API* key if you automate via CI.
4. Xcode 15+ or *fastlane* installed locally/CI.

### 2. Local one‑off upload (Xcode)
```bash
# 1. Open ios/ptchampion.xcworkspace
# 2. Select 'Any iOS Device (arm64)' or your device scheme.
# 3. Product ▶︎ Archive
# 4. In the Organizer window choose Distribute ‣ App Store Connect ‣ Upload.
```
Xcode will automatically handle code‑signing if *Automatic Signing* is enabled and the correct team is selected.

### 3. CI / fastlane workflow (recommended)
1. **Add Fastlane lanes** inside `ios/fastlane/Fastfile`:
   ```ruby
   lane :beta do
     build_app(
       workspace: "ptchampion.xcworkspace",
       scheme: "ptchampion",
       configuration: "Release",
       export_method: "app-store"
     )
     upload_to_testflight(
       skip_waiting_for_build_processing: false,
       distribute_external: false  # flip when ready for public testers
     )
   end
   ```
2. **Secrets** Store `ASC_API_KEY` or App‑specific password securely (GitHub Secrets / Bitrise Vault).
3. **CI Job** example for GitHub Actions:
   ```yaml
   name: iOS Beta
   on:
     push:
       branches: [ main ]
   jobs:
     build-ios:
       runs-on: macos-13
       steps:
         - uses: actions/checkout@v4
         - uses: ruby/setup-ruby@v1
           with:
             ruby-version: 3.2
         - name: Install fastlane
           run: gem install fastlane -NV
         - name: Cache pods
           uses: actions/cache@v3
           with:
             path: ios/Pods
             key: ${{ runner.os }}-pods-${{ hashFiles('ios/Podfile.lock') }}
         - name: Bundle install
           working-directory: ios
           run: bundle install --path vendor/bundle || true
         - name: Run lane
           working-directory: ios
           env:
             ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
             ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
             ASC_KEY_CONTENT: ${{ secrets.ASC_KEY_CONTENT }}
           run: bundle exec fastlane beta
   ```
4. **Post‑upload** — configure testers & groups in TestFlight tab on App Store Connect.

### 4. Tips & Gotchas
• Increase build number every upload (`agvtool new-version -all $(($LATEST+1))` or `increment_build_number`).  
• Attach release notes so QA knows what changed.  
• External builds require App Review; factor ~24 h lead time.  
• Use *TestFlight public link* for up to 10 k external testers.

---

> *This roadmap is a living document.* Please update status columns, estimates, and dates after each sprint retro. Contributions via PR are welcome.
