> **ARCHIVED DESIGN SPIKE ONLY.** The selected commercial platform is ShahPanel (Laravel/MySQL). No n8n purchase, payment, renewal or subscription workflow is in the selected stack. See [ADR-003](ADR-003-shahpanel-selection.md); do not deploy this plan.

---

# n8n automation contracts — implementation-ready design, NOT deployed

## Boundaries

`PaymentVerifier` is a separate trusted backend, not n8n's public payment Webhook. It must verify payment with the provider **server-to-server** (or validated provider webhook signatures) before creating an internal event. n8n handles orchestration; it must not trust `paid: true` from a browser.

Input to internal orchestration after verification:

```json
{
  "event_id": "unique-provider-event-id",
  "verified_payment_reference": "internal-payment-proof-id",
  "customer_ref": "internal-pseudonymous-customer-id",
  "operation": "activate",
  "idempotency_key": "payment:unique-provider-event-id:activate",
  "request_fingerprint": "sha256-of-canonical-verified-order-payload",
  "expires_at": "2026-11-22T00:00:00Z"
}
```

This sample event is documentation, not evidence of actual payment. Store the verified order and proof in the **billing** database; do not log full user connection links. Use source-signed internal HMAC/mTLS with request age + replay rejection. Never expose DB credentials in Git.

## Workflow: ActivateSubscription

| # | Node | Contract / behavior |
|---|---|---|
| 1 | Internal Trigger (Webhook or Execute Workflow) | Only authenticated events from PaymentVerifier; reject unauthenticated public requests |
| 2 | Code: ValidateEvent | Require nonempty `customer_ref`, unique `idempotency_key`, canonical `request_fingerprint`, future ISO expiry; reject invalid operation |
| 3 | PostgreSQL: ReserveSeat | Parameterized: `SELECT provisioning.reserve($1,$2,$3,$4::timestamptz) AS result;` with above customer/key/hash/expiry |
| 4 | Switch: Reservation | `RESERVED` → continue; `ALREADY_ALLOCATED` → reconciliation / existing subscription; `CAPACITY_REACHED` → queue/refund; `IDEMPOTENCY_CONFLICT` → security alert; other → manual review |
| 5 | PostgreSQL: MarkProvisioning | `SELECT provisioning.transition($1, 'provisioning');` |
| 6 | HTTP Request: Remnawave | Call installed-version official create-user API; idempotency via stored `customer_ref` ↔ remote user mapping; never invent an API path |
| 7 | PostgreSQL: MarkActive | **Only after verifying remote user exists:** `SELECT provisioning.transition($1,'active',$2);` |
| 8 | Billing: ConfirmDelivery | Mark verified order delivered; return subscription URL by secure customer channel, redact from logs |

### Failure handling

- On 429/5xx/network timeout from Remnawave: exponential retry, max 3 attempts, then queue reconciliation; keep occupied seat.
- On ambiguous timeout: query remote state first. **Do not blindly create a second remote user**.
- On verified remote absence and cancelled/refunded order: `reserved|provisioning → deactivating → released` after audit.
- On capacity failure after a verified charge: add to refundable/waitlist queue; do not silently lose money.
- An old idempotency key returns its prior result, including prior `CAPACITY_REACHED`. A new paid order/event must use a new key.
- Configure separate n8n `Error Trigger` workflow with redacted error and run ID notifications.
- All Postgres nodes must use a least-privilege **function-execution** account, not the migration owner.

## Workflow: RenewSubscription

1. Same verified trusted event and deduplication process in **billing DB**.
2. Lookup remote and local subscription; require active, otherwise route to reconciliation.
3. Set an **absolute** confirmed expiry, not “add 30 days every retry.”
4. `SELECT provisioning.renew_until($1,$2::timestamptz);`; mirror absolute expiration to Remnawave with post-write verification.
5. Record delivery and amount. Retries must not extend twice.

## Workflow: Reconciliation

- Trigger: Schedule Trigger every hour and after an unknown Remnawave result.
- Compare pending/reserved/deactivating local records to remote users and actual statuses.
- Do not release a seat until remote deactivation is confirmed; do not mark active without a verified remote ID.
- Escalate mismatches after limited retries and keep full technical audit without secrets.

## Workflow: NotificationsAndHealth

- Schedule Trigger once a minute for basic node health; daily reconciliation and backup verification.
- Use provider/Remnawave node health with timeout + consecutive failures.
- Alert on node-down, 75% monthly provider traffic allowance, DB failure, backup failure, and payment/provisioning discrepancies.
- Notification channel is not selected yet: Telegram (Bedolaga), Bale or business website.

## Pending integration details

Actual Remnawave API version/schema, payment gateway/provider, customer identity/channel, subscription delivery format, secure event signing and automation credentials. No production n8n JSON is called 'import-ready' until those contracts are chosen and end-to-end tested.
