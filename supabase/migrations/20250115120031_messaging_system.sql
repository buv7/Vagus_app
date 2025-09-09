-- Messaging System
-- Handle coach-client messaging

-- Conversations table
CREATE TABLE IF NOT EXISTS public.conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  last_message_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(coach_id, client_id)
);

-- Messages table
CREATE TABLE IF NOT EXISTS public.messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content text NOT NULL,
  message_type text DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'voice')),
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Message attachments table
CREATE TABLE IF NOT EXISTS public.message_attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id uuid NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
  file_url text NOT NULL,
  file_name text,
  file_type text,
  file_size int,
  created_at timestamptz DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_conversations_coach ON public.conversations(coach_id);
CREATE INDEX IF NOT EXISTS idx_conversations_client ON public.conversations(client_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message ON public.conversations(last_message_at);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);
CREATE INDEX IF NOT EXISTS idx_message_attachments_message ON public.message_attachments(message_id);

-- Updated_at triggers
CREATE OR REPLACE FUNCTION update_conversations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_conversations_updated_at') THEN
    CREATE TRIGGER trigger_update_conversations_updated_at
      BEFORE UPDATE ON public.conversations
      FOR EACH ROW
      EXECUTE FUNCTION update_conversations_updated_at();
  END IF;
END $$;

-- Function to update last_message_at when a message is inserted
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.conversations 
  SET last_message_at = NEW.created_at
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_conversation_last_message') THEN
    CREATE TRIGGER trigger_update_conversation_last_message
      AFTER INSERT ON public.messages
      FOR EACH ROW
      EXECUTE FUNCTION update_conversation_last_message();
  END IF;
END $$;

-- Enable RLS
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_attachments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for conversations
DO $$ 
BEGIN
  -- Coach and client can read their own conversations
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='conversations' AND policyname='conv_read_participants') THEN
    CREATE POLICY conv_read_participants ON public.conversations FOR SELECT
    USING (coach_id = auth.uid() OR client_id = auth.uid());
  END IF;

  -- Coach and client can create conversations
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='conversations' AND policyname='conv_create_participants') THEN
    CREATE POLICY conv_create_participants ON public.conversations FOR INSERT
    WITH CHECK (coach_id = auth.uid() OR client_id = auth.uid());
  END IF;

  -- Coach and client can update their own conversations
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='conversations' AND policyname='conv_update_participants') THEN
    CREATE POLICY conv_update_participants ON public.conversations FOR UPDATE
    USING (coach_id = auth.uid() OR client_id = auth.uid())
    WITH CHECK (coach_id = auth.uid() OR client_id = auth.uid());
  END IF;
END $$;

-- RLS Policies for messages
DO $$ 
BEGIN
  -- Participants can read messages in their conversations
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='messages' AND policyname='msg_read_participants') THEN
    CREATE POLICY msg_read_participants ON public.messages FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = messages.conversation_id
        AND (c.coach_id = auth.uid() OR c.client_id = auth.uid())
      )
    );
  END IF;

  -- Participants can insert messages in their conversations
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='messages' AND policyname='msg_insert_participants') THEN
    CREATE POLICY msg_insert_participants ON public.messages FOR INSERT
    WITH CHECK (
      sender_id = auth.uid() AND
      EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = messages.conversation_id
        AND (c.coach_id = auth.uid() OR c.client_id = auth.uid())
      )
    );
  END IF;

  -- Sender can update their own messages (for read status, etc.)
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='messages' AND policyname='msg_update_sender') THEN
    CREATE POLICY msg_update_sender ON public.messages FOR UPDATE
    USING (sender_id = auth.uid())
    WITH CHECK (sender_id = auth.uid());
  END IF;
END $$;

-- RLS Policies for message_attachments
DO $$ 
BEGIN
  -- Participants can read attachments in their conversations
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='message_attachments' AND policyname='att_read_participants') THEN
    CREATE POLICY att_read_participants ON public.message_attachments FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM public.messages m
        JOIN public.conversations c ON c.id = m.conversation_id
        WHERE m.id = message_attachments.message_id
        AND (c.coach_id = auth.uid() OR c.client_id = auth.uid())
      )
    );
  END IF;

  -- Participants can insert attachments in their conversations
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='message_attachments' AND policyname='att_insert_participants') THEN
    CREATE POLICY att_insert_participants ON public.message_attachments FOR INSERT
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM public.messages m
        JOIN public.conversations c ON c.id = m.conversation_id
        WHERE m.id = message_attachments.message_id
        AND (c.coach_id = auth.uid() OR c.client_id = auth.uid())
      )
    );
  END IF;
END $$;
