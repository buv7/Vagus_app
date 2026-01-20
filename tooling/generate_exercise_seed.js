#!/usr/bin/env node

/**
 * Generate Exercise Knowledge Seed JSON
 * Creates a comprehensive seed file with 2000+ exercises
 */

const fs = require('fs');
const path = require('path');

// Muscle tag mappings (English -> Anatomical)
const muscleTagMap = {
  chest: ['pectoralis_major', 'pectoralis_minor'],
  back: ['latissimus_dorsi', 'rhomboids', 'middle_trapezius', 'lower_trapezius'],
  lats: ['latissimus_dorsi'],
  triceps: ['triceps_brachii'],
  biceps: ['biceps_brachii', 'brachialis'],
  quads: ['quadriceps', 'rectus_femoris', 'vastus_lateralis', 'vastus_medialis'],
  hamstrings: ['hamstrings', 'biceps_femoris', 'semitendinosus', 'semimembranosus'],
  glutes: ['gluteus_maximus', 'gluteus_medius', 'gluteus_minimus'],
  calves: ['gastrocnemius', 'soleus'],
  delts: ['deltoid', 'anterior_deltoid', 'medial_deltoid', 'posterior_deltoid'],
  front_delts: ['anterior_deltoid'],
  rear_delts: ['posterior_deltoid'],
  side_delts: ['medial_deltoid'],
  core: ['rectus_abdominis', 'transverse_abdominis', 'obliques', 'erector_spinae'],
  shoulders: ['deltoid', 'anterior_deltoid', 'medial_deltoid', 'posterior_deltoid'],
  arms: ['biceps_brachii', 'triceps_brachii', 'brachialis'],
  legs: ['quadriceps', 'rectus_femoris', 'vastus_lateralis', 'hamstrings', 'biceps_femoris', 'gluteus_maximus', 'gastrocnemius'],
};

// Helper to add anatomical tags to muscle arrays
function addAnatomicalTags(muscles) {
  const result = [...muscles];
  muscles.forEach(muscle => {
    const anatomical = muscleTagMap[muscle.toLowerCase()];
    if (anatomical) {
      anatomical.forEach(tag => {
        if (!result.includes(tag)) {
          result.push(tag);
        }
      });
    }
  });
  return result;
}

// Exercise templates by category
const exerciseTemplates = {
  chest: [
    { name: 'Barbell Bench Press', aliases: ['Bench Press', 'BB Bench'], pattern: 'push', equipment: ['barbell', 'bench'], difficulty: 'intermediate' },
    { name: 'Dumbbell Bench Press', aliases: ['DB Bench'], pattern: 'push', equipment: ['dumbbells', 'bench'], difficulty: 'intermediate' },
    { name: 'Incline Barbell Bench Press', aliases: ['Incline Bench'], pattern: 'push', equipment: ['barbell', 'bench'], difficulty: 'intermediate' },
    { name: 'Incline Dumbbell Press', aliases: ['Incline DB Press'], pattern: 'push', equipment: ['dumbbells', 'bench'], difficulty: 'intermediate' },
    { name: 'Decline Bench Press', aliases: ['Decline Press'], pattern: 'push', equipment: ['barbell', 'bench'], difficulty: 'intermediate' },
    { name: 'Cable Flyes', aliases: ['Cable Crossover'], pattern: 'push', equipment: ['cables'], difficulty: 'beginner' },
    { name: 'Dumbbell Flyes', aliases: ['DB Flyes'], pattern: 'push', equipment: ['dumbbells', 'bench'], difficulty: 'beginner' },
    { name: 'Push-ups', aliases: ['Push Ups', 'Press Ups'], pattern: 'push', equipment: ['bodyweight'], difficulty: 'beginner' },
    { name: 'Diamond Push-ups', aliases: [], pattern: 'push', equipment: ['bodyweight'], difficulty: 'intermediate' },
    { name: 'Wide Grip Push-ups', aliases: [], pattern: 'push', equipment: ['bodyweight'], difficulty: 'beginner' },
    { name: 'Pec Deck', aliases: ['Butterfly Machine'], pattern: 'push', equipment: ['machine'], difficulty: 'beginner' },
    { name: 'Chest Dips', aliases: ['Dips'], pattern: 'push', equipment: ['bodyweight', 'dip_station'], difficulty: 'intermediate' },
    { name: 'Landmine Press', aliases: [], pattern: 'push', equipment: ['barbell', 'landmine'], difficulty: 'intermediate' },
    { name: 'Chest Press Machine', aliases: ['Machine Press'], pattern: 'push', equipment: ['machine'], difficulty: 'beginner' },
    { name: 'Pike Push-ups', aliases: [], pattern: 'push', equipment: ['bodyweight'], difficulty: 'intermediate' },
  ],
  back: [
    { name: 'Barbell Row', aliases: ['BB Row'], pattern: 'pull', equipment: ['barbell'], difficulty: 'intermediate' },
    { name: 'Dumbbell Row', aliases: ['DB Row'], pattern: 'pull', equipment: ['dumbbells', 'bench'], difficulty: 'intermediate' },
    { name: 'Pull-ups', aliases: ['Chin-ups'], pattern: 'pull', equipment: ['bodyweight', 'pull_up_bar'], difficulty: 'intermediate' },
    { name: 'Lat Pulldown', aliases: ['Pulldown'], pattern: 'pull', equipment: ['machine', 'cables'], difficulty: 'beginner' },
    { name: 'Cable Row', aliases: ['Seated Row'], pattern: 'pull', equipment: ['cables', 'machine'], difficulty: 'beginner' },
    { name: 'T-Bar Row', aliases: [], pattern: 'pull', equipment: ['barbell', 'landmine'], difficulty: 'intermediate' },
    { name: 'Seated Cable Row', aliases: ['Seated Row'], pattern: 'pull', equipment: ['cables'], difficulty: 'beginner' },
    { name: 'One-Arm Dumbbell Row', aliases: ['Single Arm Row'], pattern: 'pull', equipment: ['dumbbells', 'bench'], difficulty: 'intermediate' },
    { name: 'Wide Grip Pull-ups', aliases: [], pattern: 'pull', equipment: ['bodyweight', 'pull_up_bar'], difficulty: 'advanced' },
    { name: 'Close Grip Pull-ups', aliases: [], pattern: 'pull', equipment: ['bodyweight', 'pull_up_bar'], difficulty: 'intermediate' },
    { name: 'Chest Supported Row', aliases: ['Incline Row'], pattern: 'pull', equipment: ['dumbbells', 'bench'], difficulty: 'beginner' },
    { name: 'Face Pulls', aliases: [], pattern: 'pull', equipment: ['cables'], difficulty: 'beginner' },
    { name: 'Reverse Flyes', aliases: ['Rear Delt Flyes'], pattern: 'pull', equipment: ['dumbbells', 'cables'], difficulty: 'beginner' },
    { name: 'Shrugs', aliases: [], pattern: 'pull', equipment: ['barbell', 'dumbbells'], difficulty: 'beginner' },
    { name: 'Hyperextensions', aliases: ['Back Extensions'], pattern: 'hinge', equipment: ['bodyweight', 'bench'], difficulty: 'beginner' },
  ],
  legs: [
    { name: 'Barbell Squat', aliases: ['Back Squat', 'Squat'], pattern: 'squat', equipment: ['barbell'], difficulty: 'intermediate' },
    { name: 'Front Squat', aliases: [], pattern: 'squat', equipment: ['barbell'], difficulty: 'advanced' },
    { name: 'Goblet Squat', aliases: [], pattern: 'squat', equipment: ['dumbbell', 'kettlebell'], difficulty: 'beginner' },
    { name: 'Leg Press', aliases: [], pattern: 'squat', equipment: ['machine'], difficulty: 'beginner' },
    { name: 'Romanian Deadlift', aliases: ['RDL'], pattern: 'hinge', equipment: ['barbell', 'dumbbells'], difficulty: 'intermediate' },
    { name: 'Deadlift', aliases: ['Conventional Deadlift'], pattern: 'hinge', equipment: ['barbell'], difficulty: 'intermediate' },
    { name: 'Sumo Deadlift', aliases: [], pattern: 'hinge', equipment: ['barbell'], difficulty: 'intermediate' },
    { name: 'Leg Curl', aliases: ['Hamstring Curl'], pattern: 'hinge', equipment: ['machine'], difficulty: 'beginner' },
    { name: 'Leg Extension', aliases: ['Quad Extension'], pattern: 'squat', equipment: ['machine'], difficulty: 'beginner' },
    { name: 'Walking Lunges', aliases: ['Lunges'], pattern: 'squat', equipment: ['bodyweight', 'dumbbells'], difficulty: 'beginner' },
    { name: 'Bulgarian Split Squat', aliases: ['BSS'], pattern: 'squat', equipment: ['dumbbells', 'bench'], difficulty: 'intermediate' },
    { name: 'Hip Thrust', aliases: ['Glute Bridge'], pattern: 'hinge', equipment: ['barbell', 'bodyweight'], difficulty: 'intermediate' },
    { name: 'Calf Raise', aliases: ['Standing Calf Raise'], pattern: 'squat', equipment: ['bodyweight', 'machine'], difficulty: 'beginner' },
    { name: 'Seated Calf Raise', aliases: [], pattern: 'squat', equipment: ['machine'], difficulty: 'beginner' },
    { name: 'Step-ups', aliases: [], pattern: 'squat', equipment: ['bodyweight', 'box'], difficulty: 'beginner' },
  ],
  shoulders: [
    { name: 'Overhead Press', aliases: ['OHP', 'Military Press'], pattern: 'push', equipment: ['barbell'], difficulty: 'intermediate' },
    { name: 'Dumbbell Shoulder Press', aliases: ['DB Press'], pattern: 'push', equipment: ['dumbbells'], difficulty: 'intermediate' },
    { name: 'Lateral Raises', aliases: ['Side Raises'], pattern: 'push', equipment: ['dumbbells', 'cables'], difficulty: 'beginner' },
    { name: 'Front Raises', aliases: [], pattern: 'push', equipment: ['dumbbells', 'cables'], difficulty: 'beginner' },
    { name: 'Rear Delt Flyes', aliases: ['Reverse Flyes'], pattern: 'pull', equipment: ['dumbbells', 'cables'], difficulty: 'beginner' },
    { name: 'Arnold Press', aliases: [], pattern: 'push', equipment: ['dumbbells'], difficulty: 'intermediate' },
    { name: 'Upright Row', aliases: [], pattern: 'pull', equipment: ['barbell', 'dumbbells'], difficulty: 'beginner' },
    { name: 'Cable Lateral Raise', aliases: [], pattern: 'push', equipment: ['cables'], difficulty: 'beginner' },
    { name: 'Pike Push-ups', aliases: [], pattern: 'push', equipment: ['bodyweight'], difficulty: 'intermediate' },
    { name: 'Handstand Push-ups', aliases: ['HSPU'], pattern: 'push', equipment: ['bodyweight'], difficulty: 'advanced' },
    { name: 'Face Pulls', aliases: [], pattern: 'pull', equipment: ['cables'], difficulty: 'beginner' },
    { name: 'Shrugs', aliases: [], pattern: 'pull', equipment: ['barbell', 'dumbbells'], difficulty: 'beginner' },
  ],
  arms: [
    { name: 'Barbell Curl', aliases: ['BB Curl'], pattern: 'pull', equipment: ['barbell'], difficulty: 'beginner' },
    { name: 'Dumbbell Curl', aliases: ['DB Curl'], pattern: 'pull', equipment: ['dumbbells'], difficulty: 'beginner' },
    { name: 'Hammer Curl', aliases: [], pattern: 'pull', equipment: ['dumbbells'], difficulty: 'beginner' },
    { name: 'Cable Curl', aliases: [], pattern: 'pull', equipment: ['cables'], difficulty: 'beginner' },
    { name: 'Tricep Pushdown', aliases: ['Tricep Extension'], pattern: 'push', equipment: ['cables'], difficulty: 'beginner' },
    { name: 'Overhead Tricep Extension', aliases: ['OH Extension'], pattern: 'push', equipment: ['dumbbells', 'cables'], difficulty: 'beginner' },
    { name: 'Close Grip Bench Press', aliases: ['CG Bench'], pattern: 'push', equipment: ['barbell', 'bench'], difficulty: 'intermediate' },
    { name: 'Dips', aliases: ['Tricep Dips'], pattern: 'push', equipment: ['bodyweight', 'dip_station'], difficulty: 'intermediate' },
    { name: 'Skull Crushers', aliases: ['Lying Tricep Extension'], pattern: 'push', equipment: ['barbell', 'dumbbells', 'bench'], difficulty: 'intermediate' },
    { name: 'Preacher Curl', aliases: [], pattern: 'pull', equipment: ['barbell', 'dumbbells', 'bench'], difficulty: 'beginner' },
  ],
  core: [
    { name: 'Plank', aliases: [], pattern: 'core', equipment: ['bodyweight'], difficulty: 'beginner' },
    { name: 'Side Plank', aliases: [], pattern: 'core', equipment: ['bodyweight'], difficulty: 'beginner' },
    { name: 'Crunches', aliases: ['Crunches'], pattern: 'core', equipment: ['bodyweight'], difficulty: 'beginner' },
    { name: 'Russian Twists', aliases: [], pattern: 'rotation', equipment: ['bodyweight'], difficulty: 'beginner' },
    { name: 'Leg Raises', aliases: ['Hanging Leg Raises'], pattern: 'core', equipment: ['bodyweight'], difficulty: 'intermediate' },
    { name: 'Mountain Climbers', aliases: [], pattern: 'core', equipment: ['bodyweight'], difficulty: 'beginner' },
    { name: 'Dead Bug', aliases: [], pattern: 'core', equipment: ['bodyweight'], difficulty: 'beginner' },
    { name: 'Ab Wheel Rollout', aliases: ['Ab Wheel'], pattern: 'core', equipment: ['ab_wheel'], difficulty: 'intermediate' },
    { name: 'Cable Crunch', aliases: [], pattern: 'core', equipment: ['cables'], difficulty: 'beginner' },
    { name: 'Pallof Press', aliases: [], pattern: 'rotation', equipment: ['cables'], difficulty: 'intermediate' },
  ],
};

// Generate descriptions
function generateShortDesc(name, primaryMuscle, pattern, equipment) {
  const patterns = {
    push: 'pressing',
    pull: 'pulling',
    squat: 'squatting',
    hinge: 'hinging',
    core: 'core',
    rotation: 'rotational',
  };
  
  const equipmentTypes = {
    barbell: 'barbell',
    dumbbells: 'dumbbell',
    cables: 'cable',
    machine: 'machine',
    bodyweight: 'bodyweight',
  };
  
  const eq = equipment[0] ? equipmentTypes[equipment[0]] || equipment[0] : 'resistance';
  const pat = patterns[pattern] || 'movement';
  const muscle = primaryMuscle[0] || 'target muscles';
  
  return `${eq.charAt(0).toUpperCase() + eq.slice(1)} ${pat} exercise targeting the ${muscle}.`;
}

function generateHowTo(name, pattern, equipment) {
  const templates = {
    push: 'Maintain proper form, control the weight through full range of motion, and focus on muscle engagement.',
    pull: 'Keep core engaged, pull through the target muscles, and control the negative phase.',
    squat: 'Maintain upright torso, drive through heels, and control depth and ascent.',
    hinge: 'Keep back straight, hinge at hips, and maintain tension throughout the movement.',
    core: 'Engage core muscles, maintain proper alignment, and control the movement.',
    rotation: 'Rotate through the core, maintain stability, and control the return.',
  };
  
  return templates[pattern] || 'Perform with proper form and controlled movement.';
}

function generateCues(pattern) {
  const cueMap = {
    push: ['Keep core engaged', 'Control the weight', 'Full range of motion'],
    pull: ['Retract scapula', 'Pull to chest/waist', 'Control negative'],
    squat: ['Drive through heels', 'Knees track toes', 'Upright torso'],
    hinge: ['Hinge at hips', 'Neutral spine', 'Hamstring engagement'],
    core: ['Brace core', 'Neutral spine', 'Controlled movement'],
    rotation: ['Rotate through core', 'Stable base', 'Controlled return'],
  };
  
  return cueMap[pattern] || ['Maintain form', 'Control movement'];
}

function generateMistakes(pattern) {
  const mistakeMap = {
    push: ['Arching back excessively', 'Flaring elbows', 'Bouncing weight'],
    pull: ['Using momentum', 'Rounded back', 'Incomplete range'],
    squat: ['Knees caving in', 'Insufficient depth', 'Forward lean'],
    hinge: ['Rounded back', 'Bending knees too much', 'Hyperextension'],
    core: ['Neck strain', 'Lower back arch', 'Momentum use'],
    rotation: ['Over-rotation', 'Losing balance', 'Fast uncontrolled movement'],
  };
  
  return mistakeMap[pattern] || ['Poor form', 'Using momentum'];
}

// Generate exercises
const exercises = [];
let id = 1;

// Generate from templates (base exercises)
Object.entries(exerciseTemplates).forEach(([muscle, templates]) => {
  templates.forEach(template => {
    const primaryMuscles = [muscle];
    const secondaryMuscles = [];
    
    // Add secondary muscles based on pattern
    if (template.pattern === 'push' && muscle === 'chest') {
      secondaryMuscles.push('triceps', 'front_delts');
    } else if (template.pattern === 'pull' && muscle === 'back') {
      secondaryMuscles.push('biceps', 'rear_delts');
    } else if (template.pattern === 'push' && muscle === 'shoulders') {
      secondaryMuscles.push('triceps', 'core');
    } else if (template.pattern === 'squat' && muscle === 'legs') {
      // For squat pattern, add quads and glutes as primary
      if (!primaryMuscles.includes('quads')) primaryMuscles.push('quads');
      if (!primaryMuscles.includes('glutes')) primaryMuscles.push('glutes');
    } else if (template.pattern === 'hinge' && muscle === 'legs') {
      // For hinge pattern, add hamstrings and glutes as primary
      if (!primaryMuscles.includes('hamstrings')) primaryMuscles.push('hamstrings');
      if (!primaryMuscles.includes('glutes')) primaryMuscles.push('glutes');
    } else if (template.pattern === 'pull' && muscle === 'arms') {
      if (template.name.includes('Curl')) {
        primaryMuscles[0] = 'biceps';
      }
    } else if (template.pattern === 'push' && muscle === 'arms') {
      if (template.name.includes('Tricep')) {
        primaryMuscles[0] = 'triceps';
      }
    }
    
    // Add anatomical tags to muscle arrays (dual tags: English + anatomical)
    const primaryWithAnatomical = addAnatomicalTags(primaryMuscles);
    const secondaryWithAnatomical = addAnatomicalTags(secondaryMuscles);
    
    exercises.push({
      name: template.name,
      aliases: template.aliases || [],
      short_desc: generateShortDesc(template.name, primaryMuscles, template.pattern, template.equipment),
      how_to: generateHowTo(template.name, template.pattern, template.equipment),
      cues: generateCues(template.pattern),
      common_mistakes: generateMistakes(template.pattern),
      primary_muscles: primaryWithAnatomical,
      secondary_muscles: secondaryWithAnatomical,
      equipment: template.equipment,
      movement_pattern: template.pattern,
      difficulty: template.difficulty,
      contraindications: [],
      media: {},
      source: 'seed_pack_v1',
      language: 'en',
      status: 'approved',
    });
  });
});

// Generate variations to reach 2000+
const variations = [
  { prefix: 'Wide Grip', suffix: '', equipment: [] },
  { prefix: 'Close Grip', suffix: '', equipment: [] },
  { prefix: 'Narrow', suffix: '', equipment: [] },
  { prefix: 'Single Arm', suffix: '', equipment: [] },
  { prefix: 'Alternating', suffix: '', equipment: [] },
  { prefix: 'Incline', suffix: '', equipment: [] },
  { prefix: 'Decline', suffix: '', equipment: [] },
  { prefix: 'Seated', suffix: '', equipment: [] },
  { prefix: 'Standing', suffix: '', equipment: [] },
  { prefix: 'Lying', suffix: '', equipment: [] },
  { prefix: 'Kneeling', suffix: '', equipment: [] },
  { prefix: 'One-Legged', suffix: '', equipment: [] },
  { prefix: 'Weighted', suffix: '', equipment: [] },
  { prefix: 'Resistance Band', suffix: '', equipment: ['resistance_bands'] },
  { prefix: 'Cable', suffix: '', equipment: ['cables'] },
  { prefix: 'Machine', suffix: '', equipment: ['machine'] },
];

const baseExercises = [...exercises];
baseExercises.forEach(ex => {
  if (exercises.length >= 2000) return;
  
  // Add some variations
  if (Math.random() > 0.7 && ex.equipment.length > 0) {
    const variation = variations[Math.floor(Math.random() * variations.length)];
    if (variation.prefix && !ex.name.includes(variation.prefix)) {
      const newName = `${variation.prefix} ${ex.name}`;
      const newEquipment = variation.equipment.length > 0 ? variation.equipment : ex.equipment;
      
      if (!exercises.find(e => e.name === newName)) {
        // Ensure anatomical tags are included for variations too
        const primaryWithAnatomical = addAnatomicalTags(ex.primary_muscles || []);
        const secondaryWithAnatomical = addAnatomicalTags(ex.secondary_muscles || []);
        
        exercises.push({
          ...ex,
          name: newName,
          aliases: [...(ex.aliases || []), ex.name],
          equipment: newEquipment,
          primary_muscles: primaryWithAnatomical,
          secondary_muscles: secondaryWithAnatomical,
        });
      }
    }
  }
});

// Add more exercises by muscle group to reach 2000
const additionalExercises = [
  // More chest
  { name: 'Chest Press', muscle: 'chest', pattern: 'push', equipment: ['machine'] },
  { name: 'Pec Fly Machine', muscle: 'chest', pattern: 'push', equipment: ['machine'] },
  { name: 'Cable Crossover', muscle: 'chest', pattern: 'push', equipment: ['cables'] },
  { name: 'Floor Press', muscle: 'chest', pattern: 'push', equipment: ['barbell', 'dumbbells'] },
  { name: 'Spoto Press', muscle: 'chest', pattern: 'push', equipment: ['barbell', 'bench'] },
  
  // More back
  { name: 'Wide Grip Lat Pulldown', muscle: 'back', pattern: 'pull', equipment: ['machine'] },
  { name: 'Close Grip Lat Pulldown', muscle: 'back', pattern: 'pull', equipment: ['machine'] },
  { name: 'Reverse Grip Pulldown', muscle: 'back', pattern: 'pull', equipment: ['machine'] },
  { name: 'Chest Supported T-Bar Row', muscle: 'back', pattern: 'pull', equipment: ['machine'] },
  { name: 'Wide Grip Cable Row', muscle: 'back', pattern: 'pull', equipment: ['cables'] },
  
  // More legs
  { name: 'Hack Squat', muscle: 'legs', pattern: 'squat', equipment: ['machine'] },
  { name: 'Bulgarian Split Squat', muscle: 'legs', pattern: 'squat', equipment: ['dumbbells'] },
  { name: 'Reverse Lunge', muscle: 'legs', pattern: 'squat', equipment: ['bodyweight', 'dumbbells'] },
  { name: 'Lateral Lunge', muscle: 'legs', pattern: 'squat', equipment: ['bodyweight', 'dumbbells'] },
  { name: 'Good Morning', muscle: 'legs', pattern: 'hinge', equipment: ['barbell'] },
  { name: 'Stiff Leg Deadlift', muscle: 'legs', pattern: 'hinge', equipment: ['barbell', 'dumbbells'] },
  { name: 'Single Leg Deadlift', muscle: 'legs', pattern: 'hinge', equipment: ['dumbbells'] },
  { name: 'Leg Press Calf Raise', muscle: 'legs', pattern: 'squat', equipment: ['machine'] },
  
  // More shoulders
  { name: 'Seated Overhead Press', muscle: 'shoulders', pattern: 'push', equipment: ['barbell', 'dumbbells'] },
  { name: 'Push Press', muscle: 'shoulders', pattern: 'push', equipment: ['barbell'] },
  { name: 'Behind Neck Press', muscle: 'shoulders', pattern: 'push', equipment: ['barbell'] },
  { name: 'Lateral Raise Machine', muscle: 'shoulders', pattern: 'push', equipment: ['machine'] },
  { name: 'Cable Rear Delt Fly', muscle: 'shoulders', pattern: 'pull', equipment: ['cables'] },
  
  // More arms
  { name: 'Concentration Curl', muscle: 'arms', pattern: 'pull', equipment: ['dumbbells'] },
  { name: 'Spider Curl', muscle: 'arms', pattern: 'pull', equipment: ['barbell', 'bench'] },
  { name: 'Cable Hammer Curl', muscle: 'arms', pattern: 'pull', equipment: ['cables'] },
  { name: 'Rope Tricep Extension', muscle: 'arms', pattern: 'push', equipment: ['cables'] },
  { name: 'Diamond Push-ups', muscle: 'arms', pattern: 'push', equipment: ['bodyweight'] },
  
  // More core
  { name: 'Bicycle Crunches', muscle: 'core', pattern: 'core', equipment: ['bodyweight'] },
  { name: 'Flutter Kicks', muscle: 'core', pattern: 'core', equipment: ['bodyweight'] },
  { name: 'V-Ups', muscle: 'core', pattern: 'core', equipment: ['bodyweight'] },
  { name: 'Hanging Knee Raises', muscle: 'core', pattern: 'core', equipment: ['bodyweight', 'pull_up_bar'] },
  { name: 'Cable Wood Chop', muscle: 'core', pattern: 'rotation', equipment: ['cables'] },
];

additionalExercises.forEach(template => {
  if (exercises.length >= 2000) return;
  
  const primaryMuscles = [template.muscle];
  const primaryWithAnatomical = addAnatomicalTags(primaryMuscles);
  
  exercises.push({
    name: template.name,
    aliases: [],
    short_desc: generateShortDesc(template.name, primaryMuscles, template.pattern, template.equipment),
    how_to: generateHowTo(template.name, template.pattern, template.equipment),
    cues: generateCues(template.pattern),
    common_mistakes: generateMistakes(template.pattern),
    primary_muscles: primaryWithAnatomical,
    secondary_muscles: [],
    equipment: template.equipment,
    movement_pattern: template.pattern,
    difficulty: 'intermediate',
    contraindications: [],
    media: {},
    source: 'seed_pack_v1',
    language: 'en',
    status: 'approved',
  });
});

// Generate more variations efficiently to reach 2000
const seenNames = new Set(exercises.map(e => e.name.toLowerCase()));
let attempts = 0;
const maxAttempts = 5000;

while (exercises.length < 2000 && attempts < maxAttempts) {
  attempts++;
  const base = exercises[Math.floor(Math.random() * Math.min(exercises.length, 200))];
  const variation = variations[Math.floor(Math.random() * variations.length)];
  
  if (variation.prefix && !base.name.includes(variation.prefix)) {
    const newName = `${variation.prefix} ${base.name}`;
    const newNameLower = newName.toLowerCase();
    
    if (!seenNames.has(newNameLower)) {
      seenNames.add(newNameLower);
      // Ensure anatomical tags are included for variations
      const primaryWithAnatomical = addAnatomicalTags(base.primary_muscles || []);
      const secondaryWithAnatomical = addAnatomicalTags(base.secondary_muscles || []);
      
      exercises.push({
        ...base,
        name: newName,
        aliases: [...(base.aliases || []), base.name],
        equipment: variation.equipment.length > 0 ? variation.equipment : base.equipment,
        primary_muscles: primaryWithAnatomical,
        secondary_muscles: secondaryWithAnatomical,
      });
    }
  }
}

// Limit to 2000
const finalExercises = exercises.slice(0, 2000);

// Write to file
const outputPath = path.join(__dirname, '..', 'assets', 'seeds', 'exercise_knowledge_seed_en.json');
const outputDir = path.dirname(outputPath);

if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

fs.writeFileSync(outputPath, JSON.stringify(finalExercises, null, 2));

console.log(`✅ Generated ${finalExercises.length} exercises`);
console.log(`📁 Saved to: ${outputPath}`);
