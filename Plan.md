Story	Acceptance criteria
S0-1 Create project roadmap doc	Links to this plan in repo wiki; team sign-off
S0-2 Add branch protection & PR template	CI required, at least 1 review, lint/test gates
S0-3 Add baseline GitHub Actions workflow	go test ./..., golangci-lint run on PRs

Sprint 1-2 – Security & Auth Hardening
S1-1 Delete legacy internal/auth/jwt package	• ADR: choose claims + algorithm
• Refactor imports
• Remove dead code	Eng-1	All tests green; no compile warnings
S1-2 Extract refresh-token store to Redis	• Design interface RefreshStore (Save/Find/Revoke)
• Impl Redis version
• Wire via DI	Eng-2	Tokens survive pod restart; integration test passes
S1-3 Fail fast on missing secrets	• Add config.Validate()
• Return fatal log if any required env var empty	Lead	Container exits ≠ 0 when secret absent
S2-1 Early reject invalid token types	• Move type-check before token.Valid
• Unit tests for wrong typ claim	Eng-2	Fails with 401 & JSON error payload

Sprint 3 – Data layer resilience
S3-1 Context time-outs for all DB calls	• repository.go add ctx, cancel param
• Bubble timeout from config (default 3 s)	Eng-1	Slow query returns context.DeadlineExceeded
S3-2 Parametrise PostGIS WKT	• Replace fmt.Sprintf with ST_MakePoint bind vars	Eng-2	SQL-inject test string returns 400, not 500
S3-3 Tune leaderboard sort order	• Decision doc: distance vs score sort
• Rewrite SQL; verify index usage	Lead	EXPLAIN shows K-NN index scan
Sprint 4 – Router & API polish


S4-1 Remove legacy chi helpers	• Delete internal/api/router.go vestige	Eng-2	grep chi/ finds zero hits
S4-2 Fix static-file serving bug	• Use Echo.Static("/", dir) + fallback route	Eng-1	Frontend SPA loads behind /dashboard refresh
S4-3 Contract tests for stubs	• Table-driven tests for each “501” handler
• Expect OpenAPI error shape	Lead	go test ./internal/api ≥ 80 % coverage
Sprint 5 – Observability & config

S5-1 Request-ID in logs	• Echo middleware to inject into ctx
• logging.WithContext pulls it	Eng-2	Logs show req_id= field on every line
S5-2 Make grading constants tunable	• Move magic numbers to YAML
• Hot-reload on SIGHUP (viper)	Eng-1	Changing elbow angle threshold affects unit test