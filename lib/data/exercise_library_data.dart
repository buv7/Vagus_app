// Temporary exercise library data
// This will be replaced with Supabase data later

class ExerciseLibraryData {
  static final Map<String, List<ExerciseTemplate>> exercisesByMuscleGroup = {
    'Chest': [
      ExerciseTemplate(
        name: 'Barbell Bench Press',
        muscleGroup: 'Chest',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        defaultSets: 4,
        defaultReps: '8-12',
      ),
      ExerciseTemplate(
        name: 'Incline Dumbbell Press',
        muscleGroup: 'Chest',
        equipment: 'Dumbbell',
        difficulty: 'Intermediate',
        defaultSets: 3,
        defaultReps: '10-12',
      ),
      ExerciseTemplate(
        name: 'Dumbbell Flyes',
        muscleGroup: 'Chest',
        equipment: 'Dumbbell',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '12-15',
      ),
      ExerciseTemplate(
        name: 'Push-ups',
        muscleGroup: 'Chest',
        equipment: 'Bodyweight',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '12-20',
      ),
      ExerciseTemplate(
        name: 'Cable Crossovers',
        muscleGroup: 'Chest',
        equipment: 'Cable',
        difficulty: 'Intermediate',
        defaultSets: 3,
        defaultReps: '12-15',
      ),
      ExerciseTemplate(
        name: 'Decline Bench Press',
        muscleGroup: 'Chest',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        defaultSets: 3,
        defaultReps: '8-12',
      ),
    ],
    'Back': [
      ExerciseTemplate(
        name: 'Pull-ups',
        muscleGroup: 'Back',
        equipment: 'Bodyweight',
        difficulty: 'Intermediate',
        defaultSets: 4,
        defaultReps: '6-12',
      ),
      ExerciseTemplate(
        name: 'Barbell Rows',
        muscleGroup: 'Back',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        defaultSets: 4,
        defaultReps: '8-12',
      ),
      ExerciseTemplate(
        name: 'Lat Pulldowns',
        muscleGroup: 'Back',
        equipment: 'Machine',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '10-15',
      ),
      ExerciseTemplate(
        name: 'Deadlifts',
        muscleGroup: 'Back',
        equipment: 'Barbell',
        difficulty: 'Advanced',
        defaultSets: 4,
        defaultReps: '5-8',
      ),
      ExerciseTemplate(
        name: 'Face Pulls',
        muscleGroup: 'Back',
        equipment: 'Cable',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '15-20',
      ),
      ExerciseTemplate(
        name: 'Dumbbell Rows',
        muscleGroup: 'Back',
        equipment: 'Dumbbell',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '10-12',
      ),
      ExerciseTemplate(
        name: 'Seated Cable Rows',
        muscleGroup: 'Back',
        equipment: 'Cable',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '10-15',
      ),
    ],
    'Legs': [
      ExerciseTemplate(
        name: 'Barbell Squats',
        muscleGroup: 'Legs',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        defaultSets: 4,
        defaultReps: '8-12',
      ),
      ExerciseTemplate(
        name: 'Lunges',
        muscleGroup: 'Legs',
        equipment: 'Bodyweight',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '12-15',
      ),
      ExerciseTemplate(
        name: 'Leg Press',
        muscleGroup: 'Legs',
        equipment: 'Machine',
        difficulty: 'Beginner',
        defaultSets: 4,
        defaultReps: '10-15',
      ),
      ExerciseTemplate(
        name: 'Romanian Deadlifts',
        muscleGroup: 'Legs',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        defaultSets: 3,
        defaultReps: '8-12',
      ),
      ExerciseTemplate(
        name: 'Calf Raises',
        muscleGroup: 'Legs',
        equipment: 'Machine',
        difficulty: 'Beginner',
        defaultSets: 4,
        defaultReps: '15-20',
      ),
      ExerciseTemplate(
        name: 'Leg Extensions',
        muscleGroup: 'Legs',
        equipment: 'Machine',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '12-15',
      ),
      ExerciseTemplate(
        name: 'Leg Curls',
        muscleGroup: 'Legs',
        equipment: 'Machine',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '12-15',
      ),
      ExerciseTemplate(
        name: 'Bulgarian Split Squats',
        muscleGroup: 'Legs',
        equipment: 'Dumbbell',
        difficulty: 'Intermediate',
        defaultSets: 3,
        defaultReps: '10-12',
      ),
    ],
    'Shoulders': [
      ExerciseTemplate(
        name: 'Overhead Press',
        muscleGroup: 'Shoulders',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        defaultSets: 4,
        defaultReps: '8-12',
      ),
      ExerciseTemplate(
        name: 'Lateral Raises',
        muscleGroup: 'Shoulders',
        equipment: 'Dumbbell',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '12-15',
      ),
      ExerciseTemplate(
        name: 'Front Raises',
        muscleGroup: 'Shoulders',
        equipment: 'Dumbbell',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '12-15',
      ),
      ExerciseTemplate(
        name: 'Rear Delt Flyes',
        muscleGroup: 'Shoulders',
        equipment: 'Dumbbell',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '12-15',
      ),
      ExerciseTemplate(
        name: 'Arnold Press',
        muscleGroup: 'Shoulders',
        equipment: 'Dumbbell',
        difficulty: 'Intermediate',
        defaultSets: 3,
        defaultReps: '10-12',
      ),
    ],
    'Arms': [
      ExerciseTemplate(
        name: 'Barbell Bicep Curls',
        muscleGroup: 'Arms',
        equipment: 'Barbell',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '10-12',
      ),
      ExerciseTemplate(
        name: 'Tricep Rope Extensions',
        muscleGroup: 'Arms',
        equipment: 'Cable',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '12-15',
      ),
      ExerciseTemplate(
        name: 'Hammer Curls',
        muscleGroup: 'Arms',
        equipment: 'Dumbbell',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '10-12',
      ),
      ExerciseTemplate(
        name: 'Dips',
        muscleGroup: 'Arms',
        equipment: 'Bodyweight',
        difficulty: 'Intermediate',
        defaultSets: 3,
        defaultReps: '8-12',
      ),
      ExerciseTemplate(
        name: 'Skull Crushers',
        muscleGroup: 'Arms',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        defaultSets: 3,
        defaultReps: '10-12',
      ),
      ExerciseTemplate(
        name: 'Preacher Curls',
        muscleGroup: 'Arms',
        equipment: 'Dumbbell',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '10-12',
      ),
    ],
    'Core': [
      ExerciseTemplate(
        name: 'Planks',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '30-60s',
      ),
      ExerciseTemplate(
        name: 'Crunches',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '15-20',
      ),
      ExerciseTemplate(
        name: 'Russian Twists',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '20-30',
      ),
      ExerciseTemplate(
        name: 'Hanging Leg Raises',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        difficulty: 'Intermediate',
        defaultSets: 3,
        defaultReps: '10-15',
      ),
      ExerciseTemplate(
        name: 'Ab Wheel Rollouts',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        difficulty: 'Advanced',
        defaultSets: 3,
        defaultReps: '8-12',
      ),
      ExerciseTemplate(
        name: 'Cable Crunches',
        muscleGroup: 'Core',
        equipment: 'Cable',
        difficulty: 'Beginner',
        defaultSets: 3,
        defaultReps: '15-20',
      ),
    ],
  };

  static List<ExerciseTemplate> getAllExercises() {
    final List<ExerciseTemplate> allExercises = [];
    exercisesByMuscleGroup.forEach((group, exercises) {
      allExercises.addAll(exercises);
    });
    return allExercises;
  }

  static List<ExerciseTemplate> getExercisesByEquipment(String equipment) {
    return getAllExercises()
        .where((e) => e.equipment == equipment)
        .toList();
  }

  static List<ExerciseTemplate> searchExercises(String query) {
    if (query.isEmpty) return getAllExercises();

    final lowerQuery = query.toLowerCase();
    return getAllExercises()
        .where((e) =>
          e.name.toLowerCase().contains(lowerQuery) ||
          e.muscleGroup.toLowerCase().contains(lowerQuery) ||
          e.equipment.toLowerCase().contains(lowerQuery)
        )
        .toList();
  }

  static List<String> get equipmentTypes => [
    'All',
    'Barbell',
    'Dumbbell',
    'Cable',
    'Machine',
    'Bodyweight',
  ];

  static List<String> get muscleGroups => exercisesByMuscleGroup.keys.toList();
}

class ExerciseTemplate {
  final String name;
  final String muscleGroup;
  final String equipment;
  final String difficulty;
  final int defaultSets;
  final String defaultReps;
  final String? description;

  ExerciseTemplate({
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.difficulty,
    required this.defaultSets,
    required this.defaultReps,
    this.description,
  });

  Map<String, dynamic> toExercise() {
    return {
      'id': null,
      'name': name,
      'sets': defaultSets,
      'reps': defaultReps,
      'muscle_group': muscleGroup,
      'equipment': equipment,
      'notes': '',
    };
  }
}
