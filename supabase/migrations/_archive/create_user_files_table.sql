-- Create user_files table for file management
-- This table stores file metadata for user uploads

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create user_files table
CREATE TABLE IF NOT EXISTS user_files (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  file_type TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('images', 'documents', 'videos', 'audio', 'other')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique file path per user
  UNIQUE(user_id, file_path)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_files_user_id ON user_files(user_id);
CREATE INDEX IF NOT EXISTS idx_user_files_category ON user_files(category);
CREATE INDEX IF NOT EXISTS idx_user_files_created_at ON user_files(created_at);
CREATE INDEX IF NOT EXISTS idx_user_files_file_type ON user_files(file_type);

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_user_files_updated_at 
  BEFORE UPDATE ON user_files 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE user_files ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only see and manage their own files
CREATE POLICY "Users can view own files" ON user_files
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own files" ON user_files
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own files" ON user_files
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own files" ON user_files
  FOR DELETE USING (auth.uid() = user_id);

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON user_files TO authenticated;

-- Create a function to get file statistics for a user
CREATE OR REPLACE FUNCTION get_user_file_stats(user_uuid UUID)
RETURNS TABLE(
  total_files INTEGER,
  total_size BIGINT,
  files_by_category JSON,
  recent_files INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INTEGER as total_files,
    COALESCE(SUM(file_size), 0) as total_size,
    json_object_agg(category, COUNT(*)) as files_by_category,
    COUNT(CASE WHEN created_at >= NOW() - INTERVAL '7 days' THEN 1 END)::INTEGER as recent_files
  FROM user_files
  WHERE user_id = user_uuid
  GROUP BY user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_user_file_stats(UUID) TO authenticated;

-- Create a function to search files by name
CREATE OR REPLACE FUNCTION search_user_files(user_uuid UUID, search_query TEXT)
RETURNS TABLE(
  id UUID,
  file_name TEXT,
  file_path TEXT,
  file_url TEXT,
  file_size BIGINT,
  file_type TEXT,
  category TEXT,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    uf.id,
    uf.file_name,
    uf.file_path,
    uf.file_url,
    uf.file_size,
    uf.file_type,
    uf.category,
    uf.created_at
  FROM user_files uf
  WHERE uf.user_id = user_uuid
    AND uf.file_name ILIKE '%' || search_query || '%'
  ORDER BY uf.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION search_user_files(UUID, TEXT) TO authenticated;

-- Create a view for easy access to file information
CREATE OR REPLACE VIEW user_files_view AS
SELECT 
  uf.id,
  uf.user_id,
  uf.file_name,
  uf.file_path,
  uf.file_url,
  uf.file_size,
  uf.file_type,
  uf.category,
  uf.created_at,
  uf.updated_at,
  p.name as user_name,
  p.email as user_email,
  p.role as user_role
FROM user_files uf
JOIN profiles p ON uf.user_id = p.id;

-- Grant select permission on the view
GRANT SELECT ON user_files_view TO authenticated;

-- Create a function to clean up orphaned files (for maintenance)
CREATE OR REPLACE FUNCTION cleanup_orphaned_files()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER := 0;
BEGIN
  -- Delete files that reference non-existent users
  DELETE FROM user_files 
  WHERE user_id NOT IN (SELECT id FROM auth.users);
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function (admin only)
GRANT EXECUTE ON FUNCTION cleanup_orphaned_files() TO authenticated;
