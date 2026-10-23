# Xray-500 — reuse-first commercial rollout

> **STAGING PLANNING ONLY — NO VPS / NO ACTIVE VPN / NO LIVE PAYMENT / NO VERCEL PRODUCTION LINK**.
>
> **Decisions and completed evidence:** [HISTORY.md](HISTORY.md). **Binding current architecture:** [ADR-001](docs/ADR-001-commerce-stack.md). Both are mandatory reading before any edit or deployment.

## Final candidate for isolated evaluation

Our project is NOT a new Xray or subscription billing application. **Reuse maintained software and patch only demonstrable gaps.**

| Layer | Selected primary upstream | Status |
|---|---|---|
| Web storefront, customer cabinet, admin, subscriptions/payments | [Remnawave Minishop](https://github.com/3252a8/remnawave-minishop), **MIT**, web-only mode supported | **Chosen for staging evaluation**, not deployed |
| Account & Node control plane | [Official Remnawave backend](https://github.com/remnawave/backend) | Not deployed |
| Traffic relays | 2 × [Official Remnawave Nodes](https://github.com/remnawave/node) | Not deployed |
| Vercel | Optional status/landing site prototype in [site/](site/) | **Vercel team access blocked**, not live |
| n8n / custom SQL guard | Experimental fallback references only ([docs](docs/n8n-automation.md), [db](db/README.md)) | **NOT part of selected MVP** |

Minishop supports registration via email and web-based admin without Telegram (read its [no-Telegram guide](https://github.com/3252a8/remnawave-minishop/blob/main/docs/features/telegram-optional.md)). **Bedolaga is NOT selected:** its LICENSE contains Commons Clause restricting commercial service resale, despite short README MIT text. Alternative [STEALTHNET](https://github.com/STEALTHNET-APP/remnawave-STEALTHNET-Bot) requires an independent security/license fit review.

### Business constraints

- Absolute cap **500 paid active entitlements**, including staged intake **50 → 200 → 500**, not 500 simultaneous sessions.
- Infrastructure OPEX ceiling **15,000,000 toman/month**; provider traffic/FX and invoices not yet confirmed.
- Planning usage: 30 GB/entitlement/month × 500 = 15 TB/month, benchmark before accepting 500.
- All project infrastructure must remain completely separate from SFIORD company systems and credentials.

### Development rules

1. Search upstream settings and modules, then test them **before** designing a new component.
2. Keep one commerce database and one entitlement lifecycle owner (Minishop). **Do not** run duplicate n8n checkout or custom billing database.
3. Only add verified missing capabilities, probably Iranian PSP, Persian UX and true atomic 500-active seat cap. **None is implemented/integrated yet**.
4. No real credentials, users or payment details in this public repository.
5. Record **تصور / شاهد / تصمیم / اقدام / تست / مرحله بعد** in [HISTORY.md](HISTORY.md) after every material change.
6. Stage first, then trial with 50 real users and measured go/no-go gates.

## Safe pre-server work

```bash
git clone https://github.com/javad-hasani/other.git
cd other/v2ray-500
bash scripts/preflight.sh
bash scripts/fetch-upstream.sh
```

These scripts only validate the workspace and **clone exactly pinned upstream source commits** into ignored `vendor/`. They do not deploy containers, install software, call a payment provider or touch remote servers.

Current reviewed release snapshot (2026-10-23):
- Minishop **v3.8.3** (`0fe3ac3abba160517538cc86e812e655d46fe55a`)
- Remnawave Backend **3.4.7** (`52321390ac4efe04a610811446d87335f1d10a93`)
- Remnawave Node **3.4.3** (`2ad154f8f1016c94c1872f337268af878af61b18`)

The versions are pinned for **reproducible evaluation**, not verified compatibility/security.

## Required proof before buying services from customers

- [x] Upstream candidates and licenses reviewed from primary repositories
- [x] Minishop selected for **staging evaluation**
- [x] Source revisions pinned and staging runbook written
- [x] Previous experimental 500-seat SQL guard passed **disposable** PostgreSQL CI tests (NOT integrated in Minishop)
- [ ] Independent license/security and dependency audit
- [ ] Remnawave + Minishop web-only Docker integration tested
- [ ] Iranian PSP chosen, validated and integrated if required
- [ ] True atomic 500-active cap in actual Minishop checkout verified
- [ ] Persian checkout and toman/rial correctness verified
- [ ] 3 VPS and domains acquired, firewalls/TLS/backups in place
- [ ] Real client connectivity/load tests, 50 → 200 → 500 phase sign-offs

## Project index

- [HISTORY.md](HISTORY.md) — append-only engineering log; most important document
- [ADR-001 — current approved staging direction](docs/ADR-001-commerce-stack.md)
- [Minishop staging runbook](docs/minishop-staging-runbook.md)
- [Build versus reuse evaluation](docs/build-vs-reuse-review.md)
- [Pinned upstream sources](config/upstream.lock)
- [Offline source preflight](scripts/preflight.sh)
- [Read-only status dashboard prototype](site/)
- [Earlier architecture sketch — experimental](docs/architecture.md)
- [Earlier n8n orchestration — experimental, NOT selected](docs/n8n-automation.md)
- [Earlier 500-seat SQL proof — isolated CI, NOT selected for production](db/README.md)
- [Local disposable database lab](docs/local-lab.md)

**Important:** GitHub or Vercel cannot host persistent Xray proxy Nodes; eventual customer website may be hosted separately, but the Remnawave/Minishop backend needs persistent infrastructure.
