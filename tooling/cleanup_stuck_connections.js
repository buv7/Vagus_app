const { Client } = require('pg');

const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

async function cleanupStuckConnections() {
  const client = new Client({ connectionString });

  try {
    await client.connect();
    console.log('✅ Connected to database\n');

    // Get pending connections that don't have matching coach_requests
    const stuckResult = await client.query(`
      SELECT cc.coach_id, cc.client_id, cc.status, cc.created_at
      FROM coach_clients cc
      LEFT JOIN coach_requests cr ON cc.coach_id = cr.coach_id AND cc.client_id = cr.client_id
      WHERE cc.status = 'pending' AND cr.id IS NULL
    `);

    console.log(`Found ${stuckResult.rows.length} stuck pending connections without matching requests\n`);

    if (stuckResult.rows.length > 0) {
      console.log('Creating missing coach_requests entries...');

      for (const row of stuckResult.rows) {
        await client.query(`
          INSERT INTO coach_requests (coach_id, client_id, status, created_at)
          VALUES ($1, $2, 'pending', $3)
          ON CONFLICT DO NOTHING
        `, [row.coach_id, row.client_id, row.created_at]);

        console.log(`✅ Created request for coach ${row.coach_id.substring(0, 8)}...`);
      }

      console.log('\n✅ All stuck connections have been fixed!');
      console.log('Coaches should now be able to see these pending requests.');
    } else {
      console.log('No stuck connections found. Everything looks good!');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
    console.log('\n✅ Connection closed');
  }
}

cleanupStuckConnections();
