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

async function investigate() {
  try {
    await client.connect();
    console.log('✓ Connected to Supabase');
    console.log('');

    // Check if coach_clients is a view or table
    console.log('1. Checking if coach_clients is a table or view:');
    const typeQuery = `
      SELECT
        table_name,
        table_type
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_name IN ('coach_clients', 'coach_requests')
      ORDER BY table_name;
    `;
    const typeResult = await client.query(typeQuery);
    console.table(typeResult.rows);
    console.log('');

    // If coach_clients is a view, get its definition
    console.log('2. Getting view definition for coach_clients:');
    const viewQuery = `
      SELECT
        table_name,
        view_definition
      FROM information_schema.views
      WHERE table_schema = 'public'
        AND table_name = 'coach_clients';
    `;
    const viewResult = await client.query(viewQuery);
    if (viewResult.rows.length > 0) {
      console.log('View definition:');
      console.log(viewResult.rows[0].view_definition);
    } else {
      console.log('coach_clients is not a view');
    }
    console.log('');

    // Find all tables that might be related to coach-client relationships
    console.log('3. Searching for coach-related tables:');
    const relatedTablesQuery = `
      SELECT
        table_name,
        table_type
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND (table_name LIKE '%coach%' OR table_name LIKE '%client%')
      ORDER BY table_type, table_name;
    `;
    const relatedResult = await client.query(relatedTablesQuery);
    console.table(relatedResult.rows);
    console.log('');

    // Check for any base table that the view might be based on
    console.log('4. Checking for potential base tables:');
    const baseTableQuery = `
      SELECT
        schemaname,
        tablename,
        tableowner
      FROM pg_tables
      WHERE schemaname = 'public'
        AND (tablename LIKE '%coach%' OR tablename LIKE '%client%')
      ORDER BY tablename;
    `;
    const baseResult = await client.query(baseTableQuery);
    console.table(baseResult.rows);
    console.log('');

    // Show structure of all coach/client related objects
    console.log('5. Detailed structure of coach_requests (for comparison):');
    const requestsStructure = `
      SELECT
        column_name,
        data_type,
        is_nullable,
        column_default
      FROM information_schema.columns
      WHERE table_name = 'coach_requests'
      ORDER BY ordinal_position;
    `;
    const structResult = await client.query(requestsStructure);
    console.table(structResult.rows);
    console.log('');

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.end();
    console.log('Connection closed');
  }
}

investigate().catch(console.error);
