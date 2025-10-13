-- Common Queries for Vagus App Database
-- Created: 2025-10-02
-- Use these queries as reference for application development

-- ============================================================================
-- CALENDAR EVENTS QUERIES
-- ============================================================================

-- Get all events of a specific type for a coach
SELECT * FROM calendar_events
WHERE coach_id = '<coach_uuid>'
AND event_type = 'workout'
ORDER BY start_at DESC;

-- Get upcoming events grouped by type
SELECT
    event_type,
    COUNT(*) as event_count,
    MIN(start_at) as next_event
FROM calendar_events
WHERE coach_id = '<coach_uuid>'
AND start_at > NOW()
GROUP BY event_type;

-- Update existing events to set their type
UPDATE calendar_events
SET event_type = 'consultation'
WHERE title ILIKE '%consult%';

-- ============================================================================
-- CLIENT FEEDBACK QUERIES
-- ============================================================================

-- Get all feedback for a coach (ordered by rating, then date)
SELECT
    cf.*,
    u.email as client_email,
    u.raw_user_meta_data->>'full_name' as client_name
FROM client_feedback cf
JOIN auth.users u ON u.id = cf.client_id
WHERE cf.coach_id = '<coach_uuid>'
ORDER BY cf.rating DESC, cf.created_at DESC;

-- Get recent feedback (last 30 days)
SELECT * FROM client_feedback
WHERE coach_id = '<coach_uuid>'
AND created_at > NOW() - INTERVAL '30 days'
ORDER BY created_at DESC;

-- Get feedback by category
SELECT
    category,
    COUNT(*) as feedback_count,
    AVG(rating)::NUMERIC(3,2) as avg_rating
FROM client_feedback
WHERE coach_id = '<coach_uuid>'
GROUP BY category
ORDER BY avg_rating DESC;

-- Get top-rated feedback
SELECT
    feedback_text,
    rating,
    category,
    created_at
FROM client_feedback
WHERE coach_id = '<coach_uuid>'
AND rating >= 4
ORDER BY rating DESC, created_at DESC
LIMIT 10;

-- Client submits feedback
INSERT INTO client_feedback (
    client_id,
    coach_id,
    feedback_text,
    rating,
    category
) VALUES (
    auth.uid(), -- Current user
    '<coach_uuid>',
    'Excellent coaching session!',
    5,
    'workout'
);

-- Client updates their feedback
UPDATE client_feedback
SET
    feedback_text = 'Updated: Even better than I initially thought!',
    rating = 5,
    updated_at = NOW()
WHERE id = '<feedback_uuid>'
AND client_id = auth.uid(); -- RLS ensures they can only update their own

-- ============================================================================
-- PAYMENTS QUERIES
-- ============================================================================

-- Get all payments for a coach
SELECT
    p.*,
    u.email as client_email,
    u.raw_user_meta_data->>'full_name' as client_name
FROM payments p
JOIN auth.users u ON u.id = p.client_id
WHERE p.coach_id = '<coach_uuid>'
ORDER BY p.created_at DESC;

-- Get completed payments only
SELECT * FROM payments
WHERE coach_id = '<coach_uuid>'
AND status = 'completed'
ORDER BY created_at DESC;

-- Get pending payments that need attention
SELECT
    p.*,
    u.email as client_email
FROM payments p
JOIN auth.users u ON u.id = p.client_id
WHERE p.coach_id = '<coach_uuid>'
AND p.status = 'pending'
AND p.created_at < NOW() - INTERVAL '24 hours'
ORDER BY p.created_at;

-- Monthly revenue report
SELECT
    DATE_TRUNC('month', created_at) as month,
    COUNT(*) FILTER (WHERE status = 'completed') as payment_count,
    SUM(amount) FILTER (WHERE status = 'completed') as revenue,
    AVG(amount) FILTER (WHERE status = 'completed') as avg_payment
FROM payments
WHERE coach_id = '<coach_uuid>'
AND created_at > NOW() - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC;

-- Get payment by Stripe ID (for webhook processing)
SELECT * FROM payments
WHERE stripe_payment_intent_id = 'pi_xxxxxxxxxxxxx';

-- Service role: Create payment (from Stripe webhook)
INSERT INTO payments (
    client_id,
    coach_id,
    amount,
    currency,
    status,
    payment_method,
    stripe_payment_id,
    stripe_payment_intent_id,
    description,
    metadata
) VALUES (
    '<client_uuid>',
    '<coach_uuid>',
    99.99,
    'USD',
    'completed',
    'stripe',
    'py_xxxxxxxxxxxxx',
    'pi_xxxxxxxxxxxxx',
    'Monthly coaching - Premium Plan',
    jsonb_build_object(
        'subscription_id', 'sub_xxxxx',
        'plan', 'premium',
        'billing_cycle', 'monthly'
    )
);

-- Service role: Update payment status (from Stripe webhook)
UPDATE payments
SET
    status = 'completed',
    updated_at = NOW()
WHERE stripe_payment_intent_id = 'pi_xxxxxxxxxxxxx';

-- Refund a payment (service role only)
UPDATE payments
SET
    status = 'refunded',
    metadata = metadata || jsonb_build_object(
        'refunded_at', NOW(),
        'refund_reason', 'Customer request'
    ),
    updated_at = NOW()
WHERE id = '<payment_uuid>';

-- ============================================================================
-- ANALYTICAL VIEWS QUERIES
-- ============================================================================

-- Get coach feedback summary
SELECT * FROM coach_feedback_summary
WHERE coach_id = '<coach_uuid>';

-- Get all coaches ranked by rating
SELECT
    cfs.*,
    u.email as coach_email,
    u.raw_user_meta_data->>'full_name' as coach_name
FROM coach_feedback_summary cfs
JOIN auth.users u ON u.id = cfs.coach_id
WHERE cfs.total_feedback > 0
ORDER BY cfs.average_rating DESC, cfs.total_feedback DESC;

-- Get coach payment summary
SELECT * FROM coach_payment_summary
WHERE coach_id = '<coach_uuid>';

-- Get all coaches ranked by revenue
SELECT
    cps.*,
    u.email as coach_email,
    u.raw_user_meta_data->>'full_name' as coach_name
FROM coach_payment_summary cps
JOIN auth.users u ON u.id = cps.coach_id
WHERE cps.total_revenue > 0
ORDER BY cps.total_revenue DESC;

-- Combined coach performance summary
SELECT
    u.id as coach_id,
    u.email,
    u.raw_user_meta_data->>'full_name' as full_name,
    COALESCE(cfs.total_feedback, 0) as total_feedback,
    COALESCE(cfs.average_rating, 0) as average_rating,
    COALESCE(cps.completed_payments, 0) as completed_payments,
    COALESCE(cps.total_revenue, 0) as total_revenue
FROM auth.users u
LEFT JOIN coach_feedback_summary cfs ON cfs.coach_id = u.id
LEFT JOIN coach_payment_summary cps ON cps.coach_id = u.id
WHERE u.raw_user_meta_data->>'role' = 'coach'
ORDER BY cps.total_revenue DESC NULLS LAST;

-- ============================================================================
-- CROSS-TABLE ANALYTICS
-- ============================================================================

-- Get client engagement score (events + feedback + payments)
SELECT
    u.id as client_id,
    u.email,
    COUNT(DISTINCT ce.id) as total_events,
    COUNT(DISTINCT cf.id) as feedback_given,
    COUNT(DISTINCT p.id) FILTER (WHERE p.status = 'completed') as payments_made,
    SUM(p.amount) FILTER (WHERE p.status = 'completed') as total_spent
FROM auth.users u
LEFT JOIN calendar_events ce ON ce.client_id = u.id
LEFT JOIN client_feedback cf ON cf.client_id = u.id
LEFT JOIN payments p ON p.client_id = u.id
WHERE u.raw_user_meta_data->>'role' = 'client'
GROUP BY u.id, u.email
ORDER BY total_spent DESC NULLS LAST;

-- Coach dashboard summary (single query)
SELECT
    u.id as coach_id,
    u.email,
    -- Events
    COUNT(DISTINCT ce.id) as total_events,
    COUNT(DISTINCT ce.id) FILTER (WHERE ce.start_at > NOW()) as upcoming_events,
    -- Clients
    COUNT(DISTINCT ce.client_id) as total_clients,
    -- Feedback
    COUNT(DISTINCT cf.id) as total_feedback,
    AVG(cf.rating) as average_rating,
    -- Payments
    COUNT(DISTINCT p.id) FILTER (WHERE p.status = 'completed') as completed_payments,
    SUM(p.amount) FILTER (WHERE p.status = 'completed') as total_revenue
FROM auth.users u
LEFT JOIN calendar_events ce ON ce.coach_id = u.id
LEFT JOIN client_feedback cf ON cf.coach_id = u.id
LEFT JOIN payments p ON p.coach_id = u.id
WHERE u.id = '<coach_uuid>'
GROUP BY u.id, u.email;

-- ============================================================================
-- MAINTENANCE QUERIES
-- ============================================================================

-- Check for orphaned records (should return 0 rows if RLS/FK working)
SELECT 'calendar_events' as table_name, COUNT(*) as orphaned_count
FROM calendar_events ce
WHERE NOT EXISTS (SELECT 1 FROM auth.users WHERE id = ce.coach_id)
UNION ALL
SELECT 'client_feedback', COUNT(*)
FROM client_feedback cf
WHERE NOT EXISTS (SELECT 1 FROM auth.users WHERE id = cf.coach_id)
   OR NOT EXISTS (SELECT 1 FROM auth.users WHERE id = cf.client_id)
UNION ALL
SELECT 'payments', COUNT(*)
FROM payments p
WHERE NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p.coach_id)
   OR NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p.client_id);

-- Get table sizes
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('calendar_events', 'client_feedback', 'payments')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check index usage
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
AND tablename IN ('calendar_events', 'client_feedback', 'payments')
ORDER BY idx_scan DESC;

-- ============================================================================
-- TESTING QUERIES (Sample Data)
-- ============================================================================

-- Insert sample feedback
INSERT INTO client_feedback (client_id, coach_id, feedback_text, rating, category)
SELECT
    client.id,
    coach.id,
    'Sample feedback for testing',
    FLOOR(RANDOM() * 5 + 1)::INTEGER,
    (ARRAY['workout', 'nutrition', 'support', 'communication', 'results', 'general'])[FLOOR(RANDOM() * 6 + 1)]
FROM auth.users client
CROSS JOIN auth.users coach
WHERE client.raw_user_meta_data->>'role' = 'client'
AND coach.raw_user_meta_data->>'role' = 'coach'
LIMIT 10;

-- Delete test feedback
DELETE FROM client_feedback
WHERE feedback_text = 'Sample feedback for testing';
