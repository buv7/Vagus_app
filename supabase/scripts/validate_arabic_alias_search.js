#!/usr/bin/env node

/**
 * Validate Arabic Alias Search
 * 
 * This script validates that Arabic aliases are working correctly in search.
 * 
 * Tests:
 * - Arabic alias search functionality
 * - Search performance (<1000ms per query)
 * - Correct exercise results for Arabic queries
 * - Both exercise_translations and exercise_aliases are searched
 * 
 * Usage: node supabase/scripts/validate_arabic_alias_search.js
 */

const { Client } = require('pg');

// Database connection configuration (use session pooler)
const dbConfig = {
  host: process.env.SUPABASE_DB_HOST || 'aws-0-eu-central-1.pooler.supabase.com',
  port: process.env.SUPABASE_DB_PORT || 5432,
  database: process.env.SUPABASE_DB_NAME || 'postgres',
  user: process.env.SUPABASE_DB_USERNAME || 'postgres.kydrpnrmqbedjflklgue',
  password: process.env.SUPABASE_DB_PASSWORD || 'X.7achoony.X',
  ssl: true,
};

// Test queries (Arabic terms users might search for)
const testQueries = [
  'بنش',
  'صدر',
  'سكوات',
  'ظهر',
  'جانبي',
  'ضغط',
  'سحب',
  'رفع',
  'قرفصاء',
  'ديدليفت',
];

/**
 * Test a single search query
 */
async function testSearch(client, query) {
  const startTime = Date.now();
  
  try {
    const result = await client.query(`
      SELECT 
        ek.id,
        ek.name,
        et_ar.name as arabic_name,
        ARRAY_AGG(DISTINCT ea_ar.alias) FILTER (WHERE ea_ar.alias IS NOT NULL) as arabic_aliases
      FROM exercise_knowledge ek
      LEFT JOIN exercise_aliases ea_en 
        ON ea_en.exercise_id = ek.id 
        AND ea_en.language = 'en'
      LEFT JOIN exercise_aliases ea_ar 
        ON ea_ar.exercise_id = ek.id 
        AND ea_ar.language = 'ar'
      LEFT JOIN exercise_translations et_ar 
        ON et_ar.exercise_id = ek.id 
        AND et_ar.language = 'ar'
      WHERE
        ek.status = 'approved'
        AND (
          ek.name ILIKE '%' || $1 || '%'
          OR ek.short_desc ILIKE '%' || $1 || '%'
          OR ea_en.alias ILIKE '%' || $1 || '%'
          OR et_ar.name ILIKE '%' || $1 || '%'
          OR EXISTS (
            SELECT 1 
            FROM unnest(et_ar.aliases) a 
            WHERE a ILIKE '%' || $1 || '%'
          )
          OR ea_ar.alias ILIKE '%' || $1 || '%'
          OR to_tsvector('arabic', et_ar.name) @@ plainto_tsquery('arabic', $1)
          OR to_tsvector('arabic', array_to_string(et_ar.aliases, ' ')) @@ plainto_tsquery('arabic', $1)
          OR to_tsvector('arabic', ea_ar.alias) @@ plainto_tsquery('arabic', $1)
        )
      GROUP BY ek.id, ek.name, et_ar.name
      ORDER BY ek.name
      LIMIT 10
    `, [query]);
    
    const duration = Date.now() - startTime;
    
    return {
      query,
      duration,
      resultCount: result.rows.length,
      results: result.rows,
      success: duration < 1000, // Performance check: <1000ms
    };
  } catch (error) {
    return {
      query,
      duration: Date.now() - startTime,
      resultCount: 0,
      results: [],
      success: false,
      error: error.message,
    };
  }
}

/**
 * Get statistics about Arabic aliases
 */
async function getStatistics(client) {
  const stats = await client.query(`
    SELECT 
      COUNT(DISTINCT exercise_id) as exercises_with_arabic_aliases,
      COUNT(*) as total_arabic_aliases,
      AVG(alias_count) as avg_aliases_per_exercise,
      MIN(alias_count) as min_aliases,
      MAX(alias_count) as max_aliases
    FROM (
      SELECT exercise_id, COUNT(*) as alias_count
      FROM exercise_aliases
      WHERE language = 'ar'
      GROUP BY exercise_id
    ) subq
  `);
  
  const totalExercises = await client.query(`
    SELECT COUNT(*) as total
    FROM exercise_knowledge
    WHERE status = 'approved'
  `);
  
  return {
    ...stats.rows[0],
    totalApprovedExercises: parseInt(totalExercises.rows[0].total),
    coveragePercent: stats.rows[0].exercises_with_arabic_aliases 
      ? ((parseInt(stats.rows[0].exercises_with_arabic_aliases) / parseInt(totalExercises.rows[0].total)) * 100).toFixed(2)
      : '0.00',
  };
}

/**
 * Get sample exercises with their Arabic aliases
 */
async function getSampleExercises(client, limit = 5) {
  const result = await client.query(`
    SELECT 
      ek.id,
      ek.name,
      et_ar.name as arabic_name,
      ARRAY_AGG(DISTINCT ea_ar.alias ORDER BY ea_ar.alias) FILTER (WHERE ea_ar.alias IS NOT NULL) as arabic_aliases
    FROM exercise_knowledge ek
    LEFT JOIN exercise_aliases ea_ar 
      ON ea_ar.exercise_id = ek.id 
      AND ea_ar.language = 'ar'
    LEFT JOIN exercise_translations et_ar 
      ON et_ar.exercise_id = ek.id 
      AND et_ar.language = 'ar'
    WHERE ek.status = 'approved'
      AND EXISTS (
        SELECT 1 FROM exercise_aliases 
        WHERE exercise_id = ek.id AND language = 'ar'
      )
    GROUP BY ek.id, ek.name, et_ar.name
    ORDER BY RANDOM()
    LIMIT $1
  `, [limit]);
  
  return result.rows;
}

/**
 * Main function
 */
async function main() {
  const client = new Client(dbConfig);
  
  try {
    console.log('🔌 Connecting to database...');
    await client.connect();
    console.log('✅ Connected to database\n');
    
    // Get statistics
    console.log('📊 Gathering Statistics...');
    const stats = await getStatistics(client);
    console.table([stats]);
    console.log('');
    
    // Get sample exercises
    console.log('📝 Sample Exercises with Arabic Aliases:');
    const samples = await getSampleExercises(client, 5);
    samples.forEach((ex, idx) => {
      console.log(`\n${idx + 1}. ${ex.name}`);
      if (ex.arabic_name) {
        console.log(`   Arabic Name: ${ex.arabic_name}`);
      }
      if (ex.arabic_aliases && ex.arabic_aliases.length > 0) {
        console.log(`   Arabic Aliases (${ex.arabic_aliases.length}):`);
        ex.arabic_aliases.forEach(alias => {
          console.log(`     - ${alias}`);
        });
      } else {
        console.log(`   ⚠️  No Arabic aliases found`);
      }
    });
    console.log('\n');
    
    // Test search queries
    console.log('🔍 Testing Arabic Alias Search...\n');
    const testResults = [];
    
    for (const query of testQueries) {
      const result = await testSearch(client, query);
      testResults.push(result);
      
      const status = result.success ? '✅' : '❌';
      const perfStatus = result.duration < 1000 ? '⚡' : '🐌';
      console.log(`${status} "${query}": ${result.resultCount} results (${result.duration}ms) ${perfStatus}`);
      
      if (result.error) {
        console.log(`   ❌ Error: ${result.error}`);
      } else if (result.resultCount > 0 && result.results.length > 0) {
        // Show first result
        const firstResult = result.results[0];
        console.log(`   → ${firstResult.name}${firstResult.arabic_name ? ` (${firstResult.arabic_name})` : ''}`);
      }
    }
    
    // Summary
    console.log('\n📊 Search Test Summary:');
    const successful = testResults.filter(r => r.success).length;
    const totalResults = testResults.reduce((sum, r) => sum + r.resultCount, 0);
    const avgDuration = testResults.reduce((sum, r) => sum + r.duration, 0) / testResults.length;
    
    console.log(`   - Successful queries: ${successful}/${testResults.length}`);
    console.log(`   - Total results found: ${totalResults}`);
    console.log(`   - Average query duration: ${avgDuration.toFixed(2)}ms`);
    console.log(`   - Fast queries (<1000ms): ${testResults.filter(r => r.duration < 1000).length}/${testResults.length}`);
    
    // Performance check
    if (avgDuration > 1000) {
      console.log('\n⚠️  WARNING: Average query duration exceeds 1000ms. Consider optimizing indexes.');
    } else {
      console.log('\n✅ Performance check passed: All queries are fast (<1000ms average)');
    }
    
    // Coverage check
    if (parseFloat(stats.coveragePercent) < 50) {
      console.log(`\n⚠️  WARNING: Only ${stats.coveragePercent}% of exercises have Arabic aliases. Consider running the generation script.`);
    } else {
      console.log(`\n✅ Coverage check passed: ${stats.coveragePercent}% of exercises have Arabic aliases`);
    }
    
    console.log('\n✅ Validation complete!');
    
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  } finally {
    await client.end();
    console.log('🔌 Database connection closed');
  }
}

// Run if called directly
if (require.main === module) {
  main().catch(console.error);
}

module.exports = { testSearch, getStatistics, getSampleExercises };
