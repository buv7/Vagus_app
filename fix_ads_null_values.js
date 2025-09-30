const { Client } = require('pg');

async function fixAdsNullValues() {
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
    const currentAds = await client.query('SELECT * FROM public.ads');
    console.log('Current ads:');
    currentAds.rows.forEach(row => {
      console.log(`  ${row.title}: image_url=${row.image_url}, start_date=${row.start_date}, created_by=${row.created_by}`);
    });

    // 2. Update ads with proper non-null values
    console.log('🔧 Updating ads with required fields...');

    // First, add missing columns if they don't exist
    await client.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ads' AND column_name = 'created_by') THEN
          ALTER TABLE public.ads ADD COLUMN created_by uuid;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ads' AND column_name = 'is_active') THEN
          ALTER TABLE public.ads ADD COLUMN is_active boolean DEFAULT true;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ads' AND column_name = 'starts_at') THEN
          ALTER TABLE public.ads ADD COLUMN starts_at timestamp with time zone DEFAULT now();
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ads' AND column_name = 'ends_at') THEN
          ALTER TABLE public.ads ADD COLUMN ends_at timestamp with time zone;
        END IF;
      END $$;
    `);

    // Get a system user ID for created_by
    const systemUserId = '7e12816a-f50a-458a-a504-6528319bbd3d'; // Use current user

    await client.query(`
      UPDATE public.ads SET
        image_url = COALESCE(image_url, 'https://via.placeholder.com/400x200?text=VAGUS+Ad'),
        start_date = COALESCE(start_date, now()),
        created_by = COALESCE(created_by, $1),
        starts_at = COALESCE(starts_at, now()),
        is_active = COALESCE(active, true)
    `, [systemUserId]);

    console.log('✅ Updated ads with required non-null values');

    // 3. Update the view to match the model expectations
    console.log('🔧 Updating v_current_ads view...');
    await client.query('DROP VIEW IF EXISTS public.v_current_ads');
    await client.query(`
      CREATE VIEW public.v_current_ads AS
      SELECT
        id,
        title,
        description,
        image_url,
        link_url,
        target_audience as audience,
        COALESCE(starts_at, start_date, created_at) as starts_at,
        COALESCE(ends_at, end_date) as ends_at,
        COALESCE(is_active, active, true) as is_active,
        created_by,
        created_at,
        updated_at
      FROM public.ads
      WHERE COALESCE(is_active, active, true) = true
        AND (starts_at IS NULL OR starts_at <= now())
        AND (ends_at IS NULL OR ends_at >= now())
      ORDER BY priority DESC, created_at DESC;
    `);
    console.log('✅ Updated v_current_ads view with all required fields');

    // 4. Test the view
    console.log('🔍 Testing updated view...');
    const viewResult = await client.query('SELECT * FROM v_current_ads');
    console.log('✅ View test result:');
    viewResult.rows.forEach(row => {
      console.log(`  ${row.title}: image_url=${row.image_url ? 'SET' : 'NULL'}, starts_at=${row.starts_at ? 'SET' : 'NULL'}, created_by=${row.created_by ? 'SET' : 'NULL'}`);
    });

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
    console.log('🔌 Connection closed');
  }
}

fixAdsNullValues();