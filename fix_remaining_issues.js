const { Client } = require('pg');

async function fixRemainingIssues() {
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

    // 1. Fix the v_current_ads view to include audience column
    console.log('🔧 Fixing v_current_ads view...');
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
    console.log('✅ Fixed v_current_ads view with audience column');

    // 2. Initialize user data for the current user
    const userId = '7e12816a-f50a-458a-a504-6528319bbd3d';

    // Insert initial rank data
    console.log('🔧 Initializing user rank data...');
    await client.query(`
      INSERT INTO public.user_ranks (user_id, rank_type, rank_value, total_score)
      VALUES
        ($1, 'overall', 1, 0),
        ($1, 'weekly', 1, 0),
        ($1, 'monthly', 1, 0)
      ON CONFLICT (user_id, rank_type, rank_date) DO NOTHING;
    `, [userId]);
    console.log('✅ User rank data initialized');

    // Insert initial streak data
    console.log('🔧 Initializing user streak data...');
    await client.query(`
      INSERT INTO public.user_streaks (user_id, streak_type, current_streak, longest_streak)
      VALUES
        ($1, 'workout', 0, 0),
        ($1, 'nutrition', 0, 0),
        ($1, 'checkin', 0, 0),
        ($1, 'overall', 0, 0)
      ON CONFLICT (user_id, streak_type) DO NOTHING;
    `, [userId]);
    console.log('✅ User streak data initialized');

    // 3. Check if this user has coach data or if we need to handle the coach query differently
    console.log('🔧 Checking coach data...');
    const coachCheck = await client.query(`
      SELECT role FROM public.profiles WHERE id = $1
    `, [userId]);

    if (coachCheck.rows.length > 0) {
      console.log('✅ User role:', coachCheck.rows[0].role);
      if (coachCheck.rows[0].role === 'client') {
        console.log('ℹ️ User is a client, coach data query is expected to return no rows');
      }
    }

    // Verify fixes
    console.log('🔍 Verifying fixes...');

    // Test v_current_ads view
    const adsResult = await client.query('SELECT count(*) as count, audience FROM v_current_ads GROUP BY audience');
    console.log('✅ v_current_ads working:', adsResult.rows);

    // Test user rank data
    const rankResult = await client.query('SELECT rank_type FROM user_ranks WHERE user_id = $1', [userId]);
    console.log('✅ User ranks:', rankResult.rows.map(r => r.rank_type));

    // Test user streak data
    const streakResult = await client.query('SELECT streak_type FROM user_streaks WHERE user_id = $1', [userId]);
    console.log('✅ User streaks:', streakResult.rows.map(r => r.streak_type));

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
    console.log('🔌 Connection closed');
  }
}

fixRemainingIssues();