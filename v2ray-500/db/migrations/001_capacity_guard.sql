-- V2Ray-500 / provisioning reservation guard
-- PostgreSQL 16+ | migration 001 | scope: provisional billing/provisioning database ONLY
-- Does not modify Remnawave's own PostgreSQL schema.
--
-- CRITICAL: Call only after independently verified payment. This is a capacity
-- reservation mechanism, NOT payment validation nor a complete provisioning worker.
-- All writes must go through these functions under a role with EXECUTE but no table DML.

BEGIN;

CREATE SCHEMA IF NOT EXISTS provisioning;

CREATE TABLE IF NOT EXISTS provisioning.policy (
  singleton boolean PRIMARY KEY DEFAULT true CHECK (singleton),
  hard_max integer NOT NULL DEFAULT 500 CHECK (hard_max = 500),
  rollout_max integer NOT NULL DEFAULT 50 CHECK (rollout_max IN (50, 200, 500)),
  updated_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO provisioning.policy(singleton, hard_max, rollout_max)
VALUES (true, 500, 50) ON CONFLICT (singleton) DO NOTHING;

CREATE TABLE IF NOT EXISTS provisioning.subscriptions (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_ref text NOT NULL UNIQUE,
  remote_user_id text UNIQUE,
  state text NOT NULL DEFAULT 'reserved'
    CHECK (state IN ('reserved','provisioning','active','deactivating','released')),
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (state <> 'active' OR remote_user_id IS NOT NULL)
);
CREATE INDEX IF NOT EXISTS subscriptions_capacity_idx
  ON provisioning.subscriptions(state)
  WHERE state <> 'released';

CREATE TABLE IF NOT EXISTS provisioning.command_receipts (
  idempotency_key text PRIMARY KEY,
  customer_ref text NOT NULL,
  request_fingerprint text NOT NULL,
  result jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION provisioning.reserve(
  p_customer_ref text,
  p_idempotency_key text,
  p_request_fingerprint text,
  p_expires_at timestamptz
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_prev provisioning.command_receipts%ROWTYPE;
  v_existing provisioning.subscriptions%ROWTYPE;
  v_has_existing boolean;
  v_allowed integer;
  v_occupied integer;
  v_subscription_id bigint;
  v_result jsonb;
BEGIN
  IF nullif(btrim(p_customer_ref),'') IS NULL
     OR nullif(btrim(p_idempotency_key),'') IS NULL
     OR nullif(btrim(p_request_fingerprint),'') IS NULL
     OR length(p_customer_ref) > 256
     OR length(p_idempotency_key) > 256
     OR p_expires_at IS NULL OR p_expires_at <= now()
  THEN
    RETURN jsonb_build_object('ok',false,'code','INVALID_INPUT');
  END IF;

  -- Identical operations serialize across independent workers / n8n executions.
  PERFORM pg_advisory_xact_lock(500, 20261023);

  SELECT * INTO v_prev FROM provisioning.command_receipts
    WHERE idempotency_key = p_idempotency_key;
  IF FOUND THEN
    IF v_prev.request_fingerprint <> p_request_fingerprint
       OR v_prev.customer_ref <> p_customer_ref THEN
      RETURN jsonb_build_object('ok',false,'code','IDEMPOTENCY_CONFLICT');
    END IF;
    RETURN v_prev.result;
  END IF;

  SELECT * INTO v_existing FROM provisioning.subscriptions
    WHERE customer_ref = p_customer_ref FOR UPDATE;
  v_has_existing := FOUND;

  IF v_has_existing AND v_existing.state <> 'released' THEN
    v_result := jsonb_build_object(
      'ok',false,'code','ALREADY_ALLOCATED',
      'subscription_id',v_existing.id,'state',v_existing.state
    );
  ELSE
    SELECT LEAST(hard_max, rollout_max) INTO v_allowed
      FROM provisioning.policy WHERE singleton = true FOR UPDATE;

    IF v_allowed IS NULL THEN
      RAISE EXCEPTION 'Missing provisioning.policy singleton';
    END IF;

    SELECT count(*) INTO v_occupied FROM provisioning.subscriptions
      WHERE state IN ('reserved','provisioning','active','deactivating');

    IF v_occupied >= v_allowed THEN
      v_result := jsonb_build_object(
        'ok',false,'code','CAPACITY_REACHED',
        'occupied',v_occupied,'limit',v_allowed
      );
    ELSE
      IF v_has_existing THEN
        UPDATE provisioning.subscriptions
          SET state='reserved', remote_user_id=NULL,
              expires_at=p_expires_at, updated_at=now()
          WHERE id=v_existing.id
          RETURNING id INTO v_subscription_id;
      ELSE
        INSERT INTO provisioning.subscriptions(customer_ref,expires_at)
          VALUES (p_customer_ref,p_expires_at)
          RETURNING id INTO v_subscription_id;
      END IF;

      v_result := jsonb_build_object(
        'ok',true,'code','RESERVED','subscription_id',v_subscription_id
      );
    END IF;
  END IF;

  INSERT INTO provisioning.command_receipts(
    idempotency_key,customer_ref,request_fingerprint,result
  ) VALUES (p_idempotency_key,p_customer_ref,p_request_fingerprint,v_result);

  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION provisioning.transition(
  p_customer_ref text,
  p_next_state text,
  p_remote_user_id text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_subscription provisioning.subscriptions%ROWTYPE;
BEGIN
  IF nullif(btrim(p_customer_ref),'') IS NULL THEN
    RETURN jsonb_build_object('ok',false,'code','INVALID_INPUT');
  END IF;

  -- Release remains serialized with reservations.
  PERFORM pg_advisory_xact_lock(500, 20261023);
  SELECT * INTO v_subscription FROM provisioning.subscriptions
    WHERE customer_ref=p_customer_ref FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok',false,'code','NOT_FOUND');
  END IF;

  IF NOT (
    (v_subscription.state='reserved' AND p_next_state IN ('provisioning','deactivating')) OR
    (v_subscription.state='provisioning' AND p_next_state IN ('active','deactivating')) OR
    (v_subscription.state='active' AND p_next_state='deactivating') OR
    (v_subscription.state='deactivating' AND p_next_state='released')
  ) THEN
    RETURN jsonb_build_object('ok',false,'code','ILLEGAL_TRANSITION',
                              'state',v_subscription.state);
  END IF;

  IF p_next_state='active' AND nullif(btrim(coalesce(p_remote_user_id,'')),'') IS NULL THEN
    RETURN jsonb_build_object('ok',false,'code','REMOTE_ID_REQUIRED');
  END IF;

  UPDATE provisioning.subscriptions
    SET state=p_next_state,
        remote_user_id=CASE
          WHEN p_next_state='active' THEN p_remote_user_id
          WHEN p_next_state='released' THEN NULL
          ELSE remote_user_id
        END,
        updated_at=now()
    WHERE id=v_subscription.id;

  RETURN jsonb_build_object('ok',true,'code','STATE_CHANGED',
    'subscription_id',v_subscription.id,'state',p_next_state);
END;
$$;

CREATE OR REPLACE FUNCTION provisioning.renew_until(
  p_customer_ref text,
  p_new_expires_at timestamptz
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_subscription provisioning.subscriptions%ROWTYPE;
  v_expiry timestamptz;
BEGIN
  IF p_new_expires_at IS NULL OR p_new_expires_at <= now() THEN
    RETURN jsonb_build_object('ok',false,'code','INVALID_EXPIRY');
  END IF;

  PERFORM pg_advisory_xact_lock(500, 20261023);
  SELECT * INTO v_subscription FROM provisioning.subscriptions
    WHERE customer_ref=p_customer_ref FOR UPDATE;

  IF NOT FOUND OR v_subscription.state <> 'active' THEN
    RETURN jsonb_build_object('ok',false,'code','NOT_ACTIVE');
  END IF;

  v_expiry := greatest(v_subscription.expires_at,p_new_expires_at);
  UPDATE provisioning.subscriptions
    SET expires_at=v_expiry,updated_at=now() WHERE id=v_subscription.id;
  RETURN jsonb_build_object('ok',true,'code','RENEWED',
    'subscription_id',v_subscription.id,'expires_at',v_expiry);
END;
$$;

CREATE OR REPLACE VIEW provisioning.capacity_status AS
SELECT p.hard_max, p.rollout_max, LEAST(p.hard_max,p.rollout_max) AS current_limit,
  (SELECT count(*) FROM provisioning.subscriptions s
    WHERE s.state IN ('reserved','provisioning','active','deactivating')) AS occupied
FROM provisioning.policy p WHERE p.singleton=true;

-- Database owner / migrations role can write tables. Service role must receive
-- EXECUTE on these functions and SELECT on capacity_status ONLY; no direct DML.
REVOKE ALL ON SCHEMA provisioning FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA provisioning FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA provisioning FROM PUBLIC;

COMMIT;
