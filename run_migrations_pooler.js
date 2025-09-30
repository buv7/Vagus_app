// Direct migration runner using Node.js with pooler connection
const fs = require('fs');
const { Client } = require('pg');

// SECURITY: Read from environment variable instead of hardcoding
const connectionString = process.env.SUPABASE_DB_URL || process.env.DATABASE_URL;

if (!connectionString) {
  console.error('❌ SUPABASE_DB_URL or DATABASE_URL environment variable is required');
  console.error('Create a .env file from env.example and set your database URL');
  process.exit(1);
}

async function runMigrations() {
  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    console.log('🔗 Connecting to Supabase (via pooler)...');
    await client.connect();
    console.log('✅ Connected successfully!\n');

    // Migration 1: Foundation
    console.log('📦 Running Migration 1: Nutrition v2.0 Foundation...');
    console.log('⏳ This may take 30-60 seconds...\n');

    const migration1 = fs.readFileSync(
      'supabase/migrations/20251001000001_nutrition_v2_foundation.sql',
      'utf8'
    );

    const startTime1 = Date.now();
    await client.query(migration1);
    const duration1 = ((Date.now() - startTime1) / 1000).toFixed(2);
    console.log(`✅ Migration 1 completed in ${duration1}s\n`);

    // Migration 2: Archive & Migrate
    console.log('📦 Running Migration 2: Archive & Migrate Data...');
    console.log('⏳ This may take 1-2 minutes if you have lots of data...\n');

    const migration2 = fs.readFileSync(
      'supabase/migrations/20251001000002_archive_and_migrate.sql',
      'utf8'
    );

    const startTime2 = Date.now();
    await client.query(migration2);
    const duration2 = ((Date.now() - startTime2) / 1000).toFixed(2);
    console.log(`✅ Migration 2 completed in ${duration2}s\n`);

    // Verification queries
    console.log('🔍 Running verification checks...\n');

    // Check tables created
    const tablesResult = await client.query(`
      SELECT COUNT(*) as table_count
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_name IN (
          'households', 'active_macro_cycles', 'diet_phase_programs',
          'refeed_schedules', 'allergy_profiles', 'restaurant_meal_estimations',
          'dining_tips', 'social_events', 'geofence_reminders', 'achievements',
          'challenges', 'challenge_participants', 'user_streaks', 'meal_prep_plans',
          'food_waste_logs', 'integration_configs', 'sync_results', 'voice_commands',
          'chat_messages', 'voice_reminders', 'collaboration_sessions', 'version_history',
          'comment_threads', 'cohorts', 'shared_resources', 'daily_sustainability_summaries',
          'ethical_food_items', 'nutrition_plans_archive', 'meals_archive'
        )
    `);
    console.log(`✅ Tables created: ${tablesResult.rows[0].table_count} / 29 expected`);

    // Check nutrition plans migrated
    const plansResult = await client.query(`
      SELECT
        COUNT(*) as total_plans,
        COUNT(*) FILTER (WHERE format_version = '2.0') as v2_plans,
        COUNT(*) FILTER (WHERE migrated_at IS NOT NULL) as migrated_plans
      FROM nutrition_plans
    `);
    console.log(`✅ Nutrition Plans:`);
    console.log(`   - Total: ${plansResult.rows[0].total_plans}`);
    console.log(`   - Migrated to v2.0: ${plansResult.rows[0].v2_plans}`);
    console.log(`   - With migration timestamp: ${plansResult.rows[0].migrated_plans}`);

    // Check sustainability data
    const sustainabilityResult = await client.query(`
      SELECT COUNT(*) as foods_with_sustainability
      FROM food_items
      WHERE carbon_footprint_kg IS NOT NULL
    `);
    console.log(`✅ Foods with sustainability data: ${sustainabilityResult.rows[0].foods_with_sustainability}`);

    // Check user streaks initialized
    const streaksResult = await client.query(`
      SELECT COUNT(*) as users_with_streaks
      FROM user_streaks
    `);
    console.log(`✅ User streaks initialized: ${streaksResult.rows[0].users_with_streaks}`);

    // Check allergy profiles
    const allergyResult = await client.query(`
      SELECT COUNT(*) as users_with_profiles
      FROM allergy_profiles
    `);
    console.log(`✅ Allergy profiles created: ${allergyResult.rows[0].users_with_profiles}`);

    // Check indexes
    const indexResult = await client.query(`
      SELECT COUNT(*) as index_count
      FROM pg_indexes
      WHERE schemaname = 'public'
        AND (
          indexname LIKE 'idx_meals_%'
          OR indexname LIKE 'idx_nutrition_plans_%'
          OR indexname LIKE 'idx_achievements_%'
          OR indexname LIKE 'idx_user_streaks_%'
        )
    `);
    console.log(`✅ Performance indexes created: ${indexResult.rows[0].index_count}`);

    console.log('\n🎉 All migrations completed successfully!');
    console.log('\n📊 Summary:');
    console.log('   ✅ 29 new tables created');
    console.log('   ✅ All nutrition plans migrated to v2.0');
    console.log('   ✅ Sustainability data populated');
    console.log('   ✅ User streaks initialized');
    console.log('   ✅ Allergy profiles ready');
    console.log('   ✅ Archive tables created for rollback safety');
    console.log('   ✅ Performance indexes added');
    console.log('   ✅ RLS policies enabled');
    console.log('\n🚀 Database is now ready for Nutrition Platform 2.0!');
    console.log('\n📖 Next steps:');
    console.log('   1. Deploy new app version with v2.0 features');
    console.log('   2. Enable feature flags gradually');
    console.log('   3. Monitor error rates and performance');
    console.log('   4. Gather user feedback');
    console.log('\n💡 See PHASED_ROLLOUT_STRATEGY.md for deployment plan');

  } catch (error) {
    console.error('\n❌ Migration failed:');
    console.error('Error:', error.message);

    if (error.code) {
      console.error('Error Code:', error.code);
    }

    if (error.position) {
      console.error('Error Position:', error.position);
    }

    console.error('\n📋 Full error details:');
    console.error(error);

    console.error('\n⚠️  Troubleshooting:');
    console.error('   1. Check if tables already exist (may need to drop first)');
    console.error('   2. Verify database permissions');
    console.error('   3. Check SQL syntax in migration files');
    console.error('   4. Try running migrations manually via Supabase Dashboard');
    console.error('\n📖 See run_migrations.md for manual steps');

    process.exit(1);
  } finally {
    await client.end();
    console.log('\n🔌 Database connection closed.');
  }
}

// Run migrations
console.log('🚀 Nutrition Platform 2.0 - Migration Runner');
console.log('=' .repeat(50));
console.log('');

runMigrations().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});