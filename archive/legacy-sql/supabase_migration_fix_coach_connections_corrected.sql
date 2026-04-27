-- Migration: Fix Coach Connections (CORRECTED)
-- Date: 2025-10-15
-- Purpose: Add missing columns and RLS policies to fix connection issues
-- NOTE: coach_clients is a VIEW - underlying table is user_coach_links

-- ============================================================================
-- PART 1: Add Missing Columns to coach_profiles
-- ============================================================================

-- Add missing columns
ALTER TABLE coach_profiles
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS marketplace_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS rating NUMERIC(3,2) DEFAULT 0.00;

-- Add check constraint for rating (0.00 to 5.00)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'rating_range'
    ) THEN
        ALTER TABLE coach_profiles
        ADD CONSTRAINT rating_range CHECK (rating >= 0 AND rating <= 5);
    END IF;
END $$;

-- Add comment for documentation
COMMENT ON COLUMN coach_profiles.is_active IS 'Whether the coach profile is active and can receive connections';
COMMENT ON COLUMN coach_profiles.marketplace_enabled IS 'Whether the coach appears in the marketplace listing';
COMMENT ON COLUMN coach_profiles.rating IS 'Average rating from 0.00 to 5.00';

-- Create index for marketplace queries (improves performance)
CREATE INDEX IF NOT EXISTS idx_coach_profiles_marketplace
ON coach_profiles(is_active, marketplace_enabled, rating DESC)
WHERE is_active = true AND marketplace_enabled = true;

-- Set existing coaches to active and marketplace-enabled
UPDATE coach_profiles
SET is_active = COALESCE(is_active, true),
    marketplace_enabled = COALESCE(marketplace_enabled, true),
    rating = COALESCE(rating, 0.00);

-- ============================================================================
-- PART 2: Improve user_coach_links Table Structure (underlying table)
-- ============================================================================

-- Add index for faster connection lookups
CREATE INDEX IF NOT EXISTS idx_user_coach_links_coach_status
ON user_coach_links(coach_id, status);

CREATE INDEX IF NOT EXISTS idx_user_coach_links_client_status
ON user_coach_links(client_id, status);

-- Add timestamps for better tracking
ALTER TABLE user_coach_links
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Add trigger to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_user_coach_links_updated_at ON user_coach_links;
CREATE TRIGGER update_user_coach_links_updated_at
    BEFORE UPDATE ON user_coach_links
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add comments
COMMENT ON COLUMN user_coach_links.status IS 'Connection status: pending, active, rejected, or cancelled';
COMMENT ON COLUMN user_coach_links.created_at IS 'When the connection request was created';
COMMENT ON COLUMN user_coach_links.updated_at IS 'When the connection status was last updated';

-- ============================================================================
-- PART 3: Row Level Security (RLS) Policies for user_coach_links
-- ============================================================================

-- Enable RLS on user_coach_links
ALTER TABLE user_coach_links ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Coaches can view their connections" ON user_coach_links;
DROP POLICY IF EXISTS "Clients can view their connections" ON user_coach_links;
DROP POLICY IF EXISTS "Clients can create connections" ON user_coach_links;
DROP POLICY IF EXISTS "Coaches can update connection status" ON user_coach_links;
DROP POLICY IF EXISTS "Users can delete their own pending requests" ON user_coach_links;

-- Policy 1: Coaches can see their own connections
CREATE POLICY "Coaches can view their connections"
ON user_coach_links FOR SELECT
USING (auth.uid() = coach_id);

-- Policy 2: Clients can see their own connections
CREATE POLICY "Clients can view their connections"
ON user_coach_links FOR SELECT
USING (auth.uid() = client_id);

-- Policy 3: Clients can create connection requests (only pending status)
CREATE POLICY "Clients can create connections"
ON user_coach_links FOR INSERT
WITH CHECK (
    auth.uid() = client_id
    AND status = 'pending'
);

-- Policy 4: Coaches can update connection status (pending -> active/rejected)
CREATE POLICY "Coaches can update connection status"
ON user_coach_links FOR UPDATE
USING (auth.uid() = coach_id)
WITH CHECK (
    auth.uid() = coach_id
    AND status IN ('active', 'rejected', 'pending')
);

-- Policy 5: Clients can delete their own pending connection requests
CREATE POLICY "Users can delete their own pending requests"
ON user_coach_links FOR DELETE
USING (
    auth.uid() = client_id
    AND status = 'pending'
);

-- ============================================================================
-- PART 4: Enable RLS on coach_profiles (read-only for marketplace)
-- ============================================================================

-- Enable RLS on coach_profiles
ALTER TABLE coach_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public read access for active marketplace coaches" ON coach_profiles;
DROP POLICY IF EXISTS "Coaches can update their own profile" ON coach_profiles;
DROP POLICY IF EXISTS "Coaches can insert their own profile" ON coach_profiles;

-- Policy 1: Anyone can read active marketplace coaches
CREATE POLICY "Public read access for active marketplace coaches"
ON coach_profiles FOR SELECT
USING (is_active = true AND marketplace_enabled = true);

-- Policy 2: Coaches can update their own profile
CREATE POLICY "Coaches can update their own profile"
ON coach_profiles FOR UPDATE
USING (auth.uid() = coach_id)
WITH CHECK (auth.uid() = coach_id);

-- Policy 3: Users can create their coach profile
CREATE POLICY "Coaches can insert their own profile"
ON coach_profiles FOR INSERT
WITH CHECK (auth.uid() = coach_id);

-- ============================================================================
-- PART 5: Create Helper Views
-- ============================================================================

-- View for active connections only
CREATE OR REPLACE VIEW active_coach_connections AS
SELECT
    ucl.coach_id,
    ucl.client_id,
    ucl.status,
    ucl.created_at,
    ucl.updated_at,
    cp.display_name as coach_name,
    cp.headline as coach_headline,
    cl.name as client_name,
    cl.email as client_email
FROM user_coach_links ucl
LEFT JOIN coach_profiles cp ON ucl.coach_id = cp.coach_id
LEFT JOIN profiles cl ON ucl.client_id = cl.id
WHERE ucl.status = 'active';

-- View for pending connection requests (coach perspective)
CREATE OR REPLACE VIEW pending_coach_requests AS
SELECT
    ucl.coach_id,
    ucl.client_id,
    ucl.created_at,
    cl.name as client_name,
    cl.email as client_email,
    cl.avatar_url as client_avatar
FROM user_coach_links ucl
LEFT JOIN profiles cl ON ucl.client_id = cl.id
WHERE ucl.status = 'pending'
ORDER BY ucl.created_at DESC;

-- Grant access to views
GRANT SELECT ON active_coach_connections TO authenticated;
GRANT SELECT ON pending_coach_requests TO authenticated;

-- Add RLS to views
ALTER VIEW active_coach_connections SET (security_invoker = true);
ALTER VIEW pending_coach_requests SET (security_invoker = true);

-- ============================================================================
-- PART 6: Create Stored Functions for Connection Management
-- ============================================================================

-- Function to approve a connection request
CREATE OR REPLACE FUNCTION approve_connection_request(
    p_client_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_coach_id UUID;
BEGIN
    -- Get the current user's ID (must be a coach)
    v_coach_id := auth.uid();

    IF v_coach_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Update the connection status in user_coach_links
    UPDATE user_coach_links
    SET status = 'active',
        updated_at = NOW()
    WHERE coach_id = v_coach_id
      AND client_id = p_client_id
      AND status = 'pending';

    -- Return true if a row was updated
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to reject a connection request
CREATE OR REPLACE FUNCTION reject_connection_request(
    p_client_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_coach_id UUID;
BEGIN
    v_coach_id := auth.uid();

    IF v_coach_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    UPDATE user_coach_links
    SET status = 'rejected',
        updated_at = NOW()
    WHERE coach_id = v_coach_id
      AND client_id = p_client_id
      AND status = 'pending';

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if a connection is active
CREATE OR REPLACE FUNCTION is_actively_connected(
    p_coach_id UUID,
    p_client_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM user_coach_links
        WHERE coach_id = p_coach_id
          AND client_id = p_client_id
          AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION approve_connection_request(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION reject_connection_request(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_actively_connected(UUID, UUID) TO authenticated;

-- ============================================================================
-- PART 7: Create Notification Triggers
-- ============================================================================

-- Table to store connection notifications
CREATE TABLE IF NOT EXISTS connection_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    coach_id UUID REFERENCES coach_profiles(coach_id) ON DELETE CASCADE,
    client_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL CHECK (notification_type IN ('request', 'approved', 'rejected')),
    read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster notification queries
CREATE INDEX IF NOT EXISTS idx_connection_notifications_user
ON connection_notifications(user_id, read, created_at DESC);

-- Enable RLS
ALTER TABLE connection_notifications ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own notifications
DROP POLICY IF EXISTS "Users can view their own notifications" ON connection_notifications;
CREATE POLICY "Users can view their own notifications"
ON connection_notifications FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can update their own notifications (mark as read)
DROP POLICY IF EXISTS "Users can update their own notifications" ON connection_notifications;
CREATE POLICY "Users can update their own notifications"
ON connection_notifications FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Function to create notification
CREATE OR REPLACE FUNCTION notify_connection_event()
RETURNS TRIGGER AS $$
BEGIN
    -- New connection request - notify coach
    IF TG_OP = 'INSERT' AND NEW.status = 'pending' THEN
        INSERT INTO connection_notifications (user_id, coach_id, client_id, notification_type)
        VALUES (NEW.coach_id, NEW.coach_id, NEW.client_id, 'request');

    -- Connection approved - notify client
    ELSIF TG_OP = 'UPDATE' AND OLD.status = 'pending' AND NEW.status = 'active' THEN
        INSERT INTO connection_notifications (user_id, coach_id, client_id, notification_type)
        VALUES (NEW.client_id, NEW.coach_id, NEW.client_id, 'approved');

    -- Connection rejected - notify client
    ELSIF TG_OP = 'UPDATE' AND OLD.status = 'pending' AND NEW.status = 'rejected' THEN
        INSERT INTO connection_notifications (user_id, coach_id, client_id, notification_type)
        VALUES (NEW.client_id, NEW.coach_id, NEW.client_id, 'rejected');
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on user_coach_links (not coach_clients view)
DROP TRIGGER IF EXISTS connection_notification_trigger ON user_coach_links;
CREATE TRIGGER connection_notification_trigger
    AFTER INSERT OR UPDATE ON user_coach_links
    FOR EACH ROW
    EXECUTE FUNCTION notify_connection_event();

-- Grant permissions
GRANT SELECT, UPDATE ON connection_notifications TO authenticated;

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Verify columns were added to coach_profiles
SELECT 'coach_profiles columns' as check_name;
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'coach_profiles'
  AND column_name IN ('is_active', 'marketplace_enabled', 'rating')
ORDER BY column_name;

-- Verify user_coach_links has updated_at
SELECT 'user_coach_links columns' as check_name;
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'user_coach_links'
  AND column_name = 'updated_at';

-- Verify indexes were created
SELECT 'Indexes created' as check_name;
SELECT indexname, tablename
FROM pg_indexes
WHERE tablename IN ('coach_profiles', 'user_coach_links', 'connection_notifications')
  AND schemaname = 'public'
ORDER BY tablename, indexname;

-- Verify RLS is enabled
SELECT 'RLS enabled' as check_name;
SELECT tablename, rowsecurity
FROM pg_tables
WHERE tablename IN ('coach_profiles', 'user_coach_links', 'connection_notifications')
  AND schemaname = 'public'
ORDER BY tablename;

-- Verify policies exist
SELECT 'Policies created' as check_name;
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE tablename IN ('coach_profiles', 'user_coach_links', 'connection_notifications')
ORDER BY tablename, policyname;

-- Verify views exist
SELECT 'Views created' as check_name;
SELECT table_name
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name IN ('active_coach_connections', 'pending_coach_requests', 'coach_clients')
ORDER BY table_name;

-- Verify functions exist
SELECT 'Functions created' as check_name;
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'approve_connection_request',
    'reject_connection_request',
    'is_actively_connected',
    'notify_connection_event'
  )
ORDER BY routine_name;

-- ============================================================================
-- Migration Complete
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '================================================================================';
    RAISE NOTICE 'Migration completed successfully!';
    RAISE NOTICE '================================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Changes applied:';
    RAISE NOTICE '  ✓ coach_profiles: Added is_active, marketplace_enabled, rating columns';
    RAISE NOTICE '  ✓ user_coach_links: Added updated_at column and indexes';
    RAISE NOTICE '  ✓ RLS policies created for coach_profiles and user_coach_links';
    RAISE NOTICE '  ✓ Helper views created: active_coach_connections, pending_coach_requests';
    RAISE NOTICE '  ✓ Connection management functions created';
    RAISE NOTICE '  ✓ Notification system created';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '  1. Update app code to use RLS policies correctly';
    RAISE NOTICE '  2. Implement connection approval UI for coaches';
    RAISE NOTICE '  3. Test connection workflow end-to-end';
    RAISE NOTICE '================================================================================';
END $$;
