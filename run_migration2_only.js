// Run ONLY migration 2 (data migration)
const fs = require('fs');
const { Client } = require('pg');

const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

async function runMigration2() {
  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    console.log('🔗 Connecting...');
    await client.connect();
    console.log('✅ Connected!\n');

    console.log('📦 Running Migration 2 (Data Migration)...');
    const migration2 = fs.readFileSync(
      'supabase/migrations/20251001000002_archive_and_migrate_fixed.sql',
      'utf8'
    );

    const start = Date.now();
    await client.query(migration2);
    console.log(`✅ Completed in ${((Date.now() - start) / 1000).toFixed(2)}s\n`);

    // Verification
    const plansResult = await client.query(`
      SELECT COUNT(*) as total,
             COUNT(*) FILTER (WHERE format_version = '2.0') as v2
      FROM nutrition_plans
    `);
    console.log(`✅ Plans: ${plansResult.rows[0].v2}/${plansResult.rows[0].total} migrated to v2.0`);

    const sustainResult = await client.query(`
      SELECT COUNT(*) as count FROM food_items WHERE carbon_footprint_kg IS NOT NULL
    `);
    console.log(`✅ Foods with sustainability: ${sustainResult.rows[0].count}`);

    const allergyResult = await client.query(`
      SELECT COUNT(*) as count FROM allergy_profiles
    `);
    console.log(`✅ Allergy profiles: ${allergyResult.rows[0].count}`);

    console.log('\n🎉 Data migration complete!');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    if (error.code) console.error('Code:', error.code);
    process.exit(1);
  } finally {
    await client.end();
  }
}

runMigration2().catch(console.error);