# ADR-002 — Persian-first storefront evaluation (2026-10-24)

Status: **EVALUATION PRIORITY UPDATED — NO PRODUCTION SWITCH OR DEPLOYMENT**.
Supersedes the assumption in ADR-001 that Minishop needs only a small localization gap. Keeps ADR-001 as a historical decision.

## Trigger
The requested admin/customer product must be usable in **Persian (fa), RTL, Iranian checkout and toman/rial units**. The official Minishop admin demo is Russian/English. A superficial Persian read-only mockup is not sufficient.

## Verified findings (primary source evidence)

1. **Remnawave official core panel** supports Persian already. Translation language list: https://docs.rw/contributing/i18n/ . Do not rewrite/translate its entire admin panel; use official language switcher.
2. **Minishop**: default locale files are `locales/ru.json` and `locales/en.json`; its **System → Translations** editor can create an additional language `fa` and store overrides in `data/locales-overrides.json` / DB. Source: https://github.com/3252a8/remnawave-minishop/blob/main/docs/features/admin-panel.md . Frontend constants order `ru,en` and have no built-in Persian label/flag at reviewed version: https://github.com/3252a8/remnawave-minishop/blob/main/frontend/src/lib/webapp/constants.ts . Proper bidirectional RTL layouts, checkout and form alignment require separate testing/patches. **Selecting `fa` in editor DOES NOT mean the full interface is already translated or RTL.**
3. **ShahPanel**: Persian-first open-source commercial subscription/reseller/admin/customer site with native `lang/fa/*.php` and `APP_LOCALE=fa`; code contains actual `ZarinpalGateway`, `ZarinpalClient`, `ZarinpalWebhookController`, and Remnawave API integration. Sources:
   - https://github.com/shahinst/shahpanel
   - https://github.com/shahinst/shahpanel/blob/master/.env.example
   - https://github.com/shahinst/shahpanel/blob/master/app/Services/PaymentGateways/ZarinpalGateway.php
   - https://github.com/shahinst/shahpanel/blob/master/app/Services/Remnawave/RemnawavePanelClient.php
   - Source code `lang/fa/` contains dozens of organized translation modules.
   - The newest identified public release was **v3.38.5 (2026-10-17)**, with Feature tests present; tests have **not** been executed by us.
   - License **AGPL-3.0-or-later**, which allows commercial use but imposes network-use source-availability obligations for modified versions; review full terms before shipping changes.
4. **No globally atomic 500-active-entitlement cap** has been verified in either shop. Do not assume `max_users` or per-server quotas equal a commercial global seat cap.

## Comparison for Iran-first MVP

| Goal | ShahPanel | Minishop |
|---|---|---|
| Persian admin UI | **Native** `APP_LOCALE=fa` and `lang/fa/` | Additional `fa` override possible, complete strings not translated |
| Customer RTL web UX | Persian-first claimed; needs real-browser QA | RTL not validated; likely styling effort |
| Domestic PSP | Zarinpal implementation found in source | Iranian PSP not verified |
| Web-first without Telegram | Native web/admin/customer reseller product per README | Explicitly documented `TELEGRAM_ENABLED=False` |
| Remnawave API | Code found, claims v3.x | Supported, QA matrix with several 3.x presets |
| License | AGPL-3.0-or-later (publish modified server code to users per license) | MIT (more permissive) |
| Backend tech | Laravel 11 / PHP 8.2+ / MySQL 8 | Python / PostgreSQL / Redis / Svelte |
| Operational weight | Multiple reseller modules and MySQL — overhead TBD | Commerce app already includes several components — overhead TBD |
| Proven resilience | Must test deploy, payments and API against pinned Remnawave | Must test deployment + Persian customizations + Iranian PSP |
| True global 500 paid entitlements | **Unknown, test required** | **Unknown, test required** |

## New decision

**Promote ShahPanel to the first Iranian-product evaluation candidate**, without claiming it is better tested or secure. Keep Minishop as the fallback when simpler architecture, MIT license or upstream stability outweighs localization costs.

Because no VPS/controlled Docker host is connected, **there is no live Persian storefront/admin here**. Our static Vercel status dashboard is not a substitute for either shop's real admin UI.

DO NOT:
- Translate thousands of Minishop strings or create a new admin dashboard before running the already-Persian ShahPanel.
- Execute `install.sh` on shared hosts without code/security review.
- Point ShahPanel at real Remnawave credentials until isolated staging and endpoint validation.
- Deploy both storefronts simultaneously, or mix their customer/payment databases.

## Gate for choice

1. Isolated Ubuntu VM/Docker staging (not production) with dummy admin and no real payment.
2. ShahPanel: verify true Persian and RTL for admin, customer signup, packages, help, purchase and support; verify price units and Jalali dates.
3. Verify Remnawave 3.x API contract: create, renew, suspend, quota, squad placement, exact remote identity, retry and error handling.
4. Verify Zarinpal *sandbox* and receipt validation, including duplicate callbacks, fake authority, declined payment, timeout and refund workflow. PSP must support the actual business category.
5. Audit source and dependencies for unsafe command execution, auth bypass, data leakage, invoices and backup. Run project tests.
6. Verify 500 active paid-entitlement capacity rule under concurrent checkout and whether a minimal patch is required.
7. Measure memory/CPU and monthly infra costs (Laravel/MySQL + Remnawave/Postgres/Valkey + Xray nodes) against 15-million-toman ceiling.
8. If successful, adopt ShahPanel; otherwise use Minishop with systematic `fa` overrides + RTL review + PSP adaptation.

Status: research and priority changed **only**. All real runtime and commercial tests remain pending.
