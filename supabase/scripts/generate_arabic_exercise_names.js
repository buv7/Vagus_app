#!/usr/bin/env node

/**
 * Generate Arabic Exercise Names & Translations
 * 
 * This script generates Arabic translations for all exercises in exercise_knowledge
 * and inserts them into exercise_translations table.
 * 
 * Translation rules:
 * - Anatomically correct
 * - Gym-friendly (not academic only)
 * - Natural Arabic (MSA + common gym terms)
 * - NO literal word-for-word translation
 * - NO Google-translate style
 * 
 * Usage: node supabase/scripts/generate_arabic_exercise_names.js
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
// ARABIC TRANSLATION DICTIONARY
// =====================================================

// Equipment translations (gym Arabic)
const equipmentAr = {
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

// Movement patterns (gym Arabic)
const movementAr = {
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

// Muscle groups (gym Arabic)
const muscleAr = {
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

// Position/angle translations
const positionAr = {
  'incline': 'مائل',
  'decline': 'منحدر',
  'flat': 'مسطح',
  'seated': 'جلوس',
  'standing': 'وقوف',
  'lying': 'استلقاء',
  'bent over': 'منحني',
  'one arm': 'ذراع واحد',
  'one leg': 'رجل واحدة',
  'alternating': 'متناوب',
};

// Common exercise name patterns (direct translations)
const exercisePatterns = {
  // Chest exercises
  'bench press': 'ضغط على المقعد',
  'incline bench press': 'ضغط على المقعد المائل',
  'decline bench press': 'ضغط على المقعد المنحدر',
  'dumbbell bench press': 'ضغط دمبل على المقعد',
  'incline dumbbell bench press': 'ضغط دمبل مائل للصدر',
  'decline dumbbell bench press': 'ضغط دمبل منحدر للصدر',
  'chest fly': 'رفرفة صدر',
  'dumbbell fly': 'رفرفة دمبل',
  'cable fly': 'رفرفة كابل',
  'push-up': 'ضغط',
  'dips': 'غطس',
  
  // Back exercises
  'lat pulldown': 'سحب للأسفل',
  'pull-up': 'سحب',
  'chin-up': 'سحب',
  'barbell row': 'سحب هالتر',
  'dumbbell row': 'سحب دمبل',
  'cable row': 'سحب كابل',
  't-bar row': 'سحب تي بار',
  'deadlift': 'رفعة مميتة',
  'romanian deadlift': 'رفعة مميتة رومانية',
  'sumo deadlift': 'رفعة مميتة سومو',
  
  // Shoulder exercises
  'shoulder press': 'ضغط كتف',
  'overhead press': 'ضغط فوق الرأس',
  'lateral raise': 'رفع جانبي',
  'front raise': 'رفع أمامي',
  'rear delt fly': 'رفرفة كتف خلفي',
  'arnold press': 'ضغط أرنولد',
  
  // Arm exercises
  'bicep curl': 'رفع عضلة ذات الرأسين',
  'hammer curl': 'رفع مطرقة',
  'tricep extension': 'تمديد عضلة ثلاثية الرؤوس',
  'tricep pushdown': 'دفع للأسفل ثلاثية الرؤوس',
  'close grip bench press': 'ضغط قبضة ضيقة',
  
  // Leg exercises
  'squat': 'سكوات',
  'barbell squat': 'سكوات هالتر',
  'front squat': 'سكوات أمامي',
  'leg press': 'ضغط أرجل',
  'leg curl': 'رفع أرجل',
  'leg extension': 'تمديد أرجل',
  'lunge': 'اندفاع',
  'bulgarian split squat': 'سكوات بلغاري',
  'romanian deadlift': 'رفعة مميتة رومانية',
  'calf raise': 'رفع سمانة',
  
  // Core exercises
  'crunch': 'تمرين البطن',
  'sit-up': 'تمرين البطن',
  'plank': 'لوح',
  'russian twist': 'لف روسي',
  'mountain climber': 'متسلق جبال',
};

/**
 * Generate Arabic name for an exercise
 */
function generateArabicName(exercise) {
  const name = exercise.name.toLowerCase().trim();
  const equipment = (exercise.equipment || []).map(eq => eq.toLowerCase());
  const primaryMuscles = (exercise.primary_muscles || []).map(m => m.toLowerCase());
  const movementPattern = (exercise.movement_pattern || '').toLowerCase();
  
  // 1. Check for exact pattern match first
  for (const [pattern, arabic] of Object.entries(exercisePatterns)) {
    if (name.includes(pattern)) {
      return arabic;
    }
  }
  
  // 2. Build translation from components
  const parts = [];
  
  // Extract position/angle
  let position = '';
  if (name.includes('incline')) {
    position = positionAr['incline'];
  } else if (name.includes('decline')) {
    position = positionAr['decline'];
  } else if (name.includes('flat')) {
    position = positionAr['flat'];
  } else if (name.includes('seated')) {
    position = positionAr['seated'];
  } else if (name.includes('standing')) {
    position = positionAr['standing'];
  }
  
  // Extract equipment
  let equipmentArName = '';
  for (const eq of equipment) {
    if (equipmentAr[eq]) {
      equipmentArName = equipmentAr[eq];
      break;
    }
  }
  
  // Extract movement
  let movement = '';
  for (const [pattern, arabic] of Object.entries(movementAr)) {
    if (name.includes(pattern)) {
      movement = arabic;
      break;
    }
  }
  
  // Extract muscle
  let muscle = '';
  for (const m of primaryMuscles) {
    for (const [pattern, arabic] of Object.entries(muscleAr)) {
      if (m.includes(pattern)) {
        muscle = arabic;
        break;
      }
    }
    if (muscle) break;
  }
  
  // 3. Construct Arabic name based on components
  if (movement && muscle) {
    // Pattern: [position] [equipment] [movement] [muscle]
    const components = [];
    if (position) components.push(position);
    if (equipmentArName) components.push(equipmentArName);
    components.push(movement);
    components.push(muscle);
    return components.join(' ');
  }
  
  if (movement && equipmentArName) {
    // Pattern: [position] [equipment] [movement]
    const components = [];
    if (position) components.push(position);
    components.push(equipmentArName);
    components.push(movement);
    return components.join(' ');
  }
  
  if (movement) {
    // Pattern: [movement]
    return movement;
  }
  
  // 4. Fallback: transliterate common words
  const fallbackMap = {
    'bench': 'مقعد',
    'press': 'ضغط',
    'curl': 'رفع',
    'squat': 'سكوات',
    'deadlift': 'رفعة مميتة',
    'row': 'سحب',
    'fly': 'رفرفة',
  };
  
  for (const [word, arabic] of Object.entries(fallbackMap)) {
    if (name.includes(word)) {
      return arabic;
    }
  }
  
  // 5. Last resort: return transliterated name (not ideal, but better than nothing)
  return name; // Will be flagged for manual review
}

/**
 * Generate Arabic aliases for an exercise
 */
function generateArabicAliases(exercise, arabicName) {
  const aliases = new Set();
  const name = exercise.name.toLowerCase().trim();
  const equipment = (exercise.equipment || []).map(eq => eq.toLowerCase());
  const primaryMuscles = (exercise.primary_muscles || []).map(m => m.toLowerCase());
  
  // Always include the canonical Arabic name
  aliases.add(arabicName);
  
  // Generate variations
  
  // 1. Equipment variations
  if (equipment.length > 0) {
    const firstEq = equipment[0];
    if (equipmentAr[firstEq]) {
      // Try with equipment name
      const withEq = `${equipmentAr[firstEq]} ${arabicName}`;
      if (withEq !== arabicName) {
        aliases.add(withEq);
      }
      
      // Try equipment-first order
      const parts = arabicName.split(' ');
      if (parts.length > 1) {
        const eqFirst = `${equipmentAr[firstEq]} ${parts.slice(1).join(' ')}`;
        aliases.add(eqFirst);
      }
    }
  }
  
  // 2. Muscle-first variations
  for (const m of primaryMuscles) {
    for (const [pattern, arabic] of Object.entries(muscleAr)) {
      if (m.includes(pattern)) {
        const muscleFirst = `${arabic} ${arabicName}`;
        if (muscleFirst !== arabicName) {
          aliases.add(muscleFirst);
        }
        break;
      }
    }
  }
  
  // 3. Common gym slang variations
  if (name.includes('bench press')) {
    aliases.add('ضغط صدر');
    aliases.add('ضغط على المقعد');
  }
  
  if (name.includes('incline') && name.includes('press')) {
    aliases.add('ضغط مائل');
    aliases.add('ضغط صدر مائل');
  }
  
  if (name.includes('deadlift')) {
    aliases.add('رفعة');
    aliases.add('ديدليفت');
  }
  
  if (name.includes('squat')) {
    aliases.add('سكوات');
    aliases.add('قرفصاء');
  }
  
  if (name.includes('pull') && name.includes('up')) {
    aliases.add('سحب');
    aliases.add('شد');
  }
  
  // 4. Remove position words for shorter aliases
  const withoutPosition = arabicName
    .replace(/\b(مائل|منحدر|مسطح)\b/g, '')
    .replace(/\s+/g, ' ')
    .trim();
  if (withoutPosition !== arabicName && withoutPosition.length > 2) {
    aliases.add(withoutPosition);
  }
  
  // Filter and limit
  return Array.from(aliases)
    .filter(alias => alias.length >= 2 && alias.length <= 100)
    .filter(alias => alias !== arabicName) // Don't duplicate exact name
    .slice(0, 7); // Limit to 7 aliases per exercise
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
    
    // Fetch all approved English exercises
    console.log('📖 Fetching exercises from exercise_knowledge...');
    const exercisesResult = await client.query(`
      SELECT id, name, equipment, primary_muscles, movement_pattern, language
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
    `);
    const existingCount = parseInt(existingResult.rows[0].count);
    console.log(`📊 Existing Arabic translations: ${existingCount}`);
    
    // Generate and insert translations
    let totalTranslations = 0;
    let skipped = 0;
    let manualReview = 0;
    const batchSize = 200;
    
    for (let i = 0; i < exercises.length; i += batchSize) {
      const batch = exercises.slice(i, i + batchSize);
      const translationInserts = [];
      
      for (const exercise of batch) {
        // Check if translation already exists
        const existingCheck = await client.query(`
          SELECT id FROM exercise_translations
          WHERE exercise_id = $1 AND language = 'ar'
        `, [exercise.id]);
        
        if (existingCheck.rows.length > 0) {
          skipped++;
          continue;
        }
        
        // Generate Arabic name
        const arabicName = generateArabicName(exercise);
        
        // Flag for manual review if name wasn't translated (still English)
        if (arabicName === exercise.name || arabicName.length < 3) {
          manualReview++;
          console.log(`⚠️  Manual review needed: ${exercise.name} -> ${arabicName}`);
        }
        
        // Generate aliases
        const aliases = generateArabicAliases(exercise, arabicName);
        
        translationInserts.push({
          exercise_id: exercise.id,
          language: 'ar',
          name: arabicName,
          aliases: aliases,
          source: 'canonical_ar_v1',
        });
      }
      
      // Batch insert with conflict handling
      if (translationInserts.length > 0) {
        for (const trans of translationInserts) {
          try {
            await client.query(`
              INSERT INTO exercise_translations (exercise_id, language, name, aliases, source)
              VALUES ($1, $2, $3, $4, $5)
              ON CONFLICT (exercise_id, language) DO NOTHING
            `, [
              trans.exercise_id,
              trans.language,
              trans.name,
              trans.aliases,
              trans.source,
            ]);
            
            totalTranslations++;
          } catch (error) {
            console.error(`❌ Error inserting translation for ${trans.exercise_id}:`, error.message);
            skipped++;
          }
        }
      }
      
      // Progress update
      if ((i + batchSize) % 100 === 0 || i + batchSize >= exercises.length) {
        console.log(`⏳ Processed ${Math.min(i + batchSize, exercises.length)}/${exercises.length} exercises (${totalTranslations} translations generated)`);
      }
    }
    
    // Final statistics
    console.log('\n📊 Final Statistics:');
    const statsResult = await client.query(`
      SELECT 
        COUNT(*) as total_translations,
        COUNT(DISTINCT exercise_id) as exercises_translated,
        AVG(array_length(aliases, 1)) as avg_aliases_per_exercise
      FROM exercise_translations
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
