#!/usr/bin/env node

/**
 * Import Exercise Knowledge from JSON Seed File
 * 
 * Safely imports exercises from exercise_knowledge_seed_en.json into Supabase.
 * Uses batch processing with ON CONFLICT handling for idempotency.
 * 
 * Usage: node supabase/scripts/import_exercise_knowledge.js
 */

const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const CONNECTION_STRING = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';
const SEED_FILE = path.join(__dirname, '..', '..', 'assets', 'seeds', 'exercise_knowledge_seed_en.json');
const BATCH_SIZE = 200;

async function verifySchema(client) {
  console.log('🔍 Verifying table schema...');
  
  const result = await client.query(`
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'exercise_knowledge'
    ORDER BY ordinal_position
  `);
  
  if (result.rows.length === 0) {
    throw new Error('❌ exercise_knowledge table does not exist. Run migration 20251221021539_workout_knowledge_base.sql first.');
  }
  
  const columns = result.rows.map(r => r.column_name);
  const required = ['name', 'short_desc', 'how_to', 'primary_muscles', 'secondary_muscles', 'equipment', 'movement_pattern', 'difficulty', 'status', 'language'];
  
  const missing = required.filter(col => !columns.includes(col));
  if (missing.length > 0) {
    throw new Error(`❌ Missing required columns: ${missing.join(', ')}`);
  }
  
  console.log(`✅ Schema verified (${columns.length} columns found)\n`);
  return true;
}

async function verifyUniqueIndex(client) {
  console.log('🔍 Verifying unique index exists...');
  
  const result = await client.query(`
    SELECT indexname
    FROM pg_indexes
    WHERE schemaname = 'public'
    AND tablename = 'exercise_knowledge'
    AND indexname = 'idx_exercise_knowledge_unique_name_language'
  `);
  
  if (result.rows.length === 0) {
    console.log('⚠️  Unique index not found. Creating it...');
    await client.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS idx_exercise_knowledge_unique_name_language
      ON public.exercise_knowledge (LOWER(name), language)
    `);
    console.log('✅ Unique index created\n');
  } else {
    console.log('✅ Unique index exists\n');
  }
}

async function importBatch(client, batch, batchNum, totalBatches) {
  if (batch.length === 0) return 0;
  
  // Use a temporary table approach for efficient batch inserts with conflict handling
  try {
    // Drop and recreate temp table for each batch to ensure clean state
    await client.query('DROP TABLE IF EXISTS temp_exercise_import');
    
    // Create temporary table
    await client.query(`
      CREATE TEMP TABLE temp_exercise_import (
        name TEXT,
        aliases TEXT[],
        short_desc TEXT,
        how_to TEXT,
        cues TEXT[],
        common_mistakes TEXT[],
        primary_muscles TEXT[],
        secondary_muscles TEXT[],
        equipment TEXT[],
        movement_pattern TEXT,
        difficulty TEXT,
        contraindications TEXT[],
        media JSONB,
        source TEXT,
        language TEXT,
        status TEXT
      )
    `);
    
    // Prepare batch data for insertion into temp table
    const values = [];
    const placeholders = [];
    let paramIndex = 1;
    
    for (const exercise of batch) {
      const exercisePlaceholders = [];
      exercisePlaceholders.push(`$${paramIndex++}`); values.push(exercise.name || null);
      exercisePlaceholders.push(`$${paramIndex++}`); values.push(exercise.aliases || []);
      exercisePlaceholders.push(`$${paramIndex++}`); values.push(exercise.short_desc || null);
      exercisePlaceholders.push(`$${paramIndex++}`); values.push(exercise.how_to || null);
      exercisePlaceholders.push(`$${paramIndex++}`); values.push(exercise.cues || []);
      exercisePlaceholders.push(`$${paramIndex++}`); values.push(exercise.common_mistakes || []);
      exercisePlaceholders.push(`$${paramIndex++}`); values.push(exercise.primary_muscles || []);
      exercisePlaceholders.push(`$${paramIndex++}`); values.push(exercise.secondary_muscles || []);
      exercisePlaceholders.push(`$${paramIndex++}`); values.push(exercise.equipment || []);
      exercisePlaceholders.push(`$${paramIndex++}`); values.push(exercise.movement_pattern || null);
      exercisePlaceholders.push(`$${paramIndex++}`); values.push(exercise.difficulty || null);
      exercisePlaceholders.push(`$${paramIndex++}`); values.push(exercise.contraindications || []);
      exercisePlaceholders.push(`$${paramIndex++}`); values.push(exercise.media || {});
      exercisePlaceholders.push(`$${paramIndex++}`); values.push(exercise.source || 'seed_pack_v1');
      exercisePlaceholders.push(`$${paramIndex++}`); values.push(exercise.language || 'en');
      exercisePlaceholders.push(`$${paramIndex++}`); values.push(exercise.status || 'approved');
      
      placeholders.push(`(${exercisePlaceholders.join(', ')})`);
    }
    
    // Insert into temp table
    await client.query(`
      INSERT INTO temp_exercise_import VALUES ${placeholders.join(', ')}
    `, values);
    
    // Insert from temp table, excluding duplicates using NOT EXISTS
    // First deduplicate within the batch using a subquery with row_number
    const insertResult = await client.query(`
      INSERT INTO public.exercise_knowledge (
        name, aliases, short_desc, how_to, cues, common_mistakes,
        primary_muscles, secondary_muscles, equipment, movement_pattern,
        difficulty, contraindications, media, source, language, status
      )
      SELECT 
        t.name, t.aliases, t.short_desc, t.how_to, t.cues, t.common_mistakes,
        t.primary_muscles, t.secondary_muscles, t.equipment, t.movement_pattern,
        t.difficulty, t.contraindications, t.media, t.source, t.language, t.status
      FROM (
        SELECT DISTINCT ON (LOWER(name), language) *
        FROM temp_exercise_import
        ORDER BY LOWER(name), language
      ) t
      WHERE NOT EXISTS (
        SELECT 1 FROM public.exercise_knowledge ek
        WHERE LOWER(ek.name) = LOWER(t.name) AND ek.language = t.language
      )
    `);
    
    const inserted = insertResult.rowCount || 0;
    const skipped = batch.length - inserted;
    
    console.log(`  Batch ${batchNum}/${totalBatches}: ${inserted}/${batch.length} inserted (${skipped} skipped as duplicates)`);
    
    return inserted;
  } catch (error) {
    console.error(`  ❌ Error in batch ${batchNum}: ${error.message}`);
    throw error;
  }
}

async function importExercises() {
  const client = new Client({
    connectionString: CONNECTION_STRING,
  });

  try {
    console.log('🔌 Connecting to Supabase...');
    await client.connect();
    console.log('✅ Connected successfully\n');

    // Verify schema
    await verifySchema(client);

    // Verify/ensure unique index exists
    await verifyUniqueIndex(client);

    // Load JSON file
    console.log(`📄 Loading seed file: ${SEED_FILE}`);
    if (!fs.existsSync(SEED_FILE)) {
      throw new Error(`Seed file not found: ${SEED_FILE}`);
    }

    const fileContent = fs.readFileSync(SEED_FILE, 'utf8');
    const exercises = JSON.parse(fileContent);
    
    if (!Array.isArray(exercises)) {
      throw new Error('Seed file must contain an array of exercises');
    }
    
    console.log(`✅ Loaded ${exercises.length} exercises from seed file\n`);

    // Temporarily disable RLS for import (we're importing approved content)
    console.log('🔓 Temporarily disabling RLS for import...');
    await client.query('ALTER TABLE public.exercise_knowledge DISABLE ROW LEVEL SECURITY');
    console.log('✅ RLS disabled\n');

    // Process in batches
    console.log(`📦 Processing ${exercises.length} exercises in batches of ${BATCH_SIZE}...\n`);
    
    let totalInserted = 0;
    let totalSkipped = 0;
    const totalBatches = Math.ceil(exercises.length / BATCH_SIZE);

    for (let i = 0; i < exercises.length; i += BATCH_SIZE) {
      const batch = exercises.slice(i, i + BATCH_SIZE);
      const batchNum = Math.floor(i / BATCH_SIZE) + 1;
      
      const inserted = await importBatch(client, batch, batchNum, totalBatches);
      totalInserted += inserted;
      totalSkipped += (batch.length - inserted);
    }

    // Re-enable RLS
    console.log('\n🔒 Re-enabling RLS...');
    await client.query('ALTER TABLE public.exercise_knowledge ENABLE ROW LEVEL SECURITY');
    console.log('✅ RLS re-enabled\n');

    // Verify import
    console.log('🔍 Verifying import...\n');
    
    const countResult = await client.query('SELECT COUNT(*) as count FROM public.exercise_knowledge');
    const totalCount = parseInt(countResult.rows[0].count);
    
    const statusResult = await client.query(`
      SELECT status, COUNT(*) as count
      FROM public.exercise_knowledge
      GROUP BY status
      ORDER BY status
    `);
    
    console.log('📊 Import Summary:');
    console.log(`   Total exercises in database: ${totalCount}`);
    console.log(`   Inserted this run: ${totalInserted}`);
    console.log(`   Skipped (duplicates): ${totalSkipped}`);
    console.log('\n   Status breakdown:');
    statusResult.rows.forEach(row => {
      console.log(`     ${row.status}: ${row.count}`);
    });
    
    const approvedCount = statusResult.rows.find(r => r.status === 'approved')?.count || 0;
    console.log(`\n✅ Import complete! ${approvedCount} approved exercises available.`);

  } catch (error) {
    console.error('\n❌ Fatal error:');
    console.error(error.message);
    console.error(error.stack);
    
    // Try to re-enable RLS even on error
    try {
      await client.query('ALTER TABLE public.exercise_knowledge ENABLE ROW LEVEL SECURITY');
      console.log('\n✅ RLS re-enabled after error');
    } catch (rlserror) {
      console.error('\n⚠️  Warning: Could not re-enable RLS. Please check manually.');
    }
    
    process.exit(1);
  } finally {
    await client.end();
    console.log('\n🔌 Disconnected from database');
  }
}

// Run import
importExercises();
