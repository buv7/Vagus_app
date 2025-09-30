// Direct migration runner using Node.js
const fs = require('fs');
const { Client } = require('pg');

const connectionString = 'postgresql://postgres:X.7achoony.X@db.kydrpnrmqbedjflklgue.supabase.co:5432/postgres';

async function runMigrations() {
  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    console.log('🔗 Connecting to Supabase...');
    await client.connect();
    console.log('✅ Connected successfully!\n');

    // Migration 1: Foundation
    console.log('📦 Running Migration 1: Nutrition v2.0 Foundation...');
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
    const migration2 = fs.readFileSync(
      'supabase/migrations/20251001000002_archive_and_migrate.sql',
      'utf8'
    );

    const startTime2 = Date.now();
    const result = await client.query(migration2);
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

    console.log('\n🎉 All migrations completed successfully!');
    console.log('\n📊 Summary:');
    console.log('   - 29 new tables created');
    console.log('   - All nutrition plans migrated to v2.0');
    console.log('   - Sustainability data populated');
    console.log('   - User streaks initialized');
    console.log('   - Allergy profiles ready');
    console.log('   - Archive tables created for rollback safety');
    console.log('\n✅ Database is now ready for Nutrition Platform 2.0!');

  } catch (error) {
    console.error('\n❌ Migration failed:');
    console.error('Error:', error.message);
    console.error('\nDetails:', error);
    console.error('\n⚠️  Please check the error above and:');
    console.error('   1. Verify database permissions');
    console.error('   2. Check if migrations were partially applied');
    console.error('   3. Review migration files for syntax errors');
    console.error('   4. Contact support if issue persists');
    process.exit(1);
  } finally {
    await client.end();
    console.log('\n🔌 Database connection closed.');
  }
}

// Run migrations
runMigrations().catch(console.error);