-- CLUSTER 3: Contextual Memory + Knowledge → Action

-- 1) Contextual memory cache (surfaces relevant notes based on context)
CREATE TABLE IF NOT EXISTS contextual_memory_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  context_key TEXT NOT NULL,
  relevant_note_ids UUID[] NOT NULL,
  relevance_scores DECIMAL[] NOT NULL,
  cached_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  UNIQUE(user_id, context_key)
);

CREATE INDEX IF NOT EXISTS idx_contextual_memory_user_context ON contextual_memory_cache(user_id, context_key);
CREATE INDEX IF NOT EXISTS idx_contextual_memory_expires ON contextual_memory_cache(expires_at);

-- 2) Knowledge actions (extracted from notes, converted to actionable items)
CREATE TABLE IF NOT EXISTS knowledge_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  source_note_id UUID REFERENCES coach_notes(id) ON DELETE SET NULL,
  action_type TEXT NOT NULL CHECK (action_type IN ('reminder', 'task', 'follow_up', 'alert')),
  action_data JSONB NOT NULL,
  triggered_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_knowledge_actions_user ON knowledge_actions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_knowledge_actions_note ON knowledge_actions(source_note_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_actions_triggered ON knowledge_actions(triggered_at) WHERE triggered_at IS NOT NULL;

-- 3) Shared knowledge (client-facing knowledge from coach notes)
CREATE TABLE IF NOT EXISTS shared_knowledge (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  source_note_id UUID REFERENCES coach_notes(id) ON DELETE SET NULL,
  shared_content TEXT NOT NULL,
  shared_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  viewed_at TIMESTAMPTZ,
  UNIQUE(coach_id, client_id, source_note_id)
);

CREATE INDEX IF NOT EXISTS idx_shared_knowledge_coach ON shared_knowledge(coach_id, shared_at DESC);
CREATE INDEX IF NOT EXISTS idx_shared_knowledge_client ON shared_knowledge(client_id, shared_at DESC);

-- RLS
ALTER TABLE contextual_memory_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_knowledge ENABLE ROW LEVEL SECURITY;

-- contextual_memory_cache policies
DROP POLICY IF EXISTS "Users can view own memory cache" ON contextual_memory_cache;
DROP POLICY IF EXISTS "Users can insert own memory cache" ON contextual_memory_cache;
DROP POLICY IF EXISTS "Users can update own memory cache" ON contextual_memory_cache;

CREATE POLICY "Users can view own memory cache"
ON contextual_memory_cache FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own memory cache"
ON contextual_memory_cache FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own memory cache"
ON contextual_memory_cache FOR UPDATE
USING (auth.uid() = user_id);

-- knowledge_actions policies
DROP POLICY IF EXISTS "Users can view own knowledge actions" ON knowledge_actions;
DROP POLICY IF EXISTS "Users can insert own knowledge actions" ON knowledge_actions;
DROP POLICY IF EXISTS "Users can update own knowledge actions" ON knowledge_actions;

CREATE POLICY "Users can view own knowledge actions"
ON knowledge_actions FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own knowledge actions"
ON knowledge_actions FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own knowledge actions"
ON knowledge_actions FOR UPDATE
USING (auth.uid() = user_id);

-- shared_knowledge policies
DROP POLICY IF EXISTS "Coaches can view own shared knowledge" ON shared_knowledge;
DROP POLICY IF EXISTS "Clients can view shared knowledge" ON shared_knowledge;
DROP POLICY IF EXISTS "Coaches can share knowledge" ON shared_knowledge;
DROP POLICY IF EXISTS "Coaches can revoke shared knowledge" ON shared_knowledge;

CREATE POLICY "Coaches can view own shared knowledge"
ON shared_knowledge FOR SELECT
USING (auth.uid() = coach_id);

CREATE POLICY "Clients can view shared knowledge"
ON shared_knowledge FOR SELECT
USING (auth.uid() = client_id);

CREATE POLICY "Coaches can share knowledge"
ON shared_knowledge FOR INSERT
WITH CHECK (auth.uid() = coach_id);

CREATE POLICY "Coaches can revoke shared knowledge"
ON shared_knowledge FOR DELETE
USING (auth.uid() = coach_id);
