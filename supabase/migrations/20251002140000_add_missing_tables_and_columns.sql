-- Migration: Add missing tables and columns
-- Created: 2025-10-02
-- Description: Adds event_type to calendar_events, creates client_feedback and payments tables

-- ============================================================================
-- 1. Add event_type column to calendar_events table
-- ============================================================================

-- Add the event_type column with default value
ALTER TABLE calendar_events
ADD COLUMN IF NOT EXISTS event_type TEXT DEFAULT 'session';

-- Set NOT NULL constraint after adding the column
ALTER TABLE calendar_events
ALTER COLUMN event_type SET NOT NULL;

-- Add a check constraint to validate event types (drop first if exists)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'calendar_events_event_type_check'
    ) THEN
        ALTER TABLE calendar_events DROP CONSTRAINT calendar_events_event_type_check;
    END IF;
END $$;

ALTER TABLE calendar_events
ADD CONSTRAINT calendar_events_event_type_check
CHECK (event_type IN ('session', 'workout', 'consultation', 'check_in', 'appointment', 'other'));

-- Create index for filtering by event type
CREATE INDEX IF NOT EXISTS idx_calendar_events_event_type
ON calendar_events(event_type);

-- Create composite index for common queries
CREATE INDEX IF NOT EXISTS idx_calendar_events_coach_event_type
ON calendar_events(coach_id, event_type);

-- ============================================================================
-- 2. Create client_feedback table
-- ============================================================================

CREATE TABLE IF NOT EXISTS client_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    coach_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    feedback_text TEXT,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    category TEXT NOT NULL CHECK (category IN ('workout', 'nutrition', 'support', 'communication', 'results', 'general')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for client_feedback
CREATE INDEX IF NOT EXISTS idx_client_feedback_client_id ON client_feedback(client_id);
CREATE INDEX IF NOT EXISTS idx_client_feedback_coach_id ON client_feedback(coach_id);
CREATE INDEX IF NOT EXISTS idx_client_feedback_rating ON client_feedback(rating);
CREATE INDEX IF NOT EXISTS idx_client_feedback_category ON client_feedback(category);
CREATE INDEX IF NOT EXISTS idx_client_feedback_created_at ON client_feedback(created_at DESC);

-- Create composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_client_feedback_coach_rating
ON client_feedback(coach_id, rating);

CREATE INDEX IF NOT EXISTS idx_client_feedback_coach_category
ON client_feedback(coach_id, category);

-- Enable RLS on client_feedback
ALTER TABLE client_feedback ENABLE ROW LEVEL SECURITY;

-- RLS Policies for client_feedback
-- Clients can create feedback for their coaches
CREATE POLICY "Clients can create feedback for their coaches"
ON client_feedback
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = client_id
);

-- Clients can view their own feedback
CREATE POLICY "Clients can view their own feedback"
ON client_feedback
FOR SELECT
TO authenticated
USING (auth.uid() = client_id);

-- Coaches can view feedback about them
CREATE POLICY "Coaches can view feedback about them"
ON client_feedback
FOR SELECT
TO authenticated
USING (auth.uid() = coach_id);

-- Clients can update their own feedback
CREATE POLICY "Clients can update their own feedback"
ON client_feedback
FOR UPDATE
TO authenticated
USING (auth.uid() = client_id)
WITH CHECK (auth.uid() = client_id);

-- Clients can delete their own feedback
CREATE POLICY "Clients can delete their own feedback"
ON client_feedback
FOR DELETE
TO authenticated
USING (auth.uid() = client_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_client_feedback_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_client_feedback_updated_at
    BEFORE UPDATE ON client_feedback
    FOR EACH ROW
    EXECUTE FUNCTION update_client_feedback_updated_at();

-- ============================================================================
-- 3. Create payments table
-- ============================================================================

CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    coach_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
    currency TEXT NOT NULL DEFAULT 'USD' CHECK (LENGTH(currency) = 3),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded', 'cancelled')),
    payment_method TEXT CHECK (payment_method IN ('stripe', 'paypal', 'bank_transfer', 'cash', 'other')),
    stripe_payment_id TEXT,
    stripe_payment_intent_id TEXT,
    description TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for payments
CREATE INDEX IF NOT EXISTS idx_payments_client_id ON payments(client_id);
CREATE INDEX IF NOT EXISTS idx_payments_coach_id ON payments(coach_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_stripe_payment_id ON payments(stripe_payment_id);
CREATE INDEX IF NOT EXISTS idx_payments_stripe_payment_intent_id ON payments(stripe_payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at DESC);

-- Create composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_payments_coach_status
ON payments(coach_id, status);

CREATE INDEX IF NOT EXISTS idx_payments_client_status
ON payments(client_id, status);

CREATE INDEX IF NOT EXISTS idx_payments_coach_created
ON payments(coach_id, created_at DESC);

-- Enable RLS on payments
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for payments
-- Clients can view their own payments
CREATE POLICY "Clients can view their own payments"
ON payments
FOR SELECT
TO authenticated
USING (auth.uid() = client_id);

-- Coaches can view payments they receive
CREATE POLICY "Coaches can view payments they receive"
ON payments
FOR SELECT
TO authenticated
USING (auth.uid() = coach_id);

-- Only system/service role can create payments (typically via Stripe webhook)
CREATE POLICY "Service role can create payments"
ON payments
FOR INSERT
TO service_role
WITH CHECK (true);

-- Only system/service role can update payments (typically via Stripe webhook)
CREATE POLICY "Service role can update payments"
ON payments
FOR UPDATE
TO service_role
USING (true)
WITH CHECK (true);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_payments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_payments_updated_at();

-- ============================================================================
-- 4. Create helper views for analytics
-- ============================================================================

-- View for coach feedback summary
CREATE OR REPLACE VIEW coach_feedback_summary AS
SELECT
    coach_id,
    COUNT(*) as total_feedback,
    AVG(rating)::NUMERIC(3,2) as average_rating,
    COUNT(*) FILTER (WHERE rating = 5) as five_star_count,
    COUNT(*) FILTER (WHERE rating = 4) as four_star_count,
    COUNT(*) FILTER (WHERE rating = 3) as three_star_count,
    COUNT(*) FILTER (WHERE rating = 2) as two_star_count,
    COUNT(*) FILTER (WHERE rating = 1) as one_star_count,
    MAX(created_at) as latest_feedback_date
FROM client_feedback
GROUP BY coach_id;

-- View for coach payment summary
CREATE OR REPLACE VIEW coach_payment_summary AS
SELECT
    coach_id,
    COUNT(*) as total_payments,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_payments,
    SUM(amount) FILTER (WHERE status = 'completed') as total_revenue,
    AVG(amount) FILTER (WHERE status = 'completed') as average_payment,
    MAX(created_at) FILTER (WHERE status = 'completed') as last_payment_date
FROM payments
GROUP BY coach_id;

-- ============================================================================
-- Comments for documentation
-- ============================================================================

COMMENT ON TABLE client_feedback IS 'Stores client feedback and ratings for coaches';
COMMENT ON COLUMN client_feedback.rating IS 'Rating from 1-5 stars';
COMMENT ON COLUMN client_feedback.category IS 'Feedback category: workout, nutrition, support, communication, results, general';

COMMENT ON TABLE payments IS 'Stores payment transactions between clients and coaches';
COMMENT ON COLUMN payments.amount IS 'Payment amount with 2 decimal precision';
COMMENT ON COLUMN payments.currency IS 'ISO 4217 currency code (e.g., USD, EUR, GBP)';
COMMENT ON COLUMN payments.status IS 'Payment status: pending, completed, failed, refunded, cancelled';
COMMENT ON COLUMN payments.stripe_payment_id IS 'Stripe payment ID for reference';
COMMENT ON COLUMN payments.stripe_payment_intent_id IS 'Stripe payment intent ID for reference';
COMMENT ON COLUMN payments.metadata IS 'Additional payment metadata in JSON format';

COMMENT ON COLUMN calendar_events.event_type IS 'Type of calendar event: session, workout, consultation, check_in, appointment, other';
