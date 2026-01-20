#!/usr/bin/env node

/**
 * Generate Exercise Aliases & Synonyms
 * 
 * This script generates aliases for all exercises in exercise_knowledge
 * and inserts them into exercise_aliases table.
 * 
 * Alias types generated:
 * - Common names
 * - Equipment-free names
 * - Short forms
 * - Gym slang
 * - Anatomical phrasing
 * - Plural/tense variations
 * 
 * Usage: node supabase/scripts/generate_exercise_aliases.js
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

// Equipment abbreviations
const equipmentAbbr = {
  'barbell': 'BB',
  'dumbbell': 'DB',
  'dumbbells': 'DB',
  'cable': 'Cable',
  'cables': 'Cable',
  'machine': 'Machine',
  'kettlebell': 'KB',
  'kettlebells': 'KB',
  'bodyweight': 'BW',
  'resistance band': 'Band',
  'resistance bands': 'Band',
};

// Common word replacements for aliases
const wordReplacements = {
  'press': 'press',
  'presses': 'press',
  'fly': 'fly',
  'flyes': 'fly',
  'flys': 'fly',
  'curl': 'curl',
  'curls': 'curl',
  'raise': 'raise',
  'raises': 'raise',
  'extension': 'extension',
  'extensions': 'extension',
  'row': 'row',
  'rows': 'row',
  'pull': 'pull',
  'pulls': 'pull',
  'squat': 'squat',
  'squats': 'squat',
  'lunge': 'lunge',
  'lunges': 'lunge',
  'deadlift': 'deadlift',
  'deadlifts': 'deadlift',
};

/**
 * Generate aliases for an exercise
 */
function generateAliases(exercise) {
  const name = exercise.name;
  const equipment = exercise.equipment || [];
  const primaryMuscles = exercise.primary_muscles || [];
  const movementPattern = exercise.movement_pattern || '';
  
  const aliases = new Set();
  
  // 1. Always include the original name (as primary alias)
  aliases.add(name);
  
  // 2. Generate equipment-free versions
  let equipmentFree = name;
  equipment.forEach(eq => {
    const eqLower = eq.toLowerCase();
    // Remove equipment mentions
    equipmentFree = equipmentFree.replace(new RegExp(eqLower, 'gi'), '').trim();
    equipmentFree = equipmentFree.replace(new RegExp(equipmentAbbr[eqLower] || '', 'gi'), '').trim();
  });
  equipmentFree = equipmentFree.replace(/\s+/g, ' ').trim();
  if (equipmentFree && equipmentFree !== name && equipmentFree.length > 2) {
    aliases.add(equipmentFree);
  }
  
  // 3. Generate short forms with abbreviations
  if (equipment.length > 0) {
    const firstEq = equipment[0].toLowerCase();
    const abbr = equipmentAbbr[firstEq];
    if (abbr) {
      // Replace full equipment name with abbreviation
      const shortForm = name.replace(new RegExp(firstEq, 'gi'), abbr).trim();
      if (shortForm !== name && shortForm.length > 2) {
        aliases.add(shortForm);
      }
      
      // Try combining abbreviation with exercise type
      const exerciseType = extractExerciseType(name);
      if (exerciseType && exerciseType !== name) {
        aliases.add(`${abbr} ${exerciseType}`);
      }
    }
  }
  
  // 4. Generate common gym slang variations
  if (name.toLowerCase().includes('bench press')) {
    aliases.add('Bench Press');
    aliases.add('Flat Bench');
    aliases.add('BB Bench');
    aliases.add('Chest Press');
  }
  
  if (name.toLowerCase().includes('incline') && name.toLowerCase().includes('press')) {
    aliases.add('Incline Press');
    aliases.add('Upper Chest Press');
    if (equipment.some(eq => eq.toLowerCase().includes('dumbbell'))) {
      aliases.add('Incline DB Press');
    }
  }
  
  if (name.toLowerCase().includes('decline') && name.toLowerCase().includes('press')) {
    aliases.add('Decline Press');
    aliases.add('Lower Chest Press');
  }
  
  if (name.toLowerCase().includes('pull') && name.toLowerCase().includes('up')) {
    aliases.add('Pullups');
    aliases.add('Chinups');
  }
  
  if (name.toLowerCase().includes('lat') && name.toLowerCase().includes('pulldown')) {
    aliases.add('Lat Pulldown');
    aliases.add('Pulldown');
  }
  
  if (name.toLowerCase().includes('romanian') && name.toLowerCase().includes('deadlift')) {
    aliases.add('RDL');
    aliases.add('Romanian Deadlift');
  }
  
  if (name.toLowerCase().includes('bulgarian') && name.toLowerCase().includes('squat')) {
    aliases.add('BSS');
    aliases.add('Bulgarian Split Squat');
  }
  
  // 5. Generate anatomical phrasing variations
  if (primaryMuscles.length > 0) {
    const primaryMuscle = primaryMuscles[0].toLowerCase();
    const exerciseType = extractExerciseType(name);
    
    // Combine muscle with movement pattern
    if (exerciseType) {
      const muscleName = formatMuscleName(primaryMuscle);
      aliases.add(`${muscleName} ${exerciseType}`);
    }
    
    // Common muscle name mappings
    if (primaryMuscle.includes('pectoral') || primaryMuscle.includes('chest')) {
      if (name.toLowerCase().includes('press')) {
        aliases.add('Chest Press');
      }
      if (name.toLowerCase().includes('fly')) {
        aliases.add('Chest Fly');
      }
    }
    
    if (primaryMuscle.includes('latissimus') || primaryMuscle.includes('lat')) {
      if (name.toLowerCase().includes('pull')) {
        aliases.add('Lat Pull');
      }
    }
    
    if (primaryMuscle.includes('deltoid') || primaryMuscle.includes('shoulder')) {
      if (name.toLowerCase().includes('press')) {
        aliases.add('Shoulder Press');
      }
      if (name.toLowerCase().includes('raise')) {
        aliases.add('Shoulder Raise');
      }
    }
  }
  
  // 6. Generate plural/singular variations
  const words = name.split(' ');
  words.forEach((word, index) => {
    const lowerWord = word.toLowerCase();
    if (wordReplacements[lowerWord]) {
      // Try singular/plural variations
      const replacement = wordReplacements[lowerWord];
      if (lowerWord.endsWith('s') && !lowerWord.endsWith('ss')) {
        // Plural -> singular
        const singularWord = lowerWord.slice(0, -1);
        const newWords = [...words];
        newWords[index] = singularWord.charAt(0).toUpperCase() + singularWord.slice(1);
        aliases.add(newWords.join(' '));
      } else {
        // Singular -> plural
        const pluralWord = lowerWord + 's';
        const newWords = [...words];
        newWords[index] = pluralWord.charAt(0).toUpperCase() + pluralWord.slice(1);
        aliases.add(newWords.join(' '));
      }
    }
  });
  
  // 7. Remove common filler words and create variations
  const withoutCommon = name.replace(/\b(with|using|on|at|the)\b/gi, '').replace(/\s+/g, ' ').trim();
  if (withoutCommon !== name && withoutCommon.length > 2) {
    aliases.add(withoutCommon);
  }
  
  // 8. Remove hyphens and create variations
  if (name.includes('-')) {
    const withoutHyphen = name.replace(/-/g, ' ').replace(/\s+/g, ' ').trim();
    aliases.add(withoutHyphen);
    
    const withSpace = name.replace(/-/g, ' ').trim();
    if (withSpace !== name) {
      aliases.add(withSpace);
    }
  }
  
  // Filter out invalid aliases
  return Array.from(aliases)
    .filter(alias => alias.length >= 2 && alias.length <= 100)
    .filter(alias => alias.toLowerCase() !== name.toLowerCase()) // Don't duplicate exact name
    .slice(0, 15); // Limit to 15 aliases per exercise
}

/**
 * Extract the main exercise type from name
 */
function extractExerciseType(name) {
  const lower = name.toLowerCase();
  const patterns = [
    'press', 'fly', 'curl', 'raise', 'extension', 'row', 'pull', 'squat',
    'lunge', 'deadlift', 'curl', 'extension', 'crunch', 'plank', 'dip'
  ];
  
  for (const pattern of patterns) {
    if (lower.includes(pattern)) {
      return pattern.charAt(0).toUpperCase() + pattern.slice(1);
    }
  }
  
  return null;
}

/**
 * Format muscle name for alias generation
 */
function formatMuscleName(muscle) {
  // Convert anatomical names to common names
  const mapping = {
    'pectoralis_major': 'Chest',
    'pectoralis_minor': 'Chest',
    'latissimus_dorsi': 'Lat',
    'deltoid': 'Shoulder',
    'anterior_deltoid': 'Front Shoulder',
    'posterior_deltoid': 'Rear Shoulder',
    'biceps_brachii': 'Bicep',
    'triceps_brachii': 'Tricep',
    'quadriceps': 'Quad',
    'hamstrings': 'Hamstring',
    'gluteus_maximus': 'Glute',
  };
  
  for (const [key, value] of Object.entries(mapping)) {
    if (muscle.includes(key)) {
      return value;
    }
  }
  
  // Fallback: capitalize first letter of muscle name
  return muscle.split('_').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
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
    
    // Generate and insert aliases
    let totalAliases = 0;
    let skipped = 0;
    const batchSize = 500;
    
    for (let i = 0; i < exercises.length; i += batchSize) {
      const batch = exercises.slice(i, i + batchSize);
      const aliasInserts = [];
      
      for (const exercise of batch) {
        const aliases = generateAliases(exercise);
        
        for (const alias of aliases) {
          aliasInserts.push({
            exercise_id: exercise.id,
            alias: alias,
            language: exercise.language || 'en',
            source: 'canonical',
          });
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
          console.error(`❌ Error inserting batch ${i / batchSize + 1}:`, error.message);
          skipped += aliasInserts.length;
        }
      }
      
      // Progress update
      if ((i + batchSize) % 100 === 0 || i + batchSize >= exercises.length) {
        console.log(`⏳ Processed ${Math.min(i + batchSize, exercises.length)}/${exercises.length} exercises (${totalAliases} aliases generated)`);
      }
    }
    
    // Final statistics
    console.log('\n📊 Final Statistics:');
    const statsResult = await client.query(`
      SELECT 
        COUNT(DISTINCT exercise_id) as exercises_with_aliases,
        COUNT(*) as total_aliases,
        language,
        COUNT(*) / COUNT(DISTINCT exercise_id) as avg_aliases_per_exercise
      FROM exercise_aliases
      GROUP BY language
      ORDER BY language
    `);
    
    console.table(statsResult.rows);
    
    console.log(`\n✅ Alias generation complete!`);
    console.log(`   - Total aliases generated: ${totalAliases}`);
    console.log(`   - Skipped: ${skipped}`);
    
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

module.exports = { generateAliases, extractExerciseType, formatMuscleName };
