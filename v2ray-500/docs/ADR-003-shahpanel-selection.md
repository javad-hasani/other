# ADR-003 — ShahPanel replaces Minishop (2026-10-24)

Status: **ACCEPTED AS THE PROJECT'S PRIMARY COMMERCE/ADMIN PLATFORM** — code/configuration decision only; **NOT DEPLOYED OR PRODUCTION APPROVED**.

Supersedes ADR-001's Minishop-first baseline and ADR-002's "ShahPanel evaluation-first" status. Keep both as historical records. User explicitly requested ShahPanel replace Minishop.

## Architecture

| Layer | Chosen component | Database/runtime |
|---|---|---|
| Iranian sales website, Persian admin/reseller/customer portal, wallets, order lifecycle, Zarinpal integration | **ShahPanel**: https://github.com/shahinst/shahpanel | Laravel 11, PHP 8.2+, MySQL 8 |
| User subscriptions, VPN backend API, Squads | **Remnawave backend**: https://github.com/remnawave/backend | Its own PostgreSQL + Valkey |
| Traffic routing | **2 Remnawave Nodes**: https://github.com/remnawave/node | Xray on independent VPS |
| Vercel | Optional *static project status/landing* page | Does **not** host PHP, MySQL, Remnawave daemons or Xray nodes |
| n8n + custom Postgres capacity guard | **Retained as archival/offline proof only** | NOT part of the selected commercial production stack |

**Data ownership:** ShahPanel is the *only* business/commerce source of truth (orders, wallet, entitlements); Remnawave is the authoritative remote subscriber state. Do not introduce a separate n8n billing database or Minishop instance. Reconciliation and reliable webhook semantics must be tested.

## Reproducible source baseline

- ShahPanel **v3.38.5** (2026-10-17), tag resolved to commit `e898e84999779fd105a3e948a95ced3f44db9df1`; AGPL-3.0-or-later.
- Remnawave Backend **3.4.7**, commit `52321390ac4efe04a610811446d87335f1d10a93`.
- Remnawave Node **3.4.3**, commit `2ad154f8f1016c94c1872f337268af878af61b18`.
- Version/source lock: [config/upstream.lock](../config/upstream.lock).

**Pinning sources does not certify compatibility or security.** ShahPanel docs mention Remnawave v2.x in places while current code README claims v3.x compatibility: **verify installed-version API contracts with real integration tests**.

## Rationale and limits

ShahPanel already includes native `APP_LOCALE=fa`, dozens of `lang/fa` modules, Persian customer/admin UI, `VPN_CURRENCY=IRT`, existing Zarinpal request/callback code, and a Remnawave API client. Reuse these instead of translating Minishop or writing a new storefront.

This is not a claim that the entire Persian UX, local payment authorization, 500-user hard cap, resilience, or security was already tested. Existing code does not prove a transactionally enforced **global 500-active-entitlement** limit; a minimal patch may be needed inside ShahPanel's own purchase/provisioning transaction. Do not apply `db/migrations/001_capacity_guard.sql` to ShahPanel's MySQL or Remnawave's PostgreSQL.

**Licensing:** ShahPanel is AGPL-3.0-or-later; commercially operating modified versions requires compliance with all conditions, including relevant source availability for network users. Review full licenses and third-party notices before distributing or modifying.

## Operational placement and budget

Initial design: one control host may serve *both* ShahPanel/MySQL and Remnawave/PostgreSQL/Valkey if isolated, measured and secured; plus two Xray Node VPSs. This is **a capacity hypothesis, not a guarantee**. The 15,000,000-toman monthly infrastructure ceiling and pilot 50 → 200 → 500 remain. PHP and MySQL add real resource usage over the previous Minishop design; monitor sizing/backup cost before committing.

No company SFIORD server, credentials, data or repo is to be used.

## Deployment gate — NOT MET

- [ ] Security and license/dependency audits on source, root installer and exposed endpoints
- [ ] Isolated fresh Ubuntu VM, PHP/MySQL, HTTPS, least privilege, protected admin access
- [ ] ShahPanel Persian admin/customer screens exercised on mobile and desktop
- [ ] Zarinpal sandbox server-side verification with fake/duplicate/failed callback tests
- [ ] Remnawave v3.x create/renew/suspend/sync and loss-of-connectivity recovery
- [ ] Atomic hard limit 500 active (including concurrent last-slot checkout), renewals and refunds
- [ ] Node 1 and Node 2 tested with real clients, monitoring and backups/restore
- [ ] Monthly real costs and provider acceptable-use terms verified

Until these are met, **commercial checkout and production proxy use must remain disabled**.

## Rollback

If ShahPanel fails essential security/commerce/connectivity tests or licensing is unsuitable, reopen a new ADR. Minishop remains *archived fallback*, not an active dependency. Never silently deploy both billing systems.
