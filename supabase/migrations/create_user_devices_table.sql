-- Create user_devices table for OneSignal device registration
-- This table stores the mapping between VAGUS users and OneSignal player IDs

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create user_devices table
CREATE TABLE IF NOT EXISTS user_devices (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  onesignal_id TEXT NOT NULL,
  platform TEXT CHECK (platform IN ('ios', 'android', 'web')) NOT NULL,
  device_model TEXT,
  app_version TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique combination of user and OneSignal ID
  UNIQUE(user_id, onesignal_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_onesignal_id ON user_devices(onesignal_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_platform ON user_devices(platform);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_user_devices_updated_at 
  BEFORE UPDATE ON user_devices 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only see and manage their own device registrations
CREATE POLICY "Users can view own devices" ON user_devices
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own devices" ON user_devices
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own devices" ON user_devices
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own devices" ON user_devices
  FOR DELETE USING (auth.uid() = user_id);

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON user_devices TO authenticated;

-- Create a view for easy access to user device information
CREATE OR REPLACE VIEW user_devices_view AS
SELECT 
  ud.id,
  ud.user_id,
  ud.onesignal_id,
  ud.platform,
  ud.device_model,
  ud.app_version,
  ud.created_at,
  ud.updated_at,
  p.name as user_name,
  p.email as user_email,
  p.role as user_role
FROM user_devices ud
JOIN profiles p ON ud.user_id = p.id;

-- Grant select permission on the view
GRANT SELECT ON user_devices_view TO authenticated;

-- Insert sample data for testing (optional - remove in production)
-- INSERT INTO user_devices (user_id, onesignal_id, platform, device_model, app_version)
-- VALUES 
--   ('00000000-0000-0000-0000-000000000001', 'test-onesignal-id-1', 'android', 'Samsung Galaxy S21', '1.0.0+1'),
--   ('00000000-0000-0000-0000-000000000002', 'test-onesignal-id-2', 'ios', 'iPhone 13', '1.0.0+1');

-- Create a function to get all OneSignal IDs for a user (useful for sending notifications)
CREATE OR REPLACE FUNCTION get_user_onesignal_ids(user_uuid UUID)
RETURNS TEXT[] AS $$
BEGIN
  RETURN ARRAY(
    SELECT onesignal_id 
    FROM user_devices 
    WHERE user_id = user_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_user_onesignal_ids(UUID) TO authenticated;

-- Create a function to get all OneSignal IDs for users with a specific role
CREATE OR REPLACE FUNCTION get_role_onesignal_ids(user_role TEXT)
RETURNS TEXT[] AS $$
BEGIN
  RETURN ARRAY(
    SELECT DISTINCT ud.onesignal_id 
    FROM user_devices ud
    JOIN profiles p ON ud.user_id = p.id
    WHERE p.role = user_role
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_role_onesignal_ids(TEXT) TO authenticated;
