# Minishop-first staging runbook (without VPS: preparation only)

**State: instructions drafted; no installation, domain, processor, or external server available.**

## Selected review baseline

- **Commerce:** [Remnawave Minishop v3.8.3](https://github.com/3252a8/remnawave-minishop/releases/tag/v3.8.3), pinned source `0fe3ac3abba160517538cc86e812e655d46fe55a`; MIT.
- **Control plane:** [Remnawave Backend 3.4.7](https://github.com/remnawave/backend/releases/tag/3.4.7), commit `52321390ac4efe04a610811446d87335f1d10a93`.
- **Xray Node:** [Remnawave Node 3.4.3](https://github.com/remnawave/node/releases/tag/3.4.3), commit `2ad154f8f1016c94c1872f337268af878af61b18`.
- **WARNING:** These are reproducible versions checked on 2026-10-23, not a verified cross-product working combination. Remnawave Minishop claims compatibility with panel versions >2.7.0; verify with chosen 3.4.7 before paid sales.

## Offline preparation — operator machine or disposable runner

```bash
git clone https://github.com/javad-hasani/other.git
cd other/v2ray-500
bash scripts/preflight.sh
bash scripts/fetch-upstream.sh
# Review the complete vendor READMEs and LICENSE files before execution.
cat vendor/UPSTREAM-COMMITS.txt
```

Do **not** install anything from an unreviewed `curl | bash` command. Only source is cloned, pinned and logged by the script. `vendor/` is gitignored.

## Isolated staging environment — after VPS or local Docker is available

1. Use a separate staging VM/network. Never reuse production SFIORD credentials or data.
2. Deploy official **Remnawave Backend** following the docs at https://docs.rw/ with TLS, PostgreSQL/Valkey, and correctly private admin/metrics/database ports.
3. Deploy one authenticated Remnawave Node initially; register and test one synthetic user and connection profile. A second Node can be added after this works.
4. In the pinned **Minishop** checkout, consult `docs/features/telegram-optional.md`, `docs/getting-started/deployment.md`, and upstream `.env.example`. Configure:
   - `TELEGRAM_ENABLED=False`, `BOT_TOKEN=` (empty), `WEBAPP_ENABLED=True`, `EMAIL_LOGIN_ENABLED=True`
   - Unique persistent `EMAIL_AUTH_SECRET`, `WEBAPP_SESSION_SECRET`, admin identity
   - `PUBLIC_APP_URL`, `WEBHOOK_BASE_URL`, SMTP settings
   - `PANEL_API_URL`, `PANEL_API_KEY`, `PANEL_WEBHOOK_SECRET`
   - Genuine PostgreSQL/Redis credentials stored outside Git; HTTPS, firewall and backup target.
5. Review `docker-compose.yml` and `docker compose config` before starting. Do not check any real `.env` into Git.
6. Use sandbox transactions only, if available. Customer purchase must **not** be enabled until a legal domestic PSP is selected and its server-side verification + replay/chargeback rules are tested.
7. Test admin and customer login with email, all paths end to end (trial, quota, renew, expiry, support, refunds) and document actual versions and signed-off results in HISTORY.

## Capacity policy — NEVER ASSUME ALREADY IMPLEMENTED

An active entitlement is a seat, not a registered account; 500 is a global hard cap, pilot is 50. Before any real payment, determine whether Minishop already offers a concurrency-safe *global active-entitlement* limit.

Acceptance test:
- With 499 allocated seats, send two independent verified paid checkout attempts simultaneously. Exactly one may receive seat 500; the other must remain unprovisioned and be refunded / queued with notice.
- Renewing any one of 500 active subscriptions must not be blocked by the allocation limit.
- Expired local entries must not release a seat until the matching Remnawave account is confirmed disabled.
- A repeated verified payment callback must not create a second entitlement.
- Under connection or API outage, do not claim fulfillment; reconcile safely.

If Minishop lacks this feature, propose a **minimal patch to Minishop's existing checkout/entitlement DB transaction**, not a second permanent subscription database or separate n8n process. Our tested `db/` proof of concept is for reference only and must not be run in Minishop or Remnawave DB.

## Persian/Iranian payments gap

- Upstream locales directory inspected at 2026-10-23 contains **en.json** and **ru.json**. Persian localization is not confirmed.
- No Iranian PSP / Zarinpal integration verified by inspected source/docs. This is an **unresolved gap**, not a mandate to invent a new payment backend.
- Verify PS provider permitted business model, webhook signature or server-to-server API status, amount units in IRR/toman, bank settlement, refund and recurring policy.
- Translate only needed shop screens first. Treat localization as a small upstream i18n extension rather than a new customer portal.

## Monitoring and running costs

Prefer built-in upstream stats and provider alerts before installing additional monitoring. Real capacity and currency rates must be measured. A passing CI test of synthetic 500 slots does not prove 500 connected clients or 15 TB of actual traffic.

## Exit criteria

- [ ] Repo license and dependency review complete
- [ ] Minishop web-only staging instance authenticated and running
- [ ] Correct Remnawave/Node compatibility proven with actual API and client
- [ ] Verified PSP sandbox checkout, callback retry and refund
- [ ] Verified transactional 500-seat limit
- [ ] Persian UX and currency conversions tested
- [ ] Backups, alerting and restore exercise complete
- [ ] Infra cost under 15 million toman and 50-user canary approved

**None of these live-stage checkboxes are complete as of 2026-10-23.**
