-- Message Settings Table Migration
-- Creates the message_settings table for storing user messaging preferences

-- Create message_settings table if not exists
CREATE TABLE IF NOT EXISTS message_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Notification settings
    push_notifications BOOLEAN DEFAULT true,
    sound_enabled BOOLEAN DEFAULT true,
    vibration_enabled BOOLEAN DEFAULT true,
    show_preview BOOLEAN DEFAULT true,
    
    -- Chat display settings
    show_read_receipts BOOLEAN DEFAULT true,
    show_typing_indicator BOOLEAN DEFAULT true,
    auto_download_media BOOLEAN DEFAULT true,
    compress_images BOOLEAN DEFAULT true,
    
    -- Privacy settings
    show_online_status BOOLEAN DEFAULT true,
    show_last_seen BOOLEAN DEFAULT true,
    
    -- AI features
    smart_replies BOOLEAN DEFAULT true,
    ai_suggestions BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure one settings record per user
    CONSTRAINT message_settings_user_unique UNIQUE (user_id)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_message_settings_user_id ON message_settings(user_id);

-- Enable RLS
ALTER TABLE message_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can only see their own settings
CREATE POLICY "Users can view own message settings"
    ON message_settings FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own settings
CREATE POLICY "Users can insert own message settings"
    ON message_settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own settings
CREATE POLICY "Users can update own message settings"
    ON message_settings FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own settings
CREATE POLICY "Users can delete own message settings"
    ON message_settings FOR DELETE
    USING (auth.uid() = user_id);

-- Create function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_message_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-updating updated_at
DROP TRIGGER IF EXISTS trigger_message_settings_updated_at ON message_settings;
CREATE TRIGGER trigger_message_settings_updated_at
    BEFORE UPDATE ON message_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_message_settings_updated_at();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON message_settings TO authenticated;
