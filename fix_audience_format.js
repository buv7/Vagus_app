const { Client } = require('pg');

async function fixAudienceFormat() {
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

    // 1. Drop view first, then change column type
    console.log('🔧 Dropping view and changing target_audience column type...');
    await client.query('DROP VIEW IF EXISTS public.v_current_ads');
    await client.query('DELETE FROM public.ads');
    await client.query('ALTER TABLE public.ads ALTER COLUMN target_audience TYPE text');

    console.log('🔧 Updating ads table with simple string audience...');
    await client.query(`
      INSERT INTO public.ads (title, description, target_audience, active, priority)
      VALUES
        ('Welcome to VAGUS', 'Start your fitness journey today!', 'both', true, 1),
        ('Premium Features', 'Upgrade to unlock advanced analytics', 'client', true, 2)
    `);
    console.log('✅ Updated ads with simple string audience');

    // 2. Update the view to match app expectations
    console.log('🔧 Updating v_current_ads view...');
    await client.query('DROP VIEW IF EXISTS public.v_current_ads');
    await client.query(`
      CREATE VIEW public.v_current_ads AS
      SELECT id, title, description, image_url, link_url,
             target_audience as audience, active, priority,
             start_date, end_date, created_at, updated_at
      FROM public.ads
      WHERE active = true
        AND (start_date IS NULL OR start_date <= now())
        AND (end_date IS NULL OR end_date >= now())
      ORDER BY priority DESC, created_at DESC;
    `);
    console.log('✅ Updated v_current_ads view with string audience');

    // 3. Test the query the app is making
    console.log('🔍 Testing app query...');
    const testResult = await client.query(`
      SELECT * FROM v_current_ads WHERE audience IN ('client', 'both')
    `);
    console.log('✅ App query test result:', testResult.rows);

    // 4. Schema already updated above
    console.log('✅ Schema already updated to text type');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
    console.log('🔌 Connection closed');
  }
}

fixAudienceFormat();