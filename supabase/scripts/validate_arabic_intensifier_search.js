#!/usr/bin/env node

/**
 * Validate Arabic Intensifier Search
 * 
 * This script tests Arabic search functionality for intensifiers
 * by running sample queries and verifying results.
 * 
 * Usage: node supabase/scripts/validate_arabic_intensifier_search.js
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
  'دروب',      // Drop set
  'راحة',      // Rest
  'تحفيز',     // Stimulation (Myo-Reps)
  'تمبو',      // Tempo
  'ثبات',      // Isometric
  'كلستر',     // Cluster
  'إسقاط',     // Drop
  'تكرارات',   // Reps
];

async function testSearch(query, client) {
  try {
    const result = await client.query(`
      SELECT * FROM search_intensifiers_with_aliases(
        p_query => $1,
        p_status => 'approved',
        p_language => NULL,
        p_limit => 10,
        p_offset => 0
      )
    `, [query]);
    
    return {
      query,
      count: result.rows.length,
      results: result.rows.map(r => ({
        english: r.name,
        arabic: r.arabic_name,
        aliases: r.arabic_aliases || [],
      })),
    };
  } catch (error) {
    return {
      query,
      error: error.message,
    };
  }
}

async function main() {
  const client = new Client(dbConfig);
  
  try {
    console.log('🔌 Connecting to database...');
    await client.connect();
    console.log('✅ Connected to database\n');
    
    // Check translation count
    console.log('📊 Checking translation statistics...');
    const statsResult = await client.query(`
      SELECT 
        COUNT(*) as total_translations,
        COUNT(DISTINCT intensifier_id) as intensifiers_translated
      FROM intensifier_translations
      WHERE language = 'ar'
    `);
    
    console.table(statsResult.rows);
    console.log('');
    
    // Test Arabic search queries
    console.log('🔍 Testing Arabic search queries...\n');
    const results = [];
    
    for (const query of testQueries) {
      const result = await testSearch(query, client);
      results.push(result);
      
      if (result.error) {
        console.log(`❌ Query: "${query}"`);
        console.log(`   Error: ${result.error}\n`);
      } else {
        console.log(`✅ Query: "${query}"`);
        console.log(`   Found: ${result.count} results`);
        if (result.results.length > 0) {
          console.log(`   Sample: ${result.results[0].english} -> ${result.results[0].arabic}`);
        }
        console.log('');
      }
    }
    
    // Summary
    console.log('📊 Search Test Summary:');
    const successful = results.filter(r => !r.error && r.count > 0).length;
    const failed = results.filter(r => r.error).length;
    const noResults = results.filter(r => !r.error && r.count === 0).length;
    
    console.log(`   ✅ Successful searches: ${successful}/${testQueries.length}`);
    console.log(`   ❌ Failed searches: ${failed}`);
    console.log(`   ⚠️  No results: ${noResults}`);
    
    // Sample translations
    console.log('\n📝 Sample Arabic Translations:');
    const samplesResult = await client.query(`
      SELECT 
        ik.name as english_name,
        ik.short_desc as english_desc,
        it.name as arabic_name,
        it.aliases as arabic_aliases
      FROM intensifier_translations it
      JOIN intensifier_knowledge ik ON ik.id = it.intensifier_id
      WHERE it.language = 'ar'
      ORDER BY ik.created_at DESC
      LIMIT 5
    `);
    
    samplesResult.rows.forEach((row, idx) => {
      console.log(`\n${idx + 1}. English: ${row.english_name}`);
      console.log(`   Arabic:  ${row.arabic_name}`);
      console.log(`   Aliases: ${(row.arabic_aliases || []).join(', ')}`);
    });
    
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

module.exports = { testSearch };
