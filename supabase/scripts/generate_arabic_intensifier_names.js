#!/usr/bin/env node

/**
 * Generate Arabic Intensifier Names & Translations
 * 
 * This script generates Arabic translations for all intensifiers in intensifier_knowledge
 * and inserts them into intensifier_translations table.
 * 
 * Translation rules:
 * - Clear & gym-usable (understandable by Arabic-speaking athletes)
 * - Semi-technical (enough explanation to teach, not confuse)
 * - NO literal word-for-word translation
 * - NO Google-translate style
 * - NO pure slang without explanation
 * 
 * Usage: node supabase/scripts/generate_arabic_intensifier_names.js
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
// ARABIC TRANSLATION DICTIONARY (CANONICAL MAPPINGS)
// =====================================================

// Canonical intensifier translations (rule-based, not LLM hallucinations)
const intensifierTranslations = {
  // Rest-Pause
  'Rest-Pause': {
    name: 'التكرارات المتقطعة',
    aliases: ['ريست بوز', 'تكرارات مع توقف', 'راحة قصيرة بين التكرارات', 'مجموعات متقطعة'],
  },
  'rest-pause': {
    name: 'التكرارات المتقطعة',
    aliases: ['ريست بوز', 'تكرارات مع توقف', 'راحة قصيرة بين التكرارات'],
  },
  'rest pause': {
    name: 'التكرارات المتقطعة',
    aliases: ['ريست بوز', 'تكرارات مع توقف'],
  },
  
  // Drop Set
  'Drop Set': {
    name: 'الإسقاط التدريجي للوزن',
    aliases: ['دروب سيت', 'إنقاص الوزن تدريجياً', 'إسقاط الوزن', 'تقليل الوزن'],
  },
  'drop set': {
    name: 'الإسقاط التدريجي للوزن',
    aliases: ['دروب سيت', 'إنقاص الوزن تدريجياً', 'إسقاط الوزن'],
  },
  'Double Drop Set': {
    name: 'الإسقاط المزدوج للوزن',
    aliases: ['دروب سيت مزدوج', 'إسقاط مزدوج', 'تقليل الوزن مرتين'],
  },
  'double drop set': {
    name: 'الإسقاط المزدوج للوزن',
    aliases: ['دروب سيت مزدوج', 'إسقاط مزدوج'],
  },
  
  // Myo-Reps
  'Myo-Reps': {
    name: 'تكرارات التحفيز العصبي',
    aliases: ['مايو ريبس', 'تكرارات التحفيز', 'مجموعات التحفيز', 'تكرارات عصبية'],
  },
  'myo-reps': {
    name: 'تكرارات التحفيز العصبي',
    aliases: ['مايو ريبس', 'تكرارات التحفيز', 'مجموعات التحفيز'],
  },
  'myo reps': {
    name: 'تكرارات التحفيز العصبي',
    aliases: ['مايو ريبس', 'تكرارات التحفيز'],
  },
  
  // Cluster Sets
  'Cluster Sets': {
    name: 'المجموعات العنقودية',
    aliases: ['كلستر', 'مجموعات قصيرة متكررة', 'مجموعات متقاربة', 'كلستر سيت'],
  },
  'cluster sets': {
    name: 'المجموعات العنقودية',
    aliases: ['كلستر', 'مجموعات قصيرة متكررة', 'مجموعات متقاربة'],
  },
  'cluster': {
    name: 'المجموعات العنقودية',
    aliases: ['كلستر', 'مجموعات قصيرة متكررة'],
  },
  
  // Tempo Reps / Tempo Sets
  'Tempo Sets': {
    name: 'التحكم في سرعة التكرار',
    aliases: ['تمبو', 'سرعة التكرار', 'إيقاع الحركة', 'تمبو سيت'],
  },
  'tempo sets': {
    name: 'التحكم في سرعة التكرار',
    aliases: ['تمبو', 'سرعة التكرار', 'إيقاع الحركة'],
  },
  'Tempo Reps': {
    name: 'التحكم في سرعة التكرار',
    aliases: ['تمبو', 'سرعة التكرار', 'إيقاع الحركة'],
  },
  'tempo': {
    name: 'التحكم في سرعة التكرار',
    aliases: ['تمبو', 'سرعة التكرار'],
  },
  
  // Isometrics
  'Yielding Isometric': {
    name: 'الثبات العضلي',
    aliases: ['تمرين ثابت', 'الثبات العضلي', 'إيزومتريك', 'ثبات تحت الحمل'],
  },
  'yielding isometric': {
    name: 'الثبات العضلي',
    aliases: ['تمرين ثابت', 'الثبات العضلي', 'إيزومتريك'],
  },
  'Overcoming Isometric': {
    name: 'الثبات العضلي القصوي',
    aliases: ['ثبات قصوي', 'إيزومتريك قصوي', 'ثبات ضد مقاومة ثابتة'],
  },
  'overcoming isometric': {
    name: 'الثبات العضلي القصوي',
    aliases: ['ثبات قصوي', 'إيزومتريك قصوي'],
  },
  'Iso-Hold at Stretch': {
    name: 'الثبات في وضعية التمدد',
    aliases: ['ثبات في التمدد', 'إيزو في التمدد', 'ثبات عند التمدد'],
  },
  'iso-hold at stretch': {
    name: 'الثبات في وضعية التمدد',
    aliases: ['ثبات في التمدد', 'إيزو في التمدد'],
  },
  
  // Partials
  'Partials': {
    name: 'التكرارات الجزئية',
    aliases: ['تكرار جزئي', 'جزء من المدى الحركي', 'جزئي'],
  },
  'partials': {
    name: 'التكرارات الجزئية',
    aliases: ['تكرار جزئي', 'جزء من المدى الحركي'],
  },
  'Lengthened Partials': {
    name: 'التكرارات الجزئية المطولة',
    aliases: ['جزئي مطول', 'جزئي في التمدد', 'جزئي في وضعية التمدد'],
  },
  'lengthened partials': {
    name: 'التكرارات الجزئية المطولة',
    aliases: ['جزئي مطول', 'جزئي في التمدد'],
  },
  '1.5 Reps': {
    name: 'التكرارات الواحد ونصف',
    aliases: ['واحد ونصف', '1.5', 'تكرار كامل ونصف'],
  },
  '1.5 reps': {
    name: 'التكرارات الواحد ونصف',
    aliases: ['واحد ونصف', '1.5'],
  },
  
  // EMOM
  'EMOM': {
    name: 'كل دقيقة في الدقيقة',
    aliases: ['إيموم', 'كل دقيقة', 'تدريب دقيق', 'EMOM'],
  },
  'emom': {
    name: 'كل دقيقة في الدقيقة',
    aliases: ['إيموم', 'كل دقيقة', 'تدريب دقيق'],
  },
  'Every Minute on Minute': {
    name: 'كل دقيقة في الدقيقة',
    aliases: ['إيموم', 'كل دقيقة', 'تدريب دقيق'],
  },
  
  // Density Block
  'Density Block': {
    name: 'كتلة الكثافة',
    aliases: ['تدريب الكثافة', 'كثافة', 'أقصى تكرارات في وقت محدد'],
  },
  'density block': {
    name: 'كتلة الكثافة',
    aliases: ['تدريب الكثافة', 'كثافة'],
  },
  'density': {
    name: 'كتلة الكثافة',
    aliases: ['تدريب الكثافة', 'كثافة'],
  },
  
  // Paused Reps
  'Paused Reps': {
    name: 'التكرارات مع التوقف',
    aliases: ['تكرارات مع وقفة', 'توقف', 'إيقاف مؤقت'],
  },
  'paused reps': {
    name: 'التكرارات مع التوقف',
    aliases: ['تكرارات مع وقفة', 'توقف'],
  },
  'paused': {
    name: 'التكرارات مع التوقف',
    aliases: ['تكرارات مع وقفة', 'توقف'],
  },
  
  // Slow Eccentrics
  'Slow Eccentrics': {
    name: 'المرحلة السالبة البطيئة',
    aliases: ['نفي بطيء', 'هبوط بطيء', 'مرحلة سالبة بطيئة'],
  },
  'slow eccentrics': {
    name: 'المرحلة السالبة البطيئة',
    aliases: ['نفي بطيء', 'هبوط بطيء'],
  },
  'slow negative': {
    name: 'المرحلة السالبة البطيئة',
    aliases: ['نفي بطيء', 'هبوط بطيء'],
  },
  
  // Pre/Post Exhaust
  'Pre-Exhaust': {
    name: 'الإرهاق المسبق',
    aliases: ['إرهاق قبل', 'إرهاق مسبق', 'إرهاق أولي'],
  },
  'pre-exhaust': {
    name: 'الإرهاق المسبق',
    aliases: ['إرهاق قبل', 'إرهاق مسبق'],
  },
  'Post-Exhaust': {
    name: 'الإرهاق اللاحق',
    aliases: ['إرهاق بعد', 'إرهاق لاحق', 'إرهاق ثانوي'],
  },
  'post-exhaust': {
    name: 'الإرهاق اللاحق',
    aliases: ['إرهاق بعد', 'إرهاق لاحق'],
  },
  
  // Mechanical Advantage Drop Set
  'Mechanical Advantage Drop Set': {
    name: 'الإسقاط الميكانيكي للوزن',
    aliases: ['إسقاط بزاوية', 'إسقاط ميكانيكي', 'تغيير الزاوية'],
  },
  'mechanical advantage drop set': {
    name: 'الإسقاط الميكانيكي للوزن',
    aliases: ['إسقاط بزاوية', 'إسقاط ميكانيكي'],
  },
  'mechanical drop': {
    name: 'الإسقاط الميكانيكي للوزن',
    aliases: ['إسقاط بزاوية', 'إسقاط ميكانيكي'],
  },
  
  // Superset
  'Superset': {
    name: 'المجموعة المزدوجة',
    aliases: ['سوبر سيت', 'مجموعة مزدوجة', 'تمرينين متتاليين'],
  },
  'superset': {
    name: 'المجموعة المزدوجة',
    aliases: ['سوبر سيت', 'مجموعة مزدوجة'],
  },
  
  // Circuit
  'Circuit': {
    name: 'الدائرة التدريبية',
    aliases: ['سيركت', 'دائرة', 'تمرين دائري'],
  },
  'circuit': {
    name: 'الدائرة التدريبية',
    aliases: ['سيركت', 'دائرة'],
  },
  
  // BFR (Blood Flow Restriction)
  'BFR': {
    name: 'تقييد تدفق الدم',
    aliases: ['BFR', 'تقييد الدم', 'تدريب تقييد الدم'],
  },
  'bfr': {
    name: 'تقييد تدفق الدم',
    aliases: ['BFR', 'تقييد الدم'],
  },
  'Blood Flow Restriction': {
    name: 'تقييد تدفق الدم',
    aliases: ['BFR', 'تقييد الدم', 'تدريب تقييد الدم'],
  },
};

/**
 * Generate Arabic name for an intensifier
 */
function generateArabicName(intensifier) {
  const name = intensifier.name.trim();
  const nameLower = name.toLowerCase();
  
  // 1. Check for exact match first
  if (intensifierTranslations[name]) {
    return intensifierTranslations[name].name;
  }
  
  if (intensifierTranslations[nameLower]) {
    return intensifierTranslations[nameLower].name;
  }
  
  // 2. Check for partial match (contains)
  for (const [key, translation] of Object.entries(intensifierTranslations)) {
    if (nameLower.includes(key.toLowerCase()) || key.toLowerCase().includes(nameLower)) {
      return translation.name;
    }
  }
  
  // 3. Fallback: transliterate common patterns
  const fallbackPatterns = {
    'rest': 'راحة',
    'pause': 'توقف',
    'drop': 'إسقاط',
    'set': 'مجموعة',
    'rep': 'تكرار',
    'reps': 'تكرارات',
    'tempo': 'إيقاع',
    'cluster': 'عنقودي',
    'isometric': 'ثبات',
    'partial': 'جزئي',
    'exhaust': 'إرهاق',
    'superset': 'مزدوج',
    'circuit': 'دائرة',
  };
  
  let arabicName = name;
  for (const [pattern, arabic] of Object.entries(fallbackPatterns)) {
    if (nameLower.includes(pattern)) {
      arabicName = arabic;
      break;
    }
  }
  
  // If still English, return as-is (will be flagged for manual review)
  return arabicName;
}

/**
 * Generate Arabic aliases for an intensifier
 */
function generateArabicAliases(intensifier, arabicName) {
  const aliases = new Set();
  const name = intensifier.name.trim();
  const nameLower = name.toLowerCase();
  
  // Always include the canonical Arabic name
  aliases.add(arabicName);
  
  // 1. Check for exact match in dictionary
  if (intensifierTranslations[name]) {
    intensifierTranslations[name].aliases.forEach(alias => aliases.add(alias));
  } else if (intensifierTranslations[nameLower]) {
    intensifierTranslations[nameLower].aliases.forEach(alias => aliases.add(alias));
  } else {
    // 2. Check for partial match
    for (const [key, translation] of Object.entries(intensifierTranslations)) {
      if (nameLower.includes(key.toLowerCase()) || key.toLowerCase().includes(nameLower)) {
        translation.aliases.forEach(alias => aliases.add(alias));
        break;
      }
    }
  }
  
  // 3. Generate common variations
  // Add transliterated English name if commonly used
  const commonTransliterations = {
    'rest-pause': 'ريست بوز',
    'drop set': 'دروب سيت',
    'myo-reps': 'مايو ريبس',
    'cluster': 'كلستر',
    'tempo': 'تمبو',
    'emom': 'إيموم',
    'superset': 'سوبر سيت',
    'circuit': 'سيركت',
    'bfr': 'BFR',
  };
  
  for (const [pattern, translit] of Object.entries(commonTransliterations)) {
    if (nameLower.includes(pattern)) {
      aliases.add(translit);
    }
  }
  
  // 4. Remove duplicates and limit
  return Array.from(aliases)
    .filter(alias => alias.length >= 2 && alias.length <= 100)
    .filter(alias => alias !== arabicName) // Don't duplicate exact name
    .slice(0, 6); // Limit to 6 aliases per intensifier
}

/**
 * Generate Arabic description (optional, one sentence)
 */
function generateArabicDescription(intensifier) {
  const shortDesc = intensifier.short_desc || '';
  if (!shortDesc) return null;
  
  // Simple pattern-based translations for common descriptions
  const descPatterns = {
    'failure': 'الفشل',
    'rest': 'راحة',
    'seconds': 'ثواني',
    'weight': 'وزن',
    'reps': 'تكرارات',
    'sets': 'مجموعات',
    'reduce': 'تقليل',
    'continue': 'متابعة',
  };
  
  // For now, return null (descriptions can be added manually later)
  // This keeps the script focused on names and aliases
  return null;
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
      SELECT id, name, aliases, short_desc, fatigue_cost, language
      FROM intensifier_knowledge
      WHERE status = 'approved'
        AND language = 'en'
      ORDER BY created_at DESC
    `);
    
    const intensifiers = intensifiersResult.rows;
    console.log(`📊 Found ${intensifiers.length} approved English intensifiers`);
    
    // Check existing translations
    const existingResult = await client.query(`
      SELECT COUNT(*) as count
      FROM intensifier_translations
      WHERE language = 'ar'
    `);
    const existingCount = parseInt(existingResult.rows[0].count);
    console.log(`📊 Existing Arabic translations: ${existingCount}`);
    
    // Generate and insert translations
    let totalTranslations = 0;
    let skipped = 0;
    let manualReview = 0;
    const batchSize = 100;
    
    for (let i = 0; i < intensifiers.length; i += batchSize) {
      const batch = intensifiers.slice(i, i + batchSize);
      const translationInserts = [];
      
      for (const intensifier of batch) {
        // Check if translation already exists
        const existingCheck = await client.query(`
          SELECT id FROM intensifier_translations
          WHERE intensifier_id = $1 AND language = 'ar'
        `, [intensifier.id]);
        
        if (existingCheck.rows.length > 0) {
          skipped++;
          continue;
        }
        
        // Generate Arabic name
        const arabicName = generateArabicName(intensifier);
        
        // Flag for manual review if name wasn't translated (still English)
        if (arabicName === intensifier.name || arabicName.length < 3 || !/[ء-ي]/.test(arabicName)) {
          manualReview++;
          console.log(`⚠️  Manual review needed: ${intensifier.name} -> ${arabicName}`);
        }
        
        // Generate aliases
        const aliases = generateArabicAliases(intensifier, arabicName);
        
        // Generate description (optional)
        const description = generateArabicDescription(intensifier);
        
        translationInserts.push({
          intensifier_id: intensifier.id,
          language: 'ar',
          name: arabicName,
          aliases: aliases,
          description: description,
          source: 'canonical_ar_v1',
        });
      }
      
      // Batch insert with conflict handling
      if (translationInserts.length > 0) {
        for (const trans of translationInserts) {
          try {
            await client.query(`
              INSERT INTO intensifier_translations (intensifier_id, language, name, aliases, description, source)
              VALUES ($1, $2, $3, $4, $5, $6)
              ON CONFLICT (intensifier_id, language) DO NOTHING
            `, [
              trans.intensifier_id,
              trans.language,
              trans.name,
              trans.aliases,
              trans.description,
              trans.source,
            ]);
            
            totalTranslations++;
          } catch (error) {
            console.error(`❌ Error inserting translation for ${trans.intensifier_id}:`, error.message);
            skipped++;
          }
        }
      }
      
      // Progress update
      if ((i + batchSize) % 50 === 0 || i + batchSize >= intensifiers.length) {
        console.log(`⏳ Processed ${Math.min(i + batchSize, intensifiers.length)}/${intensifiers.length} intensifiers (${totalTranslations} translations generated)`);
      }
    }
    
    // Final statistics
    console.log('\n📊 Final Statistics:');
    const statsResult = await client.query(`
      SELECT 
        COUNT(*) as total_translations,
        COUNT(DISTINCT intensifier_id) as intensifiers_translated,
        AVG(array_length(aliases, 1)) as avg_aliases_per_intensifier
      FROM intensifier_translations
      WHERE language = 'ar'
    `);
    
    console.table(statsResult.rows);
    
    console.log(`\n✅ Arabic translation generation complete!`);
    console.log(`   - Total translations generated: ${totalTranslations}`);
    console.log(`   - Skipped (already exists): ${skipped}`);
    console.log(`   - Flagged for manual review: ${manualReview}`);
    
    // Sample translations
    console.log('\n📝 Sample Translations:');
    const samplesResult = await client.query(`
      SELECT 
        ik.name as english_name,
        it.name as arabic_name,
        it.aliases
      FROM intensifier_translations it
      JOIN intensifier_knowledge ik ON ik.id = it.intensifier_id
      WHERE it.language = 'ar'
      LIMIT 5
    `);
    
    samplesResult.rows.forEach(row => {
      console.log(`\n   English: ${row.english_name}`);
      console.log(`   Arabic:  ${row.arabic_name}`);
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

module.exports = { generateArabicName, generateArabicAliases };
