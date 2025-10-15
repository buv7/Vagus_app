#!/usr/bin/env node

/**
 * Supabase Messages Table Diagnostic Script
 * Analyzes the actual database schema to determine correct structure
 */

const { Client } = require('pg');

// IMPORTANT: Never hardcode credentials in production
// This is for diagnostic purposes only
const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

async function diagnose() {
  const client = new Client({
    connectionString,
    ssl: {
      rejectUnauthorized: false // Required for Supabase
    },
    connectionTimeoutMillis: 30000,
    query_timeout: 30000
  });

  try {
    console.log('Connecting to Supabase database...');
    await client.connect();
    console.log('Connected successfully!\n');

    // Query 1: Check if messages table exists and show its columns
    console.log('=== Query 1: Messages Table Schema ===');
    const messagesSchema = await client.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'messages'
      ORDER BY ordinal_position;
    `);

    if (messagesSchema.rows.length === 0) {
      console.log('❌ Messages table does NOT exist');
    } else {
      console.log('✅ Messages table exists with columns:');
      console.table(messagesSchema.rows);
    }

    // Query 2: Check if conversations table exists
    console.log('\n=== Query 2: Conversations Table Schema ===');
    const conversationsSchema = await client.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'conversations'
      ORDER BY ordinal_position;
    `);

    if (conversationsSchema.rows.length === 0) {
      console.log('❌ Conversations table does NOT exist');
    } else {
      console.log('✅ Conversations table exists with columns:');
      console.table(conversationsSchema.rows);
    }

    // Query 3: Check if message_threads table exists
    console.log('\n=== Query 3: Message Threads Table Schema ===');
    const threadsSchema = await client.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'message_threads'
      ORDER BY ordinal_position;
    `);

    if (threadsSchema.rows.length === 0) {
      console.log('❌ Message_threads table does NOT exist');
    } else {
      console.log('✅ Message_threads table exists with columns:');
      console.table(threadsSchema.rows);
    }

    // Query 4: List all messaging-related tables
    console.log('\n=== Query 4: All Messaging-Related Tables ===');
    const messagingTables = await client.query(`
      SELECT table_name,
             (SELECT COUNT(*) FROM information_schema.columns c WHERE c.table_name = t.table_name) as column_count
      FROM information_schema.tables t
      WHERE table_schema = 'public'
      AND (table_name LIKE '%message%' OR table_name LIKE '%conversation%' OR table_name LIKE '%thread%')
      ORDER BY table_name;
    `);

    console.log('Found tables:');
    console.table(messagingTables.rows);

    // Query 5: Show sample data structure from messages (if exists)
    if (messagesSchema.rows.length > 0) {
      console.log('\n=== Query 5: Sample Messages Data ===');
      try {
        const sampleData = await client.query(`
          SELECT * FROM messages LIMIT 1;
        `);

        if (sampleData.rows.length === 0) {
          console.log('⚠️  Messages table is empty (no sample data)');
        } else {
          console.log('Sample message structure:');
          console.log(JSON.stringify(sampleData.rows[0], null, 2));
        }
      } catch (err) {
        console.error('❌ Error fetching sample data:', err.message);
      }
    }

    // Query 6: Check for foreign key constraints on messages table
    console.log('\n=== Query 6: Foreign Key Constraints on Messages ===');
    const constraints = await client.query(`
      SELECT
        tc.constraint_name,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name
      FROM information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
      JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
      WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_schema = 'public'
        AND tc.table_name = 'messages'
      ORDER BY tc.constraint_name;
    `);

    if (constraints.rows.length === 0) {
      console.log('⚠️  No foreign key constraints found on messages table');
    } else {
      console.log('Foreign key constraints:');
      console.table(constraints.rows);
    }

    // Diagnostic Summary
    console.log('\n=== DIAGNOSTIC SUMMARY ===');
    const hasMessages = messagesSchema.rows.length > 0;
    const hasConversations = conversationsSchema.rows.length > 0;
    const hasConversationId = messagesSchema.rows.some(col => col.column_name === 'conversation_id');
    const hasRecipientId = messagesSchema.rows.some(col => col.column_name === 'recipient_id');

    console.log(`Messages table exists: ${hasMessages ? '✅' : '❌'}`);
    console.log(`Conversations table exists: ${hasConversations ? '✅' : '❌'}`);

    if (hasMessages) {
      console.log(`\nMessages table structure:`);
      console.log(`  - Has conversation_id: ${hasConversationId ? '✅' : '❌'}`);
      console.log(`  - Has recipient_id: ${hasRecipientId ? '✅' : '❌'}`);

      if (hasConversationId && hasConversations) {
        console.log('\n✅ CORRECT SCHEMA: Using conversation-based messaging');
        console.log('   Messages should be queried by conversation_id');
      } else if (hasRecipientId) {
        console.log('\n⚠️  LEGACY SCHEMA: Using direct sender/recipient messaging');
        console.log('   Consider migrating to conversation-based schema');
      } else {
        console.log('\n❌ UNKNOWN SCHEMA: Cannot determine messaging structure');
      }
    }

  } catch (error) {
    console.error('\n❌ Diagnostic failed:', error.message);
    console.error('Error details:', error);
    process.exit(1);
  } finally {
    await client.end();
    console.log('\nConnection closed.');
  }
}

// Run diagnostic
diagnose().catch(console.error);
