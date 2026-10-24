# ShahPanel — primary Persian staging runbook

Status: **prepared only; no VPS, no actual install and no production access**.
Start by reading [ADR-003](ADR-003-shahpanel-selection.md) and [HISTORY.md](../HISTORY.md).

## Safe source preparation (offline)

```bash
git clone https://github.com/javad-hasani/other.git
cd other/v2ray-500
bash scripts/preflight.sh
bash scripts/fetch-upstream.sh
cat vendor/UPSTREAM-COMMITS.txt
```

Expected pinned copies under `vendor/` (gitignored): `shahpanel`, `remnawave-backend`, `remnawave-node`. The fetch script **only clones and checks out source**, not a live service.

## Isolated staging prerequisites

- Fresh standalone Ubuntu 24.04 VPS or isolated local VM, **not** any SFIORD resource. Confirm public IP, optional domains, SSH key and backups.
- ShahPanel upstream requires PHP >=8.2, Laravel 11, MySQL 8, Nginx, Composer, Node toolchain for assets, and extensions per upstream. It has an `install.sh` that runs as root; **review it before using on a disposable VM**, never `curl | bash` uninspected.
- Remnawave backend runs separately with its own PostgreSQL + Valkey. Start with one Remnawave Node, add the second after real traffic succeeds.
- Prefer one staging VM at first; sharing a three-VPS control-plane host is *optional* only after sizing, fault isolation, firewall and backups are assessed.

## Installation outline (do not run against live servers without review)

1. On the isolated VM, inspect pinned `vendor/shahpanel/install.sh`, `composer.lock`, `README.md`, `LICENSE` and GitHub Actions; verify no destructive commands or secrets exfiltration and check dependency advisories.
2. Follow the upstream [official Persian README](https://github.com/shahinst/shahpanel/blob/master/README.md). Use dedicated MySQL account with only `shahpanel` database rights. Make `.env` locally, never commit it.
3. Review `.env.example`: `APP_LOCALE=fa`, `APP_TIMEZONE=Asia/Tehran`, `VPN_CURRENCY=IRT` (toman), `APP_DEBUG=false`, `SESSION_SECURE_COOKIE=true` only after HTTPS, and generated `APP_KEY`.
4. Use `php artisan migrate --force` **only after** reviewing schema changes and only on the disposable ShahPanel staging database. Never apply our separate PostgreSQL SQL experiment to this MySQL database.
5. Test first admin login, permissions/TOTP/CSRF, Persian menus and RTL, customer registration, tickets and orders using synthetic customer records.
6. Deploy official Remnawave Backend independently per https://docs.rw/ with private PostgreSQL, Valkey, admin/API access control, TLS and backups. Register one node and verify the sample client config.
7. In ShahPanel **Servers → Add Remnawave**, use short-lived least-privilege test token and a staging API endpoint. Use **Test connection → Sync Squad and Nodes → Create package → Create synthetic subscriber → Renew → Disable**. Respect the pinned Remnawave API version and actual user IDs. Upstream guide: https://github.com/shahinst/shahpanel/blob/master/docs/fa/remnawave-shahpanel.md .
8. Zarinpal: validate provider account approval and *sandbox* capability before testing. Test `amountRial = gross_toman × 10`, callback server-side verification, replay, invalid authority, webhook timeouts and refund reconciliation; do not enable public checkout or hard-code a merchant ID in Git.
9. **Global subscription cap 500**: inspect ShahPanel existing account/create/purchase flow before any customization. Verify 499 + two simultaneous paid orders yields exactly one 500th active user, with the other refunded/not charged; verify renewals of 500th and remote disable before releasing a slot. If absent, patch **ShahPanel's own MySQL transaction**; one DB for commerce.
10. Backups/restores, logs/alerts, node outage, throughput and costs; launch 50-client canary only after passing all gates and owner approval.

## Testing without actual VPS (later, on local machine)

ShahPanel upstream CI already shows a reproducible MySQL 8 + PHP 8.3 GitHub Actions test stack in `.github/workflows/ci.yml`:

```bash
# inside vendor/shahpanel after source review, with disposable MySQL database
composer install --no-interaction --prefer-dist
cp .env.example .env
php artisan key:generate
vendor/bin/phpunit
```

The above commands are guidance, **not executed by this assistant**. Existing upstream tests should run on a *disposable* local DB. Do not copy sample test credentials into any real hosted application.

## Known blockers

- No installed ShahPanel or linked Remnawave service.
- No licensed/operational Zarinpal merchant credentials or verified legal eligibility.
- No security audit or compatibility proof with these pinned releases.
- No enforced 500-user global cap in live ShahPanel checkout.
- Vercel connection may host the **read-only project status site only**, never PHP/MySQL/Remnawave daemon services.
