const { Client } = require('pg');

const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

async function verifyCancelWorks() {
  const client = new Client({ connectionString });

  try {
    await client.connect();
    console.log('✅ Connected to database\n');

    // Show current pending requests
    console.log('=== CURRENT PENDING REQUESTS ===');
    const pendingBefore = await client.query(`
      SELECT 'coach_requests' as table_name, coach_id, client_id, status
      FROM coach_requests
      WHERE status = 'pending'
      UNION ALL
      SELECT 'coach_clients' as table_name, coach_id, client_id, status
      FROM coach_clients
      WHERE status = 'pending'
      ORDER BY table_name
    `);
    console.table(pendingBefore.rows);
    console.log(`Total pending entries: ${pendingBefore.rows.length}\n`);

    // Check RLS policies for DELETE
    console.log('=== DELETE POLICIES ===');
    const deletePolicies = await client.query(`
      SELECT tablename, policyname, cmd, qual
      FROM pg_policies
      WHERE cmd = 'DELETE' AND tablename IN ('coach_requests', 'coach_clients')
      ORDER BY tablename
    `);
    console.table(deletePolicies.rows);

    if (deletePolicies.rows.length === 0) {
      console.log('⚠️  WARNING: No DELETE policies found!');
      console.log('Clients might not be able to delete their pending requests.\n');

      console.log('=== ADDING DELETE POLICIES ===');

      // Add DELETE policy for coach_requests
      await client.query(`
        DROP POLICY IF EXISTS "Clients can delete their pending requests" ON coach_requests;
        CREATE POLICY "Clients can delete their pending requests"
        ON coach_requests FOR DELETE
        USING (auth.uid() = client_id AND status = 'pending');
      `);
      console.log('✅ Added DELETE policy for coach_requests');

      // Add DELETE policy for coach_clients
      await client.query(`
        DROP POLICY IF EXISTS "Clients can delete their own pending requests" ON coach_clients;
      `);
      console.log('✅ Removed old policy from coach_clients (if existed)');

      await client.query(`
        CREATE POLICY "Clients can delete pending connections"
        ON coach_clients FOR DELETE
        USING (auth.uid() = client_id AND status = 'pending');
      `);
      console.log('✅ Added DELETE policy for coach_clients');

      console.log('\n=== POLICIES AFTER FIX ===');
      const policiesAfter = await client.query(`
        SELECT tablename, policyname, cmd
        FROM pg_policies
        WHERE tablename IN ('coach_requests', 'coach_clients')
        ORDER BY tablename, cmd
      `);
      console.table(policiesAfter.rows);
    } else {
      console.log('✅ DELETE policies exist\n');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
    console.log('\n✅ Connection closed');
  }
}

verifyCancelWorks();
