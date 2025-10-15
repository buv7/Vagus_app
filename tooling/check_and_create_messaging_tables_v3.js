const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

async function checkAndCreateMessagingTables() {
  const client = new Client({
    connectionString,
    ssl: {
      rejectUnauthorized: false
    }
  });

  try {
    console.log('Connecting to Supabase database...');
    await client.connect();
    console.log('Connected successfully!\n');

    // Check if conversations table exists
    console.log('Checking if conversations table exists...');
    const checkTableQuery = `
      SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'conversations'
      );
    `;

    const result = await client.query(checkTableQuery);
    const tableExists = result.rows[0].exists;

    console.log(`Conversations table exists: ${tableExists}\n`);

    if (!tableExists) {
      console.log('Creating messaging system tables...\n');

      console.log('Step 1: Creating tables...');

      // Create tables
      await client.query(`
        CREATE TABLE IF NOT EXISTS public.conversations (
          id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
          coach_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
          client_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
          last_message_at timestamptz DEFAULT now(),
          created_at timestamptz DEFAULT now(),
          updated_at timestamptz DEFAULT now(),
          UNIQUE(coach_id, client_id)
        );
      `);
      console.log('  ✓ conversations table created');

      await client.query(`
        CREATE TABLE IF NOT EXISTS public.messages (
          id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
          conversation_id uuid NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
          sender_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
          content text NOT NULL,
          message_type text DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'voice')),
          is_read boolean DEFAULT false,
          created_at timestamptz DEFAULT now()
        );
      `);
      console.log('  ✓ messages table created');

      await client.query(`
        CREATE TABLE IF NOT EXISTS public.message_attachments (
          id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
          message_id uuid NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
          file_url text NOT NULL,
          file_name text,
          file_type text,
          file_size int,
          created_at timestamptz DEFAULT now()
        );
      `);
      console.log('  ✓ message_attachments table created');

      console.log('\nStep 2: Creating indexes...');

      // Create indexes one by one
      const indexes = [
        'CREATE INDEX IF NOT EXISTS idx_conversations_coach ON public.conversations(coach_id)',
        'CREATE INDEX IF NOT EXISTS idx_conversations_client ON public.conversations(client_id)',
        'CREATE INDEX IF NOT EXISTS idx_conversations_last_message ON public.conversations(last_message_at)',
        'CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id)',
        'CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id)',
        'CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at)',
        'CREATE INDEX IF NOT EXISTS idx_message_attachments_message ON public.message_attachments(message_id)'
      ];

      for (const indexSQL of indexes) {
        await client.query(indexSQL);
        const indexName = indexSQL.match(/idx_\w+/)[0];
        console.log(`  ✓ ${indexName} created`);
      }

      console.log('\nStep 3: Creating functions and triggers...');
      await client.query(`
        CREATE OR REPLACE FUNCTION update_conversations_updated_at()
        RETURNS TRIGGER AS $$
        BEGIN
          NEW.updated_at = now();
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      `);
      console.log('  ✓ update_conversations_updated_at function created');

      await client.query(`
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_conversations_updated_at') THEN
            CREATE TRIGGER trigger_update_conversations_updated_at
              BEFORE UPDATE ON public.conversations
              FOR EACH ROW
              EXECUTE FUNCTION update_conversations_updated_at();
          END IF;
        END $$;
      `);
      console.log('  ✓ trigger_update_conversations_updated_at trigger created');

      await client.query(`
        CREATE OR REPLACE FUNCTION update_conversation_last_message()
        RETURNS TRIGGER AS $$
        BEGIN
          UPDATE public.conversations
          SET last_message_at = NEW.created_at
          WHERE id = NEW.conversation_id;
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      `);
      console.log('  ✓ update_conversation_last_message function created');

      await client.query(`
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_conversation_last_message') THEN
            CREATE TRIGGER trigger_update_conversation_last_message
              AFTER INSERT ON public.messages
              FOR EACH ROW
              EXECUTE FUNCTION update_conversation_last_message();
          END IF;
        END $$;
      `);
      console.log('  ✓ trigger_update_conversation_last_message trigger created');

      console.log('\nStep 4: Enabling RLS...');
      await client.query(`
        ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
        ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
        ALTER TABLE public.message_attachments ENABLE ROW LEVEL SECURITY;
      `);
      console.log('  ✓ RLS enabled on all tables');

      console.log('\nStep 5: Creating RLS policies for conversations...');
      await client.query(`
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='conversations' AND policyname='conv_read_participants') THEN
            CREATE POLICY conv_read_participants ON public.conversations FOR SELECT
            USING (coach_id = auth.uid() OR client_id = auth.uid());
          END IF;

          IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='conversations' AND policyname='conv_create_participants') THEN
            CREATE POLICY conv_create_participants ON public.conversations FOR INSERT
            WITH CHECK (coach_id = auth.uid() OR client_id = auth.uid());
          END IF;

          IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='conversations' AND policyname='conv_update_participants') THEN
            CREATE POLICY conv_update_participants ON public.conversations FOR UPDATE
            USING (coach_id = auth.uid() OR client_id = auth.uid())
            WITH CHECK (coach_id = auth.uid() OR client_id = auth.uid());
          END IF;
        END $$;
      `);
      console.log('  ✓ Conversations RLS policies created (3 policies)');

      console.log('\nStep 6: Creating RLS policies for messages...');
      await client.query(`
        DO $$
        BEGIN
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

          IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='messages' AND policyname='msg_update_sender') THEN
            CREATE POLICY msg_update_sender ON public.messages FOR UPDATE
            USING (sender_id = auth.uid())
            WITH CHECK (sender_id = auth.uid());
          END IF;
        END $$;
      `);
      console.log('  ✓ Messages RLS policies created (3 policies)');

      console.log('\nStep 7: Creating RLS policies for message_attachments...');
      await client.query(`
        DO $$
        BEGIN
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
      `);
      console.log('  ✓ Message attachments RLS policies created (2 policies)');

      console.log('\n✅ Migration completed successfully!');
    } else {
      console.log('Messaging tables already exist. Skipping migration.\n');
    }

    // Verify all three tables exist
    console.log('\n=== VERIFICATION ===\n');
    console.log('Verifying all tables...');
    const verifyQuery = `
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      AND table_name IN ('conversations', 'messages', 'message_attachments')
      ORDER BY table_name;
    `;

    const verifyResult = await client.query(verifyQuery);
    console.log('\nTables found in database:');
    verifyResult.rows.forEach(row => {
      console.log(`  ✓ ${row.table_name}`);
    });

    // Check indexes
    console.log('\nIndexes:');
    const indexQuery = `
      SELECT indexname, tablename
      FROM pg_indexes
      WHERE schemaname = 'public'
      AND tablename IN ('conversations', 'messages', 'message_attachments')
      AND indexname LIKE 'idx_%'
      ORDER BY tablename, indexname;
    `;

    const indexResult = await client.query(indexQuery);
    indexResult.rows.forEach(row => {
      console.log(`  ✓ ${row.indexname} on ${row.tablename}`);
    });

    // Check RLS policies
    console.log('\nRLS policies:');
    const policyQuery = `
      SELECT tablename, policyname
      FROM pg_policies
      WHERE schemaname = 'public'
      AND tablename IN ('conversations', 'messages', 'message_attachments')
      ORDER BY tablename, policyname;
    `;

    const policyResult = await client.query(policyQuery);
    policyResult.rows.forEach(row => {
      console.log(`  ✓ ${row.tablename}.${row.policyname}`);
    });

    // Check triggers
    console.log('\nTriggers:');
    const triggerQuery = `
      SELECT tgname, tgrelid::regclass AS table_name
      FROM pg_trigger
      WHERE tgrelid IN (
        'public.conversations'::regclass,
        'public.messages'::regclass
      )
      AND tgisinternal = false
      ORDER BY tgname;
    `;

    const triggerResult = await client.query(triggerQuery);
    triggerResult.rows.forEach(row => {
      console.log(`  ✓ ${row.tgname} on ${row.table_name}`);
    });

    console.log('\n=== SUMMARY ===');
    console.log(`Status: ${tableExists ? 'Tables already existed' : 'Tables newly created'}`);
    console.log(`Tables verified: ${verifyResult.rows.length}/3`);
    console.log(`Indexes: ${indexResult.rows.length}`);
    console.log(`RLS Policies: ${policyResult.rows.length}`);
    console.log(`Triggers: ${triggerResult.rows.length}`);

    if (verifyResult.rows.length === 3) {
      console.log('\n✅ All messaging system tables are properly configured!');
    } else {
      console.log('\n⚠ Warning: Not all expected tables were found!');
    }

    return {
      existed: tableExists,
      tablesVerified: verifyResult.rows.length === 3,
      tables: verifyResult.rows.map(r => r.table_name),
      indexCount: indexResult.rows.length,
      policyCount: policyResult.rows.length,
      triggerCount: triggerResult.rows.length
    };

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    if (error.stack) {
      console.error('\nStack trace:', error.stack);
    }
    throw error;
  } finally {
    await client.end();
    console.log('\nDatabase connection closed.');
  }
}

checkAndCreateMessagingTables()
  .then((result) => {
    console.log('\n✅ Script completed successfully.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Script failed with error:', error.message);
    process.exit(1);
  });
