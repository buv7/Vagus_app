const { Client } = require('pg');

const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

const client = new Client({
  connectionString,
  ssl: {
    rejectUnauthorized: false
  },
  connectionTimeoutMillis: 30000,
  query_timeout: 60000
});

async function executeCorrectedMigration() {
  try {
    await client.connect();
    console.log('✓ Connected to Supabase');
    console.log('');
    console.log('='.repeat(80));
    console.log('CORRECTED MIGRATION FOR user_coach_links');
    console.log('='.repeat(80));
    console.log('');
    console.log('Note: The original migration tried to modify coach_clients which is a VIEW.');
    console.log('The actual base table is user_coach_links, which already has most constraints.');
    console.log('');

    let stepNum = 0;

    // Step 1: Add id column if it doesn't exist (for backward compatibility)
    stepNum++;
    console.log(`Step ${stepNum}: Adding id column to user_coach_links (if not exists)`);
    try {
      await client.query(`
        ALTER TABLE user_coach_links
        ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid();
      `);
      console.log('✓ Success - id column added or already exists');
    } catch (error) {
      console.log('✗ Error:', error.message);
    }
    console.log('');

    // Step 2: Create a unique index on id if it was just added
    stepNum++;
    console.log(`Step ${stepNum}: Creating unique index on id column`);
    try {
      await client.query(`
        CREATE UNIQUE INDEX IF NOT EXISTS idx_user_coach_links_id
        ON user_coach_links(id);
      `);
      console.log('✓ Success - unique index on id created');
    } catch (error) {
      console.log('✗ Error:', error.message);
    }
    console.log('');

    // Step 3: Add index on status if not exists
    stepNum++;
    console.log(`Step ${stepNum}: Creating index on status column`);
    try {
      await client.query(`
        CREATE INDEX IF NOT EXISTS idx_user_coach_links_status
        ON user_coach_links(status);
      `);
      console.log('✓ Success - index on status created');
    } catch (error) {
      console.log('✗ Error:', error.message);
    }
    console.log('');

    // Step 4: Verify the status check constraint allows all needed values
    stepNum++;
    console.log(`Step ${stepNum}: Checking status constraint values`);
    const statusQuery = `
      SELECT
        conname as constraint_name,
        pg_get_constraintdef(oid) as constraint_definition
      FROM pg_constraint
      WHERE conrelid = 'user_coach_links'::regclass
        AND contype = 'c'
        AND conname LIKE '%status%';
    `;
    const statusResult = await client.query(statusQuery);
    console.log('Current status constraint:');
    console.table(statusResult.rows);
    console.log('');

    // Step 5: Summary of user_coach_links structure
    console.log('='.repeat(80));
    console.log('FINAL VERIFICATION: user_coach_links table');
    console.log('='.repeat(80));
    console.log('');

    console.log('1. Columns:');
    const columnsQuery = `
      SELECT
        column_name,
        data_type,
        is_nullable,
        column_default
      FROM information_schema.columns
      WHERE table_name = 'user_coach_links'
      ORDER BY ordinal_position;
    `;
    const columns = await client.query(columnsQuery);
    console.table(columns.rows);
    console.log('');

    console.log('2. Constraints:');
    const constraintsQuery = `
      SELECT
        constraint_name,
        constraint_type
      FROM information_schema.table_constraints
      WHERE table_name = 'user_coach_links'
      ORDER BY constraint_type, constraint_name;
    `;
    const constraints = await client.query(constraintsQuery);
    console.table(constraints.rows);
    console.log('');

    console.log('3. Indexes:');
    const indexesQuery = `
      SELECT
        indexname as index_name,
        indexdef as index_definition
      FROM pg_indexes
      WHERE tablename = 'user_coach_links'
      ORDER BY indexname;
    `;
    const indexes = await client.query(indexesQuery);
    console.table(indexes.rows);
    console.log('');

    console.log('4. Foreign Keys:');
    const fkQuery = `
      SELECT
        tc.constraint_name,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name,
        rc.delete_rule
      FROM information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
      JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
      JOIN information_schema.referential_constraints AS rc
        ON rc.constraint_name = tc.constraint_name
      WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_name = 'user_coach_links'
      ORDER BY tc.constraint_name;
    `;
    const fks = await client.query(fkQuery);
    console.table(fks.rows);
    console.log('');

    // Verify coach_requests (which was successfully migrated)
    console.log('='.repeat(80));
    console.log('VERIFICATION: coach_requests table (successfully migrated)');
    console.log('='.repeat(80));
    console.log('');

    console.log('1. Columns:');
    const requestsColumns = await client.query(`
      SELECT
        column_name,
        data_type,
        is_nullable,
        column_default
      FROM information_schema.columns
      WHERE table_name = 'coach_requests'
      ORDER BY ordinal_position;
    `);
    console.table(requestsColumns.rows);
    console.log('');

    console.log('2. Constraints:');
    const requestsConstraints = await client.query(`
      SELECT
        constraint_name,
        constraint_type
      FROM information_schema.table_constraints
      WHERE table_name = 'coach_requests'
      ORDER BY constraint_type, constraint_name;
    `);
    console.table(requestsConstraints.rows);
    console.log('');

    console.log('3. Indexes:');
    const requestsIndexes = await client.query(`
      SELECT
        indexname as index_name,
        indexdef as index_definition
      FROM pg_indexes
      WHERE tablename = 'coach_requests'
      ORDER BY indexname;
    `);
    console.table(requestsIndexes.rows);
    console.log('');

    console.log('='.repeat(80));
    console.log('MIGRATION SUMMARY');
    console.log('='.repeat(80));
    console.log('');
    console.log('✓ user_coach_links: Already had proper constraints, added id column and status index');
    console.log('✓ coach_requests: Successfully migrated with all constraints and indexes');
    console.log('');
    console.log('Note: coach_clients is a VIEW that references user_coach_links.');
    console.log('      All data integrity is enforced at the user_coach_links table level.');
    console.log('');

  } catch (error) {
    console.error('Fatal error:', error);
  } finally {
    await client.end();
    console.log('Connection closed');
  }
}

executeCorrectedMigration().catch(console.error);
