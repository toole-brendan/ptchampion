PT Champion — Detailed Implementation Plan (v0.1 • 18 Apr 2025)

This living plan turns the high‑level roadmap into concrete, time‑boxed work packages. All dates assume a five‑person core team (2 backend, 1 web, 1 Android, 1 iOS) and a fortnightly sprint cadence. Adjust estimates if capacity changes.

Legend

Abbrev.

Meaning

BE

Backend (Go) engineer

WEB

React/Tailwind engineer

AND

Android engineer

IOS

iOS engineer

QA

Test/QA lead

DevOps

Dev ops or shared infra engineer

DES

Designer / UX

Durations are ideal dev‑days (not calendar days). Multiply by 1.5–2× for calendar scheduling.

Phase 1 — Foundations & Quick Wins (Sprint 1‑4 • 22 Apr – 14 Jun 2025)

Epic

Tasks

Role

Est. (d)

Dependencies

1.1 MediaPipe Tasks Upgrade

• Replace legacy PoseSolution with PoseLandmarker in Android module• Update grading adapter to new landmark IDs

AND

4

none

1.2 Tailwind Accessibility Patch

• Convert palette to CSS variables in tailwind.config.cjs• Darken brass-gold by 20 % and add text‑shadow utility class• Regenerate shadcn/ui themes

WEB + DES

2

none

1.3 PostGIS & Redis Leaderboard

• CREATE EXTENSION postgis and GIST index on user_location• Implement K‑NN query (<->)

• Add Redis cache layer (5 min TTL)

BE

3

DB migration infra (1.4)

1.4 Unified DB Migrations

• Move all .sql to db/migrations• Integrate golang-migrate in ci.yml• Block PRs w/out migrations

DevOps

2

none

1.5 CI Matrix & OpenTelemetry MVP

• Add ci.yml matrix for Go1.22/1.23, node 20, Xcode 15, AGP 8.4• Add OTEL Echo middleware + Jaeger docker‑compose service• Docs page "How to view traces"

DevOps

4

1.4

1.6 Makefile / Dev‑container

• Write root Makefile targets: dev, test, deploy• Add .devcontainer.json with Go, Node, Java, Android SDK

DevOps

2

1.4

1.7 Synthetic Health Check Action

• GitHub Action hits /healthz + mock video upload every 6 h

DevOps

1

1.5

Phase 1 exit criteria 🔑✔ Android build using PoseLandmarker shows ≥18 fps on Pixel 5✔ /leaderboard/local median latency ≤ 60 ms & p99 ≤ 300 ms✔ CI completes in < 15 min wall‑clock✔ a11y contrast issues resolved site‑wide

Phase 2 — Shared Logic & Feature Flags (Sprint 5‑8 • 17 Jun – 9 Aug 2025)

Epic

Tasks

Role

Est. (d)

Dependencies

2.1 Grading → WASM

• Refactor internal/grading API (error types, constants)• Promote to pkg/grading• Build cmd/wasm (TinyGo) output• JS wrapper + TypeScript types• JNI loader via Wasmtime• PoC in iOS (Wasmer‑Swift)

BE + WEB + AND + IOS

12

1.5

2.2 Global Feature Flags

• Evaluate Flagsmith self‑host (Docker)• Add middleware caching subject flags• /features REST endpoint• Client wrappers (React Context, Kotlin object, Swift singleton)• Flag new grading formula, fine‑tuned model

BE + DevOps + WEB + AND + IOS

6

1.5

2.3 Observability Deep‑Dive

• Prometheus rules (CPU >75 %, p99 >500 ms)• Grafana dashboards• Pose fps histogram export

DevOps + AND

3

1.5

2.4 Testing Automation

• Add Go table‑tests coverage ≥80 % in grading• Playwright smoke tests (login, exercise run)

QA + BE + WEB

4

1.5

Phase 2 exit criteria 🔑✔ WASM grading returns identical scores across Go/JS/Android/iOS test‑vectors✔ Flagsmith toggles can disable "Fine‑tuned Push‑up" model without redeploy✔ CI gate enforces 80 % unit coverage on grading package✔ Prom/Grafana visible from dev.<env>.ptchampion.com

Phase 3 — Mobile & API Evolution (Sprint 9‑14 • 12 Aug – 31 Oct 2025)

Epic

Tasks

Role

Est. (d)

Notes

3.1 Android CameraX Pipeline

• Direct YUV feed to Tasks API via SurfaceRequest• Benchmark fps & battery

AND

6

—

3.2 iOS Vision Holistic

• Replace MediaPipe with Vision‑kit• Live Activity rep counter

IOS

8

Requires Xcode 16 beta

3.3 Health Connect & CoreData Sync

• VO₂Max import• Offline queue (DataStore / CoreData)

AND + IOS

5

2.1

3.4 GraphQL Edge Layer

• Deploy Hasura or gqlgen• Expose session→metrics→leaderboardDelta federated query• Auth via JWT “x‑hasura‑user‑id”

BE

6

1.5

3.5 Geo Leaderboard Scaling

• Implement H3 index bucketing for 1 km cells• Nightly cron summarizes to Redis hot set

BE + DevOps

4

1.3

3.6 UX Onboarding & Dark‑mode

• Mission‑style tutorial screens• Night‑ops dark theme using CSS vars

DES + WEB + AND + IOS

4

1.2

Phase 3 exit criteria 🔑✔ Android & iOS apps process reps offline and sync later✔ GraphQL endpoint powers new mobile dashboard with single query✔ Dark‑mode toggle persists per‑device✔ Local leaderboard query ≤ 20 ms at 100 k users in load test

Phase 4 — Advanced Features & Hardening (Sprint 15‑20 • 4 Nov 2025 – 6 Feb 2026)

Epic

Tasks

Role

Est. (d)

Dependencies

4.1 Event Sourcing Backbone

• events table + outbox pattern

• Rewrite grading write‑path to publish events• CDC to ClickHouse for analytics

BE + DevOps

8

3.4

4.2 Fine‑Tuned CV Models

• Collect dataset, label push‑up depth• Train & quantise TFLite INT8• Gate via feature flag

AND + ML contractor

10

2.2

4.3 Security Suite

• Short‑lived JWT + PKCE refresh flow• SAST (CodeQL) & dep scan• BLE spoofing mitigations ADR

DevOps + BE

4

1.5

4.4 gRPC Landmark Streaming

• LandmarkStream bidirectional RPC• Benchmark < 50 ms RTT in LAN tests

BE + AND + IOS

6

4.1

4.5 Team Challenges

• Squad CRUD, invite codes• Weekly ranking job• Push notifications (FCM/APNs)

BE + AND + IOS + WEB

6

3.5

Phase 4 exit criteria 🔑✔ Event log powers analytics dashboard✔ Fine‑tuned model raises push‑up accuracy +7 pp, defeatured via flag if regressions✔ Pen‑test passes OWASP MSTG baseline✔ First platoon pilot of team challenge feature

Stretch / 2026+ Backlog

WebAssembly SIMD + threads build for browser real‑time inference

PWA installable fallback

Multi‑tenant gyms with custom scoring tables

Risk & Mitigation

Risk

Impact

Mitigation

Wasm on iOS not production‑ready

Delay shared logic

Maintain Swift port as fallback until iOS 17 ? stabilises

Training data privacy

Legal / PR

Collect only landmarks, store videos opt‑in + purge 30 d

Geo queries cost spike

$$$

Pre‑aggregated H3 buckets + Redis

Next Steps (for you)

Validate estimates with each role lead in kickoff.

Book sprint‑planning for Mon 21 Apr 2025 to lock Phase 1 backlog.

Stand up Flagsmith & Grafana sandboxes in dev cluster before Sprint 5.

Share this plan in the repo Wiki; update after every retrospective.

⬆️ Feel free to mark up directly—this canvas will auto‑update as you request edits.