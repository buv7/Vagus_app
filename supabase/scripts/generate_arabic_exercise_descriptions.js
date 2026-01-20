#!/usr/bin/env node

/**
 * Generate Arabic Exercise Descriptions (Full)
 * 
 * This script generates complete Arabic translations for all exercises in exercise_knowledge:
 * - Arabic name (using existing logic)
 * - short_desc: Short description in Arabic
 * - how_to: Step-by-step instructions in Arabic
 * - cues: Coaching cues array in Arabic
 * - common_mistakes: Common mistakes array in Arabic
 * 
 * Translation rules:
 * - Medical-correct
 * - Coach-usable
 * - Gym-friendly (Modern Standard Arabic, Iraqi-understandable)
 * - NOT slang, NOT academic-only, NOT Google-translated
 * - Natural Arabic (MSA + common gym terms)
 * 
 * Usage: node supabase/scripts/generate_arabic_exercise_descriptions.js
 */

const { Client } = require('pg');
const { generateArabicName, generateArabicAliases } = require('./generate_arabic_exercise_names');

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
// ARABIC TRANSLATION DICTIONARY (Extended)
// =====================================================

// Equipment translations (gym Arabic)
const equipmentArDict = {
  'barbell': 'هالتر',
  'dumbbell': 'دمبل',
  'dumbbells': 'دمبل',
  'cable': 'كابل',
  'cables': 'كابل',
  'machine': 'آلة',
  'kettlebell': 'كيتل بيل',
  'bodyweight': 'وزن الجسم',
  'resistance band': 'شريط مقاومة',
  'smith machine': 'آلة سميث',
  'bench': 'مقعد',
  'incline bench': 'مقعد مائل',
  'decline bench': 'مقعد منحدر',
};

// Muscle groups (gym Arabic)
const muscleArDict = {
  'chest': 'صدر',
  'pectorals': 'صدر',
  'pectoralis major': 'صدر',
  'pectoralis minor': 'صدر',
  'back': 'ظهر',
  'latissimus dorsi': 'ظهر',
  'lats': 'ظهر',
  'shoulders': 'كتف',
  'deltoids': 'كتف',
  'deltoid': 'كتف',
  'anterior deltoid': 'كتف أمامي',
  'posterior deltoid': 'كتف خلفي',
  'biceps': 'عضلة ذات الرأسين',
  'biceps brachii': 'عضلة ذات الرأسين',
  'triceps': 'عضلة ثلاثية الرؤوس',
  'triceps brachii': 'عضلة ثلاثية الرؤوس',
  'legs': 'أرجل',
  'quadriceps': 'رباعية الرؤوس',
  'quads': 'رباعية الرؤوس',
  'hamstrings': 'أوتار الركبة',
  'glutes': 'أرداف',
  'gluteus maximus': 'أرداف',
  'calves': 'سمانة',
  'abs': 'بطن',
  'abdominals': 'بطن',
  'core': 'بطن',
};

// Movement patterns (gym Arabic)
const movementArDict = {
  'press': 'ضغط',
  'fly': 'رفرفة',
  'flyes': 'رفرفة',
  'curl': 'رفع',
  'raise': 'رفع',
  'extension': 'تمديد',
  'row': 'سحب',
  'pull': 'سحب',
  'push': 'دفع',
  'squat': 'سكوات',
  'lunge': 'اندفاع',
  'deadlift': 'رفعة مميتة',
  'crunch': 'تمرين البطن',
  'plank': 'لوح',
  'dip': 'غطس',
  'pull-up': 'سحب',
  'chin-up': 'سحب',
  'pulldown': 'سحب للأسفل',
  'push-up': 'ضغط',
};

// Common phrases for descriptions
const descriptionPhrases = {
  'targeting': 'يستهدف',
  'strengthening': 'تقوية',
  'building': 'بناء',
  'developing': 'تطوير',
  'compound': 'مركب',
  'isolation': 'عزل',
  'exercise': 'تمرين',
  'movement': 'حركة',
  'muscle': 'عضلة',
  'muscles': 'عضلات',
  'with control': 'بتحكم',
  'full range of motion': 'مدى حركة كامل',
  'explosively': 'باندفاع',
  'slowly': 'ببطء',
  'maintain': 'حافظ على',
  'keep': 'احتفظ بـ',
  'engage': 'شد',
  'tight': 'مشدود',
  'core': 'الجذع',
  'back': 'الظهر',
  'shoulders': 'الكتفين',
  'chest': 'الصدر',
};

// Common cue translations
const cueTranslations = {
  'keep core engaged': 'شدّ الجذع',
  'control the weight': 'تحكّم في الوزن',
  'full range of motion': 'مدى حركة كامل',
  'drive through heels': 'ادفع من الكعبين',
  'control descent': 'تحكم في النزول',
  'full extension': 'تمديد كامل',
  'keep back straight': 'حافظ على استقامة الظهر',
  'squeeze at top': 'اضغط في الأعلى',
  'slow and controlled': 'بطيء ومتحكم',
  'breathe out on exertion': 'ازفر عند الدفع',
  'keep shoulders back': 'ثبت الكتفين للخلف',
  'engage glutes': 'شد الأرداف',
};

// Common mistake translations
const mistakeTranslations = {
  'arching back excessively': 'تقوّس أسفل الظهر بشكل مبالغ',
  'flaring elbows': 'فتح المرفقين أكثر من اللازم',
  'bouncing weight': 'ارتداد الوزن',
  'too steep angle': 'زاوية شديدة الانحدار',
  'bouncing': 'ارتداد',
  'using momentum': 'استخدام الزخم',
  'rounding back': 'تقوّس الظهر',
  'knees caving in': 'انحناء الركبتين للداخل',
  'lifting heels': 'رفع الكعبين',
  'not going deep enough': 'عدم النزول بعمق كافٍ',
  'using too much weight': 'استخدام وزن زائد',
  'not controlling the negative': 'عدم التحكم في النزول',
};

/**
 * Generate Arabic short description
 */
function generateArabicShortDesc(exercise) {
  const name = exercise.name.toLowerCase();
  const primaryMuscles = (exercise.primary_muscles || []).map(m => m.toLowerCase());
  const movementPattern = (exercise.movement_pattern || '').toLowerCase();
  const equipment = (exercise.equipment || []).map(eq => eq.toLowerCase());
  
  // Extract primary muscle in Arabic
  let muscleAr = '';
  for (const m of primaryMuscles) {
    for (const [pattern, arabic] of Object.entries(muscleArDict)) {
      if (m.includes(pattern)) {
        muscleAr = arabic;
        break;
      }
    }
    if (muscleAr) break;
  }
  
  // Extract movement in Arabic
  let movementAr = '';
  for (const [pattern, arabic] of Object.entries(movementArDict)) {
    if (name.includes(pattern) || movementPattern.includes(pattern)) {
      movementAr = arabic;
      break;
    }
  }
  
  // Extract equipment in Arabic
  let equipmentAr = '';
  for (const eq of equipment) {
    if (equipmentArDict[eq]) {
      equipmentAr = equipmentArDict[eq];
      break;
    }
  }
  
  // Build description
  const parts = [];
  
  if (equipmentAr && movementAr && muscleAr) {
    // Pattern: "تمرين [equipment] [movement] يستهدف [muscle]"
    parts.push(`تمرين ${equipmentAr} ${movementAr} يستهدف ${muscleAr}`);
  } else if (movementAr && muscleAr) {
    // Pattern: "تمرين [movement] لتقوية [muscle]"
    parts.push(`تمرين ${movementAr} لتقوية ${muscleAr}`);
  } else if (muscleAr) {
    // Pattern: "تمرين لتقوية [muscle]"
    parts.push(`تمرين لتقوية ${muscleAr}`);
  } else {
    // Fallback: generic description
    parts.push('تمرين لتقوية العضلات');
  }
  
  // Add secondary muscles if mentioned
  const secondaryMuscles = (exercise.secondary_muscles || []).map(m => m.toLowerCase());
  if (secondaryMuscles.length > 0) {
    const secMuscleAr = [];
    for (const m of secondaryMuscles.slice(0, 2)) { // Limit to 2
      for (const [pattern, arabic] of Object.entries(muscleArDict)) {
        if (m.includes(pattern)) {
          secMuscleAr.push(arabic);
          break;
        }
      }
    }
    if (secMuscleAr.length > 0) {
      parts.push(`مع إشراك ${secMuscleAr.join(' و')}`);
    }
  }
  
  return parts.join('. ') + '.';
}

/**
 * Generate Arabic how-to instructions
 */
function generateArabicHowTo(exercise) {
  const name = exercise.name.toLowerCase();
  const equipment = (exercise.equipment || []).map(eq => eq.toLowerCase());
  const movementPattern = (exercise.movement_pattern || '').toLowerCase();
  
  const steps = [];
  
  // Step 1: Setup/Position
  if (name.includes('bench') || equipment.includes('bench')) {
    if (name.includes('incline')) {
      steps.push('اضبط المقعد بزاوية 30-45 درجة');
      steps.push('استلقِ على المقعد مع تثبيت القدمين على الأرض');
    } else if (name.includes('decline')) {
      steps.push('اضبط المقعد بزاوية منحدرة');
      steps.push('استلقِ على المقعد مع تثبيت القدمين');
    } else {
      steps.push('استلقِ على المقعد مع تثبيت القدمين على الأرض');
    }
  } else if (name.includes('squat') || movementPattern.includes('squat')) {
    steps.push('قف مع تباعد القدمين بعرض الكتفين');
    steps.push('ثبت البار على الكتفين');
  } else if (name.includes('deadlift') || movementPattern.includes('deadlift')) {
    steps.push('قف مع تباعد القدمين بعرض الوركين');
    steps.push('أمسك البار بقبضة مزدوجة');
  } else if (name.includes('row') || movementPattern.includes('pull')) {
    steps.push('قف مع انحناء خفيف في الركبتين');
    steps.push('ثبت الظهر في وضع مستقيم');
  } else if (name.includes('standing')) {
    steps.push('قف مع تباعد القدمين بعرض الكتفين');
  } else if (name.includes('seated')) {
    steps.push('اجلس على المقعد مع تثبيت الظهر');
  }
  
  // Step 2: Grip/Position
  if (name.includes('bench press') || name.includes('press')) {
    if (equipment.includes('barbell')) {
      steps.push('أمسك البار بعرض الكتفين أو أوسع قليلاً');
    } else if (equipment.includes('dumbbell')) {
      steps.push('أمسك الدمبلز على مستوى الصدر');
    }
  } else if (name.includes('curl')) {
    if (equipment.includes('barbell')) {
      steps.push('أمسك البار بقبضة تحتية');
    } else if (equipment.includes('dumbbell')) {
      steps.push('أمسك الدمبلز بجانب الجسم');
    }
  }
  
  // Step 3: Execution
  if (name.includes('press') || name.includes('push')) {
    if (name.includes('bench')) {
      steps.push('أنزل البار ببطء حتى يلامس منتصف الصدر');
      steps.push('ادفع البار للأعلى حتى تمد الذراعين دون قفل المرفقين');
    } else if (name.includes('shoulder') || name.includes('overhead')) {
      steps.push('ادفع الوزن للأعلى حتى تمد الذراعين بالكامل');
      steps.push('أنزل الوزن ببطء للوضع الأولي');
    }
  } else if (name.includes('squat')) {
    steps.push('أنزل ببطء مع الحفاظ على استقامة الظهر');
    steps.push('انزل حتى تصبح الفخذين موازية للأرض');
    steps.push('ادفع للأعلى من الكعبين حتى العودة للوضع الأولي');
  } else if (name.includes('deadlift')) {
    steps.push('ارفع البار ببطء مع الحفاظ على استقامة الظهر');
    steps.push('شد الأرداف والظهر عند الوصول للأعلى');
    steps.push('أنزل البار ببطء للوضع الأولي');
  } else if (name.includes('row') || name.includes('pull')) {
    steps.push('اسحب الوزن باتجاه الجسم مع شد عضلات الظهر');
    steps.push('اضغط في الأعلى لمدة ثانية');
    steps.push('أعد الوزن ببطء للوضع الأولي');
  } else if (name.includes('curl')) {
    steps.push('ارفع الوزن ببطء مع شد عضلة ذات الرأسين');
    steps.push('اضغط في الأعلى لمدة ثانية');
    steps.push('أنزل الوزن ببطء للوضع الأولي');
  } else {
    // Generic execution
    steps.push('نفذ الحركة ببطء وبتحكم');
    steps.push('ركز على شد العضلات المستهدفة');
    steps.push('أعد للوضع الأولي ببطء');
  }
  
  // Step 4: Breathing/Core
  steps.push('تنفس بشكل طبيعي');
  steps.push('شد الجذع طوال التمرين');
  
  return steps.join(' ');
}

/**
 * Generate Arabic cues
 */
function generateArabicCues(exercise) {
  const englishCues = exercise.cues || [];
  const arabicCues = [];
  
  // Translate known cues
  for (const cue of englishCues) {
    const cueLower = cue.toLowerCase();
    if (cueTranslations[cueLower]) {
      arabicCues.push(cueTranslations[cueLower]);
    } else {
      // Generate from components
      if (cueLower.includes('core')) {
        arabicCues.push('شدّ الجذع');
      } else if (cueLower.includes('control')) {
        arabicCues.push('تحكّم في الوزن');
      } else if (cueLower.includes('range of motion')) {
        arabicCues.push('مدى حركة كامل');
      } else if (cueLower.includes('back')) {
        arabicCues.push('حافظ على استقامة الظهر');
      } else if (cueLower.includes('shoulders')) {
        arabicCues.push('ثبت الكتفين للخلف');
      } else if (cueLower.includes('glutes')) {
        arabicCues.push('شد الأرداف');
      } else {
        // Generic cue
        arabicCues.push('ركز على الشكل الصحيح');
      }
    }
  }
  
  // Ensure at least 2-4 cues
  if (arabicCues.length === 0) {
    arabicCues.push('شدّ الجذع');
    arabicCues.push('تحكّم في النزول');
  }
  
  // Limit to 4 cues
  return arabicCues.slice(0, 4);
}

/**
 * Generate Arabic common mistakes
 */
function generateArabicMistakes(exercise) {
  const englishMistakes = exercise.common_mistakes || [];
  const arabicMistakes = [];
  
  // Translate known mistakes
  for (const mistake of englishMistakes) {
    const mistakeLower = mistake.toLowerCase();
    if (mistakeTranslations[mistakeLower]) {
      arabicMistakes.push(mistakeTranslations[mistakeLower]);
    } else {
      // Generate from components
      if (mistakeLower.includes('arch') || mistakeLower.includes('back')) {
        arabicMistakes.push('تقوّس أسفل الظهر بشكل مبالغ');
      } else if (mistakeLower.includes('flare') || mistakeLower.includes('elbow')) {
        arabicMistakes.push('فتح المرفقين أكثر من اللازم');
      } else if (mistakeLower.includes('bounce')) {
        arabicMistakes.push('ارتداد الوزن');
      } else if (mistakeLower.includes('momentum')) {
        arabicMistakes.push('استخدام الزخم');
      } else if (mistakeLower.includes('weight') || mistakeLower.includes('heavy')) {
        arabicMistakes.push('استخدام وزن زائد');
      } else {
        // Generic mistake
        arabicMistakes.push('عدم التحكم في الحركة');
      }
    }
  }
  
  // Ensure at least 2-4 mistakes
  if (arabicMistakes.length === 0) {
    arabicMistakes.push('تقوّس الظهر');
    arabicMistakes.push('استخدام وزن زائد');
  }
  
  // Limit to 4 mistakes
  return arabicMistakes.slice(0, 4);
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
    
    // Fetch all approved English exercises with full details
    console.log('📖 Fetching exercises from exercise_knowledge...');
    const exercisesResult = await client.query(`
      SELECT 
        id, 
        name, 
        aliases,
        short_desc,
        how_to,
        cues,
        common_mistakes,
        equipment, 
        primary_muscles, 
        secondary_muscles,
        movement_pattern,
        language
      FROM exercise_knowledge
      WHERE status = 'approved'
        AND language = 'en'
      ORDER BY created_at DESC
    `);
    
    const exercises = exercisesResult.rows;
    console.log(`📊 Found ${exercises.length} approved English exercises`);
    
    // Check existing translations
    const existingResult = await client.query(`
      SELECT COUNT(*) as count
      FROM exercise_translations
      WHERE language = 'ar'
        AND short_desc IS NOT NULL
    `);
    const existingCount = parseInt(existingResult.rows[0].count);
    console.log(`📊 Existing Arabic descriptions: ${existingCount}`);
    
    // Generate and insert translations
    let totalTranslations = 0;
    let skipped = 0;
    let updated = 0;
    const batchSize = 100;
    
    for (let i = 0; i < exercises.length; i += batchSize) {
      const batch = exercises.slice(i, i + batchSize);
      
      for (const exercise of batch) {
        try {
          // Check if translation already exists
          const existingCheck = await client.query(`
            SELECT id, name, short_desc FROM exercise_translations
            WHERE exercise_id = $1 AND language = 'ar'
          `, [exercise.id]);
          
          // Generate Arabic translations
          const arabicName = generateArabicName(exercise);
          const arabicAliases = generateArabicAliases(exercise, arabicName);
          const arabicShortDesc = generateArabicShortDesc(exercise);
          const arabicHowTo = generateArabicHowTo(exercise);
          const arabicCues = generateArabicCues(exercise);
          const arabicMistakes = generateArabicMistakes(exercise);
          
          if (existingCheck.rows.length > 0) {
            // Update existing translation (only if descriptions are missing)
            const existing = existingCheck.rows[0];
            if (!existing.short_desc) {
              await client.query(`
                UPDATE exercise_translations
                SET 
                  name = $1,
                  aliases = $2,
                  short_desc = $3,
                  how_to = $4,
                  cues = $5,
                  common_mistakes = $6,
                  source = 'canonical_ar_v1',
                  updated_at = NOW()
                WHERE id = $7
              `, [
                arabicName,
                arabicAliases,
                arabicShortDesc,
                arabicHowTo,
                arabicCues,
                arabicMistakes,
                existing.id,
              ]);
              updated++;
            } else {
              skipped++;
            }
          } else {
            // Insert new translation
            await client.query(`
              INSERT INTO exercise_translations (
                exercise_id, 
                language, 
                name, 
                aliases, 
                short_desc,
                how_to,
                cues,
                common_mistakes,
                source
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
              ON CONFLICT (exercise_id, language) DO UPDATE SET
                name = EXCLUDED.name,
                aliases = EXCLUDED.aliases,
                short_desc = COALESCE(exercise_translations.short_desc, EXCLUDED.short_desc),
                how_to = COALESCE(exercise_translations.how_to, EXCLUDED.how_to),
                cues = COALESCE(exercise_translations.cues, EXCLUDED.cues),
                common_mistakes = COALESCE(exercise_translations.common_mistakes, EXCLUDED.common_mistakes),
                source = EXCLUDED.source,
                updated_at = NOW()
            `, [
              exercise.id,
              'ar',
              arabicName,
              arabicAliases,
              arabicShortDesc,
              arabicHowTo,
              arabicCues,
              arabicMistakes,
              'canonical_ar_v1',
            ]);
            
            totalTranslations++;
          }
        } catch (error) {
          console.error(`❌ Error processing ${exercise.name}:`, error.message);
          skipped++;
        }
      }
      
      // Progress update
      if ((i + batchSize) % 500 === 0 || i + batchSize >= exercises.length) {
        console.log(`⏳ Processed ${Math.min(i + batchSize, exercises.length)}/${exercises.length} exercises (${totalTranslations} new, ${updated} updated, ${skipped} skipped)`);
      }
    }
    
    // Final statistics
    console.log('\n📊 Final Statistics:');
    const statsResult = await client.query(`
      SELECT 
        COUNT(*) as total_translations,
        COUNT(DISTINCT exercise_id) as exercises_translated,
        COUNT(*) FILTER (WHERE short_desc IS NOT NULL) as with_descriptions,
        COUNT(*) FILTER (WHERE how_to IS NOT NULL) as with_how_to,
        AVG(array_length(cues, 1)) as avg_cues,
        AVG(array_length(common_mistakes, 1)) as avg_mistakes
      FROM exercise_translations
      WHERE language = 'ar'
    `);
    
    console.table(statsResult.rows);
    
    console.log(`\n✅ Arabic description generation complete!`);
    console.log(`   - New translations: ${totalTranslations}`);
    console.log(`   - Updated translations: ${updated}`);
    console.log(`   - Skipped: ${skipped}`);
    
    // Sample translations
    console.log('\n📝 Sample Translations:');
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
      LIMIT 3
    `);
    
    samplesResult.rows.forEach((row, idx) => {
      console.log(`\n   Example ${idx + 1}: ${row.english_name}`);
      console.log(`   Arabic Name: ${row.arabic_name}`);
      console.log(`   Short Desc: ${row.short_desc}`);
      console.log(`   How-To: ${row.how_to.substring(0, 100)}...`);
      console.log(`   Cues: ${row.cues.join(', ')}`);
      console.log(`   Mistakes: ${row.common_mistakes.join(', ')}`);
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

module.exports = { 
  generateArabicShortDesc, 
  generateArabicHowTo, 
  generateArabicCues, 
  generateArabicMistakes 
};
