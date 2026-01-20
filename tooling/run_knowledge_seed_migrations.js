#!/usr/bin/env node

/**
 * Run Knowledge Base Seed Migrations
 * 
 * Connects to Supabase via connection pooler and runs migrations in order.
 * 
 * Usage: node tooling/run_knowledge_seed_migrations.js
 */

const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const CONNECTION_STRING = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

const BASE_MIGRATION = '20251221021539_workout_knowledge_base.sql';

const MIGRATIONS = [
  '20251221122033_knowledge_seed_unique_indexes.sql',
  '20251221122034_seed_exercise_knowledge_from_library.sql', // Old migration (kept for compatibility)
  '20251221130000_seed_exercise_knowledge_autodetect.sql', // New auto-detect migration
  '20251221122035_seed_intensifier_knowledge.sql',
  '20251221130001_seed_more_intensifiers.sql', // Expanded intensifiers
  '20251221122036_seed_exercise_intensifier_links.sql',
];

async function runMigrations() {
  const client = new Client({
    connectionString: CONNECTION_STRING,
  });

  try {
    console.log('🔌 Connecting to Supabase...');
    await client.connect();
    console.log('✅ Connected successfully\n');

    // Check if base tables exist, run base migration if needed
    console.log('🔍 Checking if base tables exist...');
    const tableCheck = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('exercise_knowledge', 'intensifier_knowledge')
    `);
    
    const existingTables = tableCheck.rows.map(r => r.table_name);
    if (existingTables.length < 2) {
      console.log('⚠️  Base tables not found. Running base migration first...\n');
      const baseMigrationPath = path.join(__dirname, '..', 'supabase', 'migrations', BASE_MIGRATION);
      
      if (!fs.existsSync(baseMigrationPath)) {
        console.error(`❌ Base migration file not found: ${baseMigrationPath}`);
        console.error('   Please ensure the base migration exists before running seed migrations.\n');
        process.exit(1);
      }
      
      console.log(`📄 Running base migration: ${BASE_MIGRATION}`);
      const baseSql = fs.readFileSync(baseMigrationPath, 'utf8');
      
      try {
        await client.query(baseSql);
        console.log(`✅ Base migration completed: ${BASE_MIGRATION}\n`);
      } catch (error) {
        console.error(`❌ Error running base migration:`);
        console.error(error.message);
        throw error;
      }
    } else {
      console.log('✅ Base tables exist\n');
    }

    for (const migrationFile of MIGRATIONS) {
      const migrationPath = path.join(__dirname, '..', 'supabase', 'migrations', migrationFile);
      
      if (!fs.existsSync(migrationPath)) {
        console.error(`❌ Migration file not found: ${migrationPath}`);
        continue;
      }

      console.log(`📄 Running migration: ${migrationFile}`);
      const sql = fs.readFileSync(migrationPath, 'utf8');
      
      try {
        const result = await client.query(sql);
        console.log(`✅ Migration completed: ${migrationFile}\n`);
      } catch (error) {
        console.error(`❌ Error running ${migrationFile}:`);
        console.error(error.message);
        // Continue with next migration (some errors might be expected, e.g., if already run)
        if (error.message.includes('already exists') || error.message.includes('duplicate')) {
          console.log(`ℹ️  Migration may have already been run (idempotent)\n`);
        } else {
          throw error; // Re-throw if it's a real error
        }
      }
    }

    console.log('✅ All migrations completed!\n');
    
    // Run verification
    console.log('🔍 Running verification queries...\n');
    const verifyPath = path.join(__dirname, '..', 'supabase', 'migrations', '20251221130002_verify_expanded_seed.sql');
    if (fs.existsSync(verifyPath)) {
      const verifySql = fs.readFileSync(verifyPath, 'utf8');
      const verifyResult = await client.query(verifySql);
      console.log('✅ Verification completed\n');
    }

    // Check exercises_library schema first
    console.log('🔍 Checking exercises_library schema...');
    try {
      const schemaCheck = await client.query(`
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'exercises_library'
        ORDER BY ordinal_position
      `);
      if (schemaCheck.rows.length > 0) {
        console.log('   Columns found:', schemaCheck.rows.map(r => r.column_name).join(', '));
      } else {
        console.log('   ⚠️  exercises_library table not found or empty');
      }
      console.log('');
    } catch (err) {
      console.log('   ⚠️  Could not check schema:', err.message);
      console.log('');
    }

    // Quick counts
    console.log('📊 Quick Counts:');
    const exerciseCount = await client.query(
      "SELECT COUNT(*) as count FROM exercise_knowledge WHERE source = 'imported_from_exercises_library'"
    );
    console.log(`   Exercises imported: ${exerciseCount.rows[0].count}`);

    const intensifierCount = await client.query(
      "SELECT COUNT(*) as count FROM intensifier_knowledge WHERE status = 'approved' AND language = 'en'"
    );
    console.log(`   Intensifiers: ${intensifierCount.rows[0].count}`);

    const linkCount = await client.query(
      "SELECT COUNT(*) as count FROM exercise_intensifier_links"
    );
    console.log(`   Exercise-Intensifier Links: ${linkCount.rows[0].count}\n`);

  } catch (error) {
    console.error('❌ Fatal error:');
    console.error(error);
    process.exit(1);
  } finally {
    await client.end();
    console.log('🔌 Disconnected from database');
  }
}

runMigrations();
