# XRAY-500 — ShahPanel + Remnawave

> **State: source selection/configuration complete; no VPS, live ShahPanel, real VPN, live payment or deployed Vercel website.** Read [HISTORY.md](HISTORY.md) before every change.

## Current product stack (ADR-003)

| Layer | Primary component | Role |
|---|---|---|
| Sales, Persian admin/customer portals, wallet, orders, invoices | **[ShahPanel](https://github.com/shahinst/shahpanel)** | Laravel 11, PHP 8.2+, **MySQL 8**; built-in `fa` and Zarinpal implementation |
| Subscription & VPN control plane | **[Remnawave Backend](https://github.com/remnawave/backend)** | Official panel, private PostgreSQL + Valkey |
| Two independent Xray traffic endpoints | **[Remnawave Node](https://github.com/remnawave/node)** × 2 | Client network traffic |
| Telegram bot for purchase/renewals/support | **ShahBot**, built into ShahPanel | No separate MirzaBot/Bedolaga/n8n commerce bot; setup pending BotFather + running HTTPS panel |
| Static site prototype | `site/` | Optional read-only Vercel status/landing page, **not the admin panel** |

**Minishop is no longer in the selected source lock or active deployment plan.** It remains documented as the historic alternative in [ADR-001](docs/ADR-001-commerce-stack.md), [ADR-002](docs/ADR-002-persian-first.md) and its archived runbook. Bedolaga is also excluded due to LICENSE commercial restrictions pending legal review.

### Baseline source revisions (pinned for staging, NOT tested together)

- **ShahPanel v3.38.5:** `e898e84999779fd105a3e948a95ced3f44db9df1` (2026-10-17)
- **Remnawave Backend 3.4.7:** `52321390ac4efe04a610811446d87335f1d10a93`
- **Remnawave Node 3.4.3:** `2ad154f8f1016c94c1872f337268af878af61b18`

These Git references were checked against published release tags; see [source lock](config/upstream.lock). ShahPanel carries **AGPL-3.0-or-later**; read its source-availability requirements if modifying the hosted app.

## Telegram bot identity (public metadata only)

- User-provided public bot address: **[@RavixNetBot](https://t.me/RavixNetBot)**.
- This username has **not** been verified via an authenticated Telegram Bot API `getMe` call. No webhook is configured.
- Public metadata is tracked in [config/telegram-public.json](config/telegram-public.json); never store private BotFather tokens here.
- [Native ShahBot connection checklist](docs/telegram-shahbot-connection.md) covers first `/start`, HTTPS staging, `admin_chat_ids`, and verification.

## Fixed business constraints

- Maximum **500 active paid subscriptions** (NOT necessarily 500 simultaneous users).
- Controlled capacity ramp: **50 → 200 → 500**, dependent on measured performance.
- Infrastructure budget ceiling **15,000,000 tomans/month**, including traffic, backup and operational allowances (prices not verified).
- Usage planning assumption: 30GB per subscribed user/month = 15TB total at 500 users, not a guarantee.
- Strict isolation from SFIORD company infrastructure and customer records.

## Prepare source on local/deployment machine (safe offline commands)

```bash
git clone https://github.com/javad-hasani/other.git
cd other/v2ray-500
bash scripts/preflight.sh
bash scripts/fetch-upstream.sh
cat vendor/UPSTREAM-COMMITS.txt
```

The fetch script only clones pinned source revisions under ignored `vendor/`. **No install script is executed.** Never put `.env`, API keys, payment details or customer data into this public repository.

## Delivery plan

- [x] Choose ShahPanel instead of Minishop; document rationale and AGPL considerations.
- [x] Pin ShahPanel/Remnawave/Node source commits and update static project dashboard.
- [x] Write [ShahPanel staging runbook](docs/shahpanel-staging-runbook.md) and [ADR-003](docs/ADR-003-shahpanel-selection.md).
- [x] Verify built-in ShahBot module, Webhook/secret verification, and document [Telegram connection checklist](docs/telegram-shahbot-connection.md); no live bot connection yet.
- [ ] Independently review source/dependencies/root installer and licenses.
- [x] User provided intended public Telegram username **@RavixNetBot** (identity recorded; ownership/`getMe` not verified).
- [ ] Keep BotFather token privately (never GitHub/ChatGPT), then connect via native ShahBot Settings after a real HTTPS panel exists.
- [ ] Start isolated ShahPanel **Laravel/MySQL** test host.
- [ ] Verify ShahPanel Persian/RTL and Zarinpal sandbox; test 500-active global cap and replay resistance.
- [ ] Start official Remnawave staging backend + one node; test v3 API interoperability.
- [ ] Secure backups/TLS, add second node; canary 50 → 200 → 500 only after measured gates.
- [ ] Acquire VPS/domain and fix Vercel Team permissions if choosing to publish the *static* status site.

**A passing synthetic PostgreSQL capacity test in this repository does not enforce the 500-person limit in ShahPanel.** Our legacy `db/` and `docs/n8n-automation.md` are **experimental archive only**. Implement any required cap inside ShahPanel's **existing MySQL sale/provisioning transaction** after auditing upstream features.

## Repository navigation

- **[HISTORY.md](HISTORY.md)** — append-only records: assumption, evidence, decision, action, test, next.
- **[ADR-003 — ShahPanel primary](docs/ADR-003-shahpanel-selection.md)** — authoritative architecture.
- [Current ShahPanel staging runbook](docs/shahpanel-staging-runbook.md)
- **[Telegram bot connection and acceptance checklist](docs/telegram-shahbot-connection.md)**
- [Architecture and trust boundaries](docs/architecture.md)
- [Production readiness checklist](docs/rollout-checklist.md)
- [Pinned upstream sources](config/upstream.lock)
- [Fetch pinned source](scripts/fetch-upstream.sh) / [offline preflight](scripts/preflight.sh)
- [Project status web prototype](site/)
- Historical: [ADR-001 Minishop](docs/ADR-001-commerce-stack.md), [ADR-002 Persian review](docs/ADR-002-persian-first.md), [archived Minishop runbook](docs/minishop-staging-runbook.md)
- Experiments NOT active: [PostgreSQL proof](db/README.md), [n8n orchestration](docs/n8n-automation.md).

**Do not claim this repository hosts the upstream ShahPanel code: it pins the upstream Git revision for reproducible cloning and installation.** It also does not deploy Xray on Vercel.
