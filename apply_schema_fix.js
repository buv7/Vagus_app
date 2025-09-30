const { Client } = require('pg');
const fs = require('fs');

async function applySchemaFix() {
  const client = new Client({
    host: 'aws-0-eu-central-1.pooler.supabase.com',
    port: 5432,
    database: 'postgres',
    user: 'postgres.kydrpnrmqbedjflklgue',
    password: 'X.7achoony.X',
    ssl: {
      rejectUnauthorized: false
    }
  });

  try {
    console.log('🔌 Connecting to Supabase...');
    await client.connect();
    console.log('✅ Connected to Supabase successfully!');

    console.log('📄 Reading schema fix SQL...');
    const sql = fs.readFileSync('fix_database_schema.sql', 'utf8');

    console.log('🚀 Executing schema fix...');
    await client.query(sql);
    console.log('✅ Schema fix applied successfully!');

    // Verify the tables were created
    console.log('🔍 Verifying tables...');
    const result = await client.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      AND table_name IN ('progress_entries', 'user_ranks', 'user_streaks', 'ads')
      ORDER BY table_name
    `);

    console.log('✅ Created tables:', result.rows.map(row => row.table_name));

    // Check if revoke column was added
    const deviceCol = await client.query(`
      SELECT column_name
      FROM information_schema.columns
      WHERE table_name = 'user_devices' AND column_name = 'revoke'
    `);

    if (deviceCol.rows.length > 0) {
      console.log('✅ Added revoke column to user_devices');
    }

    // Check view
    const viewResult = await client.query(`
      SELECT count(*) as ad_count FROM v_current_ads
    `);
    console.log('✅ v_current_ads view created, sample ads:', viewResult.rows[0].ad_count);

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
    console.log('🔌 Connection closed');
  }
}

applySchemaFix();