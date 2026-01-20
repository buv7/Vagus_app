#!/usr/bin/env node

/**
 * Generate Arabic Muscle Aliases
 * 
 * This script generates Arabic aliases for all unique muscle keys
 * found in exercise_knowledge.primary_muscles and secondary_muscles.
 * 
 * Each muscle gets 4-8 Arabic aliases including:
 * - Formal anatomical Arabic
 * - Common gym Arabic
 * - Short slang
 * - English-Arabic hybrid
 * 
 * Usage: node supabase/scripts/generate_arabic_muscle_aliases.js
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
// CANONICAL ARABIC MUSCLE ALIAS MAPPING
// =====================================================

const muscleAliasMap = {
  // Chest
  'pectoralis_major': [
    'العضلة الصدرية الكبرى',
    'عضلة الصدر',
    'صدر',
    'عضلات الصدر',
    'بيك',
    'Chest',
    'الصدر الكبير'
  ],
  'pectoralis_minor': [
    'العضلة الصدرية الصغرى',
    'صدر صغير',
    'الصدر الصغير',
    'عضلة الصدر الصغيرة'
  ],
  'chest': [
    'الصدر',
    'عضلة الصدر',
    'صدر',
    'عضلات الصدر',
    'Chest'
  ],
  'pectorals': [
    'عضلات الصدر',
    'الصدر',
    'صدر',
    'Pectorals'
  ],
  'upper_chest': [
    'الصدر العلوي',
    'صدر علوي',
    'الصدر الأعلى',
    'Upper Chest'
  ],
  'lower_chest': [
    'الصدر السفلي',
    'صدر سفلي',
    'الصدر الأسفل',
    'Lower Chest'
  ],

  // Back
  'latissimus_dorsi': [
    'العضلة الظهرية العريضة',
    'عضلة الظهر',
    'الظهر',
    'لات',
    'لاتس',
    'Lats',
    'اللات'
  ],
  'lats': [
    'اللات',
    'عضلات الظهر الجانبية',
    'اللاتس',
    'Lats'
  ],
  'rhomboids': [
    'العضلات المعينية',
    'المعينات',
    'عضلات المعين',
    'Rhomboids'
  ],
  'trapezius': [
    'العضلة شبه المنحرفة',
    'الترابيس',
    'شبه المنحرف',
    'Traps',
    'Trapezius'
  ],
  'traps': [
    'الترابيس',
    'شبه المنحرف',
    'العضلة شبه المنحرفة',
    'Traps'
  ],
  'upper_trapezius': [
    'الرأس العلوي للشبه المنحرف',
    'الترابيس العلوية',
    'علو الترابيس',
    'Upper Traps'
  ],
  'middle_trapezius': [
    'الرأس الأوسط للشبه المنحرف',
    'الترابيس الوسطى',
    'وسط الترابيس',
    'Middle Traps'
  ],
  'lower_trapezius': [
    'الرأس السفلي للشبه المنحرف',
    'الترابيس السفلى',
    'سفل الترابيس',
    'Lower Traps'
  ],
  'erector_spinae': [
    'العضلات القابضة للعمود الفقري',
    'عضلات الظهر السفلي',
    'أسفل الظهر',
    'Erector Spinae'
  ],
  'back': [
    'الظهر',
    'عضلة الظهر',
    'عضلات الظهر',
    'Back'
  ],

  // Shoulders
  'deltoid': [
    'العضلة الدالية',
    'الكتف',
    'دالية',
    'Deltoid',
    'Delts'
  ],
  'deltoid_anterior': [
    'العضلة الدالية الأمامية',
    'كتف أمامي',
    'الكتف الأمامي',
    'دالية أمامية',
    'Front Delts',
    'Anterior Deltoid'
  ],
  'deltoid_lateral': [
    'العضلة الدالية الجانبية',
    'كتف جانبي',
    'الكتف الجانبي',
    'دالية جانبية',
    'Lateral Delts',
    'Side Delts'
  ],
  'deltoid_posterior': [
    'العضلة الدالية الخلفية',
    'كتف خلفي',
    'الكتف الخلفي',
    'دالية خلفية',
    'Rear Delts',
    'Posterior Deltoid'
  ],
  'delts': [
    'الدالية',
    'الكتف',
    'Delts'
  ],
  'shoulders': [
    'الأكتاف',
    'الكتف',
    'Shoulders'
  ],

  // Arms
  'biceps_brachii': [
    'العضلة ذات الرأسين',
    'بايسبس',
    'عضلة الباي',
    'عضلة الذراع الأمامية',
    'Biceps',
    'الباي'
  ],
  'biceps': [
    'البايسبس',
    'الباي',
    'عضلة الباي',
    'Biceps'
  ],
  'triceps_brachii': [
    'العضلة ثلاثية الرؤوس',
    'ترايسبس',
    'عضلة الذراع الخلفية',
    'خلف الذراع',
    'Triceps',
    'التراي'
  ],
  'triceps': [
    'الترايسبس',
    'التراي',
    'عضلة التراي',
    'Triceps'
  ],
  'forearms': [
    'عضلات الساعد',
    'الساعد',
    'السواعد',
    'Forearms'
  ],
  'brachialis': [
    'العضلة العضدية',
    'عضلة العضد',
    'Brachialis'
  ],
  'brachioradialis': [
    'العضلة العضدية الكعبرية',
    'العضدية الكعبرية',
    'Brachioradialis'
  ],

  // Legs
  'quadriceps': [
    'العضلة رباعية الرؤوس',
    'عضلة الفخذ الأمامية',
    'فخذ أمامي',
    'كواد',
    'Quads',
    'الرباعية'
  ],
  'quads': [
    'الكواد',
    'الرباعية',
    'الفخذ الأمامي',
    'Quads'
  ],
  'hamstrings': [
    'عضلات الفخذ الخلفية',
    'فخذ خلفي',
    'هامسترنغ',
    'عضلة الرجل الخلفية',
    'Hamstrings',
    'أوتار الركبة'
  ],
  'gluteus_maximus': [
    'العضلة الألوية الكبرى',
    'الأرداف',
    'الغلوت الكبير',
    'Gluteus Maximus',
    'Glutes'
  ],
  'glutes': [
    'الأرداف',
    'الغلوت',
    'عضلات الألوية',
    'Glutes'
  ],
  'gluteus_medius': [
    'العضلة الألوية الوسطى',
    'الأرداف الوسطى',
    'الغلوت الأوسط',
    'Gluteus Medius'
  ],
  'gluteus_minimus': [
    'العضلة الألوية الصغرى',
    'الأرداف الصغرى',
    'الغلوت الصغير',
    'Gluteus Minimus'
  ],
  'gastrocnemius': [
    'العضلة التوأمية',
    'التوأمية',
    'عضلة الساق الخارجية',
    'Gastrocnemius',
    'Calf'
  ],
  'soleus': [
    'العضلة النعلية',
    'النعلية',
    'عضلة الساق الداخلية',
    'Soleus'
  ],
  'calves': [
    'عضلات الساق',
    'بطات',
    'سمانة',
    'الساق',
    'Calves'
  ],
  'rectus_femoris': [
    'العضلة المستقيمة الفخذية',
    'المستقيمة الفخذية',
    'عضلة الفخذ المستقيمة',
    'Rectus Femoris'
  ],
  'vastus_lateralis': [
    'العضلة الوحشية الواسعة',
    'الوحشية الواسعة',
    'عضلة الفخذ الخارجية',
    'Vastus Lateralis'
  ],
  'vastus_medialis': [
    'العضلة الإنسية الواسعة',
    'الإنسية الواسعة',
    'عضلة الفخذ الداخلية',
    'Vastus Medialis'
  ],
  'biceps_femoris': [
    'العضلة ذات الرأسين الفخذية',
    'ذات الرأسين الفخذية',
    'عضلة الفخذ الخلفية',
    'Biceps Femoris'
  ],

  // Core
  'rectus_abdominis': [
    'العضلة المستقيمة البطنية',
    'المستقيمة البطنية',
    'عضلة البطن المستقيمة',
    'Rectus Abdominis',
    'Abs'
  ],
  'abs': [
    'عضلات البطن',
    'البطن',
    'الكرش',
    'Abs'
  ],
  'abdominals': [
    'عضلات البطن',
    'البطن',
    'الكرش',
    'Abdominals'
  ],
  'obliques': [
    'العضلات المائلة',
    'المائلة',
    'عضلات البطن الجانبية',
    'Obliques'
  ],
  'transverse_abdominis': [
    'العضلة المستعرضة البطنية',
    'المستعرضة البطنية',
    'Transverse Abdominis'
  ],
  'core': [
    'عضلات البطن',
    'البطن',
    'الكور',
    'الجذع',
    'Core'
  ],

  // Other
  'legs': [
    'الأرجل',
    'الساقين',
    'Legs'
  ],
  'arms': [
    'الأذرع',
    'الذراعين',
    'Arms'
  ]
};

/**
 * Get Arabic aliases for a muscle key
 * Returns array of 4-8 aliases
 */
function getArabicAliases(muscleKey) {
  const normalized = muscleKey.toLowerCase().trim();
  
  // Direct match
  if (muscleAliasMap[normalized]) {
    return muscleAliasMap[normalized];
  }
  
  // Try with underscores replaced
  const withUnderscores = normalized.replace(/\s+/g, '_');
  if (muscleAliasMap[withUnderscores]) {
    return muscleAliasMap[withUnderscores];
  }
  
  // Try with spaces replaced
  const withSpaces = normalized.replace(/_/g, ' ');
  if (muscleAliasMap[withSpaces]) {
    return muscleAliasMap[withSpaces];
  }
  
  // Partial match (for compound keys)
  for (const [key, aliases] of Object.entries(muscleAliasMap)) {
    if (normalized.includes(key) || key.includes(normalized)) {
      return aliases;
    }
  }
  
  // Fallback: generate basic aliases
  return [
    normalized, // Keep original as fallback
    `عضلة ${normalized}`,
    normalized.replace(/_/g, ' ')
  ];
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
      WHERE (primary_muscles IS NOT NULL AND array_length(primary_muscles, 1) > 0)
         OR (secondary_muscles IS NOT NULL AND array_length(secondary_muscles, 1) > 0)
      ORDER BY muscle_key
    `);
    
    const allMuscleKeys = muscleKeysResult.rows
      .map(row => row.muscle_key)
      .filter(key => key && key.trim().length > 0)
      .map(key => key.trim().toLowerCase());
    
    const uniqueMuscleKeys = [...new Set(allMuscleKeys)];
    console.log(`📊 Found ${uniqueMuscleKeys.length} unique muscle keys`);
    
    if (uniqueMuscleKeys.length === 0) {
      console.log('⚠️  No muscle keys found. Make sure exercise_knowledge has data.');
      return;
    }
    
    // Step 2: Check existing aliases
    const existingResult = await client.query(`
      SELECT muscle_key, COUNT(*) as alias_count
      FROM muscle_aliases
      WHERE language = 'ar'
      GROUP BY muscle_key
    `);
    const existingCounts = new Map(
      existingResult.rows.map(row => [row.muscle_key.toLowerCase(), parseInt(row.alias_count)])
    );
    console.log(`📊 Existing Arabic aliases: ${existingCounts.size} muscles`);
    
    // Step 3: Generate and insert aliases
    let totalInserted = 0;
    let totalSkipped = 0;
    let totalAliases = 0;
    const aliasStats = [];
    
    for (const muscleKey of uniqueMuscleKeys) {
      try {
        const aliases = getArabicAliases(muscleKey);
        
        if (!aliases || aliases.length === 0) {
          console.log(`⚠️  No aliases generated for: ${muscleKey}`);
          totalSkipped++;
          continue;
        }
        
        let insertedForMuscle = 0;
        
        for (const alias of aliases) {
          if (!alias || alias.trim().length === 0) continue;
          
          try {
            const result = await client.query(`
              INSERT INTO muscle_aliases (muscle_key, language, alias, source)
              VALUES ($1, $2, $3, $4)
              ON CONFLICT (muscle_key, language, alias) DO NOTHING
              RETURNING id
            `, [
              muscleKey,
              'ar',
              alias.trim(),
              'canonical_ar_muscle_alias_v1'
            ]);
            
            if (result.rows.length > 0) {
              insertedForMuscle++;
              totalInserted++;
            }
          } catch (error) {
            // Skip duplicate or invalid aliases
            if (!error.message.includes('duplicate') && !error.message.includes('unique')) {
              console.error(`❌ Error inserting alias "${alias}" for ${muscleKey}:`, error.message);
            }
          }
        }
        
        totalAliases += aliases.length;
        aliasStats.push({
          muscle_key: muscleKey,
          alias_count: insertedForMuscle,
          total_aliases: aliases.length
        });
        
        if (insertedForMuscle > 0) {
          console.log(`✅ ${muscleKey}: ${insertedForMuscle}/${aliases.length} aliases inserted`);
        }
      } catch (error) {
        console.error(`❌ Error processing ${muscleKey}:`, error.message);
        totalSkipped++;
      }
    }
    
    // Final statistics
    console.log('\n📊 Final Statistics:');
    const statsResult = await client.query(`
      SELECT 
        COUNT(*) as total_aliases,
        COUNT(DISTINCT muscle_key) as unique_muscles,
        MIN(alias_count) as min_aliases_per_muscle,
        MAX(alias_count) as max_aliases_per_muscle,
        ROUND(AVG(alias_count), 2) as avg_aliases_per_muscle
      FROM (
        SELECT muscle_key, COUNT(*) as alias_count
        FROM muscle_aliases
        WHERE language = 'ar'
        GROUP BY muscle_key
      ) subq
    `);
    
    console.table(statsResult.rows);
    
    // Show top 5 muscles with most aliases
    console.log('\n🏆 Top 5 muscles by alias count:');
    const topMusclesResult = await client.query(`
      SELECT muscle_key, COUNT(*) as alias_count, 
             ARRAY_AGG(alias ORDER BY alias) as aliases
      FROM muscle_aliases
      WHERE language = 'ar'
      GROUP BY muscle_key
      ORDER BY alias_count DESC
      LIMIT 5
    `);
    
    topMusclesResult.rows.forEach((row, idx) => {
      console.log(`\n${idx + 1}. ${row.muscle_key} (${row.alias_count} aliases):`);
      console.log(`   ${row.aliases.slice(0, 5).join(', ')}${row.aliases.length > 5 ? '...' : ''}`);
    });
    
    console.log(`\n✅ Arabic muscle alias generation complete!`);
    console.log(`   - Total aliases inserted: ${totalInserted}`);
    console.log(`   - Total aliases attempted: ${totalAliases}`);
    console.log(`   - Muscles processed: ${uniqueMuscleKeys.length}`);
    console.log(`   - Muscles skipped: ${totalSkipped}`);
    
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
  main();
}

module.exports = { getArabicAliases, main };
