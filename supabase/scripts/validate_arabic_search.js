#!/usr/bin/env node

/**
 * Validate Arabic Exercise Search
 * 
 * This script tests Arabic search functionality to ensure:
 * - Arabic translations are searchable
 * - Search returns correct results for Arabic queries
 * - Performance is acceptable
 * 
 * Usage: node supabase/scripts/validate_arabic_search.js
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

// Test queries (Arabic)
const testQueries = [
  'صدر',      // chest
  'ضغط',      // press
  'سحب',      // pull
  'سكوات',    // squat
  'رفعة مميتة', // deadlift
  'دمبل',     // dumbbell
  'مائل',     // incline
];

/**
 * Test Arabic search
 */
async function testArabicSearch(client, query) {
  try {
    const startTime = Date.now();
    
    const result = await client.query(`
      SELECT 
        ek.id,
        ek.name as english_name,
        et.name as arabic_name,
        et.aliases as arabic_aliases
      FROM exercise_knowledge ek
      LEFT JOIN exercise_translations et 
        ON et.exercise_id = ek.id 
        AND et.language = 'ar'
      WHERE 
        ek.status = 'approved'
        AND ek.language = 'en'
        AND (
          et.name ILIKE '%' || $1 || '%'
          OR EXISTS (
            SELECT 1 FROM unnest(et.aliases) a WHERE a ILIKE '%' || $1 || '%'
          )
        )
      LIMIT 10
    `, [query]);
    
    const duration = Date.now() - startTime;
    
    return {
      query,
      count: result.rows.length,
      duration,
      results: result.rows,
    };
  } catch (error) {
    return {
      query,
      error: error.message,
    };
  }
}

/**
 * Test RPC function search
 */
async function testRPCSearch(client, query) {
  try {
    const startTime = Date.now();
    
    const result = await client.query(`
      SELECT * FROM search_exercises_with_aliases(
        p_query => $1,
        p_status => 'approved',
        p_language => 'en',
        p_limit => 10
      )
    `, [query]);
    
    const duration = Date.now() - startTime;
    
    return {
      query,
      count: result.rows.length,
      duration,
      results: result.rows.map(r => ({
        english_name: r.name,
        arabic_name: r.arabic_name,
        arabic_aliases: r.arabic_aliases,
      })),
    };
  } catch (error) {
    return {
      query,
      error: error.message,
    };
  }
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
    
    // Check translation count
    console.log('📊 Checking Arabic translation count...');
    const countResult = await client.query(`
      SELECT COUNT(*) as count
      FROM exercise_translations
      WHERE language = 'ar'
    `);
    const translationCount = parseInt(countResult.rows[0].count);
    console.log(`   Arabic translations: ${translationCount}\n`);
    
    if (translationCount === 0) {
      console.log('⚠️  No Arabic translations found. Run generate_arabic_exercise_names.js first.\n');
      return;
    }
    
    // Test direct SQL search
    console.log('🔍 Testing direct SQL search...\n');
    const sqlResults = [];
    for (const query of testQueries) {
      const result = await testArabicSearch(client, query);
      sqlResults.push(result);
      
      if (result.error) {
        console.log(`❌ Query "${query}": ${result.error}`);
      } else {
        console.log(`✅ Query "${query}": ${result.count} results (${result.duration}ms)`);
        if (result.results.length > 0) {
          const first = result.results[0];
          console.log(`   Example: ${first.english_name} -> ${first.arabic_name}`);
        }
      }
    }
    
    console.log('\n🔍 Testing RPC function search...\n');
    const rpcResults = [];
    for (const query of testQueries) {
      const result = await testRPCSearch(client, query);
      rpcResults.push(result);
      
      if (result.error) {
        console.log(`❌ Query "${query}": ${result.error}`);
      } else {
        console.log(`✅ Query "${query}": ${result.count} results (${result.duration}ms)`);
        if (result.results.length > 0) {
          const first = result.results[0];
          console.log(`   Example: ${first.english_name} -> ${first.arabic_name}`);
        }
      }
    }
    
    // Summary
    console.log('\n📊 Summary:');
    const sqlAvgDuration = sqlResults
      .filter(r => !r.error)
      .reduce((sum, r) => sum + r.duration, 0) / sqlResults.filter(r => !r.error).length;
    const rpcAvgDuration = rpcResults
      .filter(r => !r.error)
      .reduce((sum, r) => sum + r.duration, 0) / rpcResults.filter(r => !r.error).length;
    
    console.log(`   Direct SQL average: ${sqlAvgDuration.toFixed(2)}ms`);
    console.log(`   RPC function average: ${rpcAvgDuration.toFixed(2)}ms`);
    
    const sqlTotalResults = sqlResults
      .filter(r => !r.error)
      .reduce((sum, r) => sum + r.count, 0);
    const rpcTotalResults = rpcResults
      .filter(r => !r.error)
      .reduce((sum, r) => sum + r.count, 0);
    
    console.log(`   Direct SQL total results: ${sqlTotalResults}`);
    console.log(`   RPC function total results: ${rpcTotalResults}`);
    
    // Performance check
    if (sqlAvgDuration > 1000 || rpcAvgDuration > 1000) {
      console.log('\n⚠️  Performance warning: Search is slower than expected (>1000ms)');
    } else {
      console.log('\n✅ Performance: Acceptable (<1000ms)');
    }
    
    // Sample translations
    console.log('\n📝 Sample Translations:');
    const samplesResult = await client.query(`
      SELECT 
        ek.name as english_name,
        et.name as arabic_name,
        et.aliases
      FROM exercise_translations et
      JOIN exercise_knowledge ek ON ek.id = et.exercise_id
      WHERE et.language = 'ar'
      LIMIT 5
    `);
    
    samplesResult.rows.forEach(row => {
      console.log(`\n   English: ${row.english_name}`);
      console.log(`   Arabic:  ${row.arabic_name}`);
      console.log(`   Aliases: ${row.aliases.join(', ')}`);
    });
    
    console.log('\n✅ Validation complete!');
    
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

module.exports = { testArabicSearch, testRPCSearch };
