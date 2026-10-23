"""Integration tests for 500-active-subscription guard.

Requires disposable PostgreSQL 16+ and psycopg 3. Never run against production.
DATABASE_URL must target a test database; this script truncates provisioning tables.
"""
import os
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from pathlib import Path

import psycopg

DSN = os.environ["DATABASE_URL"]
MIGRATION = Path(__file__).resolve().parents[1] / "db/migrations/001_capacity_guard.sql"


def provision(customer, key, fingerprint=None, conn=None):
    expiry = datetime.now(timezone.utc) + timedelta(days=30)
    params = (customer, key, fingerprint or f"sha256:{key}", expiry)
    sql = "SELECT provisioning.reserve(%s,%s,%s,%s)"
    if conn is not None:
        return conn.execute(sql, params).fetchone()[0]
    with psycopg.connect(DSN, autocommit=True) as db:
        return db.execute(sql, params).fetchone()[0]


def stage(db, limit):
    db.execute("UPDATE provisioning.policy SET rollout_max=%s,updated_at=now() WHERE singleton=true", (limit,))


def occupied(db):
    return db.execute("SELECT occupied FROM provisioning.capacity_status").fetchone()[0]


def reset(db):
    db.execute("TRUNCATE provisioning.command_receipts,provisioning.subscriptions RESTART IDENTITY")
    stage(db, 50)


def expect(response, code, ok):
    assert response["code"] == code, response
    assert response["ok"] is ok, response


def main():
    # disposable CI database only; never use a connection to existing production data.
    with psycopg.connect(DSN, autocommit=True) as db:
        db.execute(MIGRATION.read_text(encoding="utf-8"))
        reset(db)
        expect(provision("customer-a","payment-a",conn=db), "RESERVED", True)
        expect(provision("customer-a","payment-a",conn=db), "RESERVED", True)  # exact replay
        expect(provision("customer-a","payment-a","other-hash",conn=db), "IDEMPOTENCY_CONFLICT", False)
        expect(provision("customer-b","payment-a","sha256:payment-a",conn=db), "IDEMPOTENCY_CONFLICT", False)
        expect(provision("customer-a","payment-b",conn=db), "ALREADY_ALLOCATED", False)
        assert occupied(db) == 1
        expect(db.execute("SELECT provisioning.transition(%s,%s)",("customer-a","active")).fetchone()[0],
               "ILLEGAL_TRANSITION",False)
        expect(db.execute("SELECT provisioning.transition(%s,%s)",("customer-a","provisioning")).fetchone()[0],
               "STATE_CHANGED",True)
        expect(db.execute("SELECT provisioning.transition(%s,%s)",("customer-a","active")).fetchone()[0],
               "REMOTE_ID_REQUIRED",False)
        expect(db.execute("SELECT provisioning.transition(%s,%s,%s)",("customer-a","active","remote-a")).fetchone()[0],
               "STATE_CHANGED",True)
        until = datetime.now(timezone.utc) + timedelta(days=60)
        expect(db.execute("SELECT provisioning.renew_until(%s,%s)",("customer-a",until)).fetchone()[0],
               "RENEWED",True)
        expect(db.execute("SELECT provisioning.transition(%s,%s)",("customer-a","deactivating")).fetchone()[0],
               "STATE_CHANGED",True)
        assert occupied(db) == 1  # do not free slot until remote disable confirmed
        expect(db.execute("SELECT provisioning.transition(%s,%s)",("customer-a","released")).fetchone()[0],
               "STATE_CHANGED",True)
        assert occupied(db) == 0
        expect(provision("customer-a","payment-c",conn=db), "RESERVED", True)
        reset(db)

    # Race test: 64 parallel verified orders competing for 50 seats.
    def reserve_index(i):
        return provision(f"race-{i}",f"race-order-{i}")

    with ThreadPoolExecutor(max_workers=16) as pool:
        results = list(pool.map(reserve_index, range(64)))

    assert sum(x["code"] == "RESERVED" for x in results) == 50, results
    assert sum(x["code"] == "CAPACITY_REACHED" for x in results) == 14, results

    with psycopg.connect(DSN, autocommit=True) as db:
        assert occupied(db) == 50
        stage(db, 200)
        for i in range(50, 200):
            expect(provision(f"stage200-{i}",f"order200-{i}",conn=db),"RESERVED",True)
        assert occupied(db) == 200
        expect(provision("stage200-over","order200-over",conn=db),"CAPACITY_REACHED",False)

        stage(db, 500)
        for i in range(200, 500):
            expect(provision(f"stage500-{i}",f"order500-{i}",conn=db),"RESERVED",True)
        assert occupied(db) == 500
        expect(provision("user501","order501",conn=db),"CAPACITY_REACHED",False)

        # Freeing a reservation requires both deactivation transitions.
        expect(db.execute("SELECT provisioning.transition(%s,%s)",
             ("stage500-499","deactivating")).fetchone()[0],"STATE_CHANGED",True)
        assert occupied(db) == 500
        expect(db.execute("SELECT provisioning.transition(%s,%s)",
             ("stage500-499","released")).fetchone()[0],"STATE_CHANGED",True)
        assert occupied(db) == 499
        expect(provision("user501","order501-new",conn=db),"RESERVED",True)
        assert occupied(db) == 500

        # Old failed idempotency key retains its failure result; new payment attempt gets a new key.
        expect(provision("user501","order501",conn=db),"CAPACITY_REACHED",False)

    print("PASS: idempotency, lifecycle, renewal, 64-way race, stages 50/200/500, 501st denied")


if __name__ == "__main__":
    main()
