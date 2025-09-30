// Check structure of existing nutrition tables
const { Client } = require('pg');

// SECURITY: Read from environment variable instead of hardcoding
const connectionString = process.env.SUPABASE_DB_URL || process.env.DATABASE_URL;

if (!connectionString) {
  console.error('❌ SUPABASE_DB_URL or DATABASE_URL environment variable is required');
  console.error('Create a .env file from env.example and set your database URL');
  process.exit(1);
}

async function checkSchema() {
  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    console.log('🔗 Connecting to database...');
    await client.connect();
    console.log('✅ Connected!\n');

    // Check nutrition_plans columns
    console.log('📋 nutrition_plans structure:');
    const plansColumns = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'nutrition_plans'
      ORDER BY ordinal_position
    `);
    plansColumns.rows.forEach(row => {
      console.log(`   - ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });

    // Check nutrition_meals columns
    console.log('\n📋 nutrition_meals structure:');
    const mealsColumns = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'nutrition_meals'
      ORDER BY ordinal_position
    `);
    mealsColumns.rows.forEach(row => {
      console.log(`   - ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });

    // Check food_items columns
    console.log('\n📋 food_items structure:');
    const foodColumns = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'food_items'
      ORDER BY ordinal_position
    `);
    foodColumns.rows.forEach(row => {
      console.log(`   - ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });

    // Check if nutrition v2 columns already exist
    console.log('\n🔍 Checking for v2.0 columns:');
    const v2Checks = [
      { table: 'nutrition_plans', column: 'format_version' },
      { table: 'nutrition_plans', column: 'metadata' },
      { table: 'nutrition_meals', column: 'is_eaten' },
      { table: 'food_items', column: 'carbon_footprint_kg' },
    ];

    for (const check of v2Checks) {
      const result = await client.query(`
        SELECT COUNT(*) as exists
        FROM information_schema.columns
        WHERE table_name = $1 AND column_name = $2
      `, [check.table, check.column]);

      const exists = result.rows[0].exists > 0;
      console.log(`   ${exists ? '✅' : '❌'} ${check.table}.${check.column}`);
    }

    // Check if v2.0 tables already exist
    console.log('\n🔍 Checking for v2.0 tables:');
    const v2Tables = [
      'households', 'active_macro_cycles', 'allergy_profiles',
      'achievements', 'user_streaks', 'meal_prep_plans'
    ];

    for (const tableName of v2Tables) {
      const result = await client.query(`
        SELECT COUNT(*) as exists
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = $1
      `, [tableName]);

      const exists = result.rows[0].exists > 0;
      console.log(`   ${exists ? '✅' : '❌'} ${tableName}`);
    }

    console.log('\n✅ Schema check complete!');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error(error);
  } finally {
    await client.end();
  }
}

checkSchema().catch(console.error);