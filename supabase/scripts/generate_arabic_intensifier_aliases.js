#!/usr/bin/env node

/**
 * Generate Arabic Intensifier Aliases
 * 
 * This script generates Arabic aliases for all intensifiers in intensifier_knowledge
 * and inserts them into intensifier_aliases table.
 * 
 * Each intensifier gets 4-7 Arabic aliases including:
 * - Formal Arabic
 * - Gym Arabic
 * - Coaching phrase
 * - Short slang
 * - English-Arabic hybrid (optional)
 * 
 * Usage: node supabase/scripts/generate_arabic_intensifier_aliases.js
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

// =====================================================
// CANONICAL ALIAS MAPPINGS (Rule-based, not LLM)
// =====================================================

/**
 * Canonical Arabic aliases for each intensifier
 * Based on user requirements with exact canonical sets
 */
const canonicalAliases = {
  // Rest-Pause
  'Rest-Pause': [
    'راحة توقف',
    'راحة ثم تكرار',
    'تكرار مع راحة قصيرة',
    'راست بوز',
    'RP',
    'Rest Pause'
  ],
  'rest-pause': [
    'راحة توقف',
    'راحة ثم تكرار',
    'تكرار مع راحة قصيرة',
    'راست بوز',
    'RP'
  ],
  'rest pause': [
    'راحة توقف',
    'راحة ثم تكرار',
    'راست بوز',
    'RP'
  ],
  
  // Drop Set
  'Drop Set': [
    'دروب سيت',
    'إنقاص الوزن',
    'تقليل الوزن مع الاستمرار',
    'سيت تنازلي',
    'Drop',
    'Drop Set'
  ],
  'drop set': [
    'دروب سيت',
    'إنقاص الوزن',
    'تقليل الوزن مع الاستمرار',
    'سيت تنازلي',
    'Drop'
  ],
  'Double Drop Set': [
    'دروب سيت مزدوج',
    'إنقاص الوزن مرتين',
    'سيت تنازلي مزدوج',
    'Double Drop',
    'Double Drop Set'
  ],
  'double drop set': [
    'دروب سيت مزدوج',
    'إنقاص الوزن مرتين',
    'Double Drop'
  ],
  
  // Myo-Reps
  'Myo-Reps': [
    'مايو ريبس',
    'تكرارات عصبية',
    'تنشيط عضلي متقطع',
    'Myo',
    'Myo Reps'
  ],
  'myo-reps': [
    'مايو ريبس',
    'تكرارات عصبية',
    'تنشيط عضلي متقطع',
    'Myo'
  ],
  'myo reps': [
    'مايو ريبس',
    'تكرارات عصبية',
    'Myo'
  ],
  
  // Cluster Sets
  'Cluster Sets': [
    'كلستر',
    'مجموعات عنقودية',
    'تكرار مع فواصل قصيرة',
    'Cluster',
    'Cluster Sets'
  ],
  'cluster sets': [
    'كلستر',
    'مجموعات عنقودية',
    'تكرار مع فواصل قصيرة',
    'Cluster'
  ],
  'cluster': [
    'كلستر',
    'مجموعات عنقودية',
    'Cluster'
  ],
  
  // Tempo Reps / Tempo Sets
  'Tempo Reps': [
    'تحكم بالسرعة',
    'تمبو',
    'إيقاع التكرار',
    'Tempo',
    'Tempo Reps'
  ],
  'tempo reps': [
    'تحكم بالسرعة',
    'تمبو',
    'إيقاع التكرار',
    'Tempo'
  ],
  'Tempo Sets': [
    'تحكم بالسرعة',
    'تمبو',
    'إيقاع التكرار',
    'Tempo',
    'Tempo Sets'
  ],
  'tempo sets': [
    'تحكم بالسرعة',
    'تمبو',
    'إيقاع التكرار',
    'Tempo'
  ],
  'tempo': [
    'تمبو',
    'تحكم بالسرعة',
    'Tempo'
  ],
  
  // Paused Reps
  'Paused Reps': [
    'توقف بالأسفل',
    'تكرار مع تثبيت',
    'وقفة عضلية',
    'Paused',
    'Paused Reps'
  ],
  'paused reps': [
    'توقف بالأسفل',
    'تكرار مع تثبيت',
    'وقفة عضلية',
    'Paused'
  ],
  'paused': [
    'توقف بالأسفل',
    'تكرار مع تثبيت',
    'Paused'
  ],
  
  // Partial Reps
  'Partials': [
    'نصف تكرار',
    'تكرار جزئي',
    'مدى حركة جزئي',
    'Partials',
    'Partial Reps'
  ],
  'partials': [
    'نصف تكرار',
    'تكرار جزئي',
    'مدى حركة جزئي',
    'Partials'
  ],
  'Partial Reps': [
    'نصف تكرار',
    'تكرار جزئي',
    'مدى حركة جزئي',
    'Partials',
    'Partial Reps'
  ],
  'partial reps': [
    'نصف تكرار',
    'تكرار جزئي',
    'Partials'
  ],
  
  // Isometrics
  'Yielding Isometric': [
    'ثابت',
    'تثبيت عضلي',
    'انقباض ثابت',
    'Isometric',
    'Isometrics'
  ],
  'yielding isometric': [
    'ثابت',
    'تثبيت عضلي',
    'انقباض ثابت',
    'Isometric'
  ],
  'Overcoming Isometric': [
    'ثابت قصوي',
    'تثبيت عضلي قصوي',
    'انقباض ثابت قصوي',
    'Overcoming Isometric'
  ],
  'overcoming isometric': [
    'ثابت قصوي',
    'تثبيت عضلي قصوي',
    'Overcoming Isometric'
  ],
  'Iso-Hold at Stretch': [
    'ثابت في التمدد',
    'تثبيت في وضعية التمدد',
    'انقباض ثابت في التمدد',
    'Iso-Hold'
  ],
  'iso-hold at stretch': [
    'ثابت في التمدد',
    'تثبيت في وضعية التمدد',
    'Iso-Hold'
  ],
  
  // EMOM
  'EMOM': [
    'كل دقيقة في الدقيقة',
    'إيموم',
    'تدريب دقيق',
    'EMOM',
    'Every Minute on Minute'
  ],
  'emom': [
    'كل دقيقة في الدقيقة',
    'إيموم',
    'تدريب دقيق',
    'EMOM'
  ],
  'Every Minute on Minute': [
    'كل دقيقة في الدقيقة',
    'إيموم',
    'تدريب دقيق',
    'EMOM'
  ],
  
  // Density Block
  'Density Block': [
    'كتلة الكثافة',
    'تدريب الكثافة',
    'أقصى تكرارات في وقت محدد',
    'Density',
    'Density Block'
  ],
  'density block': [
    'كتلة الكثافة',
    'تدريب الكثافة',
    'أقصى تكرارات في وقت محدد',
    'Density'
  ],
  'density': [
    'كتلة الكثافة',
    'تدريب الكثافة',
    'Density'
  ],
  
  // Pre/Post Exhaust
  'Pre-Exhaust': [
    'إرهاق مسبق',
    'إرهاق قبل التمرين الرئيسي',
    'إرهاق أولي',
    'Pre-Exhaust'
  ],
  'pre-exhaust': [
    'إرهاق مسبق',
    'إرهاق قبل التمرين الرئيسي',
    'Pre-Exhaust'
  ],
  'Post-Exhaust': [
    'إرهاق لاحق',
    'إرهاق بعد التمرين الرئيسي',
    'إرهاق ثانوي',
    'Post-Exhaust'
  ],
  'post-exhaust': [
    'إرهاق لاحق',
    'إرهاق بعد التمرين الرئيسي',
    'Post-Exhaust'
  ],
  
  // Superset
  'Superset': [
    'سوبر سيت',
    'مجموعة مزدوجة',
    'تمرينين متتاليين',
    'Superset'
  ],
  'superset': [
    'سوبر سيت',
    'مجموعة مزدوجة',
    'Superset'
  ],
  
  // Circuit
  'Circuit': [
    'سيركت',
    'دائرة',
    'تمرين دائري',
    'Circuit'
  ],
  'circuit': [
    'سيركت',
    'دائرة',
    'Circuit'
  ],
  
  // BFR
  'BFR': [
    'تقييد تدفق الدم',
    'BFR',
    'تدريب تقييد الدم',
    'Blood Flow Restriction'
  ],
  'bfr': [
    'تقييد تدفق الدم',
    'BFR',
    'تدريب تقييد الدم'
  ],
  'Blood Flow Restriction': [
    'تقييد تدفق الدم',
    'BFR',
    'تدريب تقييد الدم'
  ],
};

/**
 * Get aliases for an intensifier by matching name
 */
function getAliasesForIntensifier(intensifierName) {
  const name = intensifierName.trim();
  const nameLower = name.toLowerCase();
  
  // 1. Exact match
  if (canonicalAliases[name]) {
    return canonicalAliases[name];
  }
  
  // 2. Case-insensitive match
  if (canonicalAliases[nameLower]) {
    return canonicalAliases[nameLower];
  }
  
  // 3. Partial match - check if any key is contained in name or vice versa
  for (const [key, aliases] of Object.entries(canonicalAliases)) {
    const keyLower = key.toLowerCase();
    if (nameLower.includes(keyLower) || keyLower.includes(nameLower)) {
      return aliases;
    }
  }
  
  // 4. Generate fallback aliases based on common patterns
  const fallbackAliases = [];
  
  // Transliterate common English terms
  const transliterationMap = {
    'rest': 'ريست',
    'pause': 'بوز',
    'drop': 'دروب',
    'set': 'سيت',
    'rep': 'ريب',
    'reps': 'ريبس',
    'tempo': 'تمبو',
    'cluster': 'كلستر',
    'isometric': 'إيزومتريك',
    'partial': 'بارشال',
    'exhaust': 'إكهاست',
    'superset': 'سوبر سيت',
    'circuit': 'سيركت',
  };
  
  // Add transliterated version
  let transliterated = name;
  for (const [en, ar] of Object.entries(transliterationMap)) {
    if (nameLower.includes(en)) {
      transliterated = nameLower.replace(new RegExp(en, 'gi'), ar);
      fallbackAliases.push(transliterated);
      break;
    }
  }
  
  // Always include English name as alias (for search flexibility)
  fallbackAliases.push(name);
  
  return fallbackAliases.length > 0 ? fallbackAliases : [name];
}

/**
 * Main function
 */
async function main() {
  const client = new Client(dbConfig);
  
  try {
    console.log('🔌 Connecting to database...');
    await client.connect();
    console.log('✅ Connected to database');
    
    // Fetch all approved English intensifiers
    console.log('📖 Fetching intensifiers from intensifier_knowledge...');
    const intensifiersResult = await client.query(`
      SELECT id, name, aliases, short_desc, fatigue_cost
      FROM intensifier_knowledge
      WHERE status = 'approved'
        AND language = 'en'
      ORDER BY name
    `);
    
    const intensifiers = intensifiersResult.rows;
    console.log(`📊 Found ${intensifiers.length} approved English intensifiers`);
    
    // Check existing aliases count
    const existingResult = await client.query(`
      SELECT COUNT(*) as count
      FROM intensifier_aliases
      WHERE language = 'ar'
    `);
    const existingCount = parseInt(existingResult.rows[0].count);
    console.log(`📊 Existing Arabic aliases: ${existingCount}`);
    
    // Generate and insert aliases
    let totalAliases = 0;
    let skipped = 0;
    let intensifiersProcessed = 0;
    let aliasesPerIntensifier = [];
    
    for (const intensifier of intensifiers) {
      // Get aliases for this intensifier
      const aliases = getAliasesForIntensifier(intensifier.name);
      
      if (aliases.length === 0) {
        console.log(`⚠️  No aliases generated for: ${intensifier.name}`);
        continue;
      }
      
      // Insert each alias
      let insertedForThis = 0;
      for (const alias of aliases) {
        // Skip empty aliases
        if (!alias || alias.trim().length === 0) {
          continue;
        }
        
        try {
          await client.query(`
            INSERT INTO intensifier_aliases (intensifier_id, language, alias, source)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (intensifier_id, language, alias) DO NOTHING
          `, [
            intensifier.id,
            'ar',
            alias.trim(),
            'canonical_ar_intensifier_alias_v1'
          ]);
          
          // Check if it was actually inserted (not conflicted)
          const checkResult = await client.query(`
            SELECT id FROM intensifier_aliases
            WHERE intensifier_id = $1 AND language = 'ar' AND alias = $2
          `, [intensifier.id, alias.trim()]);
          
          if (checkResult.rows.length > 0) {
            totalAliases++;
            insertedForThis++;
          } else {
            skipped++;
          }
        } catch (error) {
          console.error(`❌ Error inserting alias "${alias}" for "${intensifier.name}":`, error.message);
          skipped++;
        }
      }
      
      if (insertedForThis > 0) {
        aliasesPerIntensifier.push(insertedForThis);
        intensifiersProcessed++;
      }
    }
    
    // Final statistics
    console.log('\n📊 Final Statistics:');
    const statsResult = await client.query(`
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
    
    console.table(statsResult.rows);
    
    // Detailed stats
    if (aliasesPerIntensifier.length > 0) {
      const minAliases = Math.min(...aliasesPerIntensifier);
      const maxAliases = Math.max(...aliasesPerIntensifier);
      const avgAliases = (aliasesPerIntensifier.reduce((a, b) => a + b, 0) / aliasesPerIntensifier.length).toFixed(2);
      
      console.log(`\n✅ Arabic alias generation complete!`);
      console.log(`   - Total aliases created: ${totalAliases}`);
      console.log(`   - Intensifiers processed: ${intensifiersProcessed}`);
      console.log(`   - Aliases per intensifier: min=${minAliases}, max=${maxAliases}, avg=${avgAliases}`);
      console.log(`   - Skipped (duplicates): ${skipped}`);
    } else {
      console.log(`\n⚠️  No new aliases were created (all may already exist)`);
    }
    
    // Sample aliases
    console.log('\n📝 Sample Intensifiers with Aliases:');
    const samplesResult = await client.query(`
      SELECT 
        ik.name as intensifier_name,
        array_agg(ia.alias ORDER BY ia.alias) as aliases
      FROM intensifier_knowledge ik
      JOIN intensifier_aliases ia ON ia.intensifier_id = ik.id
      WHERE ia.language = 'ar'
      GROUP BY ik.id, ik.name
      LIMIT 5
    `);
    
    samplesResult.rows.forEach(row => {
      console.log(`\n   ${row.intensifier_name}:`);
      console.log(`   Aliases: ${row.aliases.join(', ')}`);
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

module.exports = { getAliasesForIntensifier };
