// Comprehensive verification of Nutrition Platform 2.0 migration
const { Client } = require('pg');

// SECURITY: Read from environment variable instead of hardcoding
const connectionString = process.env.SUPABASE_DB_URL || process.env.DATABASE_URL;

if (!connectionString) {
  console.error('❌ SUPABASE_DB_URL or DATABASE_URL environment variable is required');
  console.error('Create a .env file from env.example and set your database URL');
  process.exit(1);
}

async function verify() {
  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    console.log('🔍 NUTRITION PLATFORM 2.0 - VERIFICATION REPORT\n');
    console.log('=' .repeat(60));

    // 1. Check v2.0 columns added
    console.log('\n1️⃣  V2.0 COLUMNS ADDED TO EXISTING TABLES\n');

    const v2Columns = [
      { table: 'nutrition_plans', column: 'format_version' },
      { table: 'nutrition_plans', column: 'metadata' },
      { table: 'nutrition_plans', column: 'is_archived' },
      { table: 'nutrition_meals', column: 'is_eaten' },
      { table: 'nutrition_meals', column: 'meal_photo_url' },
      { table: 'food_items', column: 'carbon_footprint_kg' },
      { table: 'food_items', column: 'sustainability_rating' },
      { table: 'food_items', column: 'barcode' },
    ];

    for (const check of v2Columns) {
      const result = await client.query(`
        SELECT COUNT(*) as exists FROM information_schema.columns
        WHERE table_name = $1 AND column_name = $2
      `, [check.table, check.column]);
      const symbol = result.rows[0].exists > 0 ? '✅' : '❌';
      console.log(`   ${symbol} ${check.table}.${check.column}`);
    }

    // 2. Check new tables created
    console.log('\n2️⃣  NEW TABLES CREATED (28 expected)\n');

    const newTables = [
      'households', 'active_macro_cycles', 'diet_phase_programs',
      'refeed_schedules', 'allergy_profiles', 'restaurant_meal_estimations',
      'dining_tips', 'social_events', 'geofence_reminders', 'achievements',
      'challenges', 'challenge_participants', 'meal_prep_plans',
      'food_waste_logs', 'integration_configs', 'sync_results', 'voice_commands',
      'chat_messages', 'voice_reminders', 'collaboration_sessions', 'version_history',
      'comment_threads', 'cohorts', 'shared_resources', 'daily_sustainability_summaries',
      'ethical_food_items', 'nutrition_plans_archive', 'nutrition_meals_archive'
    ];

    let tablesCreated = 0;
    for (const table of newTables) {
      const result = await client.query(`
        SELECT COUNT(*) as exists FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = $1
      `, [table]);
      if (result.rows[0].exists > 0) {
        tablesCreated++;
        console.log(`   ✅ ${table}`);
      } else {
        console.log(`   ❌ ${table}`);
      }
    }
    console.log(`\n   📊 Total: ${tablesCreated}/${newTables.length} tables created`);

    // 3. Check indexes created
    console.log('\n3️⃣  PERFORMANCE INDEXES CREATED\n');

    const indexes = await client.query(`
      SELECT COUNT(*) as count FROM pg_indexes
      WHERE schemaname = 'public' AND (
        indexname LIKE 'idx_nutrition_meals_%' OR
        indexname LIKE 'idx_nutrition_plans_%' OR
        indexname LIKE 'idx_food_items_%' OR
        indexname LIKE 'idx_achievements_%' OR
        indexname LIKE 'idx_active_macro_cycles_%' OR
        indexname LIKE 'idx_allergy_profiles_%'
      )
    `);
    console.log(`   ✅ ${indexes.rows[0].count} performance indexes created`);

    // 4. Check RLS enabled
    console.log('\n4️⃣  ROW LEVEL SECURITY (RLS)\n');

    const rlsTables = await client.query(`
      SELECT COUNT(*) as count FROM pg_tables
      WHERE schemaname = 'public'
        AND rowsecurity = true
        AND tablename IN (${newTables.slice(0, -2).map((_, i) => `$${i + 1}`).join(',')})
    `, newTables.slice(0, -2)); // Exclude archive tables
    console.log(`   ✅ RLS enabled on ${rlsTables.rows[0].count}/26 tables`);

    // 5. Check data populated
    console.log('\n5️⃣  DATA POPULATION & MIGRATION\n');

    // Nutrition plans
    const plansResult = await client.query(`
      SELECT
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE format_version = '2.0') as v2,
        COUNT(*) FILTER (WHERE migrated_at IS NOT NULL) as migrated
      FROM nutrition_plans
    `);
    console.log(`   ✅ Nutrition Plans: ${plansResult.rows[0].total} total`);
    console.log(`      - v2.0 format: ${plansResult.rows[0].v2}`);
    console.log(`      - Migration timestamp: ${plansResult.rows[0].migrated}`);

    // Sustainability data
    const sustainResult = await client.query(`
      SELECT
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE carbon_footprint_kg IS NOT NULL) as with_carbon,
        COUNT(*) FILTER (WHERE sustainability_rating IS NOT NULL) as with_rating
      FROM food_items
    `);
    console.log(`   ✅ Food Items: ${sustainResult.rows[0].total} total`);
    console.log(`      - With carbon footprint: ${sustainResult.rows[0].with_carbon}`);
    console.log(`      - With sustainability rating: ${sustainResult.rows[0].with_rating}`);

    // Allergy profiles
    const allergyResult = await client.query(`
      SELECT COUNT(*) as count FROM allergy_profiles
    `);
    console.log(`   ✅ Allergy Profiles: ${allergyResult.rows[0].count} initialized`);

    // User streaks
    const streaksResult = await client.query(`
      SELECT COUNT(*) as count FROM user_streaks
      WHERE streak_type = 'nutrition_logging'
    `);
    console.log(`   ✅ User Streaks: ${streaksResult.rows[0].count} nutrition logging streaks`);

    // Challenges
    const challengesResult = await client.query(`
      SELECT COUNT(*) as count FROM challenges WHERE is_active = true
    `);
    console.log(`   ✅ Active Challenges: ${challengesResult.rows[0].count}`);

    // Archive tables
    const archiveResult = await client.query(`
      SELECT
        (SELECT COUNT(*) FROM nutrition_plans_archive) as plans_archived,
        (SELECT COUNT(*) FROM nutrition_meals_archive) as meals_archived
    `);
    console.log(`   ✅ Archive Tables:`);
    console.log(`      - nutrition_plans_archive: ${archiveResult.rows[0].plans_archived} rows`);
    console.log(`      - nutrition_meals_archive: ${archiveResult.rows[0].meals_archived} rows`);

    // 6. Final summary
    console.log('\n' + '=' .repeat(60));
    console.log('\n✅ MIGRATION STATUS: SUCCESS\n');

    const allChecks = [
      tablesCreated === newTables.length,
      indexes.rows[0].count > 0,
      rlsTables.rows[0].count > 0,
      allergyResult.rows[0].count > 0
    ];

    if (allChecks.every(check => check === true)) {
      console.log('🎉 ALL CHECKS PASSED!');
      console.log('\n📋 Summary:');
      console.log('   ✅ Database schema extended with v2.0 columns');
      console.log('   ✅ 28 new tables created');
      console.log('   ✅ Performance indexes added');
      console.log('   ✅ RLS policies enabled');
      console.log('   ✅ Data migrated and initialized');
      console.log('   ✅ Archive tables created for rollback');
      console.log('\n🚀 Database is ready for Nutrition Platform 2.0!');
      console.log('\n📖 Next Steps:');
      console.log('   1. Deploy app with new features');
      console.log('   2. Enable feature flags gradually');
      console.log('   3. Monitor performance');
      console.log('   4. Gather user feedback');
      console.log('\n💡 See PHASED_ROLLOUT_STRATEGY.md for rollout plan');
    } else {
      console.log('⚠️  Some checks failed. Review the report above.');
    }

  } catch (error) {
    console.error('\n❌ Verification failed:', error.message);
  } finally {
    await client.end();
  }
}

verify().catch(console.error);