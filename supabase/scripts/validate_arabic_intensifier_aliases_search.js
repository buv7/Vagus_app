#!/usr/bin/env node

/**
 * Validate Arabic Intensifier Aliases Search
 * 
 * This script validates that Arabic intensifier alias search works correctly
 * by testing various Arabic search terms and verifying they return the correct intensifiers.
 * 
 * Usage: node supabase/scripts/validate_arabic_intensifier_aliases_search.js
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

// Test queries (Arabic terms that should match specific intensifiers)
const testQueries = [
  { query: 'دروب', expectedIntensifier: 'Drop Set' },
  { query: 'راحة', expectedIntensifier: 'Rest-Pause' },
  { query: 'تمبو', expectedIntensifier: 'Tempo' },
  { query: 'مايو', expectedIntensifier: 'Myo-Reps' },
  { query: 'كلستر', expectedIntensifier: 'Cluster Sets' },
  { query: 'RP', expectedIntensifier: 'Rest-Pause' },
  { query: 'سيت تنازلي', expectedIntensifier: 'Drop Set' },
  { query: 'تكرار مع تثبيت', expectedIntensifier: 'Paused Reps' },
  { query: 'نصف تكرار', expectedIntensifier: 'Partials' },
  { query: 'ثابت', expectedIntensifier: 'Isometric' },
];

/**
 * Test search using RPC function
 */
async function testSearch(client, query, expectedIntensifier) {
  try {
    const result = await client.query(`
      SELECT * FROM search_intensifiers_with_aliases(
        p_query => $1,
        p_status => 'approved',
        p_limit => 10
      )
    `, [query]);
    
    return {
      query,
      expectedIntensifier,
      results: result.rows,
      found: result.rows.some(row => 
        row.name.toLowerCase().includes(expectedIntensifier.toLowerCase()) ||
        row.name === expectedIntensifier
      ),
      matchCount: result.rows.length
    };
  } catch (error) {
    return {
      query,
      expectedIntensifier,
      error: error.message,
      found: false
    };
  }
}

/**
 * Get alias statistics
 */
async function getAliasStats(client) {
  const stats = await client.query(`
    SELECT 
      COUNT(*) as total_aliases,
      COUNT(DISTINCT intensifier_id) as intensifiers_with_aliases,
      MIN(alias_count) as min_aliases,
      MAX(alias_count) as max_aliases,
      ROUND(AVG(alias_count)::numeric, 2) as avg_aliases
    FROM (
      SELECT 
        intensifier_id,
        COUNT(*) as alias_count
      FROM intensifier_aliases
      WHERE language = 'ar'
      GROUP BY intensifier_id
    ) alias_counts
  `);
  
  return stats.rows[0];
}

/**
 * Get sample intensifiers with full alias lists
 */
async function getSampleIntensifiers(client, limit = 5) {
  const result = await client.query(`
    SELECT 
      ik.id,
      ik.name,
      ik.fatigue_cost,
      array_agg(DISTINCT ia.alias ORDER BY ia.alias) as aliases,
      COUNT(ia.id) as alias_count
    FROM intensifier_knowledge ik
    JOIN intensifier_aliases ia ON ia.intensifier_id = ik.id
    WHERE ia.language = 'ar'
      AND ik.status = 'approved'
      AND ik.language = 'en'
    GROUP BY ik.id, ik.name, ik.fatigue_cost
    ORDER BY alias_count DESC, ik.name
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
    
    // 1. Get alias statistics
    console.log('📊 Alias Statistics:');
    const stats = await getAliasStats(client);
    console.table([stats]);
    console.log('');
    
    // 2. Get sample intensifiers with full alias lists
    console.log('📝 Sample Intensifiers with Full Alias Lists:');
    const samples = await getSampleIntensifiers(client, 5);
    samples.forEach((sample, index) => {
      console.log(`\n${index + 1}. ${sample.name} (Fatigue: ${sample.fatigue_cost || 'N/A'})`);
      console.log(`   Aliases (${sample.alias_count}): ${sample.aliases.join(', ')}`);
    });
    console.log('');
    
    // 3. Test search queries
    console.log('🔍 Testing Arabic Search Queries:\n');
    const testResults = [];
    
    for (const test of testQueries) {
      const result = await testSearch(client, test.query, test.expectedIntensifier);
      testResults.push(result);
      
      if (result.error) {
        console.log(`❌ Query: "${test.query}"`);
        console.log(`   Expected: ${test.expectedIntensifier}`);
        console.log(`   Error: ${result.error}\n`);
      } else if (result.found) {
        console.log(`✅ Query: "${test.query}"`);
        console.log(`   Expected: ${test.expectedIntensifier}`);
        console.log(`   Found: ${result.matchCount} result(s)`);
        if (result.results.length > 0) {
          console.log(`   Top match: ${result.results[0].name}`);
        }
        console.log('');
      } else {
        console.log(`⚠️  Query: "${test.query}"`);
        console.log(`   Expected: ${test.expectedIntensifier}`);
        console.log(`   Found: ${result.matchCount} result(s), but expected intensifier not in top results`);
        if (result.results.length > 0) {
          console.log(`   Top result: ${result.results[0].name}`);
        }
        console.log('');
      }
    }
    
    // 4. Summary
    const passed = testResults.filter(r => r.found && !r.error).length;
    const failed = testResults.filter(r => !r.found && !r.error).length;
    const errors = testResults.filter(r => r.error).length;
    
    console.log('📊 Test Summary:');
    console.log(`   ✅ Passed: ${passed}`);
    console.log(`   ⚠️  Failed: ${failed}`);
    console.log(`   ❌ Errors: ${errors}`);
    console.log(`   Total: ${testResults.length}`);
    
    if (passed === testResults.length) {
      console.log('\n🎉 All tests passed! Arabic intensifier alias search is working correctly.');
    } else {
      console.log('\n⚠️  Some tests failed. Please review the results above.');
    }
    
    // 5. Performance check
    console.log('\n⚡ Performance Check:');
    const perfStart = Date.now();
    await client.query(`
      SELECT * FROM search_intensifiers_with_aliases(
        p_query => 'دروب',
        p_status => 'approved',
        p_limit => 10
      )
    `);
    const perfTime = Date.now() - perfStart;
    console.log(`   Search query time: ${perfTime}ms`);
    if (perfTime < 100) {
      console.log('   ✅ Performance is excellent (< 100ms)');
    } else if (perfTime < 500) {
      console.log('   ⚠️  Performance is acceptable (< 500ms)');
    } else {
      console.log('   ❌ Performance is slow (> 500ms). Consider optimizing indexes.');
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

module.exports = { testSearch, getAliasStats, getSampleIntensifiers };
