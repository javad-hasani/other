# Production acceptance checklist — ShahPanel / Remnawave

**None of these operational acceptance checks are complete.** See [ADR-003](ADR-003-shahpanel-selection.md).

## Before acquiring VPS
- [ ] Verify source of ShahPanel v3.38.5 and license/AGPL network-access obligations
- [ ] Review installer `install.sh`, security advisories, dependencies, auth/payment code
- [ ] Decide domains, backup destination and independent Xray node host locations
- [ ] Provider acceptable-use policy, quota and total monthly infrastructure cost <= 15M toman
- [ ] Establish secure staging SSH keys, admin access policy and incident contact

## Telegram / built-in ShahBot
- [x] Verified ShahBot exists in pinned ShahPanel source, with getMe/setWebhook and Telegram secret header verification
- [x] Authored nonsecret [ShahBot setup and acceptance instructions](telegram-shahbot-connection.md)
- [ ] Dedicated BotFather bot username created (never commit bot token)
- [ ] Working HTTPS ShahPanel and valid APP_URL on an independent server
- [ ] Owner agent/seller, admin_chat_ids configured safely in live admin UI
- [ ] Built-in Connect action succeeds, getWebhookInfo URL and error count checked
- [ ] Bot /start and actual admin test message succeed; no duplicate bot webhook
- [ ] Purchase, trial, wallet top-ups disabled during setup; permissions and payment flow verified before reopening

## ShahPanel (commercial admin)
- [ ] Install ShahPanel on isolated staging Ubuntu with PHP >=8.2 / Laravel 11 / MySQL 8
- [ ] Persian RTL admin + client/reseller routes validated across devices
- [ ] Fresh MySQL credentials; TLS/HTTP security headers/TOTP and restricted admin path
- [ ] Zarinpal sandbox verification: IRR vs IRT, duplicate callbacks, invalid authority and refund
- [ ] Confirm exact active-paid-entitlement count in ShahPanel, not merely registered identities
- [ ] Atomically reject 501st **active** account even under competing orders
- [ ] Renew existing subscriptions without reserving a second seat
- [ ] Restore and verify ShahPanel MySQL database backups

## Remnawave/Xray
- [ ] Install official Remnawave backend with isolated Postgres/Valkey
- [ ] Keep management API/admin/database ports private or explicitly allowlisted
- [ ] Register Node 1, confirm authenticated communication and real client subscription
- [ ] Integrate ShahPanel v3.x API: create, update, Internal Squad, suspend and quota
- [ ] Register Node 2 separately; verify behavior of client on Node 1 loss
- [ ] Test egress allowance, error rates, CPU, latency, health and monitoring
- [ ] Restore and verify Remnawave PostgreSQL backups separately

## Real customer go/no-go
- [ ] Audit/reconcile verified paid order to remote active user; no duplicated entitlements
- [ ] Repeat callbacks and failed remote provision never charge/deliver twice
- [ ] Proven safe refunds, account expiry, remote disable and released-capacity semantics
- [ ] Canary 50 connections, then 200, then 500 subscriptions after measured results
- [ ] Business checkout enabled only after manager signoff and security validation
