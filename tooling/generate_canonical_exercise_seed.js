/**
 * CANONICAL EXERCISE KNOWLEDGE SEED GENERATOR
 * Generates 1,500-2,000 production-grade exercises for VAGUS knowledge base
 * 
 * Output: supabase/seeds/exercise_knowledge_seed.json
 */

const fs = require('fs');
const path = require('path');

// =====================================================
// TAXONOMY DEFINITIONS
// =====================================================

const EQUIPMENT = [
  'barbell', 'dumbbell', 'cable', 'machine', 'smith', 
  'kettlebell', 'resistance_band', 'bodyweight', 'plate_loaded', 'cardio_machine'
];

const MOVEMENT_PATTERNS = [
  'horizontal_push', 'vertical_push', 'horizontal_pull', 'vertical_pull',
  'squat', 'hinge', 'lunge', 'carry', 'rotation', 'anti_rotation',
  'isolation', 'gait', 'jump', 'sprint'
];

const GRIP_VARIANTS = {
  wide: 'Wide-Grip',
  narrow: 'Narrow-Grip',
  neutral: 'Neutral-Grip',
  reverse: 'Reverse-Grip',
  pronated: 'Pronated',
  supinated: 'Supinated',
  hammer: 'Hammer-Grip',
  mixed: 'Mixed-Grip'
};

const POSITION_VARIANTS = {
  flat: 'Flat',
  incline: 'Incline',
  decline: 'Decline',
  seated: 'Seated',
  standing: 'Standing',
  kneeling: 'Kneeling',
  'half-kneeling': 'Half-Kneeling',
  lying: 'Lying',
  prone: 'Prone',
  supine: 'Supine',
  side: 'Side-Lying',
  hanging: 'Hanging'
};

const INTENT_VARIANTS = {
  paused: 'Paused',
  tempo: 'Tempo',
  explosive: 'Explosive',
  deficit: 'Deficit',
  partial: 'Partial ROM',
  'close-grip': 'Close-Grip',
  'wide-grip': 'Wide-Grip'
};

// =====================================================
// MUSCLE TAXONOMY (DUAL: English + Anatomical)
// =====================================================

const MUSCLE_MAP = {
  chest: ['pectoralis_major', 'pectoralis_minor'],
  back: ['latissimus_dorsi', 'rhomboids', 'middle_trapezius', 'lower_trapezius'],
  shoulders: ['anterior_deltoid', 'medial_deltoid', 'posterior_deltoid'],
  triceps: ['triceps_brachii', 'anconeus'],
  biceps: ['biceps_brachii', 'brachialis', 'brachioradialis'],
  forearms: ['flexor_carpi', 'extensor_carpi', 'pronator_teres'],
  quads: ['quadriceps', 'rectus_femoris', 'vastus_lateralis', 'vastus_medialis', 'vastus_intermedius'],
  hamstrings: ['biceps_femoris', 'semitendinosus', 'semimembranosus'],
  glutes: ['gluteus_maximus', 'gluteus_medius', 'gluteus_minimus'],
  calves: ['gastrocnemius', 'soleus'],
  core: ['rectus_abdominis', 'obliques', 'transverse_abdominis', 'erector_spinae'],
  traps: ['upper_trapezius', 'middle_trapezius', 'lower_trapezius'],
  lats: ['latissimus_dorsi']
};

// =====================================================
// BASE MOVEMENT TEMPLATES
// =====================================================

const BASE_MOVEMENTS = [
  // COMPOUND PUSH
  { name: 'Bench Press', pattern: 'horizontal_push', primary: ['chest'], secondary: ['triceps', 'shoulders'], 
    equipment: ['barbell', 'dumbbell', 'smith', 'machine'], positions: ['flat', 'incline', 'decline'] },
  { name: 'Shoulder Press', pattern: 'vertical_push', primary: ['shoulders'], secondary: ['triceps', 'core'], 
    equipment: ['barbell', 'dumbbell', 'machine', 'cable'], positions: ['seated', 'standing'] },
  { name: 'Overhead Press', pattern: 'vertical_push', primary: ['shoulders'], secondary: ['triceps', 'core'], 
    equipment: ['barbell', 'dumbbell'], positions: ['standing', 'seated'] },
  { name: 'Push Up', pattern: 'horizontal_push', primary: ['chest'], secondary: ['triceps', 'shoulders', 'core'], 
    equipment: ['bodyweight'], positions: ['flat', 'incline', 'decline'] },
  { name: 'Dip', pattern: 'vertical_push', primary: ['triceps', 'chest'], secondary: ['shoulders'], 
    equipment: ['bodyweight', 'machine'], positions: ['hanging'] },
  
  // COMPOUND PULL
  { name: 'Row', pattern: 'horizontal_pull', primary: ['back'], secondary: ['biceps', 'shoulders'], 
    equipment: ['barbell', 'dumbbell', 'cable', 'machine'], positions: ['seated', 'standing', 'bent-over'] },
  { name: 'Pulldown', pattern: 'vertical_pull', primary: ['lats'], secondary: ['biceps', 'back'], 
    equipment: ['cable', 'machine'], positions: ['seated'] },
  { name: 'Pull Up', pattern: 'vertical_pull', primary: ['lats'], secondary: ['biceps', 'back'], 
    equipment: ['bodyweight'], positions: ['hanging'] },
  { name: 'Chin Up', pattern: 'vertical_pull', primary: ['biceps', 'lats'], secondary: ['back'], 
    equipment: ['bodyweight'], positions: ['hanging'] },
  { name: 'Cable Fly', pattern: 'isolation', primary: ['chest'], secondary: ['shoulders'], 
    equipment: ['cable'], positions: ['standing'] },
  
  // SQUAT PATTERN
  { name: 'Squat', pattern: 'squat', primary: ['quads', 'glutes'], secondary: ['core', 'hamstrings'], 
    equipment: ['barbell', 'dumbbell', 'bodyweight', 'smith'], positions: ['standing'] },
  { name: 'Front Squat', pattern: 'squat', primary: ['quads', 'glutes'], secondary: ['core'], 
    equipment: ['barbell', 'dumbbell'], positions: ['standing'] },
  { name: 'Bulgarian Split Squat', pattern: 'lunge', primary: ['quads', 'glutes'], secondary: ['core'], 
    equipment: ['dumbbell', 'bodyweight'], positions: ['standing'] },
  { name: 'Lunge', pattern: 'lunge', primary: ['quads', 'glutes'], secondary: ['core', 'hamstrings'], 
    equipment: ['barbell', 'dumbbell', 'bodyweight'], positions: ['standing'] },
  { name: 'Step Up', pattern: 'lunge', primary: ['quads', 'glutes'], secondary: ['core'], 
    equipment: ['dumbbell', 'bodyweight'], positions: ['standing'] },
  
  // HINGE PATTERN
  { name: 'Deadlift', pattern: 'hinge', primary: ['hamstrings', 'glutes'], secondary: ['back', 'core'], 
    equipment: ['barbell', 'dumbbell'], positions: ['standing'] },
  { name: 'Romanian Deadlift', pattern: 'hinge', primary: ['hamstrings', 'glutes'], secondary: ['back', 'core'], 
    equipment: ['barbell', 'dumbbell'], positions: ['standing'] },
  { name: 'Hip Thrust', pattern: 'hinge', primary: ['glutes'], secondary: ['hamstrings'], 
    equipment: ['barbell', 'dumbbell', 'bodyweight'], positions: ['supine'] },
  { name: 'Good Morning', pattern: 'hinge', primary: ['hamstrings', 'glutes'], secondary: ['back', 'core'], 
    equipment: ['barbell', 'bodyweight'], positions: ['standing'] },
  { name: 'Glute Bridge', pattern: 'hinge', primary: ['glutes'], secondary: ['hamstrings', 'core'], 
    equipment: ['bodyweight', 'barbell'], positions: ['supine'] },
  
  // ISOLATION ARM
  { name: 'Bicep Curl', pattern: 'isolation', primary: ['biceps'], secondary: ['forearms'], 
    equipment: ['barbell', 'dumbbell', 'cable', 'resistance_band'], positions: ['standing', 'seated'] },
  { name: 'Tricep Extension', pattern: 'isolation', primary: ['triceps'], secondary: [], 
    equipment: ['dumbbell', 'cable', 'resistance_band'], positions: ['standing', 'seated', 'lying'] },
  { name: 'Lateral Raise', pattern: 'isolation', primary: ['shoulders'], secondary: [], 
    equipment: ['dumbbell', 'cable', 'resistance_band'], positions: ['standing', 'seated'] },
  { name: 'Rear Delt Fly', pattern: 'isolation', primary: ['shoulders'], secondary: ['back'], 
    equipment: ['dumbbell', 'cable'], positions: ['standing', 'seated', 'prone'] },
  { name: 'Front Raise', pattern: 'isolation', primary: ['shoulders'], secondary: [], 
    equipment: ['dumbbell', 'cable', 'resistance_band'], positions: ['standing'] },
  
  // ISOLATION LEGS
  { name: 'Leg Curl', pattern: 'isolation', primary: ['hamstrings'], secondary: [], 
    equipment: ['machine'], positions: ['lying', 'seated', 'standing'] },
  { name: 'Leg Extension', pattern: 'isolation', primary: ['quads'], secondary: [], 
    equipment: ['machine'], positions: ['seated'] },
  { name: 'Calf Raise', pattern: 'isolation', primary: ['calves'], secondary: [], 
    equipment: ['barbell', 'dumbbell', 'machine', 'bodyweight'], positions: ['standing', 'seated'] },
  { name: 'Leg Press', pattern: 'squat', primary: ['quads', 'glutes'], secondary: ['hamstrings'], 
    equipment: ['machine', 'plate_loaded'], positions: ['seated'] },
  
  // CORE
  { name: 'Crunch', pattern: 'isolation', primary: ['core'], secondary: [], 
    equipment: ['bodyweight'], positions: ['supine'] },
  { name: 'Plank', pattern: 'anti_rotation', primary: ['core'], secondary: ['shoulders'], 
    equipment: ['bodyweight'], positions: ['prone'] },
  { name: 'Dead Bug', pattern: 'anti_rotation', primary: ['core'], secondary: [], 
    equipment: ['bodyweight'], positions: ['supine'] },
  { name: 'Russian Twist', pattern: 'rotation', primary: ['core'], secondary: [], 
    equipment: ['bodyweight', 'dumbbell'], positions: ['seated'] },
  { name: 'Side Plank', pattern: 'anti_rotation', primary: ['core'], secondary: ['shoulders'], 
    equipment: ['bodyweight'], positions: ['side'] },
  { name: 'Hanging Knee Raise', pattern: 'isolation', primary: ['core'], secondary: ['lats'], 
    equipment: ['bodyweight'], positions: ['hanging'] },
  
  // CARRY / GAIT
  { name: 'Farmer Walk', pattern: 'carry', primary: ['core', 'forearms'], secondary: ['shoulders', 'traps'], 
    equipment: ['dumbbell', 'kettlebell'], positions: ['standing'] },
  { name: 'Suitcase Carry', pattern: 'carry', primary: ['core'], secondary: ['forearms'], 
    equipment: ['dumbbell', 'kettlebell'], positions: ['standing'] },
  
  // CARDIO MOVEMENTS
  { name: 'Burpee', pattern: 'jump', primary: ['quads', 'glutes', 'core'], secondary: ['shoulders', 'chest'], 
    equipment: ['bodyweight'], positions: ['standing'] },
  { name: 'Jump Squat', pattern: 'jump', primary: ['quads', 'glutes'], secondary: ['calves', 'core'], 
    equipment: ['bodyweight'], positions: ['standing'] },
  { name: 'Mountain Climber', pattern: 'gait', primary: ['core'], secondary: ['shoulders', 'quads'], 
    equipment: ['bodyweight'], positions: ['prone'] }
];

// =====================================================
// HELPERS
// =====================================================

function getMuscleArray(primaryTags, secondaryTags = []) {
  const primary = [];
  const secondary = [];
  
  primaryTags.forEach(tag => {
    primary.push(tag);
    if (MUSCLE_MAP[tag]) {
      primary.push(...MUSCLE_MAP[tag]);
    }
  });
  
  secondaryTags.forEach(tag => {
    secondary.push(tag);
    if (MUSCLE_MAP[tag]) {
      secondary.push(...MUSCLE_MAP[tag]);
    }
  });
  
  // Deduplicate
  return {
    primary: [...new Set(primary)],
    secondary: [...new Set(secondary)]
  };
}

function generateHowToSteps(baseName, equipment, position) {
  const steps = [];
  
  if (equipment.includes('barbell') || equipment.includes('dumbbell')) {
    steps.push(`Set up with ${equipment[0]} in starting position`);
    steps.push(`Lower weight under control with proper form`);
    steps.push(`Press/lift upward through full range of motion`);
  } else if (equipment.includes('bodyweight')) {
    steps.push(`Assume starting position`);
    steps.push(`Lower body under control`);
    steps.push(`Press/raise back to starting position`);
  } else if (equipment.includes('machine') || equipment.includes('cable')) {
    steps.push(`Adjust machine/cable to proper settings`);
    steps.push(`Execute movement with controlled tempo`);
    steps.push(`Return to starting position with control`);
  } else {
    steps.push(`Assume proper starting position`);
    steps.push(`Execute movement with controlled form`);
    steps.push(`Return to starting position`);
  }
  
  return steps;
}

function generateShortDesc(name, primaryMuscles, movementPattern) {
  const primary = primaryMuscles[0] || 'target muscles';
  const patternMap = {
    'horizontal_push': 'horizontal pushing',
    'vertical_push': 'overhead pressing',
    'horizontal_pull': 'horizontal pulling',
    'vertical_pull': 'vertical pulling',
    'squat': 'squatting',
    'hinge': 'hip hinging',
    'lunge': 'lunging',
    'isolation': 'targeted isolation',
    'carry': 'loaded carrying',
    'rotation': 'rotational',
    'anti_rotation': 'anti-rotational core',
    'gait': 'locomotor',
    'jump': 'plyometric',
    'sprint': 'sprinting'
  };
  
  const patternDesc = patternMap[movementPattern] || movementPattern;
  return `${name.toLowerCase()} targeting ${primary} through ${patternDesc} movement pattern.`;
}

function generateExercise(base, equipment, position, grip = null, intent = null) {
  const nameParts = [];
  
  if (intent && intent !== 'normal') {
    nameParts.push(INTENT_VARIANTS[intent] || intent);
  }
  if (position && position !== 'flat' && position !== 'standing') {
    nameParts.push(POSITION_VARIANTS[position] || position);
  }
  if (equipment !== 'bodyweight') {
    nameParts.push(equipment.charAt(0).toUpperCase() + equipment.slice(1));
  }
  if (grip && grip !== 'normal') {
    nameParts.push(GRIP_VARIANTS[grip] || grip);
  }
  nameParts.push(base.name);
  
  const name = nameParts.join(' ');
  
  // Get muscles with anatomical names
  const muscles = getMuscleArray(base.primary, base.secondary);
  
  // Build equipment array
  const equipmentArray = base.equipment.includes(equipment) 
    ? [equipment] 
    : base.equipment.filter(eq => eq === equipment);
  
  if (equipmentArray.length === 0) {
    equipmentArray.push(equipment);
  }
  
  // Add bench if needed for pressing movements
  if ((base.pattern.includes('push') || base.name.includes('Press')) && 
      !equipmentArray.includes('bench') && equipment !== 'bodyweight') {
    equipmentArray.push('bench');
  }
  
  const howToSteps = generateHowToSteps(base.name, equipmentArray, position);
  const shortDesc = generateShortDesc(name, muscles.primary, base.pattern);
  
  // Determine difficulty
  let difficulty = 'intermediate';
  if (base.pattern === 'isolation') {
    difficulty = 'beginner';
  } else if (base.pattern.includes('jump') || base.pattern === 'sprint' || 
             base.name.includes('Deadlift') || base.name.includes('Squat')) {
    difficulty = base.name.includes('Front') || base.name.includes('Overhead') ? 'advanced' : 'intermediate';
  }
  
  // Determine category
  let category = 'isolation';
  if (['squat', 'hinge', 'horizontal_push', 'vertical_push', 'horizontal_pull', 'vertical_pull'].includes(base.pattern)) {
    category = 'compound';
  }
  
  return {
    name: name,
    short_desc: shortDesc,
    how_to: howToSteps,
    primary_muscles: muscles.primary,
    secondary_muscles: muscles.secondary,
    equipment: equipmentArray,
    movement_pattern: base.pattern,
    difficulty: difficulty,
    category: category,
    source: 'canonical_global_db',
    language: 'en',
    status: 'approved'
  };
}

// =====================================================
// GENERATION LOGIC
// =====================================================

function generateAllExercises() {
  const exercises = [];
  const seenNames = new Set();
  
  // Generate from base movements with variations
  BASE_MOVEMENTS.forEach(base => {
    // Equipment variations
    const equipmentOptions = base.equipment || EQUIPMENT;
    equipmentOptions.forEach(equipment => {
      // Position variations
      const positions = base.positions || ['standing', 'seated'];
      positions.forEach(position => {
        // For certain movements, add grip variations
        const needsGrip = ['Row', 'Pulldown', 'Pull Up', 'Curl', 'Press'].some(term => base.name.includes(term));
        const grips = needsGrip ? ['normal', 'wide', 'narrow', 'reverse', 'neutral'] : ['normal'];
        
        grips.forEach(grip => {
          // For some movements, add intent variations
          const needsIntent = ['Deadlift', 'Squat', 'Press', 'Curl'].some(term => base.name.includes(term));
          const intents = needsIntent ? ['normal', 'paused', 'tempo', 'explosive'] : ['normal'];
          
          intents.forEach(intent => {
            const exercise = generateExercise(base, equipment, position, 
              grip === 'normal' ? null : grip, 
              intent === 'normal' ? null : intent);
            
            // Avoid duplicates
            if (!seenNames.has(exercise.name.toLowerCase())) {
              exercises.push(exercise);
              seenNames.add(exercise.name.toLowerCase());
            }
          });
        });
      });
    });
  });
  
  // ADDITIONAL SPECIFIC EXERCISES (to reach 1,500-2,000)
  
  // EXTENSIVE ISOLATION EXERCISES (to reach 600+)
  const isolationExercises = [
    // CHEST ISOLATION
    { name: 'Cable Crossover', pattern: 'isolation', primary: ['chest'], equipment: ['cable'], position: 'standing' },
    { name: 'Pec Deck', pattern: 'isolation', primary: ['chest'], equipment: ['machine'], position: 'seated' },
    { name: 'Incline Dumbbell Fly', pattern: 'isolation', primary: ['chest'], equipment: ['dumbbell'], position: 'incline' },
    { name: 'Flat Dumbbell Fly', pattern: 'isolation', primary: ['chest'], equipment: ['dumbbell'], position: 'flat' },
    { name: 'Decline Dumbbell Fly', pattern: 'isolation', primary: ['chest'], equipment: ['dumbbell'], position: 'decline' },
    { name: 'Incline Cable Fly', pattern: 'isolation', primary: ['chest'], equipment: ['cable'], position: 'incline' },
    { name: 'Decline Cable Fly', pattern: 'isolation', primary: ['chest'], equipment: ['cable'], position: 'decline' },
    { name: 'Cable Chest Fly', pattern: 'isolation', primary: ['chest'], equipment: ['cable'], position: 'standing' },
    { name: 'Low Cable Crossover', pattern: 'isolation', primary: ['chest'], equipment: ['cable'], position: 'standing' },
    { name: 'High Cable Crossover', pattern: 'isolation', primary: ['chest'], equipment: ['cable'], position: 'standing' },
    { name: 'Resistance Band Fly', pattern: 'isolation', primary: ['chest'], equipment: ['resistance_band'], position: 'standing' },
    { name: 'Dumbbell Pullover', pattern: 'isolation', primary: ['chest', 'lats'], equipment: ['dumbbell'], position: 'supine' },
    { name: 'Cable Pullover', pattern: 'isolation', primary: ['chest', 'lats'], equipment: ['cable'], position: 'kneeling' },
    
    // SHOULDER ISOLATION
    { name: 'Cable Face Pull', pattern: 'horizontal_pull', primary: ['shoulders'], equipment: ['cable'], position: 'standing' },
    { name: 'Cable Lateral Raise', pattern: 'isolation', primary: ['shoulders'], equipment: ['cable'], position: 'standing' },
    { name: 'Dumbbell Lateral Raise', pattern: 'isolation', primary: ['shoulders'], equipment: ['dumbbell'], position: 'standing' },
    { name: 'Seated Lateral Raise', pattern: 'isolation', primary: ['shoulders'], equipment: ['dumbbell'], position: 'seated' },
    { name: 'Bent-Over Lateral Raise', pattern: 'isolation', primary: ['shoulders'], equipment: ['dumbbell'], position: 'standing' },
    { name: 'Prone Lateral Raise', pattern: 'isolation', primary: ['shoulders'], equipment: ['dumbbell'], position: 'prone' },
    { name: 'Lying Lateral Raise', pattern: 'isolation', primary: ['shoulders'], equipment: ['dumbbell'], position: 'side' },
    { name: 'Cable Rear Delt Fly', pattern: 'isolation', primary: ['shoulders'], equipment: ['cable'], position: 'standing' },
    { name: 'Reverse Pec Deck', pattern: 'isolation', primary: ['shoulders'], equipment: ['machine'], position: 'seated' },
    { name: 'Dumbbell Front Raise', pattern: 'isolation', primary: ['shoulders'], equipment: ['dumbbell'], position: 'standing' },
    { name: 'Cable Front Raise', pattern: 'isolation', primary: ['shoulders'], equipment: ['cable'], position: 'standing' },
    { name: 'Barbell Front Raise', pattern: 'isolation', primary: ['shoulders'], equipment: ['barbell'], position: 'standing' },
    { name: 'Alternating Front Raise', pattern: 'isolation', primary: ['shoulders'], equipment: ['dumbbell'], position: 'standing' },
    { name: 'Plate Front Raise', pattern: 'isolation', primary: ['shoulders'], equipment: ['plate_loaded'], position: 'standing' },
    { name: 'Arnold Press', pattern: 'vertical_push', primary: ['shoulders'], equipment: ['dumbbell'], position: 'seated' },
    { name: 'Behind Neck Press', pattern: 'vertical_push', primary: ['shoulders'], equipment: ['barbell'], position: 'seated' },
    { name: 'Bradford Press', pattern: 'vertical_push', primary: ['shoulders'], equipment: ['barbell'], position: 'standing' },
    { name: 'Upright Row', pattern: 'vertical_pull', primary: ['shoulders', 'traps'], equipment: ['barbell', 'dumbbell', 'cable'], position: 'standing' },
    { name: 'Cable Upright Row', pattern: 'vertical_pull', primary: ['shoulders', 'traps'], equipment: ['cable'], position: 'standing' },
    { name: 'Wide-Grip Upright Row', pattern: 'vertical_pull', primary: ['shoulders', 'traps'], equipment: ['barbell'], position: 'standing' },
    { name: 'Narrow-Grip Upright Row', pattern: 'vertical_pull', primary: ['shoulders', 'traps'], equipment: ['barbell'], position: 'standing' },
    { name: 'Y-Raise', pattern: 'isolation', primary: ['shoulders'], equipment: ['dumbbell'], position: 'prone' },
    { name: 'T-Raise', pattern: 'isolation', primary: ['shoulders'], equipment: ['dumbbell'], position: 'prone' },
    { name: 'W-Raise', pattern: 'isolation', primary: ['shoulders'], equipment: ['dumbbell'], position: 'prone' },
    { name: 'Lateral Raise Partial', pattern: 'isolation', primary: ['shoulders'], equipment: ['dumbbell'], position: 'standing' },
    { name: 'Cable Y-Raise', pattern: 'isolation', primary: ['shoulders'], equipment: ['cable'], position: 'standing' },
    { name: 'Resistance Band Lateral Raise', pattern: 'isolation', primary: ['shoulders'], equipment: ['resistance_band'], position: 'standing' },
    { name: 'Resistance Band Front Raise', pattern: 'isolation', primary: ['shoulders'], equipment: ['resistance_band'], position: 'standing' },
    
    // BICEPS ISOLATION
    { name: 'Preacher Curl', pattern: 'isolation', primary: ['biceps'], equipment: ['barbell', 'dumbbell'], position: 'seated' },
    { name: 'Concentration Curl', pattern: 'isolation', primary: ['biceps'], equipment: ['dumbbell'], position: 'seated' },
    { name: 'Hammer Curl', pattern: 'isolation', primary: ['biceps', 'forearms'], equipment: ['dumbbell'], position: 'standing' },
    { name: 'Incline Dumbbell Curl', pattern: 'isolation', primary: ['biceps'], equipment: ['dumbbell'], position: 'seated' },
    { name: 'Standing Barbell Curl', pattern: 'isolation', primary: ['biceps'], equipment: ['barbell'], position: 'standing' },
    { name: 'Standing Dumbbell Curl', pattern: 'isolation', primary: ['biceps'], equipment: ['dumbbell'], position: 'standing' },
    { name: 'Cable Curl', pattern: 'isolation', primary: ['biceps'], equipment: ['cable'], position: 'standing' },
    { name: 'Cable Bicep Curl', pattern: 'isolation', primary: ['biceps'], equipment: ['cable'], position: 'standing' },
    { name: 'High Cable Curl', pattern: 'isolation', primary: ['biceps'], equipment: ['cable'], position: 'standing' },
    { name: 'Low Cable Curl', pattern: 'isolation', primary: ['biceps'], equipment: ['cable'], position: 'standing' },
    { name: 'Cable Rope Hammer Curl', pattern: 'isolation', primary: ['biceps', 'forearms'], equipment: ['cable'], position: 'standing' },
    { name: 'Spider Curl', pattern: 'isolation', primary: ['biceps'], equipment: ['barbell', 'dumbbell'], position: 'prone' },
    { name: 'Drag Curl', pattern: 'isolation', primary: ['biceps'], equipment: ['barbell'], position: 'standing' },
    { name: '21s', pattern: 'isolation', primary: ['biceps'], equipment: ['barbell'], position: 'standing' },
    { name: 'Reverse Curl', pattern: 'isolation', primary: ['forearms'], equipment: ['barbell'], position: 'standing' },
    { name: 'Zottman Curl', pattern: 'isolation', primary: ['biceps', 'forearms'], equipment: ['dumbbell'], position: 'standing' },
    { name: 'Cross-Body Hammer Curl', pattern: 'isolation', primary: ['biceps', 'forearms'], equipment: ['dumbbell'], position: 'standing' },
    { name: 'Cable Preacher Curl', pattern: 'isolation', primary: ['biceps'], equipment: ['cable'], position: 'seated' },
    { name: 'Resistance Band Curl', pattern: 'isolation', primary: ['biceps'], equipment: ['resistance_band'], position: 'standing' },
    { name: 'Single Arm Cable Curl', pattern: 'isolation', primary: ['biceps'], equipment: ['cable'], position: 'standing' },
    { name: 'Alternating Dumbbell Curl', pattern: 'isolation', primary: ['biceps'], equipment: ['dumbbell'], position: 'standing' },
    { name: 'Simultaneous Dumbbell Curl', pattern: 'isolation', primary: ['biceps'], equipment: ['dumbbell'], position: 'standing' },
    { name: 'Eccentric Curl', pattern: 'isolation', primary: ['biceps'], equipment: ['dumbbell'], position: 'standing' },
    { name: 'Pinwheel Curl', pattern: 'isolation', primary: ['biceps'], equipment: ['dumbbell'], position: 'standing' },
    
    // TRICEPS ISOLATION
    { name: 'Cable Tricep Pushdown', pattern: 'isolation', primary: ['triceps'], equipment: ['cable'], position: 'standing' },
    { name: 'Overhead Cable Tricep Extension', pattern: 'isolation', primary: ['triceps'], equipment: ['cable'], position: 'standing' },
    { name: 'Skull Crusher', pattern: 'isolation', primary: ['triceps'], equipment: ['barbell', 'dumbbell'], position: 'supine' },
    { name: 'Lying Tricep Extension', pattern: 'isolation', primary: ['triceps'], equipment: ['barbell', 'dumbbell'], position: 'supine' },
    { name: 'Overhead Tricep Extension', pattern: 'isolation', primary: ['triceps'], equipment: ['dumbbell'], position: 'standing' },
    { name: 'Seated Overhead Tricep Extension', pattern: 'isolation', primary: ['triceps'], equipment: ['dumbbell'], position: 'seated' },
    { name: 'Single Arm Overhead Extension', pattern: 'isolation', primary: ['triceps'], equipment: ['dumbbell'], position: 'standing' },
    { name: 'Cable Rope Pushdown', pattern: 'isolation', primary: ['triceps'], equipment: ['cable'], position: 'standing' },
    { name: 'Cable Overhead Extension', pattern: 'isolation', primary: ['triceps'], equipment: ['cable'], position: 'standing' },
    { name: 'Kickback', pattern: 'isolation', primary: ['triceps'], equipment: ['dumbbell'], position: 'standing' },
    { name: 'Cable Kickback', pattern: 'isolation', primary: ['triceps'], equipment: ['cable'], position: 'standing' },
    { name: 'Close-Grip Bench Press', pattern: 'horizontal_push', primary: ['triceps'], equipment: ['barbell', 'dumbbell'], position: 'flat' },
    { name: 'Diamond Push-Up', pattern: 'horizontal_push', primary: ['triceps'], equipment: ['bodyweight'], position: 'prone' },
    { name: 'Tricep Dips', pattern: 'vertical_push', primary: ['triceps'], equipment: ['bodyweight'], position: 'hanging' },
    { name: 'Bench Dips', pattern: 'vertical_push', primary: ['triceps'], equipment: ['bodyweight', 'bench'], position: 'seated' },
    { name: 'Weighted Dips', pattern: 'vertical_push', primary: ['triceps'], equipment: ['dumbbell'], position: 'hanging' },
    { name: 'French Press', pattern: 'isolation', primary: ['triceps'], equipment: ['barbell', 'dumbbell'], position: 'supine' },
    { name: 'Tate Press', pattern: 'isolation', primary: ['triceps'], equipment: ['dumbbell'], position: 'supine' },
    { name: 'JM Press', pattern: 'isolation', primary: ['triceps'], equipment: ['barbell'], position: 'flat' },
    { name: 'Overhead Rope Extension', pattern: 'isolation', primary: ['triceps'], equipment: ['cable'], position: 'standing' },
    { name: 'Single Arm Cable Pushdown', pattern: 'isolation', primary: ['triceps'], equipment: ['cable'], position: 'standing' },
    { name: 'Resistance Band Tricep Extension', pattern: 'isolation', primary: ['triceps'], equipment: ['resistance_band'], position: 'standing' },
    { name: 'Cable Tricep Extension Behind Back', pattern: 'isolation', primary: ['triceps'], equipment: ['cable'], position: 'standing' },
    
    // FOREARMS
    { name: 'Wrist Curl', pattern: 'isolation', primary: ['forearms'], equipment: ['barbell', 'dumbbell'], position: 'seated' },
    { name: 'Reverse Wrist Curl', pattern: 'isolation', primary: ['forearms'], equipment: ['barbell', 'dumbbell'], position: 'seated' },
    { name: 'Behind Back Wrist Curl', pattern: 'isolation', primary: ['forearms'], equipment: ['barbell'], position: 'standing' },
    { name: 'Farmers Walk', pattern: 'carry', primary: ['forearms', 'core'], equipment: ['dumbbell', 'kettlebell'], position: 'standing' },
    { name: 'Suitcase Carry', pattern: 'carry', primary: ['core', 'forearms'], equipment: ['dumbbell', 'kettlebell'], position: 'standing' },
    { name: 'Plate Pinch', pattern: 'isolation', primary: ['forearms'], equipment: ['plate_loaded'], position: 'standing' },
    { name: 'Reverse Curl', pattern: 'isolation', primary: ['forearms'], equipment: ['barbell', 'dumbbell'], position: 'standing' },
    { name: 'Cable Wrist Curl', pattern: 'isolation', primary: ['forearms'], equipment: ['cable'], position: 'seated' },
    
    // TRAPS
    { name: 'Shrug', pattern: 'isolation', primary: ['traps'], equipment: ['barbell', 'dumbbell'], position: 'standing' },
    { name: 'Behind Back Shrug', pattern: 'isolation', primary: ['traps'], equipment: ['barbell'], position: 'standing' },
    { name: 'Cable Shrug', pattern: 'isolation', primary: ['traps'], equipment: ['cable'], position: 'standing' },
    { name: 'Upright Row', pattern: 'vertical_pull', primary: ['shoulders', 'traps'], equipment: ['barbell', 'dumbbell', 'cable'], position: 'standing' },
    { name: 'Face Pull', pattern: 'horizontal_pull', primary: ['shoulders', 'traps'], equipment: ['cable'], position: 'standing' },
    
    // LEG ISOLATION
    { name: 'Leg Adduction', pattern: 'isolation', primary: ['glutes'], equipment: ['machine'], position: 'seated' },
    { name: 'Leg Abduction', pattern: 'isolation', primary: ['glutes'], equipment: ['machine'], position: 'seated' },
    { name: 'Hip Abduction', pattern: 'isolation', primary: ['glutes'], equipment: ['cable', 'resistance_band'], position: 'standing' },
    { name: 'Hip Adduction', pattern: 'isolation', primary: ['glutes'], equipment: ['cable', 'resistance_band'], position: 'standing' },
    { name: 'Standing Calf Raise', pattern: 'isolation', primary: ['calves'], equipment: ['machine', 'dumbbell', 'barbell'], position: 'standing' },
    { name: 'Seated Calf Raise', pattern: 'isolation', primary: ['calves'], equipment: ['machine'], position: 'seated' },
    { name: 'Donkey Calf Raise', pattern: 'isolation', primary: ['calves'], equipment: ['bodyweight'], position: 'standing' },
    { name: 'Single Leg Calf Raise', pattern: 'isolation', primary: ['calves'], equipment: ['bodyweight', 'dumbbell'], position: 'standing' },
    { name: 'Calf Press', pattern: 'isolation', primary: ['calves'], equipment: ['machine'], position: 'seated' },
    { name: 'Leg Press Calf Raise', pattern: 'isolation', primary: ['calves'], equipment: ['machine'], position: 'seated' },
    { name: 'Reverse Hyperextension', pattern: 'hinge', primary: ['hamstrings', 'glutes'], equipment: ['machine'], position: 'prone' },
    { name: 'Hyperextension', pattern: 'hinge', primary: ['back', 'glutes'], equipment: ['machine', 'bodyweight'], position: 'prone' },
    { name: 'Back Extension', pattern: 'hinge', primary: ['back'], equipment: ['machine', 'bodyweight'], position: 'prone' },
    { name: 'Weighted Hyperextension', pattern: 'hinge', primary: ['back', 'glutes'], equipment: ['dumbbell', 'plate'], position: 'prone' },
    { name: 'Single Leg Hip Extension', pattern: 'hinge', primary: ['glutes'], equipment: ['cable'], position: 'standing' },
    { name: 'Cable Hip Extension', pattern: 'hinge', primary: ['glutes'], equipment: ['cable'], position: 'standing' },
    { name: 'Glute Kickback', pattern: 'isolation', primary: ['glutes'], equipment: ['cable', 'resistance_band'], position: 'standing' },
    { name: 'Quadruped Hip Extension', pattern: 'isolation', primary: ['glutes'], equipment: ['bodyweight'], position: 'prone' },
    { name: 'Hip Thrust', pattern: 'hinge', primary: ['glutes'], equipment: ['barbell', 'dumbbell'], position: 'supine' },
    { name: 'Single Leg Hip Thrust', pattern: 'hinge', primary: ['glutes'], equipment: ['bodyweight'], position: 'supine' },
    { name: 'Frog Pump', pattern: 'hinge', primary: ['glutes'], equipment: ['bodyweight'], position: 'supine' },
    { name: 'Clamshell', pattern: 'isolation', primary: ['glutes'], equipment: ['bodyweight', 'resistance_band'], position: 'side' },
    { name: 'Side Lying Hip Abduction', pattern: 'isolation', primary: ['glutes'], equipment: ['bodyweight', 'resistance_band'], position: 'side' },
    { name: 'Monster Walk', pattern: 'isolation', primary: ['glutes'], equipment: ['resistance_band'], position: 'standing' },
    { name: 'Lateral Band Walk', pattern: 'isolation', primary: ['glutes'], equipment: ['resistance_band'], position: 'standing' },
    { name: 'Standing Hip Abduction', pattern: 'isolation', primary: ['glutes'], equipment: ['cable', 'resistance_band'], position: 'standing' },
    { name: 'Standing Hip Adduction', pattern: 'isolation', primary: ['glutes'], equipment: ['cable', 'resistance_band'], position: 'standing' },
    { name: 'Leg Extension', pattern: 'isolation', primary: ['quads'], equipment: ['machine'], position: 'seated' },
    { name: 'Single Leg Extension', pattern: 'isolation', primary: ['quads'], equipment: ['machine'], position: 'seated' },
    { name: 'Leg Curl', pattern: 'isolation', primary: ['hamstrings'], equipment: ['machine'], position: ['lying', 'seated', 'standing'] },
    { name: 'Lying Leg Curl', pattern: 'isolation', primary: ['hamstrings'], equipment: ['machine'], position: 'lying' },
    { name: 'Seated Leg Curl', pattern: 'isolation', primary: ['hamstrings'], equipment: ['machine'], position: 'seated' },
    { name: 'Standing Leg Curl', pattern: 'isolation', primary: ['hamstrings'], equipment: ['machine'], position: 'standing' },
    { name: 'Nordic Curl', pattern: 'isolation', primary: ['hamstrings'], equipment: ['bodyweight'], position: 'kneeling', difficulty: 'advanced' },
    { name: 'Single Leg Nordic Curl', pattern: 'isolation', primary: ['hamstrings'], equipment: ['bodyweight'], position: 'kneeling', difficulty: 'advanced' },
    { name: 'Glute Ham Raise', pattern: 'isolation', primary: ['hamstrings', 'glutes'], equipment: ['machine'], position: 'kneeling', difficulty: 'advanced' },
    { name: 'Sissy Squat', pattern: 'isolation', primary: ['quads'], equipment: ['bodyweight'], position: 'standing', difficulty: 'advanced' },
    { name: 'Wall Sit', pattern: 'isolation', primary: ['quads'], equipment: ['bodyweight'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Reverse Lunge', pattern: 'lunge', primary: ['quads', 'glutes'], equipment: ['bodyweight', 'dumbbell', 'barbell'], position: 'standing' },
    { name: 'Walking Lunge', pattern: 'lunge', primary: ['quads', 'glutes'], equipment: ['bodyweight', 'dumbbell'], position: 'standing' },
    { name: 'Lateral Lunge', pattern: 'lunge', primary: ['quads', 'glutes'], equipment: ['bodyweight', 'dumbbell'], position: 'standing' },
    { name: 'Curtsy Lunge', pattern: 'lunge', primary: ['quads', 'glutes'], equipment: ['bodyweight', 'dumbbell'], position: 'standing' },
    { name: 'Jumping Lunge', pattern: 'jump', primary: ['quads', 'glutes'], equipment: ['bodyweight'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Pistol Squat', pattern: 'squat', primary: ['quads', 'glutes'], equipment: ['bodyweight'], position: 'standing', difficulty: 'advanced' },
    { name: 'Shrimp Squat', pattern: 'squat', primary: ['quads', 'glutes'], equipment: ['bodyweight'], position: 'standing', difficulty: 'advanced' },
    { name: 'Goblet Squat', pattern: 'squat', primary: ['quads', 'glutes'], equipment: ['dumbbell', 'kettlebell'], position: 'standing' },
    { name: 'Front Squat', pattern: 'squat', primary: ['quads', 'glutes'], equipment: ['barbell'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Overhead Squat', pattern: 'squat', primary: ['quads', 'glutes', 'core'], equipment: ['barbell'], position: 'standing', difficulty: 'advanced' },
    { name: 'Hack Squat', pattern: 'squat', primary: ['quads', 'glutes'], equipment: ['machine'], position: 'standing' },
    { name: 'Bulgarian Split Squat', pattern: 'lunge', primary: ['quads', 'glutes'], equipment: ['bodyweight', 'dumbbell', 'barbell'], position: 'standing' },
    { name: 'Step-Up', pattern: 'lunge', primary: ['quads', 'glutes'], equipment: ['bodyweight', 'dumbbell'], position: 'standing' },
    { name: 'Weighted Step-Up', pattern: 'lunge', primary: ['quads', 'glutes'], equipment: ['dumbbell', 'barbell'], position: 'standing' },
    { name: 'Single Leg Step-Up', pattern: 'lunge', primary: ['quads', 'glutes'], equipment: ['bodyweight', 'dumbbell'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Romanian Deadlift', pattern: 'hinge', primary: ['hamstrings', 'glutes'], equipment: ['barbell', 'dumbbell'], position: 'standing' },
    { name: 'Stiff Leg Deadlift', pattern: 'hinge', primary: ['hamstrings', 'glutes'], equipment: ['barbell', 'dumbbell'], position: 'standing' },
    { name: 'Single Leg Romanian Deadlift', pattern: 'hinge', primary: ['hamstrings', 'glutes'], equipment: ['bodyweight', 'dumbbell'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Sumo Deadlift', pattern: 'hinge', primary: ['hamstrings', 'glutes', 'quads'], equipment: ['barbell'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Trap Bar Deadlift', pattern: 'hinge', primary: ['hamstrings', 'glutes', 'quads'], equipment: ['barbell'], position: 'standing' },
    { name: 'Deficit Deadlift', pattern: 'hinge', primary: ['hamstrings', 'glutes'], equipment: ['barbell'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Snatch Grip Deadlift', pattern: 'hinge', primary: ['hamstrings', 'glutes', 'back'], equipment: ['barbell'], position: 'standing', difficulty: 'advanced' },
    { name: 'Rack Pull', pattern: 'hinge', primary: ['back', 'glutes'], equipment: ['barbell'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Good Morning', pattern: 'hinge', primary: ['hamstrings', 'glutes', 'back'], equipment: ['barbell', 'bodyweight'], position: 'standing' },
    { name: 'Cable Pull-Through', pattern: 'hinge', primary: ['glutes', 'hamstrings'], equipment: ['cable'], position: 'standing' },
    { name: 'Kettlebell Swing', pattern: 'hinge', primary: ['glutes', 'hamstrings'], equipment: ['kettlebell'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Single Arm Kettlebell Swing', pattern: 'hinge', primary: ['glutes', 'hamstrings'], equipment: ['kettlebell'], position: 'standing', difficulty: 'intermediate' },
    { name: 'American Kettlebell Swing', pattern: 'hinge', primary: ['glutes', 'hamstrings', 'shoulders'], equipment: ['kettlebell'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Russian Kettlebell Swing', pattern: 'hinge', primary: ['glutes', 'hamstrings'], equipment: ['kettlebell'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Single Leg Glute Bridge', pattern: 'hinge', primary: ['glutes'], equipment: ['bodyweight'], position: 'supine' },
    { name: 'Weighted Glute Bridge', pattern: 'hinge', primary: ['glutes'], equipment: ['barbell', 'dumbbell'], position: 'supine', difficulty: 'intermediate' },
    { name: 'Hip Thrust', pattern: 'hinge', primary: ['glutes'], equipment: ['barbell', 'dumbbell'], position: 'supine', difficulty: 'intermediate' },
    { name: 'Single Leg Hip Thrust', pattern: 'hinge', primary: ['glutes'], equipment: ['bodyweight'], position: 'supine', difficulty: 'intermediate' },
    { name: 'Frog Pump', pattern: 'hinge', primary: ['glutes'], equipment: ['bodyweight'], position: 'supine' }
  ];
  
  isolationExercises.forEach(ex => {
    const positions = Array.isArray(ex.position) ? ex.position : [ex.position || 'standing'];
    const equipmentList = Array.isArray(ex.equipment) ? ex.equipment : [ex.equipment];
    
    equipmentList.forEach(eq => {
      positions.forEach(pos => {
        const base = {
          name: ex.name,
          pattern: ex.pattern,
          primary: ex.primary,
          secondary: ex.secondary || [],
          equipment: [eq],
          positions: [pos]
        };
        
        const exercise = generateExercise(base, eq, pos);
        
        // Override difficulty if specified
        if (ex.difficulty) {
          exercise.difficulty = ex.difficulty;
        }
        
        if (!seenNames.has(exercise.name.toLowerCase())) {
          exercises.push(exercise);
          seenNames.add(exercise.name.toLowerCase());
        }
      });
    });
  });
  
  // More compound variations
  const compoundVariations = [
    { base: 'Squat', variants: ['Overhead', 'Goblet', 'Jump', 'Pistol', 'Hack'] },
    { base: 'Deadlift', variants: ['Sumo', 'Trap Bar', 'Stiff Leg', 'Snatch Grip', 'Deficit'] },
    { base: 'Lunge', variants: ['Walking', 'Reverse', 'Lateral', 'Curtsy', 'Overhead'] },
    { base: 'Row', variants: ['T-Bar', 'Chest Supported', 'Inverted', 'Single-Arm'] },
    { base: 'Press', variants: ['Push', 'Arnold', 'Bradford', 'Behind Neck'] }
  ];
  
  // EXTENSIVE CORE EXERCISES (to reach 200+)
  const coreExercises = [
    // Basic crunches
    { name: 'Bicycle Crunch', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'V-Up', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'intermediate' },
    { name: 'Toes to Bar', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'advanced' },
    { name: 'L-Sit', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'advanced' },
    { name: 'Hollow Body Hold', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Ab Wheel Rollout', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'advanced' },
    { name: 'Dragon Flag', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'advanced' },
    { name: 'Flutter Kicks', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Scissor Kicks', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Reverse Crunch', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Hanging Leg Raise', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'intermediate' },
    { name: 'Cable Crunch', equipment: ['cable'], pattern: 'isolation' },
    { name: 'Decline Crunch', equipment: ['bodyweight', 'bench'], pattern: 'isolation' },
    { name: 'Stability Ball Crunch', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Swiss Ball Rollout', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'intermediate' },
    { name: 'Pallof Press', equipment: ['cable', 'resistance_band'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Anti-Rotation Hold', equipment: ['cable', 'resistance_band'], pattern: 'anti_rotation' },
    
    // More crunches and sit-ups
    { name: 'Crunches', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Sit-Up', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Weighted Crunch', equipment: ['dumbbell', 'plate'], pattern: 'isolation' },
    { name: 'Weighted Sit-Up', equipment: ['dumbbell', 'plate'], pattern: 'isolation' },
    { name: 'Medicine Ball Crunch', equipment: ['dumbbell'], pattern: 'isolation' },
    { name: 'Cable Rope Crunch', equipment: ['cable'], pattern: 'isolation' },
    { name: 'Kneeling Cable Crunch', equipment: ['cable'], pattern: 'isolation' },
    { name: 'Standing Cable Crunch', equipment: ['cable'], pattern: 'isolation' },
    { name: 'Cross Crunch', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Oblique Crunch', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Side Crunch', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Twisting Crunch', equipment: ['bodyweight'], pattern: 'rotation' },
    { name: 'Long Lever Crunch', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'intermediate' },
    { name: 'Frog Crunch', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Vertical Leg Crunch', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Reverse Vertical Leg Crunch', equipment: ['bodyweight'], pattern: 'isolation' },
    
    // Leg raises
    { name: 'Lying Leg Raise', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Hanging Knee Raise', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'intermediate' },
    { name: 'Hanging Straight Leg Raise', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'advanced' },
    { name: 'Cable Leg Raise', equipment: ['cable'], pattern: 'isolation' },
    { name: 'Bench Leg Raise', equipment: ['bodyweight', 'bench'], pattern: 'isolation' },
    { name: 'Weighted Leg Raise', equipment: ['dumbbell'], pattern: 'isolation' },
    { name: 'Alternating Leg Raise', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Single Leg Raise', equipment: ['bodyweight'], pattern: 'isolation' },
    
    // Planks
    { name: 'Plank', equipment: ['bodyweight'], pattern: 'anti_rotation' },
    { name: 'Side Plank', equipment: ['bodyweight'], pattern: 'anti_rotation' },
    { name: 'Reverse Plank', equipment: ['bodyweight'], pattern: 'anti_rotation' },
    { name: 'Weighted Plank', equipment: ['dumbbell', 'plate'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'RKC Plank', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Plank Up-Down', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Plank Jacks', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Plank Shoulder Tap', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Plank Pike', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Starfish Plank', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Spiderman Plank', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Moving Plank', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Forearm Plank', equipment: ['bodyweight'], pattern: 'anti_rotation' },
    { name: 'Extended Plank', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Single Arm Plank', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'advanced' },
    { name: 'Single Leg Plank', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Single Arm Single Leg Plank', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'advanced' },
    { name: 'Dolphin Plank', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Knee to Elbow Plank', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Bear Plank', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    
    // Dead bug variations
    { name: 'Dead Bug', equipment: ['bodyweight'], pattern: 'anti_rotation' },
    { name: 'Weighted Dead Bug', equipment: ['dumbbell'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Alternating Dead Bug', equipment: ['bodyweight'], pattern: 'anti_rotation' },
    { name: 'Single Arm Dead Bug', equipment: ['bodyweight'], pattern: 'anti_rotation' },
    { name: 'Single Leg Dead Bug', equipment: ['bodyweight'], pattern: 'anti_rotation' },
    
    // Russian twists and rotations
    { name: 'Russian Twist', equipment: ['bodyweight', 'dumbbell'], pattern: 'rotation' },
    { name: 'Weighted Russian Twist', equipment: ['dumbbell', 'plate'], pattern: 'rotation', difficulty: 'intermediate' },
    { name: 'Seated Russian Twist', equipment: ['bodyweight', 'dumbbell'], pattern: 'rotation' },
    { name: 'Standing Russian Twist', equipment: ['bodyweight', 'dumbbell'], pattern: 'rotation' },
    { name: 'Woodchopper', equipment: ['cable', 'resistance_band'], pattern: 'rotation' },
    { name: 'Cable Woodchopper', equipment: ['cable'], pattern: 'rotation' },
    { name: 'High to Low Woodchopper', equipment: ['cable'], pattern: 'rotation' },
    { name: 'Low to High Woodchopper', equipment: ['cable'], pattern: 'rotation' },
    { name: 'Standing Oblique Crunch', equipment: ['bodyweight', 'dumbbell'], pattern: 'rotation' },
    { name: 'Side Bend', equipment: ['bodyweight', 'dumbbell'], pattern: 'isolation' },
    { name: 'Cable Side Bend', equipment: ['cable'], pattern: 'isolation' },
    { name: 'Standing Cable Rotation', equipment: ['cable'], pattern: 'rotation' },
    { name: 'Seated Cable Rotation', equipment: ['cable'], pattern: 'rotation' },
    
    // Anti-rotation
    { name: 'Pallof Press Iso Hold', equipment: ['cable', 'resistance_band'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Pallof Press with Rotation', equipment: ['cable', 'resistance_band'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Standing Pallof Press', equipment: ['cable'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Kneeling Pallof Press', equipment: ['cable'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Half-Kneeling Pallof Press', equipment: ['cable'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Tall Kneeling Pallof Press', equipment: ['cable'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Single Arm Farmers Walk', equipment: ['dumbbell', 'kettlebell'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Single Arm Overhead Carry', equipment: ['dumbbell', 'kettlebell'], pattern: 'anti_rotation', difficulty: 'advanced' },
    { name: 'Waiter Walk', equipment: ['dumbbell', 'kettlebell'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    
    // Advanced core
    { name: 'Human Flag', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'advanced' },
    { name: 'Front Lever', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'advanced' },
    { name: 'Back Lever', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'advanced' },
    { name: 'Hanging Windshield Wiper', equipment: ['bodyweight'], pattern: 'rotation', difficulty: 'advanced' },
    { name: 'Hanging Oblique Raise', equipment: ['bodyweight'], pattern: 'rotation', difficulty: 'advanced' },
    { name: 'Dragon Flag Progression', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'advanced' },
    { name: 'Muscle Up', equipment: ['bodyweight'], pattern: 'vertical_pull', difficulty: 'advanced' },
    { name: 'L-Sit Pull-Up', equipment: ['bodyweight'], pattern: 'vertical_pull', difficulty: 'advanced' },
    { name: 'Archer Pull-Up', equipment: ['bodyweight'], pattern: 'vertical_pull', difficulty: 'advanced' },
    { name: 'Typewriter Pull-Up', equipment: ['bodyweight'], pattern: 'vertical_pull', difficulty: 'advanced' },
    
    // Core with equipment
    { name: 'TRX Pike', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'TRX Knee Tuck', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'intermediate' },
    { name: 'TRX Fallout', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'TRX Body Saw', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Suspension Trainer Crunch', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'GHD Sit-Up', equipment: ['machine'], pattern: 'isolation', difficulty: 'intermediate' },
    { name: 'Reverse Hyperextension', equipment: ['machine'], pattern: 'hinge', difficulty: 'intermediate' },
    { name: 'Hyperextension', equipment: ['machine', 'bodyweight'], pattern: 'hinge' },
    { name: 'Weighted Hyperextension', equipment: ['dumbbell', 'plate'], pattern: 'hinge', difficulty: 'intermediate' },
    { name: 'Cable Pull-Through', equipment: ['cable'], pattern: 'hinge' },
    { name: 'Kettlebell Swing', equipment: ['kettlebell'], pattern: 'hinge', difficulty: 'intermediate' },
    { name: 'Single Arm Kettlebell Swing', equipment: ['kettlebell'], pattern: 'hinge', difficulty: 'intermediate' },
    
    // Core stability
    { name: 'Bird Dog', equipment: ['bodyweight'], pattern: 'anti_rotation' },
    { name: 'Weighted Bird Dog', equipment: ['dumbbell'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Bear Crawl', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Crab Walk', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Turkish Get-Up', equipment: ['kettlebell', 'dumbbell'], pattern: 'anti_rotation', difficulty: 'advanced' },
    { name: 'Half Turkish Get-Up', equipment: ['kettlebell', 'dumbbell'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Windmill', equipment: ['kettlebell', 'dumbbell'], pattern: 'anti_rotation', difficulty: 'advanced' },
    { name: 'Bottoms Up Carry', equipment: ['kettlebell'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    
    // Core bridges
    { name: 'Glute Bridge', equipment: ['bodyweight'], pattern: 'hinge' },
    { name: 'Single Leg Glute Bridge', equipment: ['bodyweight'], pattern: 'hinge', difficulty: 'intermediate' },
    { name: 'Weighted Glute Bridge', equipment: ['barbell', 'dumbbell'], pattern: 'hinge', difficulty: 'intermediate' },
    { name: 'Hip Thrust', equipment: ['barbell', 'dumbbell'], pattern: 'hinge', difficulty: 'intermediate' },
    { name: 'Single Leg Hip Thrust', equipment: ['bodyweight'], pattern: 'hinge', difficulty: 'intermediate' },
    { name: 'Marching Glute Bridge', equipment: ['bodyweight'], pattern: 'hinge', difficulty: 'intermediate' },
    
    // Additional core
    { name: 'Flutter Kicks', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Scissor Kicks', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Leg Circles', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Bicycle Abs', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Starfish', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Mountain Climber', equipment: ['bodyweight'], pattern: 'gait', difficulty: 'intermediate' },
    { name: 'Cross Body Mountain Climber', equipment: ['bodyweight'], pattern: 'gait', difficulty: 'intermediate' },
    { name: 'Spiderman Mountain Climber', equipment: ['bodyweight'], pattern: 'gait', difficulty: 'intermediate' },
    { name: 'Bear Crawl Hold', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Hip Dip', equipment: ['bodyweight'], pattern: 'rotation' },
    { name: 'Seated Leg Tuck', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Cannonball', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Jackknife', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'intermediate' },
    { name: 'Reverse Hyper', equipment: ['bodyweight', 'bench'], pattern: 'hinge', difficulty: 'intermediate' },
    { name: 'Hollow Rock', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Arch Hold', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Superman Hold', equipment: ['bodyweight'], pattern: 'anti_rotation' },
    { name: 'Swimming', equipment: ['bodyweight'], pattern: 'anti_rotation' },
    { name: 'Weighted Swimming', equipment: ['dumbbell'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Seated Cable Crunch', equipment: ['cable'], pattern: 'isolation' },
    { name: 'Kneeling Cable Crunch', equipment: ['cable'], pattern: 'isolation' },
    { name: 'Cable Oblique Crunch', equipment: ['cable'], pattern: 'rotation' },
    { name: 'Side Plank Reach Through', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Side Plank Hip Dip', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Side Plank Leg Raise', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Side Plank Clamshell', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Plank to Pike', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Plank to Down Dog', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Reverse Plank Leg Raise', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Reverse Plank Toe Tap', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Hanging Side Knee Raise', equipment: ['bodyweight'], pattern: 'rotation', difficulty: 'intermediate' },
    { name: 'Hanging Oblique Knee Raise', equipment: ['bodyweight'], pattern: 'rotation', difficulty: 'intermediate' },
    { name: 'Hanging Windshield Wiper', equipment: ['bodyweight'], pattern: 'rotation', difficulty: 'advanced' },
    { name: 'L-Sit Hold', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'advanced' },
    { name: 'L-Sit Pull Through', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'advanced' },
    { name: 'L-Sit Leg Raise', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'advanced' },
    { name: 'Cable Crunch Single Arm', equipment: ['cable'], pattern: 'isolation' },
    { name: 'Cable Crunch Alternating', equipment: ['cable'], pattern: 'isolation' },
    { name: 'Weighted Side Plank', equipment: ['dumbbell'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Side Plank with Rotation', equipment: ['bodyweight'], pattern: 'rotation', difficulty: 'intermediate' },
    { name: 'Dead Bug with Band', equipment: ['resistance_band'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Plank Row', equipment: ['dumbbell'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Renegade Row', equipment: ['dumbbell'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Single Arm Renegade Row', equipment: ['dumbbell'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Bear Crawl Hold', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Bear Crawl Forward', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Bear Crawl Backward', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Crab Walk Forward', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Crab Walk Backward', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Body Saw', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'TRX Body Saw', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'TRX Fallout', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'TRX Pike', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'TRX Knee Tuck', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'intermediate' },
    { name: 'TRX Crunch', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Stability Ball Plank', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Stability Ball Rollout', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'intermediate' },
    { name: 'Stability Ball Pike', equipment: ['bodyweight'], pattern: 'isolation', difficulty: 'intermediate' },
    { name: 'Stability Ball Knee Tuck', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Stability Ball Crunch', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Stability Ball Reverse Crunch', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Stability Ball Side Plank', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Weighted Crunch on Ball', equipment: ['dumbbell'], pattern: 'isolation', difficulty: 'intermediate' },
    { name: 'Resistance Band Crunch', equipment: ['resistance_band'], pattern: 'isolation' },
    { name: 'Resistance Band Woodchopper', equipment: ['resistance_band'], pattern: 'rotation' },
    { name: 'Resistance Band Pallof Press', equipment: ['resistance_band'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Single Arm Farmers Walk', equipment: ['dumbbell', 'kettlebell'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Single Arm Overhead Carry', equipment: ['dumbbell', 'kettlebell'], pattern: 'anti_rotation', difficulty: 'advanced' },
    { name: 'Waiter Walk', equipment: ['dumbbell', 'kettlebell'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Bottoms Up Carry', equipment: ['kettlebell'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Suitcase Carry', equipment: ['dumbbell', 'kettlebell'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Farmers Walk', equipment: ['dumbbell', 'kettlebell'], pattern: 'carry', difficulty: 'intermediate' },
    { name: 'Overhead Carry', equipment: ['dumbbell', 'barbell', 'kettlebell'], pattern: 'carry', difficulty: 'intermediate' },
    { name: 'Double Kettlebell Carry', equipment: ['kettlebell'], pattern: 'carry', difficulty: 'intermediate' },
    { name: 'Rack Carry', equipment: ['kettlebell'], pattern: 'carry', difficulty: 'intermediate' },
    { name: 'Turkish Get-Up', equipment: ['kettlebell', 'dumbbell'], pattern: 'anti_rotation', difficulty: 'advanced' },
    { name: 'Half Turkish Get-Up', equipment: ['kettlebell', 'dumbbell'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Windmill', equipment: ['kettlebell', 'dumbbell'], pattern: 'anti_rotation', difficulty: 'advanced' },
    { name: 'Bent Press', equipment: ['kettlebell', 'dumbbell'], pattern: 'anti_rotation', difficulty: 'advanced' },
    { name: 'Side Bend with Kettlebell', equipment: ['kettlebell'], pattern: 'isolation' },
    { name: 'Kettlebell Around the World', equipment: ['kettlebell'], pattern: 'rotation', difficulty: 'intermediate' },
    { name: 'Kettlebell Halo', equipment: ['kettlebell'], pattern: 'rotation', difficulty: 'intermediate' },
    { name: 'Cable Halo', equipment: ['cable'], pattern: 'rotation', difficulty: 'intermediate' },
    { name: 'Resistance Band Halo', equipment: ['resistance_band'], pattern: 'rotation', difficulty: 'intermediate' },
    { name: 'Single Leg Deadlift Hold', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Single Leg Romanian Deadlift Hold', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Warrior III Hold', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Airplane Hold', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Single Leg Glute Bridge Hold', equipment: ['bodyweight'], pattern: 'anti_rotation' },
    { name: 'Marching Glute Bridge', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Single Leg Hip Thrust Hold', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Clamshell', equipment: ['bodyweight', 'resistance_band'], pattern: 'isolation' },
    { name: 'Side Lying Hip Abduction', equipment: ['bodyweight', 'resistance_band'], pattern: 'isolation' },
    { name: 'Side Lying Clamshell', equipment: ['bodyweight', 'resistance_band'], pattern: 'isolation' },
    { name: 'Fire Hydrant', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Donkey Kick', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Quadruped Hip Extension', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Quadruped Hip Abduction', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Quadruped Hip Circle', equipment: ['bodyweight'], pattern: 'isolation' },
    { name: 'Monster Walk', equipment: ['resistance_band'], pattern: 'isolation' },
    { name: 'Lateral Band Walk', equipment: ['resistance_band'], pattern: 'isolation' },
    { name: 'Forward Band Walk', equipment: ['resistance_band'], pattern: 'isolation' },
    { name: 'Backward Band Walk', equipment: ['resistance_band'], pattern: 'isolation' },
    { name: 'Standing Hip Abduction', equipment: ['cable', 'resistance_band'], pattern: 'isolation' },
    { name: 'Standing Hip Adduction', equipment: ['cable', 'resistance_band'], pattern: 'isolation' },
    { name: 'Standing Hip Extension', equipment: ['cable', 'resistance_band'], pattern: 'isolation' },
    { name: 'Standing Hip Flexion', equipment: ['cable', 'resistance_band'], pattern: 'isolation' },
    { name: 'Cable Pull-Through', equipment: ['cable'], pattern: 'hinge' },
    { name: 'Single Leg Cable Pull-Through', equipment: ['cable'], pattern: 'hinge', difficulty: 'intermediate' },
    { name: 'Cable Hip Extension', equipment: ['cable'], pattern: 'isolation' },
    { name: 'Cable Hip Abduction', equipment: ['cable'], pattern: 'isolation' },
    { name: 'Cable Hip Adduction', equipment: ['cable'], pattern: 'isolation' },
    { name: 'Cable Glute Kickback', equipment: ['cable'], pattern: 'isolation' },
    { name: 'Single Leg Cable Glute Kickback', equipment: ['cable'], pattern: 'isolation', difficulty: 'intermediate' },
    { name: 'Weighted Hip Thrust', equipment: ['barbell', 'dumbbell'], pattern: 'hinge', difficulty: 'intermediate' },
    { name: 'Banded Hip Thrust', equipment: ['resistance_band'], pattern: 'hinge', difficulty: 'intermediate' },
    { name: 'Single Leg Hip Thrust', equipment: ['bodyweight'], pattern: 'hinge', difficulty: 'intermediate' },
    { name: 'Weighted Single Leg Hip Thrust', equipment: ['dumbbell'], pattern: 'hinge', difficulty: 'advanced' },
    { name: 'Frog Pump', equipment: ['bodyweight'], pattern: 'hinge' },
    { name: 'Weighted Frog Pump', equipment: ['dumbbell', 'plate'], pattern: 'hinge', difficulty: 'intermediate' },
    { name: 'Glute Bridge Hold', equipment: ['bodyweight'], pattern: 'anti_rotation' },
    { name: 'Single Leg Glute Bridge Hold', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Weighted Glute Bridge Hold', equipment: ['barbell', 'dumbbell'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Marching Glute Bridge', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Single Leg Glute Bridge', equipment: ['bodyweight'], pattern: 'hinge', difficulty: 'intermediate' },
    { name: 'Weighted Single Leg Glute Bridge', equipment: ['dumbbell'], pattern: 'hinge', difficulty: 'advanced' },
    { name: 'Single Leg Romanian Deadlift', equipment: ['bodyweight', 'dumbbell'], pattern: 'hinge', difficulty: 'intermediate' },
    { name: 'Weighted Single Leg Romanian Deadlift', equipment: ['dumbbell'], pattern: 'hinge', difficulty: 'advanced' },
    { name: 'Single Leg Deadlift', equipment: ['bodyweight', 'dumbbell'], pattern: 'hinge', difficulty: 'intermediate' },
    { name: 'Weighted Single Leg Deadlift', equipment: ['dumbbell'], pattern: 'hinge', difficulty: 'advanced' },
    { name: 'Warrior III', equipment: ['bodyweight'], pattern: 'hinge', difficulty: 'intermediate' },
    { name: 'Single Leg Balance', equipment: ['bodyweight'], pattern: 'anti_rotation' },
    { name: 'Single Leg Balance with Reach', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Single Leg Balance with Rotation', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Single Leg Squat Hold', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Pistol Squat Negative', equipment: ['bodyweight'], pattern: 'squat', difficulty: 'intermediate' },
    { name: 'Assisted Pistol Squat', equipment: ['bodyweight'], pattern: 'squat', difficulty: 'intermediate' },
    { name: 'Shrimp Squat Negative', equipment: ['bodyweight'], pattern: 'squat', difficulty: 'intermediate' },
    { name: 'Assisted Shrimp Squat', equipment: ['bodyweight'], pattern: 'squat', difficulty: 'intermediate' },
    { name: 'Single Leg Wall Sit', equipment: ['bodyweight'], pattern: 'squat', difficulty: 'intermediate' },
    { name: 'Weighted Wall Sit', equipment: ['dumbbell', 'plate'], pattern: 'squat', difficulty: 'intermediate' },
    { name: 'Wall Sit with Leg Raise', equipment: ['bodyweight'], pattern: 'squat', difficulty: 'intermediate' },
    { name: 'Wall Sit with Knee Raise', equipment: ['bodyweight'], pattern: 'squat', difficulty: 'intermediate' },
    { name: 'Goblet Squat Hold', equipment: ['dumbbell', 'kettlebell'], pattern: 'squat', difficulty: 'intermediate' },
    { name: 'Overhead Squat Hold', equipment: ['barbell'], pattern: 'squat', difficulty: 'advanced' },
    { name: 'Front Squat Hold', equipment: ['barbell'], pattern: 'squat', difficulty: 'intermediate' },
    { name: 'Back Squat Hold', equipment: ['barbell'], pattern: 'squat', difficulty: 'intermediate' },
    { name: 'Jump Squat', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Weighted Jump Squat', equipment: ['dumbbell'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Jump Squat', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Box Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Weighted Box Jump', equipment: ['dumbbell'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Box Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Broad Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Weighted Broad Jump', equipment: ['dumbbell'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Broad Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Lateral Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Lateral Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: '180 Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: '360 Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Tuck Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Star Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Jumping Jacks', equipment: ['bodyweight'], pattern: 'jump' },
    { name: 'Power Jacks', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Burpee', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Burpee with Push-Up', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Burpee with Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Weighted Burpee', equipment: ['dumbbell'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Burpee', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Mountain Climber', equipment: ['bodyweight'], pattern: 'gait', difficulty: 'intermediate' },
    { name: 'Cross Body Mountain Climber', equipment: ['bodyweight'], pattern: 'gait', difficulty: 'intermediate' },
    { name: 'Spiderman Mountain Climber', equipment: ['bodyweight'], pattern: 'gait', difficulty: 'intermediate' },
    { name: 'Single Leg Mountain Climber', equipment: ['bodyweight'], pattern: 'gait', difficulty: 'intermediate' },
    { name: 'Alternating Mountain Climber', equipment: ['bodyweight'], pattern: 'gait', difficulty: 'intermediate' },
    { name: 'Bear Crawl Forward', equipment: ['bodyweight'], pattern: 'gait', difficulty: 'intermediate' },
    { name: 'Bear Crawl Backward', equipment: ['bodyweight'], pattern: 'gait', difficulty: 'intermediate' },
    { name: 'Bear Crawl Lateral', equipment: ['bodyweight'], pattern: 'gait', difficulty: 'intermediate' },
    { name: 'Bear Crawl Hold', equipment: ['bodyweight'], pattern: 'anti_rotation', difficulty: 'intermediate' },
    { name: 'Crab Walk Forward', equipment: ['bodyweight'], pattern: 'gait', difficulty: 'intermediate' },
    { name: 'Crab Walk Backward', equipment: ['bodyweight'], pattern: 'gait', difficulty: 'intermediate' },
    { name: 'Crab Walk Lateral', equipment: ['bodyweight'], pattern: 'gait', difficulty: 'intermediate' },
    { name: 'Duck Walk', equipment: ['bodyweight'], pattern: 'gait', difficulty: 'intermediate' },
    { name: 'Lateral Shuffle', equipment: ['bodyweight'], pattern: 'gait' },
    { name: 'Single Leg Lateral Shuffle', equipment: ['bodyweight'], pattern: 'gait', difficulty: 'intermediate' },
    { name: 'Carioca', equipment: ['bodyweight'], pattern: 'gait' },
    { name: 'High Knees', equipment: ['bodyweight'], pattern: 'gait' },
    { name: 'Butt Kicks', equipment: ['bodyweight'], pattern: 'gait' },
    { name: 'A-Skip', equipment: ['bodyweight'], pattern: 'gait' },
    { name: 'B-Skip', equipment: ['bodyweight'], pattern: 'gait' },
    { name: 'C-Skip', equipment: ['bodyweight'], pattern: 'gait' },
    { name: 'Straight Leg Bounds', equipment: ['bodyweight'], pattern: 'gait', difficulty: 'intermediate' },
    { name: 'Single Leg Bounds', equipment: ['bodyweight'], pattern: 'gait', difficulty: 'intermediate' },
    { name: 'Triple Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Triple Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Sprint', equipment: ['bodyweight'], pattern: 'sprint', difficulty: 'intermediate' },
    { name: 'Sprint Start', equipment: ['bodyweight'], pattern: 'sprint', difficulty: 'intermediate' },
    { name: 'Sprint Acceleration', equipment: ['bodyweight'], pattern: 'sprint', difficulty: 'intermediate' },
    { name: 'Sprint Deceleration', equipment: ['bodyweight'], pattern: 'sprint', difficulty: 'intermediate' },
    { name: 'Backward Sprint', equipment: ['bodyweight'], pattern: 'sprint', difficulty: 'intermediate' },
    { name: 'Lateral Sprint', equipment: ['bodyweight'], pattern: 'sprint', difficulty: 'intermediate' },
    { name: 'Single Leg Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Hop for Distance', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Hop for Height', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Alternating Single Leg Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Lateral Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Medial Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Forward Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Backward Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Double Leg Hop', equipment: ['bodyweight'], pattern: 'jump' },
    { name: 'Double Leg Hop for Distance', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Double Leg Hop for Height', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Alternating Double Leg Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Lateral Double Leg Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Forward Double Leg Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Backward Double Leg Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Triple Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Triple Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Standing Long Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Standing Triple Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Vertical Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Weighted Vertical Jump', equipment: ['dumbbell'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Vertical Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Countermovement Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Weighted Countermovement Jump', equipment: ['dumbbell'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Countermovement Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Drop Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Single Leg Drop Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Depth Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Single Leg Depth Jump', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Bound', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Bound', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Alternating Bound', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Alternating Bound', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Lateral Bound', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Lateral Bound', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Forward Bound', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Forward Bound', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Backward Bound', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Backward Bound', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Triple Bound', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Triple Bound', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'advanced' },
    { name: 'Single Leg Hop for Distance', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Hop for Height', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Alternating Single Leg Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Lateral Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Medial Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Forward Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Single Leg Backward Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Double Leg Hop', equipment: ['bodyweight'], pattern: 'jump' },
    { name: 'Double Leg Hop for Distance', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Double Leg Hop for Height', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Alternating Double Leg Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Lateral Double Leg Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Forward Double Leg Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' },
    { name: 'Backward Double Leg Hop', equipment: ['bodyweight'], pattern: 'jump', difficulty: 'intermediate' }
  ];
  
  coreExercises.forEach(core => {
    const name = typeof core === 'string' ? core : core.name;
    const equipment = typeof core === 'object' && core.equipment ? core.equipment : ['bodyweight'];
    const pattern = typeof core === 'object' && core.pattern ? core.pattern : 
                    (name.includes('Rotation') || name.includes('Pallof') || name.includes('Anti') ? 'anti_rotation' : 'isolation');
    const difficulty = typeof core === 'object' && core.difficulty ? core.difficulty :
                       (name.includes('Hanging') || name.includes('Dragon') || name.includes('L-Sit') || 
                        name.includes('Human Flag') || name.includes('Front Lever') || name.includes('Back Lever') ||
                        name.includes('Muscle Up') || name.includes('Turkish Get-Up') ? 'advanced' : 
                        name.includes('Single') || name.includes('Weighted') || name.includes('Pike') ? 'intermediate' : 'beginner');
    
    const muscles = getMuscleArray(['core'], ['obliques']);
    
    equipment.forEach(eq => {
      const exercise = {
        name: name + (equipment.length > 1 && eq !== 'bodyweight' ? ` (${eq})` : ''),
        short_desc: `Core strengthening exercise targeting abdominal muscles and stability.`,
        how_to: generateHowToSteps(name, Array.isArray(eq) ? eq : [eq], 'standing'),
        primary_muscles: muscles.primary,
        secondary_muscles: muscles.secondary,
        equipment: Array.isArray(eq) ? eq : [eq],
        movement_pattern: pattern,
        difficulty: difficulty,
        category: 'isolation',
        source: 'canonical_global_db',
        language: 'en',
        status: 'approved'
      };
      
      // Clean up name if it has redundant equipment
      if (exercise.name.includes(` (${eq})`) && exercise.equipment[0] === eq) {
        exercise.name = name;
      }
      
      if (!seenNames.has(exercise.name.toLowerCase())) {
        exercises.push(exercise);
        seenNames.add(exercise.name.toLowerCase());
      }
    });
  });
  
  // EXTENSIVE BODYWEIGHT EXERCISES (to reach 200+)
  const bodyweightExercises = [
    // Push-up variations
    { name: 'Pike Push Up', pattern: 'vertical_push', primary: ['shoulders'], difficulty: 'intermediate' },
    { name: 'Diamond Push Up', pattern: 'horizontal_push', primary: ['triceps', 'chest'], difficulty: 'intermediate' },
    { name: 'Archer Push Up', pattern: 'horizontal_push', primary: ['chest'], difficulty: 'advanced' },
    { name: 'Hindu Push Up', pattern: 'horizontal_push', primary: ['chest', 'shoulders', 'core'], difficulty: 'intermediate' },
    { name: 'Incline Push Up', pattern: 'horizontal_push', primary: ['chest'], difficulty: 'beginner' },
    { name: 'Decline Push Up', pattern: 'horizontal_push', primary: ['chest'], difficulty: 'intermediate' },
    { name: 'Wide-Grip Push Up', pattern: 'horizontal_push', primary: ['chest'], difficulty: 'beginner' },
    { name: 'Narrow-Grip Push Up', pattern: 'horizontal_push', primary: ['triceps', 'chest'], difficulty: 'intermediate' },
    { name: 'Spiderman Push Up', pattern: 'horizontal_push', primary: ['chest', 'core'], difficulty: 'intermediate' },
    { name: 'Staggered Push Up', pattern: 'horizontal_push', primary: ['chest'], difficulty: 'intermediate' },
    { name: 'Single Arm Push Up', pattern: 'horizontal_push', primary: ['chest'], difficulty: 'advanced' },
    { name: 'Typewriter Push Up', pattern: 'horizontal_push', primary: ['chest'], difficulty: 'advanced' },
    { name: 'Hindu Push Up', pattern: 'horizontal_push', primary: ['chest', 'shoulders', 'core'], difficulty: 'intermediate' },
    { name: 'Pike Push Up', pattern: 'vertical_push', primary: ['shoulders'], difficulty: 'intermediate' },
    { name: 'Wall Walk Push Up', pattern: 'vertical_push', primary: ['shoulders'], difficulty: 'advanced' },
    { name: 'Handstand Push Up', pattern: 'vertical_push', primary: ['shoulders'], difficulty: 'advanced' },
    { name: 'Pseudo Planche Push Up', pattern: 'horizontal_push', primary: ['chest', 'shoulders'], difficulty: 'advanced' },
    { name: 'Dive Bomber Push Up', pattern: 'horizontal_push', primary: ['chest', 'shoulders'], difficulty: 'intermediate' },
    { name: 'Clap Push Up', pattern: 'horizontal_push', primary: ['chest'], difficulty: 'intermediate' },
    { name: 'One Arm One Leg Push Up', pattern: 'horizontal_push', primary: ['chest', 'core'], difficulty: 'advanced' },
    
    // Pull-up/chin-up variations
    { name: 'Pull-Up', pattern: 'vertical_pull', primary: ['lats'], difficulty: 'intermediate' },
    { name: 'Chin-Up', pattern: 'vertical_pull', primary: ['biceps', 'lats'], difficulty: 'intermediate' },
    { name: 'Wide-Grip Pull-Up', pattern: 'vertical_pull', primary: ['lats'], difficulty: 'intermediate' },
    { name: 'Narrow-Grip Pull-Up', pattern: 'vertical_pull', primary: ['biceps', 'lats'], difficulty: 'intermediate' },
    { name: 'Commando Pull-Up', pattern: 'vertical_pull', primary: ['lats', 'biceps'], difficulty: 'advanced' },
    { name: 'Archer Pull-Up', pattern: 'vertical_pull', primary: ['lats'], difficulty: 'advanced' },
    { name: 'Typewriter Pull-Up', pattern: 'vertical_pull', primary: ['lats'], difficulty: 'advanced' },
    { name: 'L-Sit Pull-Up', pattern: 'vertical_pull', primary: ['lats', 'core'], difficulty: 'advanced' },
    { name: 'Muscle-Up', pattern: 'vertical_pull', primary: ['lats', 'triceps', 'chest'], difficulty: 'advanced' },
    { name: 'Weighted Pull-Up', pattern: 'vertical_pull', primary: ['lats'], difficulty: 'advanced' },
    { name: 'Behind Neck Pull-Up', pattern: 'vertical_pull', primary: ['lats'], difficulty: 'intermediate' },
    { name: 'One Arm Pull-Up', pattern: 'vertical_pull', primary: ['lats'], difficulty: 'advanced' },
    { name: 'Negative Pull-Up', pattern: 'vertical_pull', primary: ['lats'], difficulty: 'beginner' },
    { name: 'Australian Pull-Up', pattern: 'horizontal_pull', primary: ['lats', 'biceps'], difficulty: 'beginner' },
    { name: 'Wide-Grip Australian Pull-Up', pattern: 'horizontal_pull', primary: ['lats'], difficulty: 'beginner' },
    { name: 'Narrow-Grip Australian Pull-Up', pattern: 'horizontal_pull', primary: ['biceps', 'lats'], difficulty: 'beginner' },
    
    // Dips
    { name: 'Dip', pattern: 'vertical_push', primary: ['triceps', 'chest'], difficulty: 'intermediate' },
    { name: 'Bench Dip', pattern: 'vertical_push', primary: ['triceps'], difficulty: 'beginner' },
    { name: 'Ring Dip', pattern: 'vertical_push', primary: ['triceps', 'chest'], difficulty: 'advanced' },
    { name: 'Weighted Dip', pattern: 'vertical_push', primary: ['triceps', 'chest'], difficulty: 'advanced' },
    { name: 'Single Bar Dip', pattern: 'vertical_push', primary: ['triceps', 'chest'], difficulty: 'intermediate' },
    
    // Squats and lunges
    { name: 'Bodyweight Squat', pattern: 'squat', primary: ['quads', 'glutes'], difficulty: 'beginner' },
    { name: 'Jump Squat', pattern: 'jump', primary: ['quads', 'glutes'], difficulty: 'intermediate' },
    { name: 'Pistol Squat', pattern: 'squat', primary: ['quads', 'glutes'], difficulty: 'advanced' },
    { name: 'Shrimp Squat', pattern: 'squat', primary: ['quads', 'glutes'], difficulty: 'advanced' },
    { name: 'Sissy Squat', pattern: 'squat', primary: ['quads'], difficulty: 'advanced' },
    { name: 'Wall Sit', pattern: 'squat', primary: ['quads'], difficulty: 'intermediate' },
    { name: 'Single Leg Squat', pattern: 'squat', primary: ['quads', 'glutes'], difficulty: 'advanced' },
    { name: 'Narrow Stance Squat', pattern: 'squat', primary: ['quads', 'glutes'], difficulty: 'beginner' },
    { name: 'Wide Stance Squat', pattern: 'squat', primary: ['quads', 'glutes'], difficulty: 'beginner' },
    { name: 'Overhead Squat', pattern: 'squat', primary: ['quads', 'glutes', 'core'], difficulty: 'advanced' },
    { name: 'Jump Squat', pattern: 'jump', primary: ['quads', 'glutes'], difficulty: 'intermediate' },
    { name: 'Reverse Lunge', pattern: 'lunge', primary: ['quads', 'glutes'], difficulty: 'beginner' },
    { name: 'Walking Lunge', pattern: 'lunge', primary: ['quads', 'glutes'], difficulty: 'beginner' },
    { name: 'Lateral Lunge', pattern: 'lunge', primary: ['quads', 'glutes'], difficulty: 'beginner' },
    { name: 'Curtsy Lunge', pattern: 'lunge', primary: ['quads', 'glutes'], difficulty: 'intermediate' },
    { name: 'Jumping Lunge', pattern: 'jump', primary: ['quads', 'glutes'], difficulty: 'intermediate' },
    { name: 'Bulgarian Split Squat', pattern: 'lunge', primary: ['quads', 'glutes'], difficulty: 'intermediate' },
    { name: 'Single Leg Romanian Deadlift', pattern: 'hinge', primary: ['hamstrings', 'glutes'], difficulty: 'intermediate' },
    
    // Hinges and bridges
    { name: 'Glute Bridge', pattern: 'hinge', primary: ['glutes'], difficulty: 'beginner' },
    { name: 'Single Leg Glute Bridge', pattern: 'hinge', primary: ['glutes'], difficulty: 'intermediate' },
    { name: 'Hip Thrust', pattern: 'hinge', primary: ['glutes'], difficulty: 'intermediate' },
    { name: 'Single Leg Hip Thrust', pattern: 'hinge', primary: ['glutes'], difficulty: 'intermediate' },
    { name: 'Nordic Curl', pattern: 'hinge', primary: ['hamstrings'], difficulty: 'advanced' },
    { name: 'Single Leg Nordic Curl', pattern: 'hinge', primary: ['hamstrings'], difficulty: 'advanced' },
    { name: 'Hyperextension', pattern: 'hinge', primary: ['back', 'glutes'], difficulty: 'beginner' },
    { name: 'Good Morning', pattern: 'hinge', primary: ['hamstrings', 'glutes'], difficulty: 'intermediate' },
    
    // Core bodyweight
    { name: 'Plank', pattern: 'anti_rotation', primary: ['core'], difficulty: 'beginner' },
    { name: 'Side Plank', pattern: 'anti_rotation', primary: ['core'], difficulty: 'beginner' },
    { name: 'Reverse Plank', pattern: 'anti_rotation', primary: ['core'], difficulty: 'intermediate' },
    { name: 'Hollow Body Hold', pattern: 'anti_rotation', primary: ['core'], difficulty: 'intermediate' },
    { name: 'Hollow Rock', pattern: 'anti_rotation', primary: ['core'], difficulty: 'intermediate' },
    { name: 'Arch Hold', pattern: 'anti_rotation', primary: ['core'], difficulty: 'intermediate' },
    { name: 'V-Sit', pattern: 'isolation', primary: ['core'], difficulty: 'intermediate' },
    { name: 'L-Sit', pattern: 'isolation', primary: ['core'], difficulty: 'advanced' },
    { name: 'Human Flag', pattern: 'anti_rotation', primary: ['core', 'shoulders'], difficulty: 'advanced' },
    { name: 'Front Lever', pattern: 'anti_rotation', primary: ['core', 'lats'], difficulty: 'advanced' },
    { name: 'Back Lever', pattern: 'anti_rotation', primary: ['core', 'back'], difficulty: 'advanced' },
    
    // Cardio/conditioning
    { name: 'Burpee', pattern: 'jump', primary: ['quads', 'glutes', 'core'], difficulty: 'intermediate' },
    { name: 'Mountain Climber', pattern: 'gait', primary: ['core'], difficulty: 'intermediate' },
    { name: 'Bear Crawl', pattern: 'gait', primary: ['core', 'shoulders'], difficulty: 'intermediate' },
    { name: 'Crab Walk', pattern: 'gait', primary: ['glutes', 'shoulders'], difficulty: 'intermediate' },
    { name: 'Jumping Jacks', pattern: 'jump', primary: ['shoulders', 'quads'], difficulty: 'beginner' },
    { name: 'Star Jumps', pattern: 'jump', primary: ['quads', 'glutes'], difficulty: 'intermediate' },
    { name: 'Tuck Jumps', pattern: 'jump', primary: ['quads', 'glutes'], difficulty: 'intermediate' },
    { name: 'Broad Jump', pattern: 'jump', primary: ['quads', 'glutes'], difficulty: 'intermediate' },
    { name: 'Box Jump', pattern: 'jump', primary: ['quads', 'glutes'], difficulty: 'intermediate' },
    { name: 'High Knees', pattern: 'gait', primary: ['quads', 'calves'], difficulty: 'beginner' },
    { name: 'Butt Kicks', pattern: 'gait', primary: ['hamstrings', 'calves'], difficulty: 'beginner' },
    { name: 'Lateral Shuffle', pattern: 'gait', primary: ['glutes', 'quads'], difficulty: 'beginner' },
    { name: 'A-Skip', pattern: 'gait', primary: ['quads', 'calves'], difficulty: 'beginner' },
    { name: 'B-Skip', pattern: 'gait', primary: ['hamstrings', 'quads'], difficulty: 'beginner' },
    { name: 'Duck Walk', pattern: 'gait', primary: ['quads', 'glutes'], difficulty: 'intermediate' },
    
    // Gymnastics/calisthenics
    { name: 'Muscle-Up', pattern: 'vertical_pull', primary: ['lats', 'triceps', 'chest'], difficulty: 'advanced' },
    { name: 'Planche', pattern: 'horizontal_push', primary: ['shoulders', 'chest', 'core'], difficulty: 'advanced' },
    { name: 'Planche Push-Up', pattern: 'horizontal_push', primary: ['shoulders', 'chest'], difficulty: 'advanced' },
    { name: 'Handstand', pattern: 'anti_rotation', primary: ['shoulders', 'core'], difficulty: 'advanced' },
    { name: 'Handstand Push-Up', pattern: 'vertical_push', primary: ['shoulders'], difficulty: 'advanced' },
    { name: 'Wall Handstand Push-Up', pattern: 'vertical_push', primary: ['shoulders'], difficulty: 'advanced' },
    { name: 'One Arm Handstand', pattern: 'anti_rotation', primary: ['shoulders', 'core'], difficulty: 'advanced' },
    { name: 'Dragon Flag', pattern: 'isolation', primary: ['core'], difficulty: 'advanced' },
    { name: 'Ab Wheel Rollout', pattern: 'isolation', primary: ['core'], difficulty: 'advanced' },
    { name: 'Hanging Leg Raise', pattern: 'isolation', primary: ['core'], difficulty: 'intermediate' },
    { name: 'Toes to Bar', pattern: 'isolation', primary: ['core'], difficulty: 'advanced' },
    { name: 'Hanging Windshield Wiper', pattern: 'rotation', primary: ['core'], difficulty: 'advanced' },
    
    // Balance and stability
    { name: 'Single Leg Balance', pattern: 'anti_rotation', primary: ['core'], difficulty: 'beginner' },
    { name: 'Single Leg Deadlift', pattern: 'hinge', primary: ['hamstrings', 'glutes', 'core'], difficulty: 'intermediate' },
    { name: 'Warrior III', pattern: 'hinge', primary: ['hamstrings', 'glutes', 'core'], difficulty: 'intermediate' },
    { name: 'Tree Pose', pattern: 'anti_rotation', primary: ['core'], difficulty: 'beginner' },
    
    // Mobility
    { name: 'Cat-Cow', pattern: 'isolation', primary: ['back', 'core'], difficulty: 'beginner' },
    { name: 'Hip Circle', pattern: 'isolation', primary: ['glutes', 'hips'], difficulty: 'beginner' },
    { name: 'Leg Swings', pattern: 'isolation', primary: ['hips'], difficulty: 'beginner' },
    { name: 'Hip Flexor Stretch', pattern: 'isolation', primary: ['hips'], difficulty: 'beginner' },
    { name: 'Pigeon Pose', pattern: 'isolation', primary: ['hips', 'glutes'], difficulty: 'beginner' },
    { name: '90-90 Stretch', pattern: 'isolation', primary: ['hips'], difficulty: 'beginner' }
  ];
  
  bodyweightExercises.forEach(bw => {
    const muscles = getMuscleArray(bw.primary, bw.secondary || []);
    const exercise = {
      name: bw.name,
      short_desc: generateShortDesc(bw.name, muscles.primary, bw.pattern),
      how_to: generateHowToSteps(bw.name, ['bodyweight'], 'standing'),
      primary_muscles: muscles.primary,
      secondary_muscles: muscles.secondary,
      equipment: ['bodyweight'],
      movement_pattern: bw.pattern,
      difficulty: bw.difficulty || 'intermediate',
      category: ['squat', 'hinge', 'horizontal_push', 'vertical_push', 'horizontal_pull', 'vertical_pull'].includes(bw.pattern) ? 'compound' : 'isolation',
      source: 'canonical_global_db',
      language: 'en',
      status: 'approved'
    };
    
    if (!seenNames.has(exercise.name.toLowerCase())) {
      exercises.push(exercise);
      seenNames.add(exercise.name.toLowerCase());
    }
  });
  
  // Olympic Lifts and Advanced Movements
  const olympicLifts = [
    { name: 'Clean', pattern: 'vertical_pull', primary: ['quads', 'glutes', 'traps'], equipment: ['barbell'], position: 'standing', difficulty: 'advanced' },
    { name: 'Power Clean', pattern: 'vertical_pull', primary: ['quads', 'glutes', 'traps'], equipment: ['barbell'], position: 'standing', difficulty: 'advanced' },
    { name: 'Hang Clean', pattern: 'vertical_pull', primary: ['quads', 'glutes', 'traps'], equipment: ['barbell'], position: 'standing', difficulty: 'advanced' },
    { name: 'High Pull', pattern: 'vertical_pull', primary: ['traps', 'quads', 'glutes'], equipment: ['barbell'], position: 'standing', difficulty: 'advanced' },
    { name: 'Snatch', pattern: 'vertical_pull', primary: ['quads', 'glutes', 'shoulders'], equipment: ['barbell'], position: 'standing', difficulty: 'advanced' },
    { name: 'Power Snatch', pattern: 'vertical_pull', primary: ['quads', 'glutes', 'shoulders'], equipment: ['barbell'], position: 'standing', difficulty: 'advanced' },
    { name: 'Hang Snatch', pattern: 'vertical_pull', primary: ['quads', 'glutes', 'shoulders'], equipment: ['barbell'], position: 'standing', difficulty: 'advanced' },
    { name: 'Clean and Jerk', pattern: 'vertical_pull', primary: ['quads', 'glutes', 'shoulders'], equipment: ['barbell'], position: 'standing', difficulty: 'advanced' },
    { name: 'Jerk', pattern: 'vertical_push', primary: ['shoulders', 'triceps', 'quads'], equipment: ['barbell'], position: 'standing', difficulty: 'advanced' },
    { name: 'Push Press', pattern: 'vertical_push', primary: ['shoulders', 'triceps', 'quads'], equipment: ['barbell', 'dumbbell'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Push Jerk', pattern: 'vertical_push', primary: ['shoulders', 'triceps', 'quads'], equipment: ['barbell'], position: 'standing', difficulty: 'advanced' },
    { name: 'Split Jerk', pattern: 'vertical_push', primary: ['shoulders', 'triceps', 'quads'], equipment: ['barbell'], position: 'standing', difficulty: 'advanced' },
    { name: 'Thruster', pattern: 'vertical_push', primary: ['quads', 'glutes', 'shoulders'], equipment: ['barbell', 'dumbbell'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Kettlebell Clean', pattern: 'vertical_pull', primary: ['quads', 'glutes', 'traps'], equipment: ['kettlebell'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Kettlebell Snatch', pattern: 'vertical_pull', primary: ['quads', 'glutes', 'shoulders'], equipment: ['kettlebell'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Kettlebell Clean and Press', pattern: 'vertical_pull', primary: ['quads', 'glutes', 'shoulders'], equipment: ['kettlebell'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Kettlebell Clean and Jerk', pattern: 'vertical_pull', primary: ['quads', 'glutes', 'shoulders'], equipment: ['kettlebell'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Dumbbell Clean', pattern: 'vertical_pull', primary: ['quads', 'glutes', 'traps'], equipment: ['dumbbell'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Dumbbell Snatch', pattern: 'vertical_pull', primary: ['quads', 'glutes', 'shoulders'], equipment: ['dumbbell'], position: 'standing', difficulty: 'intermediate' },
    { name: 'Dumbbell Thruster', pattern: 'vertical_push', primary: ['quads', 'glutes', 'shoulders'], equipment: ['dumbbell'], position: 'standing', difficulty: 'intermediate' }
  ];
  
  olympicLifts.forEach(ol => {
    const muscles = getMuscleArray(ol.primary, []);
    const exercise = {
      name: ol.name,
      short_desc: generateShortDesc(ol.name, muscles.primary, ol.pattern),
      how_to: generateHowToSteps(ol.name, Array.isArray(ol.equipment) ? ol.equipment : [ol.equipment], ol.position || 'standing'),
      primary_muscles: muscles.primary,
      secondary_muscles: muscles.secondary,
      equipment: Array.isArray(ol.equipment) ? ol.equipment : [ol.equipment],
      movement_pattern: ol.pattern,
      difficulty: ol.difficulty || 'advanced',
      category: 'compound',
      source: 'canonical_global_db',
      language: 'en',
      status: 'approved'
    };
    
    if (!seenNames.has(exercise.name.toLowerCase())) {
      exercises.push(exercise);
      seenNames.add(exercise.name.toLowerCase());
    }
  });
  
  // Cardio/conditioning exercises
  const cardioExercises = [
    { name: 'High Knees', pattern: 'gait', primary: ['quads', 'calves', 'core'] },
    { name: 'Butt Kicks', pattern: 'gait', primary: ['hamstrings', 'calves'] },
    { name: 'Jumping Jacks', pattern: 'jump', primary: ['shoulders', 'quads', 'calves'] },
    { name: 'Star Jumps', pattern: 'jump', primary: ['quads', 'glutes', 'calves'] },
    { name: 'Tuck Jumps', pattern: 'jump', primary: ['quads', 'glutes', 'calves'] },
    { name: 'Broad Jump', pattern: 'jump', primary: ['quads', 'glutes', 'calves'] },
    { name: 'Box Jump', pattern: 'jump', primary: ['quads', 'glutes', 'calves'] },
    { name: 'Sprint', pattern: 'sprint', primary: ['quads', 'hamstrings', 'calves', 'glutes'] },
    { name: 'Lateral Shuffle', pattern: 'gait', primary: ['glutes', 'quads'] },
    { name: 'A-Skip', pattern: 'gait', primary: ['quads', 'calves'] },
    { name: 'B-Skip', pattern: 'gait', primary: ['hamstrings', 'quads'] },
    { name: 'Bear Crawl', pattern: 'gait', primary: ['core', 'shoulders', 'quads'] },
    { name: 'Crab Walk', pattern: 'gait', primary: ['glutes', 'shoulders', 'core'] },
    { name: 'Duck Walk', pattern: 'gait', primary: ['quads', 'glutes'] }
  ];
  
  cardioExercises.forEach(cardio => {
    const muscles = getMuscleArray(cardio.primary, []);
    const exercise = {
      name: cardio.name,
      short_desc: generateShortDesc(cardio.name, muscles.primary, cardio.pattern),
      how_to: generateHowToSteps(cardio.name, ['bodyweight'], 'standing'),
      primary_muscles: muscles.primary,
      secondary_muscles: muscles.secondary,
      equipment: ['bodyweight'],
      movement_pattern: cardio.pattern,
      difficulty: 'intermediate',
      category: 'isolation',
      source: 'canonical_global_db',
      language: 'en',
      status: 'approved'
    };
    
    if (!seenNames.has(exercise.name.toLowerCase())) {
      exercises.push(exercise);
      seenNames.add(exercise.name.toLowerCase());
    }
  });
  
  return exercises;
}

// =====================================================
// MAIN EXECUTION
// =====================================================

console.log('🚀 Generating canonical exercise knowledge seed...\n');

const exercises = generateAllExercises();

console.log(`✅ Generated ${exercises.length} exercises\n`);

// Statistics
const stats = {
  total: exercises.length,
  byEquipment: {},
  byMovementPattern: {},
  byPrimaryMuscle: {},
  byDifficulty: {},
  byCategory: {}
};

exercises.forEach(ex => {
  // Equipment
  ex.equipment.forEach(eq => {
    stats.byEquipment[eq] = (stats.byEquipment[eq] || 0) + 1;
  });
  
  // Movement pattern
  stats.byMovementPattern[ex.movement_pattern] = (stats.byMovementPattern[ex.movement_pattern] || 0) + 1;
  
  // Primary muscle
  ex.primary_muscles.forEach(muscle => {
    if (!muscle.includes('_')) { // Only count English names
      stats.byPrimaryMuscle[muscle] = (stats.byPrimaryMuscle[muscle] || 0) + 1;
    }
  });
  
  // Difficulty
  stats.byDifficulty[ex.difficulty] = (stats.byDifficulty[ex.difficulty] || 0) + 1;
  
  // Category
  stats.byCategory[ex.category] = (stats.byCategory[ex.category] || 0) + 1;
});

console.log('📊 STATISTICS:\n');
console.log(`Total Exercises: ${stats.total}\n`);

console.log('By Equipment:');
Object.entries(stats.byEquipment).sort((a, b) => b[1] - a[1]).forEach(([eq, count]) => {
  console.log(`  ${eq}: ${count}`);
});

console.log('\nBy Movement Pattern:');
Object.entries(stats.byMovementPattern).sort((a, b) => b[1] - a[1]).forEach(([pattern, count]) => {
  console.log(`  ${pattern}: ${count}`);
});

console.log('\nBy Category:');
Object.entries(stats.byCategory).forEach(([cat, count]) => {
  console.log(`  ${cat}: ${count}`);
});

console.log('\nBy Difficulty:');
Object.entries(stats.byDifficulty).forEach(([diff, count]) => {
  console.log(`  ${diff}: ${count}`);
});

// Write to file
const outputPath = path.join(__dirname, '..', 'supabase', 'seeds', 'exercise_knowledge_seed.json');
fs.writeFileSync(outputPath, JSON.stringify(exercises, null, 2), 'utf8');

console.log(`\n✅ Saved to: ${outputPath}`);
console.log(`\n📝 File size: ${(fs.statSync(outputPath).size / 1024 / 1024).toFixed(2)} MB`);

// Validation checks
console.log('\n🔍 VALIDATION:');
const validationIssues = [];

// Check for duplicates
const nameCounts = {};
exercises.forEach(ex => {
  const lower = ex.name.toLowerCase();
  nameCounts[lower] = (nameCounts[lower] || 0) + 1;
});

const duplicates = Object.entries(nameCounts).filter(([name, count]) => count > 1);
if (duplicates.length > 0) {
  validationIssues.push(`Found ${duplicates.length} duplicate names`);
} else {
  console.log('  ✅ No duplicate names');
}

// Check minimums
const minChecks = [
  { name: 'Compound', target: 400, actual: stats.byCategory.compound || 0 },
  { name: 'Isolation', target: 600, actual: stats.byCategory.isolation || 0 },
  { name: 'Bodyweight', target: 200, actual: stats.byEquipment.bodyweight || 0 },
  { name: 'Core', target: 200, actual: (exercises.filter(ex => ex.primary_muscles.includes('core')).length) }
];

minChecks.forEach(check => {
  if (check.actual >= check.target) {
    console.log(`  ✅ ${check.name}: ${check.actual} (target: ${check.target})`);
  } else {
    console.log(`  ⚠️  ${check.name}: ${check.actual} (target: ${check.target}) - BELOW TARGET`);
    validationIssues.push(`${check.name} below target (${check.actual}/${check.target})`);
  }
});

if (validationIssues.length > 0) {
  console.log('\n⚠️  Validation issues found:', validationIssues);
} else {
  console.log('\n✅ All validations passed!');
}

console.log('\n✨ Generation complete!');
