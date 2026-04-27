-- Create Live Calling System for Vagus App
-- This migration creates all the necessary tables and functions for live audio/video calling

SELECT '=== CREATING LIVE CALLING SYSTEM ===' as section;

-- ========================================
-- CREATE LIVE SESSIONS TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS public.live_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_type TEXT NOT NULL CHECK (session_type IN ('audio_call', 'video_call', 'group_call', 'coaching_session')),
    title TEXT,
    description TEXT,
    coach_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    client_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    scheduled_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    duration_minutes INTEGER DEFAULT 0,
    status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'active', 'ended', 'cancelled', 'missed')),
    max_participants INTEGER DEFAULT 2,
    is_recording_enabled BOOLEAN DEFAULT false,
    recording_url TEXT,
    session_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================
-- CREATE CALL PARTICIPANTS TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS public.call_participants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id UUID REFERENCES public.live_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    left_at TIMESTAMPTZ,
    duration_seconds INTEGER DEFAULT 0,
    is_muted BOOLEAN DEFAULT false,
    is_video_enabled BOOLEAN DEFAULT true,
    is_screen_sharing BOOLEAN DEFAULT false,
    connection_quality TEXT DEFAULT 'good' CHECK (connection_quality IN ('excellent', 'good', 'fair', 'poor')),
    device_type TEXT CHECK (device_type IN ('mobile', 'desktop', 'tablet')),
    user_agent TEXT,
    ip_address INET,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(session_id, user_id)
);

-- ========================================
-- CREATE CALL MESSAGES TABLE (for in-call chat)
-- ========================================

CREATE TABLE IF NOT EXISTS public.call_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id UUID REFERENCES public.live_sessions(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'emoji', 'file', 'image')),
    file_url TEXT,
    is_system_message BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================
-- CREATE CALL RECORDINGS TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS public.call_recordings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id UUID REFERENCES public.live_sessions(id) ON DELETE CASCADE,
    recording_url TEXT NOT NULL,
    recording_duration_seconds INTEGER,
    file_size_bytes BIGINT,
    recording_format TEXT DEFAULT 'mp4' CHECK (recording_format IN ('mp4', 'webm', 'mp3', 'wav')),
    recording_quality TEXT DEFAULT 'hd' CHECK (recording_quality IN ('sd', 'hd', 'fhd')),
    is_processed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================
-- CREATE CALL INVITATIONS TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS public.call_invitations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id UUID REFERENCES public.live_sessions(id) ON DELETE CASCADE,
    inviter_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    invitee_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    invitation_token TEXT UNIQUE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'expired')),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '1 hour'),
    responded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================
-- CREATE CALL SETTINGS TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS public.call_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    default_mic_enabled BOOLEAN DEFAULT true,
    default_camera_enabled BOOLEAN DEFAULT true,
    default_speaker_volume INTEGER DEFAULT 80 CHECK (default_speaker_volume >= 0 AND default_speaker_volume <= 100),
    default_mic_volume INTEGER DEFAULT 80 CHECK (default_mic_volume >= 0 AND default_mic_volume <= 100),
    preferred_video_quality TEXT DEFAULT 'hd' CHECK (preferred_video_quality IN ('sd', 'hd', 'fhd')),
    preferred_audio_quality TEXT DEFAULT 'high' CHECK (preferred_audio_quality IN ('low', 'medium', 'high')),
    auto_accept_calls BOOLEAN DEFAULT false,
    do_not_disturb BOOLEAN DEFAULT false,
    show_caller_info BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================
-- CREATE INDEXES FOR PERFORMANCE
-- ========================================

-- Live sessions indexes
CREATE INDEX IF NOT EXISTS idx_live_sessions_coach_id ON public.live_sessions(coach_id);
CREATE INDEX IF NOT EXISTS idx_live_sessions_client_id ON public.live_sessions(client_id);
CREATE INDEX IF NOT EXISTS idx_live_sessions_status ON public.live_sessions(status);
CREATE INDEX IF NOT EXISTS idx_live_sessions_scheduled_at ON public.live_sessions(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_live_sessions_session_type ON public.live_sessions(session_type);

-- Call participants indexes
CREATE INDEX IF NOT EXISTS idx_call_participants_session_id ON public.call_participants(session_id);
CREATE INDEX IF NOT EXISTS idx_call_participants_user_id ON public.call_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_call_participants_joined_at ON public.call_participants(joined_at);

-- Call messages indexes
CREATE INDEX IF NOT EXISTS idx_call_messages_session_id ON public.call_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_call_messages_sender_id ON public.call_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_call_messages_created_at ON public.call_messages(created_at);

-- Call invitations indexes
CREATE INDEX IF NOT EXISTS idx_call_invitations_session_id ON public.call_invitations(session_id);
CREATE INDEX IF NOT EXISTS idx_call_invitations_invitee_id ON public.call_invitations(invitee_id);
CREATE INDEX IF NOT EXISTS idx_call_invitations_status ON public.call_invitations(status);
CREATE INDEX IF NOT EXISTS idx_call_invitations_token ON public.call_invitations(invitation_token);

-- ========================================
-- ENABLE ROW LEVEL SECURITY
-- ========================================

-- Enable RLS on all tables
ALTER TABLE public.live_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_recordings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_settings ENABLE ROW LEVEL SECURITY;

-- ========================================
-- CREATE RLS POLICIES
-- ========================================

-- Live sessions policies
CREATE POLICY "live_sessions_select_policy" ON public.live_sessions
    FOR SELECT TO authenticated
    USING (
        coach_id = auth.uid() OR 
        client_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.call_participants 
            WHERE session_id = live_sessions.id AND user_id = auth.uid()
        )
    );

CREATE POLICY "live_sessions_insert_policy" ON public.live_sessions
    FOR INSERT TO authenticated
    WITH CHECK (coach_id = auth.uid() OR client_id = auth.uid());

CREATE POLICY "live_sessions_update_policy" ON public.live_sessions
    FOR UPDATE TO authenticated
    USING (coach_id = auth.uid() OR client_id = auth.uid())
    WITH CHECK (coach_id = auth.uid() OR client_id = auth.uid());

CREATE POLICY "live_sessions_delete_policy" ON public.live_sessions
    FOR DELETE TO authenticated
    USING (coach_id = auth.uid() OR client_id = auth.uid());

-- Call participants policies
CREATE POLICY "call_participants_select_policy" ON public.call_participants
    FOR SELECT TO authenticated
    USING (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.live_sessions 
            WHERE id = call_participants.session_id 
            AND (coach_id = auth.uid() OR client_id = auth.uid())
        )
    );

CREATE POLICY "call_participants_insert_policy" ON public.call_participants
    FOR INSERT TO authenticated
    WITH CHECK (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.live_sessions 
            WHERE id = call_participants.session_id 
            AND (coach_id = auth.uid() OR client_id = auth.uid())
        )
    );

CREATE POLICY "call_participants_update_policy" ON public.call_participants
    FOR UPDATE TO authenticated
    USING (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.live_sessions 
            WHERE id = call_participants.session_id 
            AND (coach_id = auth.uid() OR client_id = auth.uid())
        )
    );

-- Call messages policies
CREATE POLICY "call_messages_select_policy" ON public.call_messages
    FOR SELECT TO authenticated
    USING (
        sender_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.live_sessions 
            WHERE id = call_messages.session_id 
            AND (coach_id = auth.uid() OR client_id = auth.uid())
        )
    );

CREATE POLICY "call_messages_insert_policy" ON public.call_messages
    FOR INSERT TO authenticated
    WITH CHECK (
        sender_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.live_sessions 
            WHERE id = call_messages.session_id 
            AND (coach_id = auth.uid() OR client_id = auth.uid())
        )
    );

-- Call recordings policies
CREATE POLICY "call_recordings_select_policy" ON public.call_recordings
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.live_sessions 
            WHERE id = call_recordings.session_id 
            AND (coach_id = auth.uid() OR client_id = auth.uid())
        )
    );

-- Call invitations policies
CREATE POLICY "call_invitations_select_policy" ON public.call_invitations
    FOR SELECT TO authenticated
    USING (invitee_id = auth.uid() OR inviter_id = auth.uid());

CREATE POLICY "call_invitations_insert_policy" ON public.call_invitations
    FOR INSERT TO authenticated
    WITH CHECK (inviter_id = auth.uid());

CREATE POLICY "call_invitations_update_policy" ON public.call_invitations
    FOR UPDATE TO authenticated
    USING (invitee_id = auth.uid() OR inviter_id = auth.uid());

-- Call settings policies
CREATE POLICY "call_settings_select_policy" ON public.call_settings
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "call_settings_insert_policy" ON public.call_settings
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "call_settings_update_policy" ON public.call_settings
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- ========================================
-- CREATE HELPER FUNCTIONS
-- ========================================

-- Function to create a new live session
CREATE OR REPLACE FUNCTION public.create_live_session(
    p_session_type TEXT,
    p_title TEXT DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_coach_id UUID DEFAULT NULL,
    p_client_id UUID DEFAULT NULL,
    p_scheduled_at TIMESTAMPTZ DEFAULT NULL,
    p_max_participants INTEGER DEFAULT 2
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    session_id UUID;
BEGIN
    -- Validate session type
    IF p_session_type NOT IN ('audio_call', 'video_call', 'group_call', 'coaching_session') THEN
        RAISE EXCEPTION 'Invalid session type: %', p_session_type;
    END IF;
    
    -- Create the session
    INSERT INTO public.live_sessions (
        session_type, title, description, coach_id, client_id, 
        scheduled_at, max_participants
    ) VALUES (
        p_session_type, p_title, p_description, p_coach_id, p_client_id,
        p_scheduled_at, p_max_participants
    ) RETURNING id INTO session_id;
    
    -- Add the creator as a participant
    INSERT INTO public.call_participants (session_id, user_id)
    VALUES (session_id, COALESCE(p_coach_id, p_client_id, auth.uid()));
    
    RETURN session_id;
END;
$$;

-- Function to join a live session
CREATE OR REPLACE FUNCTION public.join_live_session(
    p_session_id UUID,
    p_user_id UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    session_exists BOOLEAN;
    current_participants INTEGER;
    max_participants INTEGER;
BEGIN
    -- Check if session exists and user has access
    SELECT EXISTS (
        SELECT 1 FROM public.live_sessions 
        WHERE id = p_session_id 
        AND (coach_id = p_user_id OR client_id = p_user_id)
    ) INTO session_exists;
    
    IF NOT session_exists THEN
        RAISE EXCEPTION 'Session not found or access denied';
    END IF;
    
    -- Check participant limit
    SELECT 
        COUNT(*),
        ls.max_participants
    INTO current_participants, max_participants
    FROM public.call_participants cp
    JOIN public.live_sessions ls ON cp.session_id = ls.id
    WHERE cp.session_id = p_session_id AND cp.left_at IS NULL
    GROUP BY ls.max_participants;
    
    IF current_participants >= max_participants THEN
        RAISE EXCEPTION 'Session is full';
    END IF;
    
    -- Add participant (or update if already exists)
    INSERT INTO public.call_participants (session_id, user_id)
    VALUES (p_session_id, p_user_id)
    ON CONFLICT (session_id, user_id) 
    DO UPDATE SET 
        joined_at = NOW(),
        left_at = NULL,
        updated_at = NOW();
    
    -- Update session status to active if it's the first participant
    UPDATE public.live_sessions 
    SET status = 'active', started_at = COALESCE(started_at, NOW())
    WHERE id = p_session_id AND status = 'scheduled';
    
    RETURN TRUE;
END;
$$;

-- Function to leave a live session
CREATE OR REPLACE FUNCTION public.leave_live_session(
    p_session_id UUID,
    p_user_id UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    remaining_participants INTEGER;
BEGIN
    -- Update participant record
    UPDATE public.call_participants 
    SET 
        left_at = NOW(),
        duration_seconds = EXTRACT(EPOCH FROM (NOW() - joined_at))::INTEGER,
        updated_at = NOW()
    WHERE session_id = p_session_id AND user_id = p_user_id AND left_at IS NULL;
    
    -- Check remaining participants
    SELECT COUNT(*) INTO remaining_participants
    FROM public.call_participants 
    WHERE session_id = p_session_id AND left_at IS NULL;
    
    -- End session if no participants left
    IF remaining_participants = 0 THEN
        UPDATE public.live_sessions 
        SET 
            status = 'ended',
            ended_at = NOW(),
            duration_minutes = EXTRACT(EPOCH FROM (NOW() - started_at))::INTEGER / 60,
            updated_at = NOW()
        WHERE id = p_session_id;
    END IF;
    
    RETURN TRUE;
END;
$$;

-- Function to send call invitation
CREATE OR REPLACE FUNCTION public.send_call_invitation(
    p_session_id UUID,
    p_invitee_id UUID,
    p_invitation_token TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    invitation_id UUID;
    token TEXT;
BEGIN
    -- Generate token if not provided
    token := COALESCE(p_invitation_token, encode(gen_random_bytes(32), 'hex'));
    
    -- Create invitation
    INSERT INTO public.call_invitations (
        session_id, inviter_id, invitee_id, invitation_token
    ) VALUES (
        p_session_id, auth.uid(), p_invitee_id, token
    ) RETURNING id INTO invitation_id;
    
    RETURN invitation_id;
END;
$$;

-- Function to get active sessions for user
CREATE OR REPLACE FUNCTION public.get_user_active_sessions(p_user_id UUID DEFAULT auth.uid())
RETURNS TABLE(
    session_id UUID,
    session_type TEXT,
    title TEXT,
    status TEXT,
    participants_count INTEGER,
    started_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ls.id,
        ls.session_type,
        ls.title,
        ls.status,
        COUNT(cp.id)::INTEGER as participants_count,
        ls.started_at
    FROM public.live_sessions ls
    LEFT JOIN public.call_participants cp ON ls.id = cp.session_id AND cp.left_at IS NULL
    WHERE (ls.coach_id = p_user_id OR ls.client_id = p_user_id)
    AND ls.status IN ('active', 'scheduled')
    GROUP BY ls.id, ls.session_type, ls.title, ls.status, ls.started_at
    ORDER BY ls.started_at DESC;
END;
$$;

-- ========================================
-- CREATE TRIGGERS FOR UPDATED_AT
-- ========================================

-- Create updated_at triggers
CREATE TRIGGER update_live_sessions_updated_at
    BEFORE UPDATE ON public.live_sessions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_call_participants_updated_at
    BEFORE UPDATE ON public.call_participants
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_call_settings_updated_at
    BEFORE UPDATE ON public.call_settings
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ========================================
-- GRANT PERMISSIONS
-- ========================================

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.live_sessions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.call_participants TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.call_messages TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.call_recordings TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.call_invitations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.call_settings TO authenticated;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION public.create_live_session(TEXT, TEXT, TEXT, UUID, UUID, TIMESTAMPTZ, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.join_live_session(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.leave_live_session(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_call_invitation(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_active_sessions(UUID) TO authenticated;

SELECT '=== LIVE CALLING SYSTEM CREATED SUCCESSFULLY ===' as section;
