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

## 2026-10-23 — H012 — Reuse-first architecture review (DONE: research and documented policy; selection pending)

- **Assumption / تصور:** For a 500-subscription business, developing a parallel customer portal, full billing system, SQL lifecycle and n8n workflows upfront would repeat features already supported by the Remnawave community ecosystem.
- **Evidence / شاهد:** Reviewed official Remnawave documentation and curated ecosystem, plus primary repository READMEs: official core already handles user management, node control, quotas and subscription pages; **Remnawave Minishop** documents optional Telegram and a standalone Web App, whereas **Bedolaga + Cabinet** is Telegram-centric, and **STEALTHNET** is a further combined web/bot candidate. No candidate has yet been security audited or verified to enforce a global atomic 500-active-subscription cap or domestic Iranian payment.
- **Decision / تصمیم:** **Reuse before build**. Select **one** maintained commerce product after gap analysis; keep custom SQL, n8n and the hand-built Vercel status dashboard as **optional experiments**, not assumed production architecture. Never run competing billing systems or split entitlement ownership. Vercel is optional frontend/landing hosting and is not needed for the Xray data plane.
- **Action:** Created `docs/build-vs-reuse-review.md` with explicit candidates, alternatives, acceptance gates, procurement/security requirements and no-code-first staging strategy. Commit `a0f90671ffea4355881b75c1daf91e641ae5ea1d`.
- **Validation:** Source documentation verified; **no live release, payment, test client, VPS or integration**. This is an architectural review, not a benchmark.
- **Next:** Evaluate Minishop against Bedolaga Cabinet on reproducible test criteria, confirm licensing/security, then choose **one** product and implement only unfilled gaps.


## 2026-10-23 — H013 — Reuse-first stack selected and staged (DONE: documentation, pins and offline CI; NO production deployment)

- **Assumption / تصور:** A maintained, web-first shop can substantially reduce time and risk compared with building a customer portal, payment ledger, order lifecycle and n8n provisioning from scratch.
- **Evidence / شاهد:** Inspected repository docs, LICENSE files, dated releases and tag-to-commit refs. **Minishop** v3.8.3 (2026-10-22) is MIT, has Web App/admin, email login and documented `TELEGRAM_ENABLED=False`. Its inspected locale directory only listed `en.json` and `ru.json`. **Bedolaga** bot LICENSE contains *Commons Clause* prohibiting software resale as a service notwithstanding README's MIT wording; Cabinet has a separate AGPL-derived license. **STEALTHNET** is AGPL-3.0-or-later and remains an alternative, not selected.
- **Decision / تصمیم:** Select **Minishop as sole candidate for staging commerce**; official Remnawave Backend/Node for control and data planes. **Do not build** another customer portal or parallel payment database. Move custom 500-seat SQL, n8n workflows and Vercel project dashboard to optional experimental/reference status. **Hard cap 500 still unimplemented in actual commerce checkout**; Iranian PSP and Persian UX remain open. Selected versions must pass integration tests before production.
- **Action:** Authored `docs/ADR-001-commerce-stack.md` (commit `be356971b`), `docs/minishop-staging-runbook.md` (`9bf48fa9e`), switched `config/upstream.lock` to exact Minishop v3.8.3, Remnawave Backend 3.4.7, Remnawave Node 3.4.3 release commits (`aa292c787`), updated offline preflight for the 3 chosen source repos (`7767fae38`), refreshed README (`1c1833103`) and static website copy / timeline (`099a86c33`, `acce14609`).
- **Validation:** GitHub Actions after the source-preflight edit **passed**: https://github.com/javad-hasani/other/actions/runs/40005866690 . One intermediate run after changing the lock but *before* changing the preflight count failed (https://github.com/javad-hasani/other/actions/runs/40005838611); root cause was expected-four-repos assertion against new three-repo lock and was corrected. **No upstream Docker stack or API was executed**. No Vercel deployment, VPS, payment, latency or client test.
- **Next:** On an isolated disposable machine fetch pinned Minishop/Backend/Node, inspect upstream instructions/licenses, test **web-only** shop and Remnawave interoperability. Verify checkout/renewal, local PSP eligibility, Persian localization and **atomic 500 active entitlement hard cap**, then sign off 50-client canary. Do not run the older experimental `db/` migration on either product database.


## 2026-10-23 — H014 — Ready-made official admin demo identified (DONE: external demo verified; our admin NOT deployed)

- **Assumption / تصور:** The quickest way to inspect Minishop admin features is to reuse the project's official existing interactive demo rather than building a visual clone.
- **Evidence / شاهد:** Official Minishop documentation https://minishop.minidoc.cc/getting-started/overview/ explicitly describes browser-based **static mock-data** admin/client routes needing no backend/DB/API. Direct admin users preview: https://minishop.minidoc.cc/demo/admin/users/ . The same maintainer's dev-stand docs specify a Docker Compose full-stack QA option, with frontend `http://127.0.0.1:18082` and local Remnawave panel `http://127.0.0.1:3000`.
- **Decision / تصمیم:** Present the upstream demo as the immediate UI preview. Do **not** misrepresent it as our Vercel deployment or a functional billing/admin deployment. For real authentication and persisted changes, deploy the upstream stack on a separately controlled Docker host or VPS and verify it first.
- **Action:** Updated README with official preview and dev-stand entry points. Commit `94339fe3f`.
- **Validation:** The public official demo and documentation links were retrieved and inspected. No VPS, Docker host, running custom Minishop instance or Vercel deployment available to this project.
- **Next:** Obtain an isolated Docker host / VPS, then use upstream dev stand with synthetic data; verify secure admin access and compatibility before any real customer/payment records.

## 2026-10-24 — H015 — Persian-language product gap and ShahPanel evaluation (DONE: source audit + docs; DEPLOYMENT PENDING)

- **Assumption / تصور:** The selected Minishop admin demo would be adequate for an Iranian operator after trivial localization.
- **Evidence / شاهد:** The upstream Minishop main locale directory contains `locales/en.json` and `locales/ru.json` only. Upstream `docs/features/admin-panel.md` confirms additional languages including `fa` can be added via **System → Translations**, stored as locale overrides, with fallback strings; this does **not** prove full translations or correct RTL. Official Remnawave backend dashboard separately lists **Persian** among built-in languages: https://docs.rw/contributing/i18n/ . In alternative https://github.com/shahinst/shahpanel source, `.env.example` sets `APP_LOCALE=fa`, there are many `lang/fa/*.php` modules, and Zarinpal gateway/webhook plus Remnawave v3.x API integration code exists. ShahPanel latest inspected release **v3.38.5** was published 2026-10-17. License is **AGPL-3.0-or-later**, including obligations when modified source is accessed over network. The source includes Feature tests but **we have not executed them**.
- **Decision / تصمیم:** Do **not** translate or rewrite all of Minishop yet. **Evaluate ShahPanel FIRST** for Iranian-market product fit, with Minishop kept as fallback. This supersedes the previous evaluation *priority*, not the past event in H013. No confirmed choice for production until security, actual 500-seat cap, end-to-end checkout/PSP, and Remnawave client connectivity pass. Do not interpret official Remnawave dashboard Persian support as automatically localizing the independent Minishop storefront.
- **Action:** Created `docs/ADR-002-persian-first.md` in commit `c36478d7c`, updated README in `7fc0adecb`, updated planned (not deployed) site dashboard in `7606e5344` and history list in `27b56f37f`.
- **Validation:** GitHub READMEs and source files inspected. **No Persian storefront was deployed, no ShahPanel installer was executed, no credentials or paid accounts touched.** This update is a research/documentation change, not a runtime test.
- **Next:** On an isolated Docker/VPS host, test ShahPanel's Persian RTL web/admin, authentication, Zarinpal sandbox, Remnawave API v3.x, correct toman/rial units, idempotent payment and concurrency-safe 500 active entitlements, compliance with AGPL, and monthly infra resources. If it fails the gates, return to Minishop via built-in `fa` locale override plus minimal RTL/PSP patch.

## 2026-10-24 — H016 — ShahPanel substituted for Minishop (DONE: project configuration/documentation; NOT deployed)

- **Assumption / تصور:** The user explicitly selected ShahPanel, so keeping Minishop in selected source pins, production diagrams or instructions would create duplicate/contradictory architecture. Rewriting an existing Persian storefront is unnecessary.
- **Evidence / شاهد:** Verified ShahPanel public release **v3.38.5** tag points to `e898e84999779fd105a3e948a95ced3f44db9df1` and directly checked `LICENSE`, `composer.json`, `.env.example` *at the tag*: AGPL-3.0-or-later, PHP >=8.2, Laravel 11, MySQL and `APP_LOCALE=fa`. The README/source includes Zarinpal and Remnawave integrations; actual operational quality remains untested.
- **Decision / تصمیم:** **ShahPanel is now the primary commercial/admin product**, not merely first evaluation candidate; it replaces Minishop in active project source pins and design. Keep Remnawave Backend + 2 nodes. Retain Minishop only as an archived alternative. Do not deploy a second customer/billing database, obsolete n8n automation or Postgres seat-guard experiment.
- **Action:** Source pin updated to ShahPanel v3.38.5 and generic source fetcher now retrieves ShahPanel instead of Minishop (`config/upstream.lock`, commit `efad47786`). Preflight checks the three selected pins (`04551c616`). Wrote `ADR-003-shahpanel-selection.md` (`05e2253ea`) and `shahpanel-staging-runbook.md` (`244748478`). Reworked `README.md` (`4baeb8e5c`), `docs/architecture.md` (`c70326fb3`), `docs/rollout-checklist.md` (`d4c315ea4`) and planned static site and history timeline (`922e7c16b`, `ef293181a`). Marked old Minishop runbook, n8n blueprint, PostgreSQL proof as archived (`4722f4e9b`, `05a661d1e`, `51cd1a4a8`). ADR-002 clearly marks itself superseded (`8482f8b46`).
- **Validation:** Current offline GitHub Actions run with ShahPanel source-lock and updated preflight **passed**: https://github.com/javad-hasani/other/actions/runs/40065686234 . Earlier two runs **failed transiently** while the documentation files required by the newly updated preflight had not yet been committed (runs `40065518695` and `40065521441`); those missing files were subsequently created and the validation passed. **CI checks the local project structure and the old isolated PostgreSQL proof, NOT an installed ShahPanel, PHP/MySQL tests or Remnawave API compatibility.** The source is tracked by immutable upstream commit references rather than copied or forked here.
- **Next:** Before any live service, review ShahPanel installer/security and AGPL obligations, run its native PHP/MySQL upstream tests on a disposable host, then validate Persian RTL, Zarinpal sandbox, Remnawave v3.x create/renew/suspend, and a truly transactional 500-active-entitlement cap. No VPS, live backend, database, payment or Xray node has been installed by this change.

## 2026-10-27 — H017 — ShahBot Telegram connection path prepared (DONE: source review and runbook / PENDING: real Telegram linkage)

- **Assumption / تصور:** ShahPanel's chosen product might require a custom Telegram/MirzaBot runtime and Vercel or n8n integration in order to sell subscriptions.
- **Evidence / شاهد:** Inspected ShahPanel **v3.38.5** source: `modules/shahbot/module.json` names a built-in Persian sales Telegram bot; `modules/shahbot/src/Http/Controllers/Admin/SettingsController.php` exposes admin settings and a Connect action; `modules/shahbot/src/Services/WebhookService.php` performs `getMe`, `setWebhook`, `sendTestMessage`, and uses `APP_URL` for webhook endpoint; `modules/shahbot/src/Http/Controllers/WebhookController.php` verifies the secret route and `X-Telegram-Bot-Api-Secret-Token` header. The built-in settings support `admin_chat_ids`, `owner_user_id` (agent/seller), optional proxy, default `mode=webhook`, default Persian language. Telegram official Bot API confirms HTTPS webhook requirements, supported ports, and `getWebhookInfo` checks: https://core.telegram.org/bots/api .
- **Decision / تصمیم:** **Adopt the native ShahBot** as the project's Telegram store/support module; do not add a separate MirzaBot/Bedolaga/n8n checkout. Keep bot token and webhook secrets out of GitHub, HISTORY and ChatGPT. Because there is no running ShahPanel/VPS/HTTPS, user may create a dedicated @BotFather bot now but a working webhook requires a public ShahPanel instance. **Do not use another active bot's token** without deliberate migration. Keep ShahBot `sales_enabled=0`, `test_enabled=0`, and `topup_enabled=0` during setup; upstream default sales was `1` and must be explicitly disabled.
- **Action:** Authored `docs/telegram-shahbot-connection.md` (commit `f3fd1bb00`), added navigation and scope clarifications to README (`674bab182`), ShahPanel runbook (`33cba5f80`), rollout checklist (`322074858`).
- **Validation:** Repository source reviewed and guide committed; **NO BotFather bot was created by this assistant; no token or username supplied; no `getMe`, `setWebhook`, `sendMessage`, server or real Telegram traffic was executed.** Earlier capacity CI does not test native ShahBot.
- **Next:** Create a **dedicated** Telegram bot through @BotFather, store token privately, provide only its public `@username` if needed for project naming; then after an isolated ShahPanel host with HTTPS is online, use ShahPanel's native Connect tab and verify username, webhook health, real admin chat delivery and `/start` responses before enabling payments or sales.
