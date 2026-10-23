# Production rollout checklist — 500 active subscriptions

## Prerequisites
- [ ] Ownership/administrative access to three VPS (control plane, node-1, node-2)
- [ ] Three valid DNS records; HTTPS certificates
- [ ] SSH keys only; firewall restricting admin and database ports
- [ ] External encrypted backups, tested restore and operational contact
- [ ] Reviewed/pinned vendor revisions and security/abuse policy

## Control plane
- [ ] Deploy `remnawave/backend` per official docs, including Postgres and Valkey
- [ ] Ensure reverse proxy/TLS and subscription endpoint work
- [ ] Public PostgreSQL, metrics and administrative backends blocked
- [ ] Credentials generated and stored in external secret manager
- [ ] Configure health monitoring and recoverability tests

## Nodes
- [ ] Provision node-1 and node-2 in separate failure domains when practical
- [ ] Register both nodes in Remnawave, verify authenticated communication
- [ ] Validate real client connection, speed, latency, bandwidth counters
- [ ] Test behavior when one node is unavailable; failover is client-dependent

## Business automation
- [ ] Decide Telegram (Bedolaga) vs Bale / web checkout
- [ ] Iranian payment gateway adapter, server-side signature check, fraud and retry handling
- [ ] Atomic hard cap 500 ACTIVE subscriptions; apply cap before provisioning
- [ ] Per-payment idempotency key and reconciliation queue; fail closed on DB outage
- [ ] Create/renew/suspend only from verified paid orders; audit each action
- [ ] Expiry, quotas, traffic reset, notification integration

## Canary gates
- [ ] 50 users: validate app compatibility, connection success, support workflow
- [ ] 200 users: measure per-node CPU, p95 latency, errors, traffic and VPS quotas
- [ ] 500 users: allow only if capacity and budget comfortably cover actual demand
- [ ] Explicit rollback and incident checklist

## Acceptance
- [ ] Successful end-to-end creation, activation, connection, usage, expiry and renewal
- [ ] 501st **active** account creation rejected, concurrent provisioning does not overrun cap
- [ ] No duplicate subscriptions on retry / duplicate payment webhook
- [ ] Failover tested and documented, backups restored in test environment
- [ ] Monitoring + alerts active; no private credentials committed
- [ ] Cost remains <= 15,000,000 toman/month based on actual invoices and FX
