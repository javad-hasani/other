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
