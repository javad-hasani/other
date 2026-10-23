# ADR-001 — Reuse-first commercial stack (2026-10-23)

**State:** ACCEPTED FOR STAGING EVALUATION. Not approved for production deployment.

## Context

Business target: 500 **active paid entitlements**, initial canary of 50, a 200-user gate, maximum monthly **infrastructure** expense of 15 million toman. Vercel can host a landing/status page, not persistent Xray/TCP relay services. We must not maintain two sources of truth for subscriptions or develop features already available upstream.

We compared current primary repositories and their license files at the current released versions:

| Criterion | Remnawave Minishop | Bedolaga + Cabinet | STEALTHNET |
|---|---|---|---|
| Browser-first customer purchase / admin UI | Yes, Web App with email-only login | Yes, separate Cabinet; Telegram-first backend | Yes, combined website and bot |
| Operation without Telegram | **Documented** (`TELEGRAM_ENABLED=False`) | Not confirmed by inspected docs | Not confirmed by inspected docs |
| Payments, renewals, referrals and support | Built in | Built in | Built in |
| License evidence | **MIT**, LICENSE checked | **Commons Clause + MIT** in bot LICENSE (commercial-sale restriction); Cabinet license claims AGPL; README “MIT” does not override LICENSE | AGPL-3.0-or-later |
| Recent published version (on 2026-10-23) | **v3.8.3**, Oct 22, 2026 | Bot v5.0.0, Sep 29; Cabinet v1.80.1, Sep 29 | v6.8.0-lts, Oct 19 |
| Persian / Iranian gateway | Not confirmed. Only `locales/en.json`, `locales/ru.json` in inspected locales directory | Not confirmed | Persian documentation, but Persian checkout/PSP not verified |
| Global 500-*active*-entitlement checkout cap | **Not established** | **Not established** | **Not established** |
| Official Remnawave integration | Yes, readme and development stand | Yes | Yes |
| Operational complexity | Shop + official Remnawave; Telegram optional | Bot + Cabinet + Remnawave | Large integrated platform + Remnawave |
| MVP fit | **Preferred for controlled proof** | License blocker and extra runtime until clarified | Alternative if Minishop fails |

Evidence links:
- Minishop: [repo](https://github.com/3252a8/remnawave-minishop), [MIT LICENSE](https://github.com/3252a8/remnawave-minishop/blob/v3.8.3/LICENSE), [no-Telegram deployment](https://github.com/3252a8/remnawave-minishop/blob/v3.8.3/docs/features/telegram-optional.md), [v3.8.3 release](https://github.com/3252a8/remnawave-minishop/releases/tag/v3.8.3), [locales](https://github.com/3252a8/remnawave-minishop/tree/v3.8.3/locales).
- Bedolaga: [bot LICENSE](https://github.com/BEDOLAGA-DEV/remnawave-bedolaga-telegram-bot/blob/main/LICENSE), [Cabinet LICENSE](https://github.com/BEDOLAGA-DEV/bedolaga-cabinet/blob/main/LICENSE), [Cabinet integration](https://github.com/BEDOLAGA-DEV/bedolaga-cabinet/blob/main/README.md).
- STEALTHNET: [license](https://github.com/STEALTHNET-APP/remnawave-STEALTHNET-Bot/blob/main/LICENSE), [README](https://github.com/STEALTHNET-APP/remnawave-STEALTHNET-Bot).
- Official runtime: [Remnawave backend](https://github.com/remnawave/backend), [node](https://github.com/remnawave/node).
- [Remnawave community curated ecosystem](https://docs.rw/docs/awesome-remnawave) (community entries **are not** safety certifications).

**License warning:** The Bedolaga bot's LICENSE explicitly prohibits selling the software as a product or service deriving substantially from its functionality unless appropriately licensed. Commercial use requires legal review / upstream permission. The Cabinet license text also needs counsel's review. Do not assume the README's short MIT badge authorizes this commercial deployment.

## Decision

Use **Remnawave Minishop (MIT) as sole commerce system** for the first isolated proof-of-concept. Use **official Remnawave Backend + Nodes** for account subscriptions and Xray routing. In first release operate web-first with Telegram disabled, unless a verified product/business requirement changes this.

The selected source revisions are pinned in `config/upstream.lock`, with exact commit SHAs retrieved from GitHub release refs on 2026-10-23. They are a **reproducible review baseline**, not a verified compatible combination, security approval, or deployment authorization.

### Explicit non-goals for v0

- **No new customer frontend** or bespoke payment ledger.
- No parallel n8n payment provisioning unless the chosen shop demonstrably cannot perform an essential task.
- Keep `db/migrations/001_capacity_guard.sql` as **offline spike only**, not part of production Minishop database. Any 500-seat cap belongs at the chosen shop's transactional checkout / provisioning boundary, with proven race safety.
- Treat `site/` as an optional **project status prototype** until Vercel access is repaired. It is **not** the Minishop customer portal.
- Do not fork Minishop to the existing public repo or publish secrets. Prefer a standalone private repository once privileges are available.

## Required gated proof (only then production approval)

1. **Reproducible, license-clean install:** `upstream.lock` SHAs, read LICENSE, pass `make check` / upstream CI or document deviations. Confirm Node/Backend/API compatibility and correct Docker resource envelope.
2. **Web-only onboarding:** `TELEGRAM_ENABLED=False`, email auth + SMTP + verified admin login, secure callback URLs. No Telegram login requirement.
3. **Payment:** choose a legally available local processor; implement only if not already supported, perform server-side verification, dedup, failed-charge refund reconciliation. **Never trust browser flag `paid=true`.**
4. **Global active subscription cap:** block 501st entitlement atomically (and reject dual concurrent 500th-seat purchases); account registration can exceed 500. Existing paid renewals remain allowed. Expiry does not release a seat until remote account disabled. Define refund/waitlist for paid but not provisioned accounts.
5. **Localization:** evaluate upstream i18n extensibility. Verify Persian copy and toman/rial conversion and RTL in checkout. Not yet implemented.
6. **Operations:** verified independent backups, restoration, alerts, node health and subscription link generation; no customer secrets in logs; test failure replay and restore.
7. **Capacity/cost:** 50 -> 200 -> 500 measured on real clients; monitor monthly outbound traffic and provider ToS, provider cost and taxes under cap. Do not claim 500 simultaneous sessions guaranteed.
8. **Licensing:** inspect OSS license of all components, including Remnawave, before a commercial release.

## Acceptance decision

**GO for offline research and isolated staging only.** **NO-GO for paid customer launch or public claim of a live service.** If Minishop fails any essential gate, compare its gap remediation to STEALTHNET before writing anything bespoke.

## Change control

Every decision goes to `HISTORY.md` with Assumption / Evidence / Decision / Action / Validation / Next. Amend this ADR with a new version instead of silently changing a previous deployment conclusion.
