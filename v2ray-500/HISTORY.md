# HISTORY — V2Ray-500

> Canonical, append-only engineering history for `javad-hasani/other/v2ray-500`. Every change must record **Date / Assumption (تصور) / Evidence (شاهد) / Decision (تصمیم) / Action / Validation / Next step**. Do not record credentials, private IPs, customer identities, subscription URLs, or payment data here.
>
> Status legend: **DONE** = committed or verified; **DESIGNED** = specified, not run; **PENDING** = blocked or not started; **FAILED** = attempted and unsuccessful.

## 2026-10-23 — H001 — Scope and business constraints (DECIDED)

- **Assumption / تصور:** 500 registered users and 500 simultaneous active connections are not equivalent.
- **Evidence / شاهد:** Project conversation established hard limit **500 active subscriptions**, initial **100 estimated concurrent connections**, planning assumption **30 GB/user/month = 15 TB/month**, two Xray traffic nodes and one control-plane server.
- **Decision / تصمیم:** Maximum **500 concurrently entitled active subscriptions**, staged **50 → 200 → 500**. Budget ceiling **15,000,000 toman/month** for infrastructure. CPU/bandwidth throughput must be measured before each phase.
- **Action:** Recorded these assumptions and rollout limits.
- **Validation:** Requirements review only; no benchmark or invoices.
- **Next:** Enforce capacity at the database/provisioning boundary with transactional idempotency.

## 2026-10-23 — H002 — Upstream assessment (DONE: references)

- **Assumption / تصور:** A maintained OSS stack can replace bespoke VPN panel development.
- **Evidence / شاهد:** Official projects verified through GitHub connector:
  - https://github.com/remnawave/backend (control-plane backend)
  - https://github.com/remnawave/node (Xray/Remnawave node)
  - https://github.com/BEDOLAGA-DEV/remnawave-bedolaga-telegram-bot (Telegram sales bot)
  - https://github.com/Capybara-z/RemnaSetup (optional installer)
  - https://github.com/remnawave/panel (mostly panel documentation/UI; not the backend runtime)
- **Decision / تصمیم:** Use Remnawave backend + two nodes. Consider Bedolaga for Telegram sales only after audit; payment processing for Iran and Bale support are separate adaptations. Installer is optional and must be reviewed before root execution.
- **Action:** Tracked upstream projects and written staging installation strategy.
- **Validation:** Repository metadata and README review; **not** security audit.
- **Next:** Pin known-good releases and test compatible combinations before deployment.

## 2026-10-23 — H003 — GitHub bootstrap (DONE)

- **Assumption / تصور:** Keep a preparation workspace separate from production and company repositories.
- **Evidence / شاهد:** Connected GitHub account: `javad-hasani`; accessible existing `javad-hasani/other` is **PUBLIC**. GitHub connector in this workspace does not offer a native new-repository/fork action.
- **Decision / تصمیم:** Work under `javad-hasani/other/v2ray-500/` temporarily; publish documentation only, never secrets or customer records. Do not change unrelated projects.
- **Action:** Created `README.md`, `.gitignore`, `scripts/fetch-upstream.sh`, and `docs/rollout-checklist.md`.
- **Validation:** Four files fetched back from GitHub. Fetch script is **source-only**, not a production deployment.
- **Next:** If commercial IP/privacy requires it, relocate to a private repository with appropriate access before adding nonpublic material.

## 2026-10-23 — H004 — Pre-server implementation work (IN PROGRESS)

- **Assumption / تصور:** Capacity gating and automation contracts can be built without renting a VPS.
- **Evidence / شاهد:** Production hosting/domain/payment provider and SSH access are not yet available.
- **Decision / تصمیم:** Implement SQL-based atomic reservation, stage limits, request replay protection, state-transition contracts, integration tests, and n8n wiring specifications offline.
- **Action:** Create database migration, tests, CI, architecture/automation documentation and preflight files.
- **Validation:** To be filled only after commit and checks; do not claim deployment.
- **Next:** Verify GitHub paths and CI results, then wait for VPS procurement.

---

## Update procedure (mandatory)

1. **Read this HISTORY before any change.** Never reconstruct the project from unverified memory.
2. Add a new `H###` entry for every meaningful design change, commit, failed test, deployment, incident or rollback.
3. Each entry must differentiate planned work from verified execution; link the commit/PR/workflow run if available.
4. Preserve previous entries. If a prior record is mistaken, append a correction with a reference to the original ID.
5. Never write secret material or identifiable customer data. Store configuration templates only.

## Open decisions (not guessed)

- Actual VPS provider/pricing/availability, DNS domains and separate failure domains.
- Telegram/Bedolaga versus Bale versus website checkout.
- Iranian payment gateway, business/abuse policy, refund and support rules.
- Measured concurrent connection success, latency and bandwidth at 50 and 200 users.
- Security review, license compliance, tested versions and deployment permissions.

## 2026-10-23 — H005 — Atomic capacity gate (DONE: offline implementation and integration test)

- **Assumption / تصور:** Naive `COUNT(*)` + subsequent `INSERT` can oversubscribe under concurrent n8n runs; retiring an account should not free capacity until the remote resource is disabled.
- **Evidence / شاهد:** Added `db/migrations/001_capacity_guard.sql` and `tests/test_capacity.py`. The migration uses a transaction-scoped advisory lock, 500-row hard constraint, 50/200/500 staged policy and receipt-based replay protection. Occupied statuses include `reserved`, `provisioning`, `active`, `deactivating`.
- **Decision / تصمیم:** Only authorized provisioning workers may call SQL functions; no direct DML privileges to the app role. A reused idempotency key for a different customer/hash fails. Renewal is based on absolute expiry, not repeated increments.
- **Action:** Commits: `b164f0986` (initial SQL), `7677615c6` (existing-row guard correction), `c8e2a8b9a` (integration test), `22e41b208` (customer-bound receipts and released remote ID), `92744d4fb` (additional test), `204443722` (CI).
- **Validation:** GitHub Actions passed in disposable PostgreSQL 16: https://github.com/javad-hasani/other/actions/runs/39997411508 . Tests include 64 concurrent contenders for 50 seats, 200 and 500 rollout thresholds, 501st denied, lifecycle, renewal and replay conflicts.
- **Next:** Build and audit the payment verifier and official Remnawave API adapter after selecting the business/payment channel; real customer entitlement is not active.

## 2026-10-23 — H006 — Architecture, automation, operations docs (DONE: designs only)

- **Assumption / تصور:** The dependency on VPS/domain/payment provider does not prevent specifying operational contracts in advance.
- **Evidence / شاهد:** Added `docs/architecture.md`, `docs/n8n-automation.md`, `docs/security-and-release.md`, `db/README.md`; updated README to distinguish completed offline work from production. Commits `053401b55`, `7863ab911`, `52f8de49b`, `01aad61e5`, `1bd008c48`.
- **Decision / تصمیم:** Separate Remnawave DB from business provisioning DB. Trust verified payment only; keep internal API, external webhook and DB boundaries explicit. No release from occupied state until confirmed remote deactivation. n8n workflows are **specified**, not deployed/imported.
- **Action:** Documented node/control-plane layout, SQL permissions, verified payment → reservation → remote provisioning → reconciliation, alert conditions and canary go/no-go.
- **Validation:** Documentation committed, SQL-backed assumptions supported by H005. No live API, payment-provider, user-client or VPS test yet.
- **Next:** Provider-specific compatibility, secure credentials and approval gates when deployment infrastructure becomes available.

## 2026-10-23 — H007 — Reproducible dependencies and offline preflight (DONE: source snapshots)

- **Assumption / تصور:** Fetching floating `main` at an unknown future date may silently change upstream behavior.
- **Evidence / شاهد:** GitHub HEAD SHAs captured in `config/upstream.lock` on 2026-10-23; `scripts/fetch-upstream.sh` modified to use exact pinned commits and to reject drift of an existing checkout. `scripts/preflight.sh` validates manifest, files and syntax without a live server.
- **Decision / تصمیم:** Snapshot commits are provenance only, not a security audit or compatibility certification. Audit licenses, dependencies and images before server deployment.
- **Action:** Commits `3c9028e9e` (source lock), `c630e811f` (pinned fetch), `17aa356e6` (preflight), `20d019cba` (CI preflight). Added Python ignore patterns in `bf97bcd1b`.
- **Validation:** GitHub Actions with preflight and PostgreSQL integration completed successfully: https://github.com/javad-hasani/other/actions/runs/39997631624 .
- **Next:** On operator machine run `bash scripts/preflight.sh`, then `bash scripts/fetch-upstream.sh`; inspect pinned upstream sources before installing.

## 2026-10-23 — H008 — Unresolved production dependencies (PENDING)

- **Assumption / تصور:** A passing CI job is necessary but does not demonstrate live capacity, client connectivity, billing or security.
- **Evidence / شاهد:** No VPS credentials, IPs, domains, payment-provider implementation, working Remnawave instance, remote node or real-user canary provided to this project.
- **Decision / تصمیم:** **NO PRODUCTION DEPLOYMENT.** Do not claim a live VPN or tested 500-user throughput. Remain under the 15,000,000 toman/month budget, pending real provider invoices.
- **Action:** Recorded blocked items and required test gates; no outside server touched.
- **Validation:** Offline only.
- **Next:** Provision one isolated staging VPS (later separate two nodes), prepare DNS/TLS/SSH safely, verify Remnawave API contract and then integrate billing + n8n.


## 2026-10-23 — H009 — Optional local PostgreSQL lab (DONE: templates committed; runtime not started)

- **Assumption / تصور:** A standalone disposable database test environment can be prepared without purchasing the three intended VPSs.
- **Evidence / شاهد:** Created `docker-compose.lab.yml` (loopback-only PostgreSQL 16), `config/lab.env.example` (empty password placeholder, secrets stay local), `docs/local-lab.md` (start/test/stop instructions). Added Compose validation to CI.
- **Decision / تصمیم:** The local lab is **test-only** and must never be confused with the Remnawave deployment stack or payment system. The CI database remains disposable and separate from all company databases.
- **Action:** Commits: `4c2766ed2` (Compose), `54c85e052` (example env), `95dfb7e65` (lab manual), `bf13837d5` (README), `c0c28a950` (CI config validation).
- **Validation:** Files committed; GitHub CI validates Compose syntax; no live Docker Compose was started by the assistant.
- **Next:** Local lab may be tested on an operator machine, but VPS sourcing, checkout/payment verification and remote node connectivity remain blocked.

## 2026-10-23 — H010 — Final CI verification and trigger cost control (DONE)

- **Assumption / تصور:** Rerunning the full PostgreSQL race test for every prose/history change wastes CI runtime without checking changed executable logic.
- **Evidence / شاهد:** Compose validation and PostgreSQL integration both passed on the project state through `H009`: https://github.com/javad-hasani/other/actions/runs/39998059562 .
- **Decision / تصمیم:** CI now triggers on SQL, tests, scripts, pinned sources, example lab env, lab Compose, and CI workflow edits—not on documentation-only commits. It remains available through `workflow_dispatch`.
- **Action:** Updated GitHub Actions path filters in commit `3cf20e8f3`.
- **Validation:** Previous full CI run passed; updated workflow re-run is independently tracked at https://github.com/javad-hasani/other/actions/runs/39998141471 .
- **Next:** Keep all future work in `HISTORY.md`, distinguish tests from deployment, and procure VPS and domain before attempting any live Remnawave/Xray service.

## 2026-10-23 — H011 — Vercel dashboard (DONE: source files / BLOCKED: remote deployment)

- **Assumption / تصور:** Vercel can host a static management/status frontend, but cannot substitute for long-lived TCP/UDP Xray Nodes or always-on Remnawave runtime.
- **Evidence / شاهد:** Added static RTL Persian dashboard in `site/`: `index.html`, `styles.css`, `app.js`, `favicon.svg`, `vercel.json` with security headers, project timeline H001-H010, clear non-live status, planned capacity and architecture. Commits `c275e3554`, `f12b9b00b`, `3ec00017f`, `42a62942b`, `6fdd7f49d`.
- **Decision / تصمیم:** Deploy **only** the read-only status website from GitHub `javad-hasani/other`, root directory `v2ray-500/site`; no billing, live VPN or admin endpoints on Vercel. The website is static and has no backend secrets.
- **Action:** Attempted to create a Git-linked Vercel project `xray-500-console` under the discovered Vercel team `team_HfjRdUCd8exaNgZkbomGUfEC`.
- **Validation:** GitHub files committed. **Vercel deployment NOT created**: provider returned `403 forbidden`, connection has no authorization for team scope `javadhreporter-gmailcoms-projects`. No Vercel URL is verified.
- **Next:** User grants the Vercel connection access to the correct team; retry Git-linked project creation with `rootDirectory=v2ray-500/site`, confirm Vercel deployment READY and check URL response. Update this record with successful URL only after verification.

## 2026-10-23 — H012 — Vercel access verification (BLOCKED: authorization)

- **Assumption / تصور:** The prepared static web console can deploy when Vercel team scope is authorized.
- **Evidence / شاهد:** GitHub repository `javad-hasani/other` and `v2ray-500/site` files verified. Authenticated Vercel account has default team `team_HfjRdUCd8exaNgZkbomGUfEC`; team/project lookup and Git-linked project creation returned HTTP 403 for `javadhreporter-gmailcoms-projects`.
- **Decision / تصمیم:** Do not deploy into a different or guessed owner. Preserve Vercel target `xray-500-console`, Git repository `javad-hasani/other` and rootDirectory `v2ray-500/site`.
- **Action:** Attempted `create_git_project` with `deploy=true`; it was rejected before creating any deployment.
- **Validation:** **NOT DEPLOYED**; no verified Vercel URL. Problem is authorization, not frontend build.
- **Next:** User grants this Vercel plugin connection access to `javadhreporter-gmailcoms-projects`; retry Git link and verify READY plus URL. Xray runtime remains VPS-only.
