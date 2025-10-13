-- Add marketplace columns to coach_profiles if they don't exist
ALTER TABLE coach_profiles
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS marketplace_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS rating DECIMAL(3,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS client_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS years_experience INTEGER DEFAULT 0;

-- Create index for marketplace queries
CREATE INDEX IF NOT EXISTS idx_coach_marketplace
ON coach_profiles(is_active, marketplace_enabled, rating DESC);

-- Update RLS to allow clients to view active coach profiles
DROP POLICY IF EXISTS "Clients can view active coach profiles" ON coach_profiles;
CREATE POLICY "Clients can view active coach profiles"
ON coach_profiles
FOR SELECT
TO authenticated
USING (is_active = true AND marketplace_enabled = true);

-- Ensure coach_clients table exists for connection tracking
CREATE TABLE IF NOT EXISTS coach_clients (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  coach_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(coach_id, client_id)
);

-- Create index on coach_clients for faster lookups
CREATE INDEX IF NOT EXISTS idx_coach_clients_coach
ON coach_clients(coach_id, status);

CREATE INDEX IF NOT EXISTS idx_coach_clients_client
ON coach_clients(client_id, status);

-- RLS policies for coach_clients
ALTER TABLE coach_clients ENABLE ROW LEVEL SECURITY;

-- Clients can insert their own connection requests
DROP POLICY IF EXISTS "Clients can create connection requests" ON coach_clients;
CREATE POLICY "Clients can create connection requests"
ON coach_clients
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = client_id);

-- Clients can view their own connections
DROP POLICY IF EXISTS "Clients can view own connections" ON coach_clients;
CREATE POLICY "Clients can view own connections"
ON coach_clients
FOR SELECT
TO authenticated
USING (auth.uid() = client_id OR auth.uid() = coach_id);

-- Coaches can update connection status
DROP POLICY IF EXISTS "Coaches can update connection status" ON coach_clients;
CREATE POLICY "Coaches can update connection status"
ON coach_clients
FOR UPDATE
TO authenticated
USING (auth.uid() = coach_id)
WITH CHECK (auth.uid() = coach_id);

-- Function to update client_count when connections are added
CREATE OR REPLACE FUNCTION update_coach_client_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.status = 'accepted' THEN
    UPDATE coach_profiles
    SET client_count = client_count + 1
    WHERE coach_id = NEW.coach_id;
  ELSIF TG_OP = 'UPDATE' AND OLD.status != 'accepted' AND NEW.status = 'accepted' THEN
    UPDATE coach_profiles
    SET client_count = client_count + 1
    WHERE coach_id = NEW.coach_id;
  ELSIF TG_OP = 'UPDATE' AND OLD.status = 'accepted' AND NEW.status != 'accepted' THEN
    UPDATE coach_profiles
    SET client_count = GREATEST(0, client_count - 1)
    WHERE coach_id = NEW.coach_id;
  ELSIF TG_OP = 'DELETE' AND OLD.status = 'accepted' THEN
    UPDATE coach_profiles
    SET client_count = GREATEST(0, client_count - 1)
    WHERE coach_id = OLD.coach_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for client count
DROP TRIGGER IF EXISTS trigger_update_coach_client_count ON coach_clients;
CREATE TRIGGER trigger_update_coach_client_count
AFTER INSERT OR UPDATE OR DELETE ON coach_clients
FOR EACH ROW
EXECUTE FUNCTION update_coach_client_count();

-- Set all existing coaches to active and marketplace enabled by default
UPDATE coach_profiles
SET is_active = true, marketplace_enabled = true
WHERE is_active IS NULL OR marketplace_enabled IS NULL;
