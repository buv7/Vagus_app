const { Client } = require('pg');

const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

async function fixDeletePolicies() {
  const client = new Client({ connectionString });

  try {
    await client.connect();
    console.log('✅ Connected to database\n');

    // Add DELETE policy for coach_requests
    console.log('=== ADDING DELETE POLICY FOR coach_requests ===');
    await client.query(`
      DROP POLICY IF EXISTS "Clients can delete their pending requests" ON coach_requests;
      CREATE POLICY "Clients can delete their pending requests"
      ON coach_requests FOR DELETE
      USING (auth.uid() = client_id AND status = 'pending');
    `);
    console.log('✅ Added DELETE policy for coach_requests');

    // Add DELETE policy for user_coach_links (the base table)
    console.log('\n=== ADDING DELETE POLICY FOR user_coach_links ===');
    await client.query(`
      DROP POLICY IF EXISTS "Clients can delete pending connections" ON user_coach_links;
      CREATE POLICY "Clients can delete pending connections"
      ON user_coach_links FOR DELETE
      USING (auth.uid() = client_id AND status = 'pending');
    `);
    console.log('✅ Added DELETE policy for user_coach_links');

    // Verify policies
    console.log('\n=== VERIFICATION ===');
    const policies = await client.query(`
      SELECT tablename, policyname, cmd, using_expr
      FROM pg_policies
      WHERE (tablename = 'coach_requests' OR tablename = 'user_coach_links')
        AND cmd = 'DELETE'
      ORDER BY tablename
    `);
    console.table(policies.rows);

    console.log('\n✅ Clients can now cancel their pending requests!');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
    console.log('\n✅ Connection closed');
  }
}

fixDeletePolicies();
