-- THRIFT: AI response cache table
-- Stores hashed prompt → response mappings to reduce upstream LLM calls.
-- Hit rate target: 30%+ within 60 days.

CREATE TABLE IF NOT EXISTS ai_cache (
  prompt_hash  text        PRIMARY KEY,
  model        text        NOT NULL,
  task_type    text        NOT NULL,
  response     jsonb       NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  expires_at   timestamptz NOT NULL,
  hit_count    integer     NOT NULL DEFAULT 0,
  last_hit_at  timestamptz
);

-- Fast expiry sweeps and hit-rate telemetry queries
CREATE INDEX IF NOT EXISTS idx_ai_cache_expires_at ON ai_cache (expires_at);
CREATE INDEX IF NOT EXISTS idx_ai_cache_task_type  ON ai_cache (task_type);

-- RLS: auth'd clients can read non-expired rows; service_role has full access
ALTER TABLE ai_cache ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'ai_cache' AND policyname = 'ai_cache service_role all'
  ) THEN
    CREATE POLICY "ai_cache service_role all" ON ai_cache
      FOR ALL TO service_role USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'ai_cache' AND policyname = 'ai_cache authenticated read'
  ) THEN
    CREATE POLICY "ai_cache authenticated read" ON ai_cache
      FOR SELECT TO authenticated USING (expires_at > now());
  END IF;
END$$;

-- Atomic hit increment called from the Dart service
CREATE OR REPLACE FUNCTION increment_cache_hit(p_hash text)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE ai_cache
  SET hit_count   = hit_count + 1,
      last_hit_at = now()
  WHERE prompt_hash = p_hash;
$$;

-- Purge entries that have expired (called periodically by a cron job or on-demand)
CREATE OR REPLACE FUNCTION purge_expired_ai_cache()
RETURNS integer
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  WITH deleted AS (
    DELETE FROM ai_cache WHERE expires_at <= now() RETURNING 1
  )
  SELECT count(*)::integer FROM deleted;
$$;

-- ============================================================
-- ROLLBACK (execute in reverse order to undo this migration):
-- DROP FUNCTION IF EXISTS purge_expired_ai_cache();
-- DROP FUNCTION IF EXISTS increment_cache_hit(text);
-- DROP POLICY IF EXISTS "ai_cache authenticated read" ON ai_cache;
-- DROP POLICY IF EXISTS "ai_cache service_role all" ON ai_cache;
-- DROP TABLE IF EXISTS ai_cache;
-- ============================================================
