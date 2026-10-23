# Local disposable database lab — before VPS

This lab runs **only one PostgreSQL container** on loopback port 15432 for testing the reservation guard. It does **not** run Remnawave, Xray or a payment service.

## Start (requires local Docker and Python)

```bash
cd v2ray-500
cp config/lab.env.example .env
# Edit .env and set LAB_DB_PASSWORD to a locally generated secret:
openssl rand -hex 32
docker compose --env-file .env -f docker-compose.lab.yml up -d
python3 -m pip install "psycopg[binary]>=3.2,<4"
set -a; source .env; set +a
export DATABASE_URL="postgresql://${LAB_DB_USER}:${LAB_DB_PASSWORD}@127.0.0.1:${LAB_DB_PORT}/${LAB_DB_NAME}"
python3 tests/test_capacity.py
```

**WARNING:** `tests/test_capacity.py` explicitly truncates local provisioning tables. Never point `DATABASE_URL` to a shared, existing, or production database.

## Stop

```bash
docker compose --env-file .env -f docker-compose.lab.yml down
```

Use `down --volumes` only when you intentionally want to destroy all local lab test data. No managed production resources are involved.

## Status

CI already tests this SQL against disposable PostgreSQL. Local Docker is optional and not required for keeping the staging repo ready while waiting for servers.
