#!/usr/bin/env node

/**
 * Validate Arabic Exercise Descriptions
 * 
 * This script validates the Arabic exercise descriptions:
 * - Tests Arabic search queries
 * - Verifies data quality (non-empty fields, proper formatting)
 * - Tests fallback to English when Arabic is missing
 * - Reports statistics and sample results
 * 
 * Usage: node supabase/scripts/validate_arabic_exercise_descriptions.js
 */

const { Client } = require('pg');

// Database connection configuration
const dbConfig = {
  host: process.env.SUPABASE_DB_HOST || 'aws-0-eu-central-1.pooler.supabase.com',
  port: process.env.SUPABASE_DB_PORT || 5432,
  database: process.env.SUPABASE_DB_NAME || 'postgres',
  user: process.env.SUPABASE_DB_USERNAME || 'postgres.kydrpnrmqbedjflklgue',
  password: process.env.SUPABASE_DB_PASSWORD || 'X.7achoony.X',
  ssl: true,
};

// Test Arabic search queries
const testQueries = [
  'صدر',      // chest
  'ضغط',      // press
  'سكوات',    // squat
  'ظهر',      // back
  'بايسبس',   // biceps (transliterated)
  'ضغط صدر',  // chest press
  'سحب',      // pull
  'رفعة',     // deadlift
];

/**
 * Main function
 */
async function main() {
  const client = new Client(dbConfig);
  
  try {
    console.log('🔌 Connecting to database...');
    await client.connect();
    console.log('✅ Connected to database\n');
    
    // =====================================================
    // 1. STATISTICS
    // =====================================================
    console.log('📊 STATISTICS');
    console.log('='.repeat(60));
    
    const statsResult = await client.query(`
      SELECT 
        COUNT(*) as total_exercises,
        COUNT(DISTINCT ek.id) FILTER (WHERE ek.status = 'approved' AND ek.language = 'en') as approved_english,
        COUNT(DISTINCT et.exercise_id) FILTER (WHERE et.language = 'ar') as with_arabic_translation,
        COUNT(DISTINCT et.exercise_id) FILTER (WHERE et.language = 'ar' AND et.short_desc IS NOT NULL) as with_arabic_desc,
        COUNT(DISTINCT et.exercise_id) FILTER (WHERE et.language = 'ar' AND et.how_to IS NOT NULL) as with_arabic_how_to,
        COUNT(DISTINCT et.exercise_id) FILTER (WHERE et.language = 'ar' AND array_length(et.cues, 1) > 0) as with_arabic_cues,
        COUNT(DISTINCT et.exercise_id) FILTER (WHERE et.language = 'ar' AND array_length(et.common_mistakes, 1) > 0) as with_arabic_mistakes,
        ROUND(
          100.0 * COUNT(DISTINCT et.exercise_id) FILTER (WHERE et.language = 'ar' AND et.short_desc IS NOT NULL) 
          / NULLIF(COUNT(DISTINCT ek.id) FILTER (WHERE ek.status = 'approved' AND ek.language = 'en'), 0),
          2
        ) as coverage_percent
      FROM exercise_knowledge ek
      LEFT JOIN exercise_translations et ON et.exercise_id = ek.id
      WHERE ek.status = 'approved' AND ek.language = 'en'
    `);
    
    const stats = statsResult.rows[0];
    console.table(stats);
    console.log();
    
    // =====================================================
    // 2. DATA QUALITY CHECKS
    // =====================================================
    console.log('🔍 DATA QUALITY CHECKS');
    console.log('='.repeat(60));
    
    // Check for empty or missing fields
    const qualityResult = await client.query(`
      SELECT 
        COUNT(*) FILTER (WHERE name IS NULL OR name = '') as missing_name,
        COUNT(*) FILTER (WHERE short_desc IS NULL OR short_desc = '') as missing_short_desc,
        COUNT(*) FILTER (WHERE how_to IS NULL OR how_to = '') as missing_how_to,
        COUNT(*) FILTER (WHERE array_length(cues, 1) IS NULL OR array_length(cues, 1) = 0) as missing_cues,
        COUNT(*) FILTER (WHERE array_length(common_mistakes, 1) IS NULL OR array_length(common_mistakes, 1) = 0) as missing_mistakes,
        AVG(LENGTH(short_desc)) as avg_short_desc_length,
        AVG(LENGTH(how_to)) as avg_how_to_length,
        AVG(array_length(cues, 1)) as avg_cues_count,
        AVG(array_length(common_mistakes, 1)) as avg_mistakes_count
      FROM exercise_translations
      WHERE language = 'ar'
    `);
    
    const quality = qualityResult.rows[0];
    console.table(quality);
    console.log();
    
    // =====================================================
    // 3. ARABIC SEARCH TESTS
    // =====================================================
    console.log('🔎 ARABIC SEARCH TESTS');
    console.log('='.repeat(60));
    
    for (const query of testQueries) {
      console.log(`\n📝 Testing query: "${query}"`);
      
      try {
        // Test RPC function
        const searchResult = await client.query(`
          SELECT 
            ek.name as english_name,
            et.name as arabic_name,
            et.short_desc,
            et.how_to,
            et.cues,
            et.common_mistakes
          FROM exercise_knowledge ek
          LEFT JOIN exercise_translations et ON et.exercise_id = ek.id AND et.language = 'ar'
          WHERE ek.status = 'approved'
            AND ek.language = 'en'
            AND (
              et.name ILIKE '%' || $1 || '%'
              OR et.short_desc ILIKE '%' || $1 || '%'
              OR et.how_to ILIKE '%' || $1 || '%'
              OR EXISTS (
                SELECT 1 FROM unnest(et.aliases) a WHERE a ILIKE '%' || $1 || '%'
              )
              OR EXISTS (
                SELECT 1 FROM unnest(et.cues) c WHERE c ILIKE '%' || $1 || '%'
              )
            )
          LIMIT 5
        `, [query]);
        
        if (searchResult.rows.length > 0) {
          console.log(`   ✅ Found ${searchResult.rows.length} results:`);
          searchResult.rows.forEach((row, idx) => {
            console.log(`   ${idx + 1}. ${row.english_name} → ${row.arabic_name || 'N/A'}`);
            if (row.short_desc) {
              console.log(`      Desc: ${row.short_desc.substring(0, 60)}...`);
            }
          });
        } else {
          console.log(`   ⚠️  No results found`);
        }
      } catch (error) {
        console.log(`   ❌ Error: ${error.message}`);
      }
    }
    
    // =====================================================
    // 4. SAMPLE ARABIC EXERCISES
    // =====================================================
    console.log('\n\n📋 SAMPLE ARABIC EXERCISES');
    console.log('='.repeat(60));
    
    const samplesResult = await client.query(`
      SELECT 
        ek.name as english_name,
        et.name as arabic_name,
        et.short_desc,
        et.how_to,
        et.cues,
        et.common_mistakes
      FROM exercise_translations et
      JOIN exercise_knowledge ek ON ek.id = et.exercise_id
      WHERE et.language = 'ar'
        AND et.short_desc IS NOT NULL
        AND et.how_to IS NOT NULL
        AND array_length(et.cues, 1) > 0
        AND array_length(et.common_mistakes, 1) > 0
      ORDER BY RANDOM()
      LIMIT 3
    `);
    
    samplesResult.rows.forEach((row, idx) => {
      console.log(`\n   Example ${idx + 1}: ${row.english_name}`);
      console.log(`   ──────────────────────────────────────────────────────────`);
      console.log(`   Arabic Name: ${row.arabic_name}`);
      console.log(`   Short Desc: ${row.short_desc}`);
      console.log(`   How-To: ${row.how_to.substring(0, 150)}...`);
      console.log(`   Cues: ${row.cues.join(', ')}`);
      console.log(`   Mistakes: ${row.common_mistakes.join(', ')}`);
    });
    
    // =====================================================
    // 5. COVERAGE REPORT
    // =====================================================
    console.log('\n\n📈 COVERAGE REPORT');
    console.log('='.repeat(60));
    
    const coverageResult = await client.query(`
      SELECT 
        ek.name as exercise_name,
        CASE 
          WHEN et.id IS NULL THEN 'No translation'
          WHEN et.short_desc IS NULL THEN 'Name only'
          WHEN et.how_to IS NULL THEN 'Partial (no how_to)'
          WHEN array_length(et.cues, 1) IS NULL OR array_length(et.cues, 1) = 0 THEN 'Partial (no cues)'
          WHEN array_length(et.common_mistakes, 1) IS NULL OR array_length(et.common_mistakes, 1) = 0 THEN 'Partial (no mistakes)'
          ELSE 'Complete'
        END as translation_status
      FROM exercise_knowledge ek
      LEFT JOIN exercise_translations et ON et.exercise_id = ek.id AND et.language = 'ar'
      WHERE ek.status = 'approved' AND ek.language = 'en'
      ORDER BY 
        CASE translation_status
          WHEN 'No translation' THEN 1
          WHEN 'Name only' THEN 2
          WHEN 'Partial (no how_to)' THEN 3
          WHEN 'Partial (no cues)' THEN 4
          WHEN 'Partial (no mistakes)' THEN 5
          ELSE 6
        END,
        ek.name
      LIMIT 20
    `);
    
    const statusCounts = {};
    coverageResult.rows.forEach(row => {
      const status = row.translation_status;
      statusCounts[status] = (statusCounts[status] || 0) + 1;
    });
    
    console.log('\n   Translation Status Distribution (first 20):');
    Object.entries(statusCounts).forEach(([status, count]) => {
      console.log(`   - ${status}: ${count}`);
    });
    
    // =====================================================
    // 6. SUMMARY
    // =====================================================
    console.log('\n\n✅ VALIDATION COMPLETE');
    console.log('='.repeat(60));
    console.log(`   Total English Exercises: ${stats.approved_english}`);
    console.log(`   With Arabic Translation: ${stats.with_arabic_translation}`);
    console.log(`   With Full Descriptions: ${stats.with_arabic_desc}`);
    console.log(`   Coverage: ${stats.coverage_percent}%`);
    console.log();
    
    if (parseFloat(stats.coverage_percent) < 50) {
      console.log('   ⚠️  WARNING: Coverage is below 50%. Consider running the generation script.');
    } else if (parseFloat(stats.coverage_percent) < 80) {
      console.log('   ⚠️  Coverage is good but could be improved.');
    } else {
      console.log('   ✅ Excellent coverage!');
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  } finally {
    await client.end();
    console.log('\n🔌 Database connection closed');
  }
}

// Run if called directly
if (require.main === module) {
  main().catch(console.error);
}

module.exports = { testQueries };
