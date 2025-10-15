const { Client } = require('pg');

const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

async function runDiagnostics() {
  const client = new Client({
    connectionString,
    ssl: {
      rejectUnauthorized: false
    },
    connectionTimeoutMillis: 30000,
    query_timeout: 30000,
  });

  try {
    console.log('Connecting to Supabase database...\n');
    await client.connect();
    console.log('✓ Connected successfully!\n');
    console.log('='.repeat(80));

    // Query 1: Show all connections in coach_clients with details
    console.log('\n1. ALL CONNECTIONS IN coach_clients WITH DETAILS:\n');
    const query1 = `
      SELECT
        cc.coach_id,
        cc.client_id,
        cc.status,
        cc.created_at,
        cp.display_name as coach_name,
        cl.name as client_name
      FROM coach_clients cc
      LEFT JOIN coach_profiles cp ON cc.coach_id = cp.coach_id
      LEFT JOIN profiles cl ON cc.client_id = cl.id;
    `;
    const result1 = await client.query(query1);
    console.log(`Found ${result1.rows.length} connection(s):`);
    console.table(result1.rows);
    console.log('='.repeat(80));

    // Query 2: Show all coach profiles
    console.log('\n2. ALL COACH PROFILES:\n');
    const query2 = `
      SELECT coach_id, display_name, is_active, marketplace_enabled
      FROM coach_profiles;
    `;
    const result2 = await client.query(query2);
    console.log(`Found ${result2.rows.length} coach profile(s):`);
    console.table(result2.rows);
    console.log('='.repeat(80));

    // Query 3: Check the underlying user_coach_links table
    console.log('\n3. UNDERLYING user_coach_links TABLE:\n');
    const query3 = `SELECT * FROM user_coach_links;`;
    try {
      const result3 = await client.query(query3);
      console.log(`Found ${result3.rows.length} link(s):`);
      console.table(result3.rows);
    } catch (error) {
      console.log(`Note: user_coach_links table may not exist or is inaccessible: ${error.message}`);
    }
    console.log('='.repeat(80));

    // Query 4: Count connections per coach
    console.log('\n4. COUNT CONNECTIONS PER COACH:\n');
    const query4 = `
      SELECT coach_id, COUNT(*) as client_count
      FROM coach_clients
      GROUP BY coach_id;
    `;
    const result4 = await client.query(query4);
    console.log(`Found ${result4.rows.length} coach(es) with clients:`);
    console.table(result4.rows);
    console.log('='.repeat(80));

    // Query 5: Count connections per client
    console.log('\n5. COUNT CONNECTIONS PER CLIENT:\n');
    const query5 = `
      SELECT client_id, COUNT(*) as coach_count
      FROM coach_clients
      GROUP BY client_id;
    `;
    const result5 = await client.query(query5);
    console.log(`Found ${result5.rows.length} client(s) with coaches:`);
    console.table(result5.rows);
    console.log('='.repeat(80));

    // Additional diagnostic queries
    console.log('\n6. ADDITIONAL DIAGNOSTICS:\n');

    // Check table structure
    console.log('coach_clients table structure:');
    const structureQuery = `
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'coach_clients'
      ORDER BY ordinal_position;
    `;
    const structureResult = await client.query(structureQuery);
    console.table(structureResult.rows);

    // Check for any RLS policies
    console.log('\nRow Level Security Policies on coach_clients:');
    const rlsQuery = `
      SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
      FROM pg_policies
      WHERE tablename = 'coach_clients';
    `;
    const rlsResult = await client.query(rlsQuery);
    if (rlsResult.rows.length > 0) {
      console.table(rlsResult.rows);
    } else {
      console.log('No RLS policies found (or RLS not enabled)');
    }

    console.log('\n='.repeat(80));
    console.log('\nDiagnostics complete!');

  } catch (error) {
    console.error('Error during diagnostics:', error);
    console.error('\nFull error details:', error.stack);
  } finally {
    await client.end();
    console.log('\n✓ Database connection closed');
  }
}

runDiagnostics();
