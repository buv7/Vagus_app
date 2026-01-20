#!/usr/bin/env node

/**
 * Validate Arabic Muscle Alias Search
 * 
 * This script validates that Arabic muscle aliases are working correctly
 * in the search function.
 * 
 * Tests:
 * - Arabic muscle alias search queries
 * - Muscle filter with Arabic aliases
 * - Full-text search on Arabic muscle aliases
 * 
 * Usage: node supabase/scripts/validate_arabic_muscle_alias_search.js
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

// Test queries (Arabic muscle aliases)
const testQueries = [
  'صدر',      // Chest
  'ظهر',      // Back
  'باي',      // Biceps
  'تراي',     // Triceps
  'كتف',      // Shoulder
  'فخذ',      // Thigh
  'بطن',      // Abs
  'كواد',     // Quads
  'لات',      // Lats
  'الترابيس', // Traps
];

/**
 * Test search function with Arabic muscle alias queries
 */
async function testSearch() {
  const client = new Client(dbConfig);
  
  try {
    console.log('🔌 Connecting to database...');
    await client.connect();
    console.log('✅ Connected to database\n');
    
    console.log('🧪 Testing Arabic muscle alias search...\n');
    
    let totalTests = 0;
    let passedTests = 0;
    let failedTests = 0;
    
    for (const query of testQueries) {
      totalTests++;
      console.log(`Test ${totalTests}: Searching for "${query}"...`);
      
      try {
        const result = await client.query(`
          SELECT 
            id,
            name,
            primary_muscles,
            secondary_muscles
          FROM search_exercises_with_aliases(
            p_query => $1,
            p_limit => 5
          )
        `, [query]);
        
        if (result.rows.length > 0) {
          console.log(`  ✅ Found ${result.rows.length} exercises`);
          console.log(`  Sample: ${result.rows[0].name}`);
          passedTests++;
        } else {
          console.log(`  ⚠️  No exercises found`);
          failedTests++;
        }
      } catch (error) {
        console.log(`  ❌ Error: ${error.message}`);
        failedTests++;
      }
      
      console.log('');
    }
    
    // Test muscle filter with Arabic aliases
    console.log('🧪 Testing muscle filter with Arabic aliases...\n');
    
    const muscleFilterTests = [
      { alias: 'صدر', expectedMuscle: 'pectoralis_major' },
      { alias: 'باي', expectedMuscle: 'biceps_brachii' },
      { alias: 'كواد', expectedMuscle: 'quadriceps' },
    ];
    
    for (const test of muscleFilterTests) {
      totalTests++;
      console.log(`Test ${totalTests}: Filter by muscle alias "${test.alias}"...`);
      
      try {
        const result = await client.query(`
          SELECT 
            id,
            name,
            primary_muscles,
            secondary_muscles
          FROM search_exercises_with_aliases(
            p_muscles => ARRAY[$1],
            p_limit => 5
          )
        `, [test.alias]);
        
        if (result.rows.length > 0) {
          const hasExpectedMuscle = result.rows.some(row => 
            (row.primary_muscles && row.primary_muscles.includes(test.expectedMuscle)) ||
            (row.secondary_muscles && row.secondary_muscles.includes(test.expectedMuscle))
          );
          
          if (hasExpectedMuscle) {
            console.log(`  ✅ Found ${result.rows.length} exercises with ${test.expectedMuscle}`);
            passedTests++;
          } else {
            console.log(`  ⚠️  Found exercises but muscle key mismatch`);
            failedTests++;
          }
        } else {
          console.log(`  ⚠️  No exercises found`);
          failedTests++;
        }
      } catch (error) {
        console.log(`  ❌ Error: ${error.message}`);
        failedTests++;
      }
      
      console.log('');
    }
    
    // Summary
    console.log('📊 Test Summary:');
    console.log(`   Total tests: ${totalTests}`);
    console.log(`   Passed: ${passedTests}`);
    console.log(`   Failed: ${failedTests}`);
    console.log(`   Success rate: ${((passedTests / totalTests) * 100).toFixed(1)}%\n`);
    
    // Check alias coverage
    console.log('📊 Checking alias coverage...\n');
    
    const coverageResult = await client.query(`
      SELECT 
        COUNT(DISTINCT muscle_key) as muscles_with_aliases,
        COUNT(*) as total_aliases,
        ROUND(AVG(alias_count), 2) as avg_aliases_per_muscle
      FROM (
        SELECT muscle_key, COUNT(*) as alias_count
        FROM muscle_aliases
        WHERE language = 'ar'
        GROUP BY muscle_key
      ) subq
    `);
    
    console.table(coverageResult.rows);
    
    // Check which muscles are missing aliases
    const missingResult = await client.query(`
      SELECT DISTINCT unnest(primary_muscles || secondary_muscles) as muscle_key
      FROM exercise_knowledge
      WHERE (primary_muscles IS NOT NULL AND array_length(primary_muscles, 1) > 0)
         OR (secondary_muscles IS NOT NULL AND array_length(secondary_muscles, 1) > 0)
      EXCEPT
      SELECT DISTINCT muscle_key
      FROM muscle_aliases
      WHERE language = 'ar'
      ORDER BY muscle_key
      LIMIT 10
    `);
    
    if (missingResult.rows.length > 0) {
      console.log(`\n⚠️  Muscles without Arabic aliases (showing first 10):`);
      missingResult.rows.forEach(row => {
        console.log(`   - ${row.muscle_key}`);
      });
    } else {
      console.log(`\n✅ All muscles have Arabic aliases!`);
    }
    
    console.log('\n✅ Validation complete!');
    
  } catch (error) {
    console.error('❌ Fatal error:', error);
    process.exit(1);
  } finally {
    await client.end();
    console.log('🔌 Database connection closed');
  }
}

// Run if called directly
if (require.main === module) {
  testSearch();
}

module.exports = { testSearch };
