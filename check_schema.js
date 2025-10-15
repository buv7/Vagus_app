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

async function checkSchema() {
  console.log('Checking database schema...\n');

  try {
    await client.connect();
    console.log('Connected to database\n');

    // Check if coach_clients is a table or view
    console.log('1. Checking coach_clients type:');
    const typeCheck = await client.query(`
      SELECT
        CASE
          WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'coach_clients' AND table_type = 'BASE TABLE') THEN 'TABLE'
          WHEN EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'coach_clients') THEN 'VIEW'
          ELSE 'NOT FOUND'
        END as object_type;
    `);
    console.log(`   coach_clients is a: ${typeCheck.rows[0].object_type}`);
    console.log('');

    // If it's a view, get the view definition
    if (typeCheck.rows[0].object_type === 'VIEW') {
      console.log('2. Getting view definition:');
      const viewDef = await client.query(`
        SELECT definition
        FROM pg_views
        WHERE viewname = 'coach_clients' AND schemaname = 'public';
      `);
      if (viewDef.rows.length > 0) {
        console.log('   View definition:');
        console.log('   ' + viewDef.rows[0].definition);
      }
      console.log('');
    }

    // Check for underlying table
    console.log('3. Checking for related tables:');
    const tables = await client.query(`
      SELECT table_name, table_type
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_name LIKE '%coach%'
      ORDER BY table_name;
    `);
    console.log('   Tables/Views with "coach" in name:');
    console.table(tables.rows);

    // Check coach_profiles structure
    console.log('4. Checking coach_profiles columns:');
    const columns = await client.query(`
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'coach_profiles'
      ORDER BY ordinal_position;
    `);
    console.table(columns.rows);

    // Check for connection-related tables
    console.log('5. Checking for connection-related tables:');
    const connTables = await client.query(`
      SELECT table_name, table_type
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND (table_name LIKE '%connection%' OR table_name LIKE '%client%')
      ORDER BY table_name;
    `);
    console.table(connTables.rows);

  } catch (error) {
    console.error('Error:', error.message);
    console.error('Code:', error.code);
    console.error('Detail:', error.detail);
  } finally {
    await client.end();
  }
}

checkSchema();
