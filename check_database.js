// Check current database state
const { Client } = require('pg');

const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

async function checkDatabase() {
  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    console.log('🔗 Connecting to database...');
    await client.connect();
    console.log('✅ Connected!\n');

    // Check all tables
    console.log('📋 Existing tables in public schema:');
    const tablesResult = await client.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      ORDER BY table_name
    `);

    if (tablesResult.rows.length === 0) {
      console.log('   ⚠️  No tables found!');
    } else {
      tablesResult.rows.forEach((row, index) => {
        console.log(`   ${index + 1}. ${row.table_name}`);
      });
      console.log(`\n📊 Total tables: ${tablesResult.rows.length}`);
    }

    // Check for nutrition-related tables
    console.log('\n🍎 Nutrition-related tables:');
    const nutritionTables = tablesResult.rows.filter(row =>
      row.table_name.includes('nutrition') ||
      row.table_name.includes('meal') ||
      row.table_name.includes('food')
    );

    if (nutritionTables.length === 0) {
      console.log('   ⚠️  No nutrition tables found!');
      console.log('   💡 You may need to run base migrations first.');
    } else {
      nutritionTables.forEach((row) => {
        console.log(`   ✅ ${row.table_name}`);
      });
    }

    // Check for migrations table
    console.log('\n📝 Migration tracking:');
    const migrationCheck = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'supabase_migrations'
          AND table_name = 'schema_migrations'
      ) as exists
    `);

    if (migrationCheck.rows[0].exists) {
      const appliedMigrations = await client.query(`
        SELECT version, name
        FROM supabase_migrations.schema_migrations
        ORDER BY version DESC
        LIMIT 10
      `);

      console.log('   ✅ Last 10 applied migrations:');
      appliedMigrations.rows.forEach((row) => {
        console.log(`      ${row.version} - ${row.name || 'unnamed'}`);
      });
    } else {
      console.log('   ⚠️  No migration tracking table found');
    }

    console.log('\n✅ Database check complete!');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error(error);
  } finally {
    await client.end();
  }
}

checkDatabase().catch(console.error);