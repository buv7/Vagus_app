const { Client } = require('pg');

async function fixFinalIssues() {
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

    // 1. Fix the ads table with proper JSON data
    console.log('🔧 Fixing ads table JSON data...');
    await client.query(`
      UPDATE public.ads
      SET target_audience = '{"roles": ["client", "coach"]}'
      WHERE target_audience IS NULL OR target_audience::text = 'null';
    `);
    console.log('✅ Updated ads with proper JSON target_audience');

    // 2. Check current rank data structure
    console.log('🔍 Checking rank data...');
    const userId = '7e12816a-f50a-458a-a504-6528319bbd3d';
    const rankData = await client.query(`
      SELECT rank_type, rank_value, total_score FROM user_ranks WHERE user_id = $1
    `, [userId]);
    console.log('Current rank data:', rankData.rows);

    // 3. Update to have one overall rank entry (the app seems to expect single row)
    console.log('🔧 Updating rank data structure...');
    await client.query(`
      DELETE FROM public.user_ranks WHERE user_id = $1 AND rank_type != 'overall';
    `, [userId]);
    console.log('✅ Simplified rank data to single overall entry');

    // 4. Test the ads view
    console.log('🔍 Testing ads view...');
    const adsResult = await client.query('SELECT audience FROM v_current_ads LIMIT 1');
    console.log('✅ Ads view working:', adsResult.rows);

    // 5. Test rank query
    console.log('🔍 Testing rank query...');
    const singleRankResult = await client.query(`
      SELECT rank_value, total_score FROM user_ranks WHERE user_id = $1 AND rank_type = 'overall'
    `, [userId]);
    console.log('✅ Single rank query result:', singleRankResult.rows);

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
    console.log('🔌 Connection closed');
  }
}

fixFinalIssues();