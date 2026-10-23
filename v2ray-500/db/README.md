# Provisioning database

This migration runs on a **dedicated PostgreSQL 16+ provisioning / billing integration database**, not the Remnawave product DB. It is a **database gate**, not the complete payment or Remnawave API integration.

## Apply (only on an empty dedicated DB)

```bash
export DATABASE_URL='postgresql://PROVISIONING_ADMIN:***@HOST:5432/provisioning_db'
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f db/migrations/001_capacity_guard.sql
psql "$DATABASE_URL" -c 'SELECT * FROM provisioning.capacity_status;'
```

Migration is repeatable for the same schema. The `hard_max` constraint prevents a limit above 500. The current rollout defaults to 50 and can be changed **by an authorized migration/admin only**:

```sql
BEGIN;
UPDATE provisioning.policy SET rollout_max = 200, updated_at = now() WHERE singleton = true;
COMMIT;
```

Do not raise the staged limit until monitoring and canary are signed off.

## Least-privilege role example

First create the `provisioning_app` login with a unique secret outside Git and without superuser privileges. Then as the DB owner:

```sql
GRANT USAGE ON SCHEMA provisioning TO provisioning_app;
GRANT SELECT ON provisioning.capacity_status TO provisioning_app;
GRANT EXECUTE ON FUNCTION provisioning.reserve(text,text,text,timestamptz) TO provisioning_app;
GRANT EXECUTE ON FUNCTION provisioning.transition(text,text,text) TO provisioning_app;
GRANT EXECUTE ON FUNCTION provisioning.renew_until(text,timestamptz) TO provisioning_app;
-- No INSERT / UPDATE / DELETE privileges on provisioning.* tables.
```

Important: anyone authorized to call `transition()` can mark a record released and free a seat. Give lifecycle permissions only to an authenticated backend worker **that verifies actual Remnawave deletion**. Ideally use separate roles for reserving and reconciling.

## Code & operational contracts

- `reserve(customer_ref, idempotency_key, request_fingerprint, expires_at)`: atomic slot claim; returns JSONB with `ok` and stable `code`.
- `transition(customer_ref, next_state, remote_user_id)`: allowed paths `reserved → provisioning → active → deactivating → released` (also `reserved/provisioning → deactivating` after cancellation and remote-absence verification).
- `renew_until(customer_ref, absolute_expiry)`: idempotent by absolute expiry (never increment duration on retry).
- `capacity_status`: counts all occupied states, including pending remote release.

`request_fingerprint` **must hash the canonical verified order payload** including customer, product and expiry. Do not accept an arbitrary fingerprint from an untrusted client.

## Local integration test (DISPOSABLE DB ONLY)

```bash
python -m pip install "psycopg[binary]>=3.2,<4"
export DATABASE_URL='postgresql://postgres:ci_only_disposable_password@127.0.0.1:5432/provisioning_ci'
python tests/test_capacity.py
```

**WARNING:** Test script truncates the provisioning tables. Only run it against a disposable test instance (GitHub Actions uses its own ephemeral PostgreSQL service).

## Non-goals and remaining work

No payment signature verification, refund logic, provider-specific API client, user-facing quota limiter, distributed provider failover, real-time customer analytics or production rollback is implemented yet. A slot limit is not a physical server capacity benchmark.
