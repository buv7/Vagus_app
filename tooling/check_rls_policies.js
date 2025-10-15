const { Client } = require('pg');

const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

async function checkRLSPolicies() {
  const client = new Client({ connectionString });

  try {
    await client.connect();
    console.log('✅ Connected to database\n');

    // Check if RLS is enabled
    console.log('=== RLS STATUS ===');
    const rlsStatus = await client.query(`
      SELECT tablename, rowsecurity
      FROM pg_tables
      WHERE tablename IN ('coach_requests', 'coach_clients')
      ORDER BY tablename
    `);
    console.table(rlsStatus.rows);

    // Check existing policies
    console.log('\n=== EXISTING POLICIES ON coach_requests ===');
    const policies = await client.query(`
      SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
      FROM pg_policies
      WHERE tablename = 'coach_requests'
      ORDER BY policyname
    `);
    console.table(policies.rows);

    // Add missing policy for client inserts
    console.log('\n=== ADDING MISSING POLICY ===');
    try {
      await client.query(`
        DROP POLICY IF EXISTS "Clients can create connection requests" ON coach_requests;
      `);

      await client.query(`
        CREATE POLICY "Clients can create connection requests"
        ON coach_requests FOR INSERT
        WITH CHECK (auth.uid() = client_id);
      `);
      console.log('✅ Policy created: Clients can create connection requests');
    } catch (e) {
      console.log('⚠️  Policy creation result:', e.message);
    }

    // Verify policies after
    console.log('\n=== POLICIES AFTER FIX ===');
    const policiesAfter = await client.query(`
      SELECT policyname, cmd, with_check
      FROM pg_policies
      WHERE tablename = 'coach_requests'
      ORDER BY policyname
    `);
    console.table(policiesAfter.rows);

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
    console.log('\n✅ Connection closed');
  }
}

checkRLSPolicies();
