#!/usr/bin/env node

/**
 * Generate Arabic Muscle Names & Translations
 * 
 * This script generates Arabic translations for all unique muscle keys
 * found in exercise_knowledge.primary_muscles and secondary_muscles.
 * 
 * Translation rules:
 * - Anatomically correct Arabic (MSA)
 * - Gym-friendly aliases
 * - Natural Arabic (not literal word-for-word)
 * - NO Google-translate style
 * 
 * Usage: node supabase/scripts/generate_arabic_muscle_names.js
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
// CANONICAL ARABIC MUSCLE MAPPING
// =====================================================

const muscleArabicMap = {
  // Chest
  'chest': {
    name: 'عضلات الصدر',
    aliases: ['الصدر', 'عضلة الصدر', 'صدر'],
    description: 'عضلات الصدر الرئيسية'
  },
  'pectorals': {
    name: 'عضلات الصدر',
    aliases: ['الصدر', 'عضلة الصدر', 'صدر'],
    description: 'عضلات الصدر الرئيسية'
  },
  'pectoralis_major': {
    name: 'العضلة الصدرية الكبرى',
    aliases: ['صدر علوي', 'الصدر الكبير', 'العضلة الصدرية'],
    description: 'العضلة الصدرية الرئيسية الكبرى'
  },
  'pectoralis_minor': {
    name: 'العضلة الصدرية الصغرى',
    aliases: ['صدر صغير', 'الصدر الصغير'],
    description: 'العضلة الصدرية الصغرى'
  },
  
  // Back
  'back': {
    name: 'عضلات الظهر',
    aliases: ['الظهر', 'عضلة الظهر'],
    description: 'عضلات الظهر الرئيسية'
  },
  'latissimus_dorsi': {
    name: 'العضلة الظهرية العريضة',
    aliases: ['اللات', 'عضلات الظهر الجانبية', 'اللاتس'],
    description: 'العضلة الظهرية العريضة (اللات)'
  },
  'lats': {
    name: 'العضلة الظهرية العريضة',
    aliases: ['اللات', 'عضلات الظهر الجانبية'],
    description: 'العضلة الظهرية العريضة'
  },
  'rhomboids': {
    name: 'العضلات المعينية',
    aliases: ['المعينات', 'عضلات المعين'],
    description: 'العضلات المعينية في الظهر'
  },
  'middle_trapezius': {
    name: 'الرأس الأوسط للشبه المنحرف',
    aliases: ['الترابيس الوسطى', 'وسط الترابيس'],
    description: 'الرأس الأوسط للعضلة شبه المنحرفة'
  },
  'lower_trapezius': {
    name: 'الرأس السفلي للشبه المنحرف',
    aliases: ['الترابيس السفلى', 'سفل الترابيس'],
    description: 'الرأس السفلي للعضلة شبه المنحرفة'
  },
  'upper_trapezius': {
    name: 'الرأس العلوي للشبه المنحرف',
    aliases: ['الترابيس العلوية', 'علو الترابيس'],
    description: 'الرأس العلوي للعضلة شبه المنحرفة'
  },
  'traps': {
    name: 'العضلة شبه المنحرفة',
    aliases: ['الترابيس', 'شبه المنحرف'],
    description: 'العضلة شبه المنحرفة'
  },
  'trapezius': {
    name: 'العضلة شبه المنحرفة',
    aliases: ['الترابيس', 'شبه المنحرف'],
    description: 'العضلة شبه المنحرفة'
  },
  'erector_spinae': {
    name: 'عضلات ناصبة الفقار',
    aliases: ['أسفل الظهر', 'القطنية', 'ناصبة الفقار'],
    description: 'عضلات ناصبة الفقار في أسفل الظهر'
  },
  
  // Shoulders
  'shoulders': {
    name: 'عضلات الكتف',
    aliases: ['الكتف', 'الأكتاف'],
    description: 'عضلات الكتف الرئيسية'
  },
  'deltoids': {
    name: 'عضلات الكتف',
    aliases: ['الكتف', 'الدالية'],
    description: 'عضلات الكتف (الدالية)'
  },
  'deltoid': {
    name: 'العضلة الدالية',
    aliases: ['الكتف', 'الدالية'],
    description: 'العضلة الدالية (الكتف)'
  },
  'anterior_deltoid': {
    name: 'الرأس الأمامي للكتف',
    aliases: ['كتف أمامي', 'الدالية الأمامية'],
    description: 'الرأس الأمامي للعضلة الدالية'
  },
  'front_delts': {
    name: 'الرأس الأمامي للكتف',
    aliases: ['كتف أمامي', 'الدالية الأمامية'],
    description: 'الرأس الأمامي للعضلة الدالية'
  },
  'medial_deltoid': {
    name: 'الرأس الجانبي للكتف',
    aliases: ['كتف جانبي', 'الدالية الجانبية'],
    description: 'الرأس الجانبي للعضلة الدالية'
  },
  'lateral_deltoid': {
    name: 'الرأس الجانبي للكتف',
    aliases: ['كتف جانبي', 'الدالية الجانبية'],
    description: 'الرأس الجانبي للعضلة الدالية'
  },
  'side_delts': {
    name: 'الرأس الجانبي للكتف',
    aliases: ['كتف جانبي', 'الدالية الجانبية'],
    description: 'الرأس الجانبي للعضلة الدالية'
  },
  'posterior_deltoid': {
    name: 'الرأس الخلفي للكتف',
    aliases: ['كتف خلفي', 'الدالية الخلفية'],
    description: 'الرأس الخلفي للعضلة الدالية'
  },
  'rear_delts': {
    name: 'الرأس الخلفي للكتف',
    aliases: ['كتف خلفي', 'الدالية الخلفية'],
    description: 'الرأس الخلفي للعضلة الدالية'
  },
  
  // Arms
  'arms': {
    name: 'عضلات الذراعين',
    aliases: ['الذراعين', 'الأذرع'],
    description: 'عضلات الذراعين'
  },
  'biceps': {
    name: 'العضلة ذات الرأسين',
    aliases: ['البايسبس', 'العضلة الأمامية'],
    description: 'العضلة ذات الرأسين في الذراع'
  },
  'biceps_brachii': {
    name: 'العضلة ذات الرأسين العضدية',
    aliases: ['البايسبس', 'العضلة الأمامية', 'ذات الرأسين'],
    description: 'العضلة ذات الرأسين العضدية'
  },
  'brachialis': {
    name: 'العضلة العضدية',
    aliases: ['العضدية', 'عضلة العضد'],
    description: 'العضلة العضدية في الذراع'
  },
  'brachioradialis': {
    name: 'العضلة العضدية الكعبرية',
    aliases: ['الكعبرية', 'عضلة الساعد'],
    description: 'العضلة العضدية الكعبرية في الساعد'
  },
  'triceps': {
    name: 'العضلة ثلاثية الرؤوس',
    aliases: ['الترايسبس', 'العضلة الخلفية'],
    description: 'العضلة ثلاثية الرؤوس في الذراع'
  },
  'triceps_brachii': {
    name: 'العضلة ثلاثية الرؤوس العضدية',
    aliases: ['الترايسبس', 'العضلة الخلفية', 'ثلاثية الرؤوس'],
    description: 'العضلة ثلاثية الرؤوس العضدية'
  },
  'anconeus': {
    name: 'العضلة المرفقية',
    aliases: ['المرفقية'],
    description: 'العضلة المرفقية الصغيرة'
  },
  'forearms': {
    name: 'عضلات الساعد',
    aliases: ['الساعد', 'السواعد'],
    description: 'عضلات الساعد'
  },
  'flexor_carpi': {
    name: 'عضلات قابضة الرسغ',
    aliases: ['قابضة الرسغ'],
    description: 'عضلات قابضة الرسغ'
  },
  'extensor_carpi': {
    name: 'عضلات باسطة الرسغ',
    aliases: ['باسطة الرسغ'],
    description: 'عضلات باسطة الرسغ'
  },
  'pronator_teres': {
    name: 'العضلة الكابة المدورة',
    aliases: ['الكابة المدورة'],
    description: 'العضلة الكابة المدورة'
  },
  
  // Legs
  'legs': {
    name: 'عضلات الأرجل',
    aliases: ['الأرجل', 'الساقين'],
    description: 'عضلات الأرجل'
  },
  'quadriceps': {
    name: 'العضلة رباعية الرؤوس',
    aliases: ['الفخذ الأمامي', 'الكوادر', 'الرباعية'],
    description: 'العضلة رباعية الرؤوس في الفخذ'
  },
  'quads': {
    name: 'العضلة رباعية الرؤوس',
    aliases: ['الفخذ الأمامي', 'الكوادر', 'الرباعية'],
    description: 'العضلة رباعية الرؤوس'
  },
  'rectus_femoris': {
    name: 'العضلة المستقيمة الفخذية',
    aliases: ['المستقيمة الفخذية', 'عضلة الفخذ المستقيمة'],
    description: 'العضلة المستقيمة الفخذية'
  },
  'vastus_lateralis': {
    name: 'العضلة الوحشية الواسعة',
    aliases: ['الوحشية الواسعة', 'عضلة الفخذ الخارجية'],
    description: 'العضلة الوحشية الواسعة في الفخذ'
  },
  'vastus_medialis': {
    name: 'العضلة الإنسية الواسعة',
    aliases: ['الإنسية الواسعة', 'عضلة الفخذ الداخلية'],
    description: 'العضلة الإنسية الواسعة في الفخذ'
  },
  'vastus_intermedius': {
    name: 'العضلة المتوسطة الواسعة',
    aliases: ['المتوسطة الواسعة'],
    description: 'العضلة المتوسطة الواسعة في الفخذ'
  },
  'hamstrings': {
    name: 'العضلات الخلفية للفخذ',
    aliases: ['الفخذ الخلفي', 'أوتار الركبة'],
    description: 'العضلات الخلفية للفخذ'
  },
  'biceps_femoris': {
    name: 'العضلة ذات الرأسين الفخذية',
    aliases: ['ذات الرأسين الفخذية', 'عضلة الفخذ الخلفية'],
    description: 'العضلة ذات الرأسين الفخذية'
  },
  'semitendinosus': {
    name: 'العضلة النصف وترية',
    aliases: ['النصف وترية'],
    description: 'العضلة النصف وترية في الفخذ'
  },
  'semimembranosus': {
    name: 'العضلة النصف غشائية',
    aliases: ['النصف غشائية'],
    description: 'العضلة النصف غشائية في الفخذ'
  },
  'glutes': {
    name: 'عضلات الألوية',
    aliases: ['الأرداف', 'الغلوت'],
    description: 'عضلات الألوية (الأرداف)'
  },
  'gluteus_maximus': {
    name: 'العضلة الألوية الكبرى',
    aliases: ['الأرداف', 'الغلوت الكبير'],
    description: 'العضلة الألوية الكبرى'
  },
  'gluteus_medius': {
    name: 'العضلة الألوية الوسطى',
    aliases: ['الأرداف الوسطى', 'الغلوت الأوسط'],
    description: 'العضلة الألوية الوسطى'
  },
  'gluteus_minimus': {
    name: 'العضلة الألوية الصغرى',
    aliases: ['الأرداف الصغرى', 'الغلوت الصغير'],
    description: 'العضلة الألوية الصغرى'
  },
  'calves': {
    name: 'عضلات الساق',
    aliases: ['بطات', 'سمانة', 'الساق'],
    description: 'عضلات الساق الخلفية'
  },
  'gastrocnemius': {
    name: 'العضلة التوأمية',
    aliases: ['التوأمية', 'عضلة الساق الخارجية'],
    description: 'العضلة التوأمية في الساق'
  },
  'soleus': {
    name: 'العضلة النعلية',
    aliases: ['النعلية', 'عضلة الساق الداخلية'],
    description: 'العضلة النعلية في الساق'
  },
  
  // Core
  'core': {
    name: 'عضلات البطن',
    aliases: ['البطن', 'الكور', 'الجذع'],
    description: 'عضلات البطن والجذع'
  },
  'abs': {
    name: 'عضلات البطن',
    aliases: ['البطن', 'الكرش'],
    description: 'عضلات البطن'
  },
  'abdominals': {
    name: 'عضلات البطن',
    aliases: ['البطن', 'الكرش'],
    description: 'عضلات البطن'
  },
  'rectus_abdominis': {
    name: 'العضلة المستقيمة البطنية',
    aliases: ['المستقيمة البطنية', 'عضلة البطن المستقيمة'],
    description: 'العضلة المستقيمة البطنية'
  },
  'transverse_abdominis': {
    name: 'العضلة المستعرضة البطنية',
    aliases: ['المستعرضة البطنية'],
    description: 'العضلة المستعرضة البطنية'
  },
  'obliques': {
    name: 'العضلات المائلة',
    aliases: ['المائلة', 'عضلات البطن الجانبية'],
    description: 'العضلات المائلة في البطن'
  },
  
  // Other
  'upper_chest': {
    name: 'الصدر العلوي',
    aliases: ['صدر علوي', 'الصدر الأعلى'],
    description: 'الصدر العلوي'
  },
  'lower_chest': {
    name: 'الصدر السفلي',
    aliases: ['صدر سفلي', 'الصدر الأسفل'],
    description: 'الصدر السفلي'
  }
};

/**
 * Get Arabic translation for a muscle key
 */
function getArabicTranslation(muscleKey) {
  const normalized = muscleKey.toLowerCase().trim();
  
  // Direct match
  if (muscleArabicMap[normalized]) {
    return muscleArabicMap[normalized];
  }
  
  // Try with underscores replaced
  const withUnderscores = normalized.replace(/\s+/g, '_');
  if (muscleArabicMap[withUnderscores]) {
    return muscleArabicMap[withUnderscores];
  }
  
  // Try with spaces replaced
  const withSpaces = normalized.replace(/_/g, ' ');
  if (muscleArabicMap[withSpaces]) {
    return muscleArabicMap[withSpaces];
  }
  
  // Partial match (for compound keys)
  for (const [key, value] of Object.entries(muscleArabicMap)) {
    if (normalized.includes(key) || key.includes(normalized)) {
      return value;
    }
  }
  
  // Fallback: generate from key
  return {
    name: normalized, // Will be flagged for manual review
    aliases: [],
    description: `ترجمة لـ ${normalized}`
  };
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
    
    // Step 1: Collect all unique muscle keys from exercise_knowledge
    console.log('📖 Collecting unique muscle keys from exercise_knowledge...');
    const muscleKeysResult = await client.query(`
      SELECT DISTINCT unnest(primary_muscles || secondary_muscles) as muscle_key
      FROM exercise_knowledge
      WHERE primary_muscles IS NOT NULL 
        OR secondary_muscles IS NOT NULL
      ORDER BY muscle_key
    `);
    
    const allMuscleKeys = muscleKeysResult.rows
      .map(row => row.muscle_key)
      .filter(key => key && key.trim().length > 0)
      .map(key => key.trim().toLowerCase());
    
    const uniqueMuscleKeys = [...new Set(allMuscleKeys)];
    console.log(`📊 Found ${uniqueMuscleKeys.length} unique muscle keys`);
    
    // Step 2: Check existing translations
    const existingResult = await client.query(`
      SELECT muscle_key, COUNT(*) as count
      FROM muscle_translations
      WHERE language = 'ar'
      GROUP BY muscle_key
    `);
    const existingKeys = new Set(existingResult.rows.map(row => row.muscle_key.toLowerCase()));
    console.log(`📊 Existing Arabic translations: ${existingKeys.size}`);
    
    // Step 3: Generate and insert translations
    let totalInserted = 0;
    let totalUpdated = 0;
    let skipped = 0;
    let manualReview = 0;
    
    for (const muscleKey of uniqueMuscleKeys) {
      try {
        const translation = getArabicTranslation(muscleKey);
        
        // Flag for manual review if name wasn't translated (still English/Latin)
        if (translation.name === muscleKey || 
            translation.name.length < 3 ||
            !/[ء-ي]/.test(translation.name)) {
          manualReview++;
          console.log(`⚠️  Manual review needed: ${muscleKey} -> ${translation.name}`);
        }
        
        // Insert or update
        const result = await client.query(`
          INSERT INTO muscle_translations (muscle_key, language, name, aliases, description, source)
          VALUES ($1, $2, $3, $4, $5, $6)
          ON CONFLICT (muscle_key, language) 
          DO UPDATE SET
            name = EXCLUDED.name,
            aliases = EXCLUDED.aliases,
            description = EXCLUDED.description,
            updated_at = NOW()
          RETURNING (xmax = 0) AS inserted
        `, [
          muscleKey,
          'ar',
          translation.name,
          translation.aliases || [],
          translation.description || null,
          'canonical_ar_v1'
        ]);
        
        if (result.rows[0].inserted) {
          totalInserted++;
        } else {
          totalUpdated++;
        }
      } catch (error) {
        console.error(`❌ Error processing ${muscleKey}:`, error.message);
        skipped++;
      }
    }
    
    // Final statistics
    console.log('\n📊 Final Statistics:');
    const statsResult = await client.query(`
      SELECT 
        COUNT(*) as total_translations,
        COUNT(DISTINCT muscle_key) as unique_muscles,
        AVG(array_length(aliases, 1)) as avg_aliases_per_muscle
      FROM muscle_translations
      WHERE language = 'ar'
    `);
    
    console.table(statsResult.rows);
    
    console.log(`\n✅ Arabic muscle translation generation complete!`);
    console.log(`   - Total inserted: ${totalInserted}`);
    console.log(`   - Total updated: ${totalUpdated}`);
    console.log(`   - Skipped (errors): ${skipped}`);
    console.log(`   - Flagged for manual review: ${manualReview}`);
    
    // Sample translations
    console.log('\n📝 Sample Translations:');
    const samplesResult = await client.query(`
      SELECT 
        muscle_key,
        name,
        aliases,
        description
      FROM muscle_translations
      WHERE language = 'ar'
      ORDER BY muscle_key
      LIMIT 10
    `);
    
    samplesResult.rows.forEach(row => {
      console.log(`\n   Key: ${row.muscle_key}`);
      console.log(`   Arabic: ${row.name}`);
      console.log(`   Aliases: ${row.aliases.join(', ')}`);
      if (row.description) {
        console.log(`   Description: ${row.description}`);
      }
    });
    
    // Coverage report
    console.log('\n📈 Coverage Report:');
    const coverageResult = await client.query(`
      SELECT 
        (SELECT COUNT(DISTINCT unnest(primary_muscles || secondary_muscles)) 
         FROM exercise_knowledge 
         WHERE primary_muscles IS NOT NULL OR secondary_muscles IS NOT NULL) as total_muscle_keys,
        (SELECT COUNT(DISTINCT muscle_key) FROM muscle_translations WHERE language = 'ar') as translated_keys
    `);
    
    const coverage = coverageResult.rows[0];
    const coveragePercent = coverage.total_muscle_keys > 0 
      ? ((coverage.translated_keys / coverage.total_muscle_keys) * 100).toFixed(1)
      : 0;
    
    console.log(`   Total unique muscle keys in exercises: ${coverage.total_muscle_keys}`);
    console.log(`   Translated muscle keys: ${coverage.translated_keys}`);
    console.log(`   Coverage: ${coveragePercent}%`);
    
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

module.exports = { getArabicTranslation, muscleArabicMap };
