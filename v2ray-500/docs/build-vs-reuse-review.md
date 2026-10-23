# Build-vs-Reuse Review — V2Ray-500
Date: 2026-10-23
Status: **ARCHITECTURE REVIEW / NO DEPLOYMENT**
Decision: **Reuse proven, maintained upstream before writing business features.** Candidate selection is provisional and requires a controlled evaluation.

## Product objectives
- Sell and operate up to **500 entitled active subscriptions**, with stages 50 -> 200 -> 500.
- Infrastructure ceiling: **15,000,000 toman/month**; current provider prices/tax/bandwidth still unverified at purchase.
- Prefer a **usable customer website**, potentially with a messaging bot, and reliable payment and renewal.
- Maintain independence from SFIORD production assets, accounts and customer information.
- Every future milestone updates `HISTORY.md` with evidence and commit links.

## Reuse-first reference stack

| Layer | Default strategy | Why |
|---|---|---|
| Xray runtime / Node management | Official Remnawave Backend + Remnawave Node | Built-in nodes, user management, traffic limits, subscription links, statistics and API |
| Public subscription page | Official Remnawave subscription-page (when needed) | Don't write a new subscription renderer |
| Customer portal / commerce | **Select exactly one** of the evaluated shop projects | Avoid parallel billing/customer databases and duplicated lifecycle logic |
| Installer | Official documentation first; RemnaSetup optionally after audit | Avoid unreviewed root scripts |
| Monitoring | Built-in Remnawave telemetry first; add Xray Checker/Watchdog only for a measured gap | Reduces operational complexity |
| Infra spend tracking | Existing provider billing; consider community Infra Billing only if manual cost tracking becomes onerous | Keep <15M toman goal |
| Frontend on Vercel | Optional static landing/status portal, **not** the Xray transport, Remnawave panel, or a substitute for the shop's ready-made web app | Do not build a new dashboard when existing app solves the need |
| n8n | Optional edge orchestration for a proven missing integration; NOT a second billing system | Avoid fragile double-write and duplicate entitlements |

### Candidate commerce solutions (no selected winner yet)

**1. Remnawave Minishop — first evaluation for web-first operation**

- Source: https://gitlab.com/3252a8/remnawave-minishop (GitHub copy: https://github.com/3252a8/remnawave-minishop)
- README advertises Web App, admin panel, tariff editor, payments, renewals, login by email/Telegram, support, backups, full-stack QA.
- Docs explicitly support `TELEGRAM_ENABLED=false`, making web-first onboarding possible.
- Docs claim compatibility with Remnawave versions **>2.7.0**; test against a chosen pinned version.
- Missing for our target: Iranian gateway(s) and proven **global** atomic 500-active-subscription checkout cap. Verify before customizing.
- Decision gate: web purchase -> verified payment -> Remnawave account -> expiry -> renewal -> refund, test without Telegram.

**2. Bedolaga Bot + Bedolaga Cabinet — evaluate if Telegram channel is central**

- Sources: https://github.com/BEDOLAGA-DEV/remnawave-bedolaga-telegram-bot and https://github.com/BEDOLAGA-DEV/bedolaga-cabinet
- Telegram-first bot already advertises multiple payment providers, plans, renewal, referrals, Web API, Web Cabinet.
- Cabinet README documents a static React frontend and a persistent bot backend API.
- More components and Telegram integration than web-first MVP needs; Iranian payment and 500-seat cap still not verified.
- Decision gate: choose only if its ready-made checkout/channel functionality materially outperforms the web-first candidate.

**3. STEALTHNET — inspect as ready-made combined website + admin + bot**

- Source: https://github.com/STEALTHNET-APP/remnawave-STEALTHNET-Bot
- README advertises web customer/admin dashboard, integrated sales, Telegram and Persian-language documentation.
- Not automatically a better fit: verify actual Persian UI, security controls, maintained releases, license and compatibility before trusting payment handling.
- Avoid running `install.sh` blindly, and especially never run any destructive cleanup instructions on a shared server.

**Additional possible community options:** https://docs.rw/awesome-remnawave/ lists commerce, monitoring, installers and backups. Discovery is not an endorsement or production security certification.

## Decisions regarding previous custom work

| Already made | Decision |
|---|---|
| `site/` custom static dashboard | Keep as optional **project read-only status / landing prototype**; do not extend into new customer/admin/billing UI without gap analysis |
| `db/migrations/001_capacity_guard.sql` | Keep tested code as **experimental fallback**. Do not deploy until an existing shop's lifecycle and total-sales cap are audited. If truly required, place a minimal atomic cap at the selected shop's sale/provisioning boundary, with one source of truth |
| `docs/n8n-automation.md` | Keep as a contract reference only. Do not deploy redundant purchase, payment, renewal and monitoring workflows if the selected shop implements them |
| `config/upstream.lock` | Reassess pinned component versions only after choosing a shop and compatibility-tested core. Date-pinned SHA != supported release |
| `docker-compose.lab.yml` and CI | Keep as disposable test harness, not the future commerce database |

## Evaluation checklist before declaring a winner

1. **Security and maintenance**: license, maintainer activity, CVE/issue history, secrets handling, admin authentication, dependency lock, test suite, backup/restore.
2. **Install and compatibility**: reproducible Docker Compose staging, exact Remnawave versions, resource and memory footprint, no unreviewed root downloads.
3. **Business workflow**: complete paid order, server-side gateway verification, subscription creation, usage/expiry, renewal, pause, refund and accurate invoice reconciliation.
4. **Iran-first localization/payment**: Persian UX, toman/rial correctness, chosen PSP eligibility and callback security, user support. Iranian payment examples such as https://github.com/azno-space/ir-payment-gateway are **unverified**, not approved production dependencies.
5. **Hard 500-cap**: discover existing global active entitlement cap; test two simultaneous orders at remaining one seat, ensure paid-but-blocked order is returned/refunded, and ensure expired users release seats only after remote disabling.
6. **Capacity performance**: measured 50 -> 200 -> 500 load tests; bandwidth and real network connectivity; avoid interpreting 500 accounts as 500 simultaneous connections.
7. **Opex control**: actual VPS traffic, backup, taxes, domain, network policy and support under 15 million toman/month.
8. **Operational exit**: data export, migration path and dependency independence from vendor lock-in.

## Proposed controlled delivery

- **Gate A (no VPS):** audit Minishop vs Bedolaga (+ optionally STEALTHNET) with a documented feature matrix and license/security checklist. **No code fork or customization yet**.
- **Gate B (staging):** reproduce upstream demo/Compose on isolated machine, choose one shop; deploy official Remnawave stack; test complete lifecycle with mock/sandbox payment.
- **Gate C (50 clients):** only fill demonstrated gaps, especially local payment and hard 500 seat control; measure stability and customer support cost.
- **Gate D (200/500):** grow to second Node and increase limits only after real evidence.

## Non-goals

- No new Remnawave clone, Xray core rewrite or home-made subscription manager.
- No custom CRM, user ledger, checkout, admin portal or monitoring stack without demonstrating a missing requirement.
- No attempt to run Xray Nodes or always-on bot backends on Vercel.
- No deployment to company SFIORD production.
- No claim of successful production readiness until full end-to-end canary, security and financial verification.
