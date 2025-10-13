-- =====================================================
-- DASHBOARD ANALYTICS TABLES
-- Tables to support coach dashboard metrics
-- Created: 2025-10-02
-- =====================================================

BEGIN;

-- =====================================================
-- PART 1: CLIENT FEEDBACK TABLE
-- For satisfaction ratings and feedback
-- =====================================================

CREATE TABLE IF NOT EXISTS client_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  coach_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  feedback TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_feedback_coach_date ON client_feedback(coach_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedback_client ON client_feedback(client_id);

-- RLS Policies
ALTER TABLE client_feedback ENABLE ROW LEVEL SECURITY;

-- Clients can insert their own feedback
CREATE POLICY "Clients can insert their own feedback"
  ON client_feedback FOR INSERT
  WITH CHECK (auth.uid() = client_id);

-- Clients can view their own feedback
CREATE POLICY "Clients can view their own feedback"
  ON client_feedback FOR SELECT
  USING (auth.uid() = client_id);

-- Coaches can view feedback about them
CREATE POLICY "Coaches can view their feedback"
  ON client_feedback FOR SELECT
  USING (auth.uid() = coach_id);

-- Clients can update their own feedback within 24 hours
CREATE POLICY "Clients can update recent feedback"
  ON client_feedback FOR UPDATE
  USING (
    auth.uid() = client_id
    AND created_at > NOW() - INTERVAL '24 hours'
  )
  WITH CHECK (auth.uid() = client_id);

-- =====================================================
-- PART 2: PAYMENTS TABLE
-- For revenue tracking
-- =====================================================

CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  coach_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL, -- Amount in cents (e.g., 3240 = $32.40)
  currency TEXT DEFAULT 'USD',
  status TEXT NOT NULL CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
  payment_method TEXT,
  description TEXT,
  stripe_payment_id TEXT, -- For Stripe integration
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_payments_coach_status ON payments(coach_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payments_client ON payments(client_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payments_stripe ON payments(stripe_payment_id) WHERE stripe_payment_id IS NOT NULL;

-- RLS Policies
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Coaches can view their payments
CREATE POLICY "Coaches can view their payments"
  ON payments FOR SELECT
  USING (auth.uid() = coach_id);

-- Clients can view their payments
CREATE POLICY "Clients can view their payments"
  ON payments FOR SELECT
  USING (auth.uid() = client_id);

-- Only system/admin can insert payments (via service role)
-- No INSERT policy for authenticated users - payments created via backend

-- =====================================================
-- PART 3: UPDATE TRIGGERS
-- =====================================================

-- Trigger to update updated_at on client_feedback
CREATE OR REPLACE FUNCTION update_feedback_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER feedback_updated_at
  BEFORE UPDATE ON client_feedback
  FOR EACH ROW
  EXECUTE FUNCTION update_feedback_updated_at();

-- Trigger to update updated_at on payments
CREATE OR REPLACE FUNCTION update_payments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER payments_updated_at
  BEFORE UPDATE ON payments
  FOR EACH ROW
  EXECUTE FUNCTION update_payments_updated_at();

-- =====================================================
-- PART 4: HELPER FUNCTIONS
-- =====================================================

-- Function to add coach_reviewed column to checkins if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'checkins' AND column_name = 'coach_reviewed'
  ) THEN
    ALTER TABLE checkins ADD COLUMN coach_reviewed BOOLEAN DEFAULT FALSE;
    CREATE INDEX IF NOT EXISTS idx_checkins_coach_reviewed ON checkins(coach_reviewed, created_at DESC);
  END IF;
END $$;

-- =====================================================
-- PART 5: SAMPLE DATA (Optional - for testing only)
-- =====================================================

-- Uncomment below to add sample feedback for testing
/*
-- Sample feedback (only if tables are empty)
INSERT INTO client_feedback (client_id, coach_id, rating, feedback)
SELECT
  c.client_id,
  c.coach_id,
  (RANDOM() * 2 + 3)::INTEGER, -- Rating between 3-5
  CASE (RANDOM() * 3)::INTEGER
    WHEN 0 THEN 'Great coaching! Really helped me achieve my goals.'
    WHEN 1 THEN 'Very responsive and knowledgeable. Highly recommend!'
    ELSE 'Good experience overall. Looking forward to continued progress.'
  END
FROM coach_clients c
WHERE NOT EXISTS (SELECT 1 FROM client_feedback)
LIMIT 5;
*/

COMMIT;

-- =====================================================
-- VERIFICATION
-- =====================================================

SELECT 'Dashboard analytics tables migration completed successfully!' AS status;
SELECT COUNT(*) AS feedback_count FROM client_feedback;
SELECT COUNT(*) AS payments_count FROM payments;
