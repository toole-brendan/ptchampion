# PT Champion – Roll‑Back Procedure (15‑Minute Target)

> Applies to: Web, Backend (ECS), iOS, Android – Production Environment
>
> Audience: On‑call Engineer / Release Captain
>
> Goal: Restore the last **known‑good** production version within **15 minutes** of a roll‑back trigger (SEV‑1 incident, critical bug, impaired KPIs, etc.).

---

## 1. Roll‑Back Triggers
| Trigger | Detection Source | Owner |
|---------|------------------|-------|
| API 5xx error‑rate ≥ 3 % for 5 min | Azure Monitor Alert → PagerDuty | Backend TL (Primary) |
| Frontend JS error surge (> 500/min) | Sentry Alert → Slack #alerts | Web TL |
| P90 Latency > 2× baseline for 10 min | Prometheus Alertmanager | DevOps |
| Failed health‑check /probe | Azure Application Insights | DevOps |
| Manual roll‑back request (Product) | Slack `/rollback` command | Release Captain |

---

## 2. Preparation Checklist (Before You Roll Back)
1. 🚦 **Confirm Severity:** Validate that the issue is not an isolated outage (e.g., client ISP).
2. 🚑 **Acknowledge Alerts:** Silence duplicate alerts (PagerDuty / Slack) to avoid noise.
3. 📝 **Gather Context:** `az webapp log tail`, Azure Portal → App Service Logs, Grafana dashboards – capture evidence for post‑mortem.
4. 🔒 **Freeze Deployments:** Disable GitHub Actions "Deploy to Prod" workflow via environment protection rule.

> **Time budget:** ≤ 5 minutes for this section.

---

## 3. Roll‑Back Steps (Azure App Service / CDN)
| # | Action | Command / Console | Expected Result |
|---|--------|------------------|-----------------|
| 1 | Identify last healthy deployment | Azure Portal → **App Service** → Deployment Center → Logs | Last successful deployment hash |
| 2 | Roll back to previous deployment | Azure Portal → **App Service** → Deployment Center → select deployment → **Redeploy** | Previous deployment starts |
| 3 | Monitor deployment health | Azure Portal → **App Service** → Monitoring → Log stream | Successful startup logs |
| 4 | Purge Azure CDN endpoints | Azure Portal → **Front Door and CDN** → select profile → **Purge** → `/*` | Edge caches refreshed |
| 5 | Verify application | Open `/health`, run smoke tests, confirm sentry error rate normal | All checks passing |

> **Automation:** The `rollback.sh` script (in `scripts/`) performs steps 1‑3 via Azure CLI. Use: `./scripts/rollback.sh DEPLOYMENT_ID`.

---

## 4. Mobile Apps Roll‑Back
1. **Feature Flags:** Disable new feature flag in LaunchDarkly (propagates within seconds).
2. **Hot‑fix Build (if needed):** Tag stable commit → GitHub Action builds, pushes to TestFlight / Internal Track for expedited review.
3. **Rollback to Prior Release:** App Store Connect → *Re‑enable* previous build for Production (iOS) / Play Console → *Make prior release live* (Android).

> Mobile roll‑backs typically exceed 15 min; mitigate via feature‑flags / Kill‑Switch remotes.

---

## 5. Post‑Roll‑Back
- ✏️ **Incident Ticket:** Update Jira SEV‑1 ticket with summary, timeline, and mitigations.
- 📡 **Un‑suppress Alerts:** Re‑enable GitHub Actions deployment and PagerDuty notifications.
- 🧩 **Post‑Mortem:** Schedule blameless RCA within 24 h.

---

## 6. Validation Checklist ✅
- [ ] App/API functional (smoke tests pass)
- [ ] Error rate & latency back to baseline
- [ ] Stakeholders notified in #status channel
- [ ] Roll‑back documented in incident ticket

---

### References
- Production Readiness Plan (§ Definition of "Production‑Ready", point 4)
- Azure App Service Previous Deployments: https://learn.microsoft.com/en-us/azure/app-service/deploy-continuous-deployment#view-the-deployment-log
- Azure CDN Purge: https://learn.microsoft.com/en-us/azure/cdn/cdn-purge-endpoint
- GitHub Actions Environment Protection Rules

*Last updated: {{TODAY}}* 