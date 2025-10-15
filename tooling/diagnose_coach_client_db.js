const { Client } = require('pg');

// Connection string
const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

// SQL queries to execute
const queries = [
  {
    name: '1. List all tables related to coach-client relationships',
    sql: `SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND (table_name LIKE '%coach%' OR table_name LIKE '%client%')`
  },
  {
    name: '2. Schema of coach_clients table',
    sql: `SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'coach_clients' ORDER BY ordinal_position`
  },
  {
    name: '3. Schema of coach_requests table',
    sql: `SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'coach_requests' ORDER BY ordinal_position`
  },
  {
    name: '4. Schema of client_coach_links table',
    sql: `SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'client_coach_links' ORDER BY ordinal_position`
  },
  {
    name: '5. Foreign key constraints',
    sql: `SELECT tc.table_name, kcu.column_name, ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name
          FROM information_schema.table_constraints AS tc
          JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name
          JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name
          WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name IN ('coach_clients', 'coach_requests', 'client_coach_links')`
  },
  {
    name: '6. Duplicate or conflicting connection records',
    sql: `SELECT coach_id, client_id, COUNT(*) as count FROM coach_clients GROUP BY coach_id, client_id HAVING COUNT(*) > 1`
  },
  {
    name: '7. Sample data from coach_clients',
    sql: `SELECT * FROM coach_clients LIMIT 5`
  },
  {
    name: '8. Sample pending coach requests',
    sql: `SELECT * FROM coach_requests WHERE status = 'pending' LIMIT 5`
  }
];

async function runDiagnostics() {
  const client = new Client({
    connectionString,
    ssl: {
      rejectUnauthorized: false
    },
    connectionTimeoutMillis: 30000,
    query_timeout: 60000
  });

  try {
    console.log('Connecting to Supabase database...\n');
    await client.connect();
    console.log('✓ Connected successfully!\n');
    console.log('='.repeat(80));
    console.log('\n');

    // Execute each query
    for (const query of queries) {
      console.log(`\n${query.name}`);
      console.log('-'.repeat(80));

      try {
        const result = await client.query(query.sql);

        if (result.rows.length === 0) {
          console.log('(No rows returned)');
        } else {
          console.log(`Found ${result.rows.length} row(s):\n`);
          console.log(JSON.stringify(result.rows, null, 2));
        }
      } catch (error) {
        console.error(`ERROR executing query: ${error.message}`);
      }

      console.log('\n');
    }

    console.log('='.repeat(80));
    console.log('\nDiagnostics completed successfully!');

  } catch (error) {
    console.error('Connection error:', error.message);
    console.error('\nFull error details:', error);
    process.exit(1);
  } finally {
    await client.end();
    console.log('\nDatabase connection closed.');
  }
}

// Run the diagnostics
runDiagnostics().catch(err => {
  console.error('Unexpected error:', err);
  process.exit(1);
});
