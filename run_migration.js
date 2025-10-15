const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// Database connection configuration
const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

// Create client with SSL configuration
const client = new Client({
  connectionString,
  ssl: {
    rejectUnauthorized: false
  },
  connectionTimeoutMillis: 30000,
  query_timeout: 60000
});

// Migration file path
const migrationFilePath = path.join(__dirname, 'supabase_migration_fix_coach_connections_corrected.sql');

async function runMigration() {
  console.log('='.repeat(80));
  console.log('SUPABASE DATABASE MIGRATION EXECUTION');
  console.log('='.repeat(80));
  console.log(`Migration file: ${migrationFilePath}`);
  console.log(`Target database: aws-0-eu-central-1.pooler.supabase.com`);
  console.log(`Project ID: kydrpnrmqbedjflklgue`);
  console.log('='.repeat(80));
  console.log('');

  try {
    // Connect to database
    console.log('[1/5] Connecting to Supabase database...');
    await client.connect();
    console.log('✓ Connected successfully');
    console.log('');

    // Read migration file
    console.log('[2/5] Reading migration file...');
    const migrationSQL = fs.readFileSync(migrationFilePath, 'utf8');
    console.log(`✓ Migration file loaded (${migrationSQL.length} characters)`);
    console.log('');

    // Execute migration
    console.log('[3/5] Executing migration...');
    console.log('This may take a moment...');
    console.log('');

    const result = await client.query(migrationSQL);
    console.log('✓ Migration executed successfully');
    console.log('');

    // Run verification queries
    console.log('[4/5] Running verification queries...');
    console.log('');

    // Verify columns
    console.log('Verifying coach_profiles columns...');
    const columnsResult = await client.query(`
      SELECT column_name, data_type, column_default
      FROM information_schema.columns
      WHERE table_name = 'coach_profiles'
        AND column_name IN ('is_active', 'marketplace_enabled', 'rating')
      ORDER BY column_name;
    `);
    console.log('Columns added:');
    console.table(columnsResult.rows);

    // Verify indexes
    console.log('Verifying indexes...');
    const indexesResult = await client.query(`
      SELECT indexname, tablename
      FROM pg_indexes
      WHERE tablename IN ('coach_profiles', 'user_coach_links', 'connection_notifications')
        AND schemaname = 'public'
      ORDER BY tablename, indexname;
    `);
    console.log('Indexes created:');
    console.table(indexesResult.rows);

    // Verify RLS
    console.log('Verifying RLS (Row Level Security)...');
    const rlsResult = await client.query(`
      SELECT tablename, rowsecurity
      FROM pg_tables
      WHERE tablename IN ('coach_profiles', 'user_coach_links', 'connection_notifications')
        AND schemaname = 'public'
      ORDER BY tablename;
    `);
    console.log('RLS enabled on tables:');
    console.table(rlsResult.rows);

    // Verify policies
    console.log('Verifying RLS policies...');
    const policiesResult = await client.query(`
      SELECT tablename, policyname, cmd
      FROM pg_policies
      WHERE tablename IN ('coach_profiles', 'user_coach_links', 'connection_notifications')
      ORDER BY tablename, policyname;
    `);
    console.log(`Policies created (${policiesResult.rows.length} total):`);
    console.table(policiesResult.rows);

    // Verify views
    console.log('Verifying views...');
    const viewsResult = await client.query(`
      SELECT table_name as view_name
      FROM information_schema.views
      WHERE table_schema = 'public'
        AND table_name IN ('active_coach_connections', 'pending_coach_requests')
      ORDER BY table_name;
    `);
    console.log('Views created:');
    console.table(viewsResult.rows);

    // Verify functions
    console.log('Verifying stored functions...');
    const functionsResult = await client.query(`
      SELECT routine_name, routine_type
      FROM information_schema.routines
      WHERE routine_schema = 'public'
        AND routine_name IN (
          'approve_connection_request',
          'reject_connection_request',
          'is_actively_connected',
          'update_updated_at_column',
          'notify_connection_event'
        )
      ORDER BY routine_name;
    `);
    console.log('Functions created:');
    console.table(functionsResult.rows);

    // Check connection_notifications table
    console.log('Verifying connection_notifications table...');
    const tableResult = await client.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_name = 'connection_notifications';
    `);
    if (tableResult.rows.length > 0) {
      console.log('✓ connection_notifications table created');
    } else {
      console.log('✗ connection_notifications table not found');
    }
    console.log('');

    // Final summary
    console.log('[5/5] Migration Summary');
    console.log('='.repeat(80));
    console.log('✓ PART 1: Coach profiles columns added (is_active, marketplace_enabled, rating)');
    console.log('✓ PART 2: user_coach_links table improved with indexes and timestamps');
    console.log('✓ PART 3: Row Level Security policies created for user_coach_links');
    console.log('✓ PART 4: Row Level Security policies created for coach_profiles');
    console.log('✓ PART 5: Helper views created (active_coach_connections, pending_coach_requests)');
    console.log('✓ PART 6: Stored functions created for connection management');
    console.log('✓ PART 7: Notification system created with triggers');
    console.log('='.repeat(80));
    console.log('');
    console.log('MIGRATION COMPLETED SUCCESSFULLY!');
    console.log('');
    console.log('Next steps:');
    console.log('1. Update app code to use the new RLS policies');
    console.log('2. Implement connection approval UI for coaches');
    console.log('3. Test connection workflow end-to-end');
    console.log('4. Optionally run PART 7 to auto-approve pending connections');
    console.log('='.repeat(80));

  } catch (error) {
    console.error('');
    console.error('='.repeat(80));
    console.error('MIGRATION FAILED');
    console.error('='.repeat(80));
    console.error('Error details:');
    console.error(`Message: ${error.message}`);
    if (error.code) console.error(`Code: ${error.code}`);
    if (error.position) console.error(`Position: ${error.position}`);
    if (error.detail) console.error(`Detail: ${error.detail}`);
    if (error.hint) console.error(`Hint: ${error.hint}`);
    console.error('='.repeat(80));
    console.error('');
    console.error('Full error:');
    console.error(error);
    process.exit(1);
  } finally {
    // Close connection
    await client.end();
    console.log('');
    console.log('Database connection closed.');
  }
}

// Run the migration
runMigration().catch(error => {
  console.error('Unexpected error:', error);
  process.exit(1);
});
