-- Fix coach_clients table schema issues
-- This migration adds proper constraints and indexes to the coach_clients table

-- 1. Add primary key (id column)
ALTER TABLE coach_clients
ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid() PRIMARY KEY;

-- 2. Make coach_id and client_id NOT NULL
ALTER TABLE coach_clients
ALTER COLUMN coach_id SET NOT NULL,
ALTER COLUMN client_id SET NOT NULL;

-- 3. Make created_at NOT NULL with default
ALTER TABLE coach_clients
ALTER COLUMN created_at SET DEFAULT NOW(),
ALTER COLUMN created_at SET NOT NULL;

-- 4. Add unique constraint to prevent duplicate coach-client pairs
ALTER TABLE coach_clients
ADD CONSTRAINT unique_coach_client_pair UNIQUE (coach_id, client_id);

-- 5. Add foreign key constraints for referential integrity
ALTER TABLE coach_clients
ADD CONSTRAINT fk_coach_clients_coach
FOREIGN KEY (coach_id) REFERENCES profiles(id) ON DELETE CASCADE;

ALTER TABLE coach_clients
ADD CONSTRAINT fk_coach_clients_client
FOREIGN KEY (client_id) REFERENCES profiles(id) ON DELETE CASCADE;

-- 6. Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_coach_clients_coach_id ON coach_clients(coach_id);
CREATE INDEX IF NOT EXISTS idx_coach_clients_client_id ON coach_clients(client_id);
CREATE INDEX IF NOT EXISTS idx_coach_clients_status ON coach_clients(status);

-- 7. Add default status if null
UPDATE coach_clients SET status = 'pending' WHERE status IS NULL;

-- 8. Add check constraint for valid status values
ALTER TABLE coach_clients
ADD CONSTRAINT check_valid_status
CHECK (status IN ('pending', 'active', 'inactive', 'rejected'));

-- 9. Similarly fix coach_requests table
ALTER TABLE coach_requests
ALTER COLUMN coach_id SET NOT NULL,
ALTER COLUMN client_id SET NOT NULL;

ALTER TABLE coach_requests
ADD CONSTRAINT fk_coach_requests_coach
FOREIGN KEY (coach_id) REFERENCES profiles(id) ON DELETE CASCADE;

ALTER TABLE coach_requests
ADD CONSTRAINT fk_coach_requests_client
FOREIGN KEY (client_id) REFERENCES profiles(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_coach_requests_coach_id ON coach_requests(coach_id);
CREATE INDEX IF NOT EXISTS idx_coach_requests_client_id ON coach_requests(client_id);
CREATE INDEX IF NOT EXISTS idx_coach_requests_status ON coach_requests(status);

-- Add check constraint for valid status values in coach_requests
ALTER TABLE coach_requests
ADD CONSTRAINT check_valid_request_status
CHECK (status IN ('pending', 'approved', 'rejected'));
