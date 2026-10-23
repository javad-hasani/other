# Security and release policy

## Scope
This is a PUBLIC staging repository in the `javad-hasani/other` project. It may contain only non-confidential planning, schema, tests and templates.

## Secrets and personal data

- Never commit `.env`, secret keys, database URLs with passwords, cloud tokens, certificates, VPN subscription URLs, IP allowlist personal addresses or real customer data.
- Use GitHub Actions repository/environment secrets for any future authenticated deploy, **never** publish untrusted PR code with secrets.
- Prefer a private dedicated commercial repository before adding proprietary payment code or customer analytics.
- Rotate credentials if accidentally disclosed; redacting a later commit does not invalidate leaked secrets.

## Change control

1. Pull and read `HISTORY.md` before any edits. Append change/decision/test evidence to it after work.
2. Compare and pin upstream source commits, image versions, licenses and advisories; do not execute a remotely hosted shell script without inspecting it.
3. Require a staging environment, tests and explicit authorization before installing or changing customer-facing Xray configurations.
4. Avoid deploying on SFIORD production or other shared business systems.
5. Keep PostgreSQL, Valkey, metrics, Xray node control ports and administrative endpoints private or allowlisted.
6. Separate billing payment verification, provisioning orchestration and Remnawave/Xray data plane. Only release capacity after verified remote deactivation.

## Backups and observability

- Encrypt offsite PostgreSQL + relevant panel configuration backups; test restore to a disposable environment.
- Keep minimal logging and rotate/redact data, especially payment and subscription artifacts.
- Track per-node egress quota, network error rate, CPU steal, latency, database health, canary completion and data consistency.
- Alerts may notify to Bale/Telegram once a supported channel is selected.

## Next review gates

- Compliance with the VPS acceptable-use policy and applicable laws.
- Project licensing/attribution, especially the backend and UI licenses.
- Remnawave version compatibility with node + Bedolaga.
- Server role-based access, audit logging, account takeover resistance and threat model review.
- End-to-end tests for charge→allocation→delivery→expiry/refund.
