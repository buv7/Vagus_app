#!/usr/bin/env node

/**
 * Generate Arabic Exercise Aliases & Synonyms
 * 
 * This script generates Arabic aliases for all exercises in exercise_knowledge
 * and inserts them into exercise_aliases table.
 * 
 * Alias categories generated (3-8 per exercise):
 * - Formal Arabic (طبي/تشريحي)
 * - Gym Common Name (ما يقوله المدرب)
 * - Short/Slang (كلمة أو كلمتين)
 * - English-Arabic Hybrid (تعريب الاسم الإنجليزي)
 * 
 * Usage: node supabase/scripts/generate_arabic_exercise_aliases.js
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
  'deadlift': 'رفعة',
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
};

// Common exercise slang (short Arabic names)
const slangAr = {
  'bench press': ['بنش', 'ضغط صدر', 'بنش بريس'],
  'incline bench press': ['بنش مائل', 'ضغط مائل', 'Incline Press'],
  'decline bench press': ['بنش منحدر', 'ضغط منحدر'],
  'dumbbell bench press': ['دمبل بنش', 'DB Bench'],
  'lat pulldown': ['لات بول داون', 'سحب الظهر', 'سحب أمامي', 'Lat Pulldown'],
  'pull-up': ['سحب', 'شد', 'Pull-up'],
  'squat': ['سكوات', 'قرفصاء', 'Squat'],
  'deadlift': ['ديدليفت', 'رفعة', 'Deadlift'],
  'shoulder press': ['ضغط كتف', 'Shoulder Press'],
  'lateral raise': ['رفرفة جانبية', 'جانبي', 'Lateral Raise'],
  'bicep curl': ['رفع بيسبس', 'Bicep Curl'],
  'tricep extension': ['تمديد ترايسبس', 'Tricep Extension'],
  'leg press': ['ضغط أرجل', 'Leg Press'],
  'leg curl': ['رفع أرجل', 'Leg Curl'],
  'calf raise': ['رفع سمانة', 'Calf Raise'],
};

/**
 * Generate Arabic aliases for an exercise (3-8 aliases)
 */
function generateArabicAliases(exercise) {
  const aliases = new Set();
  const name = exercise.name.toLowerCase().trim();
  const equipment = (exercise.equipment || []).map(eq => eq.toLowerCase());
  const primaryMuscles = (exercise.primary_muscles || []).map(m => m.toLowerCase());
  const movementPattern = (exercise.movement_pattern || '').toLowerCase();
  
  // 1. Check for exact slang match first (Gym Common Name)
  for (const [pattern, slangList] of Object.entries(slangAr)) {
    if (name.includes(pattern)) {
      slangList.forEach(slang => aliases.add(slang));
      break;
    }
  }
  
  // 2. Generate formal Arabic (طبي/تشريحي)
  let formalName = '';
  
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
  
  // Extract movement
  let movement = '';
  for (const [pattern, arabic] of Object.entries(movementAr)) {
    if (name.includes(pattern)) {
      movement = arabic;
      break;
    }
  }
  
  // Build formal name: [movement] [muscle] or [muscle] [movement]
  if (movement && muscle) {
    formalName = `${movement} ${muscle}`;
    aliases.add(formalName);
    
    // Also try muscle-first order
    aliases.add(`${muscle} ${movement}`);
  }
  
  // 3. Equipment-based variations (Gym Common Name)
  if (equipment.length > 0) {
    const firstEq = equipment[0];
    if (equipmentAr[firstEq]) {
      const eqName = equipmentAr[firstEq];
      
      // [equipment] [movement]
      if (movement) {
        aliases.add(`${eqName} ${movement}`);
      }
      
      // [equipment] [movement] [muscle]
      if (movement && muscle) {
        aliases.add(`${eqName} ${movement} ${muscle}`);
      }
      
      // Equipment with English hybrid
      if (name.includes('press')) {
        aliases.add(`${eqName} Press`);
      }
      if (name.includes('curl')) {
        aliases.add(`${eqName} Curl`);
      }
      if (name.includes('raise')) {
        aliases.add(`${eqName} Raise`);
      }
    }
  }
  
  // 4. Short/Slang variations (كلمة أو كلمتين)
  
  // Short muscle + movement
  if (muscle && movement) {
    // Very short versions
    if (muscle === 'صدر' && movement === 'ضغط') {
      aliases.add('ضغط صدر');
    }
    if (muscle === 'ظهر' && movement === 'سحب') {
      aliases.add('سحب ظهر');
    }
    if (muscle === 'كتف' && movement === 'ضغط') {
      aliases.add('ضغط كتف');
    }
  }
  
  // Common short names
  if (name.includes('bench press')) {
    aliases.add('بنش');
    aliases.add('ضغط صدر');
  }
  
  if (name.includes('incline') && name.includes('press')) {
    aliases.add('ضغط مائل');
    aliases.add('بنش مائل');
  }
  
  if (name.includes('lat') && name.includes('pulldown')) {
    aliases.add('سحب ظهر');
    aliases.add('سحب أمامي');
  }
  
  if (name.includes('squat')) {
    aliases.add('سكوات');
    aliases.add('قرفصاء');
  }
  
  if (name.includes('deadlift')) {
    aliases.add('رفعة');
    aliases.add('ديدليفت');
  }
  
  if (name.includes('lateral') && name.includes('raise')) {
    aliases.add('رفرفة جانبية');
    aliases.add('جانبي');
  }
  
  // 5. English-Arabic Hybrid (تعريب الاسم الإنجليزي)
  
  // Keep original English name as hybrid (for gym-goers who use English terms)
  // But only if it's a common exercise
  if (name.includes('bench press')) {
    aliases.add('Bench Press');
  }
  if (name.includes('squat')) {
    aliases.add('Squat');
  }
  if (name.includes('deadlift')) {
    aliases.add('Deadlift');
  }
  if (name.includes('lateral raise')) {
    aliases.add('Lateral Raise');
  }
  if (name.includes('lat pulldown')) {
    aliases.add('Lat Pulldown');
  }
  if (name.includes('shoulder press')) {
    aliases.add('Shoulder Press');
  }
  
  // 6. Position-based variations
  if (name.includes('incline')) {
    if (movement) {
      aliases.add(`${movement} مائل`);
    }
  }
  
  if (name.includes('decline')) {
    if (movement) {
      aliases.add(`${movement} منحدر`);
    }
  }
  
  // 7. Muscle-focused variations
  if (muscle) {
    // [muscle] تمرين
    aliases.add(`تمرين ${muscle}`);
    
    // [muscle] only (for very common exercises)
    if (muscle === 'صدر' && movement === 'ضغط') {
      aliases.add('صدر');
    }
  }
  
  // Filter and return (3-8 aliases)
  const filtered = Array.from(aliases)
    .filter(alias => alias && alias.trim().length >= 2 && alias.trim().length <= 100)
    .slice(0, 8); // Limit to 8 aliases per exercise
  
  // Ensure we have at least 3 aliases (pad if needed)
  while (filtered.length < 3 && filtered.length < 8) {
    // Try to add more variations
    if (movement && filtered.length < 8) {
      filtered.push(movement);
    }
    if (muscle && filtered.length < 8 && !filtered.includes(muscle)) {
      filtered.push(muscle);
    }
    if (filtered.length >= 3) break;
  }
  
  return filtered.slice(0, 8); // Max 8 aliases
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
    
    // Fetch all approved exercises
    console.log('📖 Fetching exercises from exercise_knowledge...');
    const exercisesResult = await client.query(`
      SELECT id, name, equipment, primary_muscles, movement_pattern, language
      FROM exercise_knowledge
      WHERE status = 'approved'
      ORDER BY created_at DESC
    `);
    
    const exercises = exercisesResult.rows;
    console.log(`📊 Found ${exercises.length} approved exercises`);
    
    // Check existing Arabic aliases to avoid duplicates
    console.log('🔍 Checking existing Arabic aliases...');
    const existingAliasesResult = await client.query(`
      SELECT exercise_id, alias 
      FROM exercise_aliases 
      WHERE language = 'ar'
    `);
    
    const existingAliases = new Set();
    existingAliasesResult.rows.forEach(row => {
      existingAliases.add(`${row.exercise_id}:${row.alias}`);
    });
    console.log(`📊 Found ${existingAliases.size} existing Arabic aliases`);
    
    // Generate and insert aliases
    let totalAliases = 0;
    let skipped = 0;
    let inserted = 0;
    const batchSize = 500;
    const examples = [];
    
    for (let i = 0; i < exercises.length; i += batchSize) {
      const batch = exercises.slice(i, i + batchSize);
      const aliasInserts = [];
      
      for (const exercise of batch) {
        const aliases = generateArabicAliases(exercise);
        
        // Store first 5 examples
        if (examples.length < 5) {
          examples.push({
            exercise: exercise.name,
            aliases: aliases,
          });
        }
        
        for (const alias of aliases) {
          const key = `${exercise.id}:${alias}`;
          if (!existingAliases.has(key)) {
            aliasInserts.push({
              exercise_id: exercise.id,
              alias: alias.trim(),
              language: 'ar',
              source: 'canonical_ar_alias_v1',
            });
            inserted++;
          } else {
            skipped++;
          }
        }
      }
      
      // Batch insert with conflict handling
      if (aliasInserts.length > 0) {
        const values = aliasInserts.map((a, idx) => {
          const base = idx * 4;
          return `($${base + 1}::uuid, $${base + 2}::text, $${base + 3}::text, $${base + 4}::text)`;
        }).join(', ');
        
        const params = aliasInserts.flatMap(a => [
          a.exercise_id,
          a.alias,
          a.language,
          a.source,
        ]);
        
        try {
          await client.query(`
            INSERT INTO exercise_aliases (exercise_id, alias, language, source)
            VALUES ${values}
            ON CONFLICT (exercise_id, alias, language) DO NOTHING
          `, params);
          
          totalAliases += aliasInserts.length;
        } catch (error) {
          console.error(`❌ Error inserting batch ${Math.floor(i / batchSize) + 1}:`, error.message);
        }
      }
      
      // Progress update
      if ((i + batchSize) % 100 === 0 || i + batchSize >= exercises.length) {
        console.log(`⏳ Processed ${Math.min(i + batchSize, exercises.length)}/${exercises.length} exercises (${totalAliases} aliases inserted, ${skipped} skipped)`);
      }
    }
    
    // Final statistics
    console.log('\n📊 Final Statistics:');
    const statsResult = await client.query(`
      SELECT 
        COUNT(DISTINCT exercise_id) as exercises_with_aliases,
        COUNT(*) as total_aliases,
        AVG(alias_count) as avg_aliases_per_exercise
      FROM (
        SELECT exercise_id, COUNT(*) as alias_count
        FROM exercise_aliases
        WHERE language = 'ar'
        GROUP BY exercise_id
      ) subq
    `);
    
    console.table(statsResult.rows);
    
    console.log(`\n✅ Arabic alias generation complete!`);
    console.log(`   - Total aliases inserted: ${inserted}`);
    console.log(`   - Skipped (already exists): ${skipped}`);
    console.log(`   - Total Arabic aliases in DB: ${totalAliases + existingAliases.size}`);
    
    console.log('\n📝 Example Exercises with Aliases:');
    examples.forEach((ex, idx) => {
      console.log(`\n${idx + 1}. ${ex.exercise}:`);
      ex.aliases.forEach(alias => console.log(`   - ${alias}`));
    });
    
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

module.exports = { generateArabicAliases };
