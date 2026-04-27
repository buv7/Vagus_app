-- Create AI usage table for tracking user AI usage
-- This table stores AI usage statistics for each user with monthly tracking

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create ai_usage table
CREATE TABLE IF NOT EXISTS ai_usage (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
  year INTEGER NOT NULL CHECK (year >= 2020),
  tokens_used INTEGER DEFAULT 0,
  total_requests INTEGER DEFAULT 0,
  requests_this_month INTEGER DEFAULT 0,
  monthly_limit INTEGER DEFAULT 100,
  last_used TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure one record per user per month per year
  UNIQUE(user_id, month, year)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_ai_usage_user_id ON ai_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_usage_month_year ON ai_usage(month, year);
CREATE INDEX IF NOT EXISTS idx_ai_usage_last_used ON ai_usage(last_used);

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_ai_usage_updated_at 
  BEFORE UPDATE ON ai_usage 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE ai_usage ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only see and manage their own AI usage
CREATE POLICY "Users can view own AI usage" ON ai_usage
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own AI usage" ON ai_usage
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own AI usage" ON ai_usage
  FOR UPDATE USING (auth.uid() = user_id);

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE ON ai_usage TO authenticated;

-- Create a function to increment AI usage for a user (legacy support)
CREATE OR REPLACE FUNCTION increment_ai_usage(user_uuid UUID)
RETURNS VOID AS $$
BEGIN
  INSERT INTO ai_usage (user_id, month, year, total_requests, requests_this_month, last_used)
  VALUES (user_uuid, EXTRACT(MONTH FROM NOW()), EXTRACT(YEAR FROM NOW()), 1, 1, NOW())
  ON CONFLICT (user_id, month, year)
  DO UPDATE SET
    total_requests = ai_usage.total_requests + 1,
    requests_this_month = ai_usage.requests_this_month + 1,
    last_used = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION increment_ai_usage(UUID) TO authenticated;

-- Create a function to update AI usage with tokens (for Edge Function)
CREATE OR REPLACE FUNCTION update_ai_usage_tokens(
  user_uuid UUID,
  tokens_count INTEGER,
  target_month INTEGER DEFAULT NULL,
  target_year INTEGER DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  current_month INTEGER;
  current_year INTEGER;
BEGIN
  -- Use current month/year if not specified
  IF target_month IS NULL THEN
    current_month := EXTRACT(MONTH FROM NOW());
  ELSE
    current_month := target_month;
  END IF;
  
  IF target_year IS NULL THEN
    current_year := EXTRACT(YEAR FROM NOW());
  ELSE
    current_year := target_year;
  END IF;

  INSERT INTO ai_usage (user_id, month, year, tokens_used, total_requests, requests_this_month, last_used)
  VALUES (user_uuid, current_month, current_year, tokens_count, 1, 1, NOW())
  ON CONFLICT (user_id, month, year)
  DO UPDATE SET
    tokens_used = ai_usage.tokens_used + tokens_count,
    total_requests = ai_usage.total_requests + 1,
    requests_this_month = ai_usage.requests_this_month + 1,
    last_used = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION update_ai_usage_tokens(UUID, INTEGER, INTEGER, INTEGER) TO authenticated;

-- Create a function to reset monthly usage (can be called by a cron job)
CREATE OR REPLACE FUNCTION reset_monthly_ai_usage()
RETURNS VOID AS $$
BEGIN
  UPDATE ai_usage 
  SET 
    requests_this_month = 0,
    updated_at = NOW()
  WHERE DATE_TRUNC('month', updated_at) < DATE_TRUNC('month', NOW());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION reset_monthly_ai_usage(UUID) TO authenticated;

-- Create a function to get AI usage summary for a user
CREATE OR REPLACE FUNCTION get_ai_usage_summary(user_uuid UUID)
RETURNS TABLE(
  total_requests INTEGER,
  requests_this_month INTEGER,
  monthly_limit INTEGER,
  remaining_requests INTEGER,
  total_tokens INTEGER,
  tokens_this_month INTEGER,
  last_used TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(SUM(au.total_requests), 0) as total_requests,
    COALESCE(SUM(au.requests_this_month), 0) as requests_this_month,
    COALESCE(MAX(au.monthly_limit), 100) as monthly_limit,
    COALESCE(MAX(au.monthly_limit), 100) - COALESCE(SUM(au.requests_this_month), 0) as remaining_requests,
    COALESCE(SUM(au.tokens_used), 0) as total_tokens,
    COALESCE(SUM(CASE 
      WHEN au.month = EXTRACT(MONTH FROM NOW()) AND au.year = EXTRACT(YEAR FROM NOW()) 
      THEN au.tokens_used 
      ELSE 0 
    END), 0) as tokens_this_month,
    MAX(au.last_used) as last_used
  FROM ai_usage au
  WHERE au.user_id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_ai_usage_summary(UUID) TO authenticated;

-- Create a function to get current month usage for a user
CREATE OR REPLACE FUNCTION get_current_month_usage(user_uuid UUID)
RETURNS TABLE(
  month INTEGER,
  year INTEGER,
  tokens_used INTEGER,
  requests_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    au.month,
    au.year,
    au.tokens_used,
    au.requests_this_month
  FROM ai_usage au
  WHERE au.user_id = user_uuid
    AND au.month = EXTRACT(MONTH FROM NOW())
    AND au.year = EXTRACT(YEAR FROM NOW());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_current_month_usage(UUID) TO authenticated;

-- Insert sample data for testing (optional - remove in production)
-- INSERT INTO ai_usage (user_id, month, year, tokens_used, total_requests, requests_this_month, monthly_limit, last_used)
-- VALUES 
--   ('00000000-0000-0000-0000-000000000001', 12, 2024, 1500, 25, 15, 100, NOW()),
--   ('00000000-0000-0000-0000-000000000002', 12, 2024, 800, 10, 5, 100, NOW() - INTERVAL '2 days');

-- Create a view for easy access to AI usage information
CREATE OR REPLACE VIEW ai_usage_view AS
SELECT 
  au.id,
  au.user_id,
  au.month,
  au.year,
  au.tokens_used,
  au.total_requests,
  au.requests_this_month,
  au.monthly_limit,
  au.monthly_limit - au.requests_this_month as remaining_requests,
  au.last_used,
  au.created_at,
  au.updated_at,
  p.name as user_name,
  p.email as user_email,
  p.role as user_role
FROM ai_usage au
JOIN profiles p ON au.user_id = p.id;

-- Grant select permission on the view
GRANT SELECT ON ai_usage_view TO authenticated;
