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

      // Read the migration file
      const migrationPath = path.join(__dirname, '..', 'supabase', 'migrations', '20250115120031_messaging_system.sql');
      const migrationSQL = fs.readFileSync(migrationPath, 'utf8');

      console.log('Executing migration SQL...');
      await client.query(migrationSQL);
      console.log('Migration executed successfully!\n');
    } else {
      console.log('Messaging tables already exist. Skipping migration.\n');
    }

    // Verify all three tables exist
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
    console.log('\nChecking indexes...');
    const indexQuery = `
      SELECT indexname
      FROM pg_indexes
      WHERE schemaname = 'public'
      AND tablename IN ('conversations', 'messages', 'message_attachments')
      ORDER BY indexname;
    `;

    const indexResult = await client.query(indexQuery);
    console.log(`Found ${indexResult.rows.length} indexes`);

    // Check RLS policies
    console.log('\nChecking RLS policies...');
    const policyQuery = `
      SELECT tablename, policyname
      FROM pg_policies
      WHERE schemaname = 'public'
      AND tablename IN ('conversations', 'messages', 'message_attachments')
      ORDER BY tablename, policyname;
    `;

    const policyResult = await client.query(policyQuery);
    console.log(`Found ${policyResult.rows.length} RLS policies:`);
    policyResult.rows.forEach(row => {
      console.log(`  - ${row.tablename}.${row.policyname}`);
    });

    // Check triggers
    console.log('\nChecking triggers...');
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
    console.log(`Found ${triggerResult.rows.length} triggers:`);
    triggerResult.rows.forEach(row => {
      console.log(`  - ${row.tgname} on ${row.table_name}`);
    });

    console.log('\n=== SUMMARY ===');
    console.log(`Status: ${tableExists ? 'Tables already existed' : 'Tables created successfully'}`);
    console.log(`Tables verified: ${verifyResult.rows.length}/3`);
    console.log(`Indexes: ${indexResult.rows.length}`);
    console.log(`RLS Policies: ${policyResult.rows.length}`);
    console.log(`Triggers: ${triggerResult.rows.length}`);

    if (verifyResult.rows.length === 3) {
      console.log('\n✓ All messaging system tables are properly configured!');
    } else {
      console.log('\n⚠ Warning: Not all expected tables were found!');
    }

  } catch (error) {
    console.error('Error:', error.message);
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
  .then(() => {
    console.log('\nScript completed successfully.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\nScript failed with error:', error.message);
    process.exit(1);
  });
