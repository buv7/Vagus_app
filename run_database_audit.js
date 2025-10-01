#!/usr/bin/env node
/**
 * VAGUS Database Audit Script - Direct PostgreSQL Connection
 * Uses pg module to connect to Supabase and verify schema
 */

const { Client } = require('pg');
const fs = require('fs');

// Database connection
const client = new Client({
  host: 'aws-0-eu-central-1.pooler.supabase.com',
  port: 5432,
  database: 'postgres',
  user: 'postgres.kydrpnrmqbedjflklgue',
  password: 'X.7achoony.X',
  ssl: { rejectUnauthorized: false }
});

console.log('================================');
console.log('VAGUS Database Audit');
console.log('================================\n');

async function runAudit() {
  try {
    console.log('📡 Connecting to database...');
    await client.connect();
    console.log('✅ Connected successfully!\n');

    const results = {};

    // 1. Connection Test
    console.log('🔍 Running audit queries...\n');
    const version = await client.query('SELECT version()');
    console.log('📊 PostgreSQL Version:', version.rows[0].version.split('\n')[0]);
    results.version = version.rows[0].version;

    // 2. Table Count
    const tableCount = await client.query(`
      SELECT COUNT(*) as total_tables
      FROM information_schema.tables
      WHERE table_schema = 'public'
    `);
    console.log(`\n📋 Total Tables: ${tableCount.rows[0].total_tables} (expected: ~127)`);
    results.totalTables = parseInt(tableCount.rows[0].total_tables);

    // 3. List All Tables
    const tables = await client.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      ORDER BY table_name
    `);
    const dbTables = tables.rows.map(r => r.table_name);
    fs.writeFileSync('db_tables.txt', dbTables.join('\n'));
    console.log(`✅ Exported ${dbTables.length} tables to db_tables.txt`);
    results.tables = dbTables;

    // 4. Critical Tables Check
    console.log('\n🔍 Checking critical tables...');
    const criticalTables = ['profiles', 'nutrition_plans', 'workout_plans', 'ai_usage',
                           'user_files', 'client_metrics', 'progress_photos', 'checkins',
                           'coach_notes', 'messages', 'message_threads', 'calendar_events'];

    const criticalStatus = {};
    for (const table of criticalTables) {
      const exists = dbTables.includes(table);
      console.log(`  ${exists ? '✅' : '❌'} ${table}`);
      criticalStatus[table] = exists;
    }
    results.criticalTables = criticalStatus;

    // 5. View Count
    const viewCount = await client.query(`
      SELECT COUNT(*) as total_views
      FROM information_schema.views
      WHERE table_schema = 'public'
    `);
    console.log(`\n📊 Total Views: ${viewCount.rows[0].total_views} (expected: ~45)`);
    results.totalViews = parseInt(viewCount.rows[0].total_views);

    // 6. Check nutrition_grocery_items_with_info view
    const groceryView = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.views
        WHERE table_schema = 'public'
        AND table_name = 'nutrition_grocery_items_with_info'
      ) as exists
    `);
    const groceryViewExists = groceryView.rows[0].exists;
    console.log(`  ${groceryViewExists ? '✅' : '❌'} nutrition_grocery_items_with_info view`);
    results.nutritionGroceryView = groceryViewExists;

    // 7. Function Count
    const functionCount = await client.query(`
      SELECT COUNT(*) as total_functions
      FROM information_schema.routines
      WHERE routine_schema = 'public'
    `);
    console.log(`\n📊 Total Functions: ${functionCount.rows[0].total_functions} (expected: ~75)`);
    results.totalFunctions = parseInt(functionCount.rows[0].total_functions);

    // 8. RLS Coverage
    const rlsCoverage = await client.query(`
      SELECT
        COUNT(*) FILTER (WHERE rowsecurity = true) as tables_with_rls,
        COUNT(*) FILTER (WHERE rowsecurity = false) as tables_without_rls,
        COUNT(*) as total
      FROM pg_tables
      WHERE schemaname = 'public'
    `);
    const rlsData = rlsCoverage.rows[0];
    const rlsPercent = ((parseInt(rlsData.tables_with_rls) / parseInt(rlsData.total)) * 100).toFixed(1);
    console.log(`\n🔒 RLS Coverage: ${rlsData.tables_with_rls}/${rlsData.total} tables (${rlsPercent}%, expected: 94.5%)`);
    results.rlsCoverage = {
      withRLS: parseInt(rlsData.tables_with_rls),
      withoutRLS: parseInt(rlsData.tables_without_rls),
      total: parseInt(rlsData.total),
      percentage: parseFloat(rlsPercent)
    };

    // 9. Tables without RLS
    const noRLS = await client.query(`
      SELECT tablename
      FROM pg_tables
      WHERE schemaname = 'public'
        AND rowsecurity = false
      ORDER BY tablename
    `);
    const tablesWithoutRLS = noRLS.rows.map(r => r.tablename);
    console.log(`\n⚠️  Tables WITHOUT RLS (${tablesWithoutRLS.length}):`);
    tablesWithoutRLS.slice(0, 10).forEach(t => console.log(`   - ${t}`));
    if (tablesWithoutRLS.length > 10) {
      console.log(`   ... and ${tablesWithoutRLS.length - 10} more`);
    }
    results.tablesWithoutRLS = tablesWithoutRLS;

    // 10. Policy Count
    const policyCount = await client.query(`
      SELECT COUNT(*) as total_policies
      FROM pg_policies
      WHERE schemaname = 'public'
    `);
    console.log(`\n🛡️  Total RLS Policies: ${policyCount.rows[0].total_policies} (expected: ~348)`);
    results.totalPolicies = parseInt(policyCount.rows[0].total_policies);

    // 11. Workout v2 tables
    const workoutTables = await client.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_name LIKE '%workout%'
      ORDER BY table_name
    `);
    console.log(`\n💪 Workout-related tables: ${workoutTables.rows.length}`);
    results.workoutTables = workoutTables.rows.map(r => r.table_name);

    // 12. Nutrition v2 tables
    const nutritionTables = await client.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_name LIKE '%nutrition%'
      ORDER BY table_name
    `);
    console.log(`🥗 Nutrition-related tables: ${nutritionTables.rows.length}`);
    results.nutritionTables = nutritionTables.rows.map(r => r.table_name);

    // 13. Foreign Key Count
    const fkCount = await client.query(`
      SELECT COUNT(*) as total_fks
      FROM information_schema.table_constraints
      WHERE constraint_type = 'FOREIGN KEY'
        AND table_schema = 'public'
    `);
    console.log(`\n🔗 Total Foreign Keys: ${fkCount.rows[0].total_fks}`);
    results.totalForeignKeys = parseInt(fkCount.rows[0].total_fks);

    // 14. Index Count
    const indexCount = await client.query(`
      SELECT COUNT(*) as total_indexes
      FROM pg_indexes
      WHERE schemaname = 'public'
    `);
    console.log(`📑 Total Indexes: ${indexCount.rows[0].total_indexes}`);
    results.totalIndexes = parseInt(indexCount.rows[0].total_indexes);

    // Save full results
    fs.writeFileSync('database_audit_results.json', JSON.stringify(results, null, 2));
    console.log('\n✅ Full results saved to database_audit_results.json');

    // Compare with code tables
    console.log('\n================================');
    console.log('Comparing Code vs Database');
    console.log('================================\n');

    const codeTables = fs.readFileSync('code_tables.txt', 'utf8').split('\n').filter(t => t.trim());
    console.log(`📋 Tables in code: ${codeTables.length}`);
    console.log(`📊 Tables in database: ${dbTables.length}`);

    const missing = codeTables.filter(t => !dbTables.includes(t));
    const unused = dbTables.filter(t => !codeTables.includes(t));

    fs.writeFileSync('missing_tables.txt', missing.join('\n'));
    fs.writeFileSync('unused_tables.txt', unused.join('\n'));

    console.log(`\n${missing.length > 0 ? '⚠️' : '✅'}  Missing tables (in code but not DB): ${missing.length}`);
    if (missing.length > 0 && missing.length < 20) {
      missing.forEach(t => console.log(`   - ${t}`));
    } else if (missing.length >= 20) {
      missing.slice(0, 10).forEach(t => console.log(`   - ${t}`));
      console.log(`   ... and ${missing.length - 10} more (see missing_tables.txt)`);
    }

    console.log(`\nℹ️   Unused tables (in DB but not in code): ${unused.length}`);
    if (unused.length > 0) {
      unused.slice(0, 5).forEach(t => console.log(`   - ${t}`));
      if (unused.length > 5) {
        console.log(`   ... and ${unused.length - 5} more (see unused_tables.txt)`);
      }
    }

    results.comparison = {
      codeTableCount: codeTables.length,
      dbTableCount: dbTables.length,
      missingCount: missing.length,
      unusedCount: unused.length,
      missing,
      unused
    };

    // Final summary
    console.log('\n================================');
    console.log('Audit Summary');
    console.log('================================\n');

    const issues = [];
    if (results.totalTables < 100) issues.push('❌ Table count too low');
    if (results.rlsCoverage.percentage < 90) issues.push('⚠️  RLS coverage below 90%');
    if (!results.nutritionGroceryView) issues.push('❌ nutrition_grocery_items_with_info view missing');
    if (missing.length > 50) issues.push(`⚠️  ${missing.length} missing tables`);

    const allCriticalExist = Object.values(results.criticalTables).every(v => v);
    if (!allCriticalExist) issues.push('❌ Some critical tables missing');

    if (issues.length === 0) {
      console.log('✅ Database schema looks healthy!');
      console.log('✅ All critical tables present');
      console.log('✅ RLS coverage good');
      console.log('✅ View structure intact');
    } else {
      console.log('⚠️  Issues found:');
      issues.forEach(issue => console.log(`   ${issue}`));
    }

    console.log('\n📁 Generated files:');
    console.log('   - database_audit_results.json (Full results)');
    console.log('   - db_tables.txt (All DB tables)');
    console.log('   - missing_tables.txt (Missing in DB)');
    console.log('   - unused_tables.txt (Not used in code)');

    console.log('\n✅ Audit complete!');

    return results;

  } catch (err) {
    console.error('\n❌ Error during audit:', err.message);
    throw err;
  } finally {
    await client.end();
  }
}

// Run audit
runAudit()
  .then(() => {
    console.log('\n🎉 Audit successful!');
    process.exit(0);
  })
  .catch((err) => {
    console.error('\n💥 Audit failed:', err);
    process.exit(1);
  });
