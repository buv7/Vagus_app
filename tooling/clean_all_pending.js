const { Client } = require('pg');

const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

async function cleanAllPending() {
  const client = new Client({ connectionString });

  try {
    await client.connect();
    console.log('✅ Connected to database\n');

    // Show current pending requests
    console.log('=== CURRENT PENDING REQUESTS ===');
    const currentRequests = await client.query(`
      SELECT 'coach_requests' as source, id, coach_id, client_id, status, created_at
      FROM coach_requests
      WHERE status = 'pending'
      ORDER BY created_at DESC
    `);
    console.table(currentRequests.rows);

    const currentLinks = await client.query(`
      SELECT 'user_coach_links' as source, coach_id, client_id, status, created_at
      FROM user_coach_links
      WHERE status = 'pending'
      ORDER BY created_at DESC
    `);
    console.table(currentLinks.rows);

    // Delete all pending requests
    console.log('\n=== CLEANING UP ===');

    const deletedRequests = await client.query(`
      DELETE FROM coach_requests
      WHERE status = 'pending'
      RETURNING id, coach_id, client_id
    `);
    console.log(`✅ Deleted ${deletedRequests.rows.length} pending requests from coach_requests`);

    const deletedLinks = await client.query(`
      DELETE FROM user_coach_links
      WHERE status = 'pending'
      RETURNING coach_id, client_id
    `);
    console.log(`✅ Deleted ${deletedLinks.rows.length} pending connections from user_coach_links`);

    // Verify cleanup
    console.log('\n=== VERIFICATION ===');
    const remainingRequests = await client.query(`
      SELECT COUNT(*) as count FROM coach_requests WHERE status = 'pending'
    `);
    const remainingLinks = await client.query(`
      SELECT COUNT(*) as count FROM user_coach_links WHERE status = 'pending'
    `);

    console.log(`Remaining pending in coach_requests: ${remainingRequests.rows[0].count}`);
    console.log(`Remaining pending in user_coach_links: ${remainingLinks.rows[0].count}`);

    if (remainingRequests.rows[0].count === '0' && remainingLinks.rows[0].count === '0') {
      console.log('\n✅ All pending requests cleaned up!');
      console.log('You can now try connecting again.');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
    console.log('\n✅ Connection closed');
  }
}

cleanAllPending();
