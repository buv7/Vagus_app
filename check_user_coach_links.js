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

async function checkTable() {
  try {
    await client.connect();
    console.log('✓ Connected to Supabase');
    console.log('');

    console.log('='.repeat(80));
    console.log('USER_COACH_LINKS TABLE STRUCTURE');
    console.log('='.repeat(80));
    console.log('');

    // 1. Column structure
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

    // 2. Existing constraints
    console.log('2. Existing Constraints:');
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

    // 3. Existing indexes
    console.log('3. Existing Indexes:');
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

    // 4. Check for NULL values
    console.log('4. Checking for NULL values in key columns:');
    const nullCheckQuery = `
      SELECT
        COUNT(*) as total_rows,
        COUNT(CASE WHEN client_id IS NULL THEN 1 END) as null_client_id,
        COUNT(CASE WHEN coach_id IS NULL THEN 1 END) as null_coach_id,
        COUNT(CASE WHEN created_at IS NULL THEN 1 END) as null_created_at,
        COUNT(CASE WHEN status IS NULL THEN 1 END) as null_status
      FROM user_coach_links;
    `;
    const nullCheck = await client.query(nullCheckQuery);
    console.table(nullCheck.rows);
    console.log('');

    // 5. Check for duplicate coach-client pairs
    console.log('5. Checking for duplicate coach-client pairs:');
    const duplicatesQuery = `
      SELECT
        coach_id,
        client_id,
        COUNT(*) as count
      FROM user_coach_links
      GROUP BY coach_id, client_id
      HAVING COUNT(*) > 1;
    `;
    const duplicates = await client.query(duplicatesQuery);
    if (duplicates.rows.length > 0) {
      console.log('Found duplicates:');
      console.table(duplicates.rows);
    } else {
      console.log('✓ No duplicate coach-client pairs found');
    }
    console.log('');

    // 6. Check for orphaned records (coach_id or client_id not in profiles)
    console.log('6. Checking for orphaned records:');
    const orphansQuery = `
      SELECT
        COUNT(*) as total,
        COUNT(CASE WHEN NOT EXISTS (SELECT 1 FROM profiles WHERE id = ucl.coach_id) THEN 1 END) as orphaned_coach_id,
        COUNT(CASE WHEN NOT EXISTS (SELECT 1 FROM profiles WHERE id = ucl.client_id) THEN 1 END) as orphaned_client_id
      FROM user_coach_links ucl;
    `;
    const orphans = await client.query(orphansQuery);
    console.table(orphans.rows);
    console.log('');

    // 7. Sample data
    console.log('7. Sample data (first 5 rows):');
    const sampleQuery = `
      SELECT * FROM user_coach_links LIMIT 5;
    `;
    const sample = await client.query(sampleQuery);
    console.table(sample.rows);
    console.log('');

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.end();
    console.log('Connection closed');
  }
}

checkTable().catch(console.error);
