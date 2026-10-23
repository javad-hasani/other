# V2Ray / Xray — 500-user rollout

> Status: **STAGING / NOT DEPLOYED**. This repository contains a deployment workspace and references to upstream projects, **not forks**, working containers, or a live VPN service.

## Scope

- **Hard maximum**: 500 ACTIVE subscriptions (not 500 registered identities).
- Canary phases: **50 → 200 → 500**, subject to load tests and verified user experience.
- Initial infra: **1 control-plane VPS**, **2 independent Xray node VPS**; expand based on traffic and CPU.
- Monthly infrastructure budget: **15,000,000 toman maximum** (exchange rates/provider pricing must be verified at purchase).
- Estimated traffic: **15 TB/month** at 30 GB per active subscription.
- Production requirements: domain, TLS, secrets, SSH access, backups, monitoring, alerts, payment-verification service.

## Upstream components (never copy credentials or run unreviewed install scripts)

| Role | Official repository |
|---|---|
| Core backend / control plane | https://github.com/remnawave/backend |
| Xray / Remnawave node | https://github.com/remnawave/node |
| Subscription sales automation | https://github.com/BEDOLAGA-DEV/remnawave-bedolaga-telegram-bot |
| Optional installation helper | https://github.com/Capybara-z/RemnaSetup |
| Official docs | https://docs.rw/ |

**Important:** Bedolaga is a **Telegram** bot, not a Bale bot. An Iranian payment gateway/Bale channel integration is **not shipped** here. The upstream Remnawave `panel` repository is documentation/UI-related; actual backend deployment uses `remnawave/backend`.

## Prepare sources (safe: clones only; does not start servers)

```bash
git clone https://github.com/javad-hasani/other.git
cd other/v2ray-500
bash scripts/fetch-upstream.sh
```

The script clones upstream projects into `vendor/`, which is ignored by Git. Review and pin exact upstream versions/SHAs before production.

## Production install strategy

1. Provision three separate Ubuntu 24.04 LTS VPS instances and DNS records for the control plane and nodes. Do not put secrets in GitHub.
2. Configure SSH keys, firewall, updates, and a private panel/control-plane network where feasible. Do **not** expose databases, metrics or internal panel ports publicly.
3. Follow the **official** Remnawave installation documentation for backend, PostgreSQL, Valkey, reverse proxy, TLS and subscription service: https://docs.rw/
4. Register each Remnawave Node, create a test profile/host, then validate client connections end-to-end.
5. Add Bedolaga **only after** auditing its integrations and deciding on Telegram vs Bale and an Iranian payment provider. Keep payment verification server-side.
6. Enforce the **500 ACTIVE** user limit in the provisioning backend with a transaction/lock and unique idempotency key. Do not rely on an informational `.env` field to enforce a hard capacity limit.
7. Set monitoring, alerting, backups and restore tests; then canary 50 → 200 → 500 with explicit go/no-go gates.

## Critical safety / operational notes

- The script in this repository **does not** start or modify an external server.
- Clone sources and review changes before using third-party installers, especially those requesting root.
- A public GitHub repository must never contain private keys, tokens, user records, passwords, subscription URLs or payment data.
- Avoid blind `curl | bash` and unpinned images in production. Review the upstream Docker Compose files and pin tested image digests/tags.
- Billing records are separate from the Remnawave panel database; provisioning must be idempotent and auditable.
- 500 subscriptions is an administrative cap, **not** a throughput guarantee: benchmark realistic simultaneous connections and monthly traffic.
- GitHub Actions / Vercel **cannot host long-lived TCP/UDP Xray nodes** as a replacement for VPS.

## Deployment status checklist

- [x] Upstream projects identified
- [x] GitHub staging workspace prepared
- [ ] Upstreams cloned/audited on deployment operator machine
- [ ] Domains/DNS and VPS provisioned
- [ ] Control plane running and secured
- [ ] Two nodes running and verified
- [ ] 500-active-user provisioning gate implemented and tested
- [ ] Payment gateway/channel integration verified
- [ ] Load tests, monitoring, backups and canary rollout completed

See [rollout checklist](docs/rollout-checklist.md) for acceptance criteria.
