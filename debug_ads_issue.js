const { Client } = require('pg');

async function debugAdsIssue() {
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

    // 1. Check current ads data
    console.log('🔍 Checking current ads data...');
    const adsData = await client.query('SELECT id, title, target_audience FROM public.ads');
    console.log('Current ads data:');
    adsData.rows.forEach(row => {
      console.log(`  ID: ${row.id}, Title: ${row.title}, Audience: ${JSON.stringify(row.target_audience)}`);
    });

    // 2. Check the view data
    console.log('🔍 Checking view data...');
    try {
      const viewData = await client.query('SELECT id, title, audience FROM public.v_current_ads');
      console.log('View data:');
      viewData.rows.forEach(row => {
        console.log(`  ID: ${row.id}, Title: ${row.title}, Audience: ${JSON.stringify(row.audience)}`);
      });
    } catch (error) {
      console.log('View error:', error.message);
    }

    // 3. Let's recreate the ads with proper data
    console.log('🔧 Recreating ads with proper JSON...');
    await client.query('DELETE FROM public.ads');
    await client.query(`
      INSERT INTO public.ads (title, description, target_audience, active, priority)
      VALUES
        ('Welcome to VAGUS', 'Start your fitness journey today!', '{"roles": ["client", "coach"]}', true, 1),
        ('Premium Features', 'Upgrade to unlock advanced analytics', '{"roles": ["client"]}', true, 2)
    `);
    console.log('✅ Recreated ads with proper JSON');

    // 4. Test view again
    console.log('🔍 Testing view after recreation...');
    const newViewData = await client.query('SELECT id, title, audience FROM public.v_current_ads');
    console.log('New view data:');
    newViewData.rows.forEach(row => {
      console.log(`  ID: ${row.id}, Title: ${row.title}, Audience: ${JSON.stringify(row.audience)}`);
    });

    // 5. Test raw JSON parsing
    console.log('🔍 Testing raw JSON parsing...');
    const jsonTest = await client.query(`
      SELECT target_audience::text as text_version,
             target_audience::json as json_version
      FROM public.ads LIMIT 1
    `);
    console.log('JSON test:', jsonTest.rows[0]);

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
    console.log('🔌 Connection closed');
  }
}

debugAdsIssue();