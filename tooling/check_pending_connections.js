const { Client } = require('pg');

const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

async function checkPendingConnections() {
  const client = new Client({ connectionString });

  try {
    await client.connect();
    console.log('✅ Connected to database\n');

    // 1. Check pending connections in coach_clients
    console.log('=== PENDING CONNECTIONS IN COACH_CLIENTS ===');
    const pendingResult = await client.query(`
      SELECT cc.coach_id, cc.client_id, cc.status, cc.created_at,
             cp.display_name as coach_name, cp.username as coach_username,
             cl.name as client_name, cl.email as client_email
      FROM coach_clients cc
      LEFT JOIN coach_profiles cp ON cc.coach_id = cp.coach_id
      LEFT JOIN profiles cl ON cc.client_id = cl.id
      WHERE cc.status = 'pending'
      ORDER BY cc.created_at DESC
    `);
    console.log(`Found ${pendingResult.rows.length} pending connections:`);
    console.table(pendingResult.rows);

    // 2. Check coach_requests table
    console.log('\n=== COACH REQUESTS TABLE ===');
    const requestsResult = await client.query(`
      SELECT cr.id, cr.coach_id, cr.client_id, cr.status, cr.created_at, cr.message,
             cp.display_name as coach_name,
             cl.name as client_name
      FROM coach_requests cr
      LEFT JOIN coach_profiles cp ON cr.coach_id = cp.coach_id
      LEFT JOIN profiles cl ON cr.client_id = cl.id
      ORDER BY cr.created_at DESC
      LIMIT 10
    `);
    console.log(`Found ${requestsResult.rows.length} requests:`);
    console.table(requestsResult.rows);

    // 3. Check for mismatches
    console.log('\n=== MISMATCHES BETWEEN TABLES ===');
    const mismatchResult = await client.query(`
      SELECT
        'Only in coach_clients' as location,
        cc.coach_id, cc.client_id, cc.status, cc.created_at
      FROM coach_clients cc
      LEFT JOIN coach_requests cr ON cc.coach_id = cr.coach_id AND cc.client_id = cr.client_id
      WHERE cr.id IS NULL
      UNION ALL
      SELECT
        'Only in coach_requests' as location,
        cr.coach_id, cr.client_id, cr.status::text, cr.created_at
      FROM coach_requests cr
      LEFT JOIN coach_clients cc ON cr.coach_id = cc.coach_id AND cr.client_id = cc.client_id
      WHERE cc.client_id IS NULL
    `);
    console.log(`Found ${mismatchResult.rows.length} mismatches:`);
    console.table(mismatchResult.rows);

    // 4. Check for duplicates
    console.log('\n=== DUPLICATE ENTRIES ===');
    const duplicateResult = await client.query(`
      SELECT coach_id, client_id, COUNT(*) as count
      FROM coach_clients
      GROUP BY coach_id, client_id
      HAVING COUNT(*) > 1
    `);
    console.log(`Found ${duplicateResult.rows.length} duplicates:`);
    console.table(duplicateResult.rows);

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
    console.log('\n✅ Connection closed');
  }
}

checkPendingConnections();
