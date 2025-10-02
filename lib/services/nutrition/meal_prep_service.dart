import 'package:flutter/foundation.dart';
import '../../models/nutrition/nutrition_plan.dart';

/// Revolutionary meal prep planning service
/// Features: Batch cooking, prep scheduling, storage tracking, efficiency optimization
class MealPrepService extends ChangeNotifier {
  static final _instance = MealPrepService._internal();
  factory MealPrepService() => _instance;
  MealPrepService._internal();

  // Prep mode state
  bool _isPrepModeEnabled = false;
  List<PrepDay> _prepDays = [];
  final Map<String, PrepTask> _prepTasks = {};
  final Map<String, StorageInfo> _storageInfo = {};

  bool get isPrepModeEnabled => _isPrepModeEnabled;
  List<PrepDay> get prepDays => _prepDays;

  /// Toggle between daily and meal prep mode
  void togglePrepMode(bool enabled) {
    _isPrepModeEnabled = enabled;
    notifyListeners();
  }

  /// Set prep days (e.g., Sunday and Wednesday)
  void setPrepDays(List<PrepDay> days) {
    _prepDays = days;
    notifyListeners();
  }

  /// Analyze nutrition plan for batch cooking opportunities
  BatchCookingAnalysis analyzeBatchOpportunities(NutritionPlan plan) {
    final opportunities = <BatchOpportunity>[];
    final recipeFrequency = <String, List<Meal>>{};

    // Group meals by recipe/food similarity
    for (final meal in plan.meals) {
      for (final item in meal.items) {
        final key = _generateRecipeKey(item);
        recipeFrequency[key] = recipeFrequency[key] ?? [];
        recipeFrequency[key]!.add(meal);
      }
    }

    // Find items that appear 3+ times (batch cooking candidates)
    recipeFrequency.forEach((key, meals) {
      if (meals.length >= 3) {
        opportunities.add(BatchOpportunity(
          recipeName: key,
          occurrences: meals.length,
          totalAmount: _calculateTotalAmount(meals, key),
          savingsMinutes: _estimateTimeSavings(meals.length),
          meals: meals,
        ));
      }
    });

    // Sort by time savings (most impactful first)
    opportunities.sort((a, b) => b.savingsMinutes.compareTo(a.savingsMinutes));

    return BatchCookingAnalysis(
      opportunities: opportunities,
      totalTimeSavingsMinutes: opportunities.fold(0, (sum, opp) => sum + opp.savingsMinutes),
      recommendedPrepDays: _recommendPrepDays(opportunities),
    );
  }

  /// Generate prep schedule for given prep days
  PrepSchedule generatePrepSchedule(NutritionPlan plan, List<PrepDay> prepDays) {
    final analysis = analyzeBatchOpportunities(plan);
    final tasks = <PrepTask>[];

    // Group tasks by prep day
    final tasksByDay = <PrepDay, List<PrepTask>>{};

    for (final opportunity in analysis.opportunities) {
      // Determine which prep day this should be cooked on
      final prepDay = _assignPrepDay(opportunity, prepDays);

      final task = PrepTask(
        id: _generateTaskId(),
        recipeName: opportunity.recipeName,
        totalAmount: opportunity.totalAmount,
        estimatedMinutes: opportunity.savingsMinutes,
        prepDay: prepDay,
        servings: opportunity.occurrences,
        containers: _calculateContainersNeeded(opportunity),
        storageInstructions: _getStorageInstructions(opportunity.recipeName),
        reheatingInstructions: _getReheatingInstructions(opportunity.recipeName),
        isCompleted: false,
      );

      tasks.add(task);
      tasksByDay[prepDay] = tasksByDay[prepDay] ?? [];
      tasksByDay[prepDay]!.add(task);
    }

    // Optimize task order within each prep day
    tasksByDay.forEach((day, dayTasks) {
      dayTasks.sort((a, b) => _compareTaskEfficiency(a, b));
    });

    return PrepSchedule(
      prepDays: prepDays,
      tasks: tasks,
      tasksByDay: tasksByDay,
      totalPrepTimeMinutes: tasks.fold(0, (sum, task) => sum + task.estimatedMinutes),
      containersNeeded: tasks.fold(0, (sum, task) => sum + task.containers),
    );
  }

  /// Get optimized prep instructions with parallel cooking tips
  List<PrepInstruction> getOptimizedInstructions(PrepSchedule schedule, PrepDay day) {
    final instructions = <PrepInstruction>[];
    final dayTasks = schedule.tasksByDay[day] ?? [];

    if (dayTasks.isEmpty) return instructions;

    // Group tasks that can be done in parallel
    final parallelGroups = _identifyParallelTasks(dayTasks);

    int step = 1;
    for (final group in parallelGroups) {
      if (group.length == 1) {
        // Single task
        instructions.add(PrepInstruction(
          step: step++,
          description: _getTaskDescription(group.first),
          estimatedMinutes: group.first.estimatedMinutes,
          isParallel: false,
          tasks: [group.first],
        ));
      } else {
        // Parallel tasks
        final parallelDesc = _generateParallelDescription(group);
        instructions.add(PrepInstruction(
          step: step++,
          description: parallelDesc,
          estimatedMinutes: group.map((t) => t.estimatedMinutes).reduce((a, b) => a > b ? a : b),
          isParallel: true,
          tasks: group,
          parallelTip: _generateParallelTip(group),
        ));
      }
    }

    return instructions;
  }

  /// Track storage information for prepped meals
  void trackStorage(String mealId, StorageInfo info) {
    _storageInfo[mealId] = info;
    notifyListeners();
  }

  /// Get storage recommendations
  StorageRecommendation getStorageRecommendation(String foodType) {
    final recommendations = <String, StorageRecommendation>{
      'chicken': StorageRecommendation(
        refrigeratedDays: 4,
        freezerDays: 120,
        containerType: 'Airtight glass or plastic',
        tips: [
          'Store in shallow containers for quick cooling',
          'Label with date cooked',
          'Keep at 40°F or below',
        ],
      ),
      'rice': StorageRecommendation(
        refrigeratedDays: 5,
        freezerDays: 180,
        containerType: 'Airtight container or freezer bags',
        tips: [
          'Cool completely before storing',
          'Flatten freezer bags for space-saving',
          'Add splash of water when reheating',
        ],
      ),
      'vegetables': StorageRecommendation(
        refrigeratedDays: 5,
        freezerDays: 90,
        containerType: 'Glass meal prep containers',
        tips: [
          'Store vegetables separate from protein if possible',
          'Blanch before freezing for best quality',
          'Reheat gently to avoid mushiness',
        ],
      ),
      // Add more food types...
    };

    return recommendations[foodType.toLowerCase()] ?? StorageRecommendation(
      refrigeratedDays: 3,
      freezerDays: 60,
      containerType: 'Airtight container',
      tips: ['Label with date', 'Store properly sealed'],
    );
  }

  /// Get reheating instructions
  ReheatingInstructions getReheatingInstructions(String recipeName) {
    return ReheatingInstructions(
      microwave: MicrowaveInstructions(
        powerLevel: 'High (100%)',
        initialTime: '2:30',
        stirInstructions: 'Stir halfway through',
        additionalTime: '1:00',
        tips: ['Cover with damp paper towel', 'Let stand 1 minute before eating'],
      ),
      oven: OvenInstructions(
        temperature: 350,
        timeMinutes: 15,
        preparation: 'Cover with foil',
        tips: ['Preheat oven', 'Remove foil last 5 minutes for crispiness'],
      ),
      stovetop: StovetopInstructions(
        heat: 'Medium',
        timeMinutes: 8,
        tips: ['Add splash of water or broth', 'Stir frequently'],
      ),
    );
  }

  /// Mark prep task as completed
  void completeTask(String taskId, {String? photoUrl}) {
    if (_prepTasks.containsKey(taskId)) {
      _prepTasks[taskId] = _prepTasks[taskId]!.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        photoUrl: photoUrl,
      );
      notifyListeners();
    }
  }

  /// Get prep progress for a day
  PrepProgress getPrepProgress(PrepDay day) {
    final dayTasks = _prepTasks.values.where((task) => task.prepDay == day).toList();
    final completedTasks = dayTasks.where((task) => task.isCompleted).toList();

    return PrepProgress(
      totalTasks: dayTasks.length,
      completedTasks: completedTasks.length,
      totalMinutes: dayTasks.fold(0, (sum, task) => sum + task.estimatedMinutes),
      completedMinutes: completedTasks.fold(0, (sum, task) => sum + task.estimatedMinutes),
      remainingTasks: dayTasks.where((task) => !task.isCompleted).toList(),
    );
  }

  // Private helper methods

  String _generateRecipeKey(FoodItem item) {
    // Simplified recipe key - could be more sophisticated
    return item.name.toLowerCase().replaceAll(RegExp(r'[0-9]'), '').trim();
  }

  double _calculateTotalAmount(List<Meal> meals, String recipeKey) {
    double total = 0;
    for (final meal in meals) {
      for (final item in meal.items) {
        if (_generateRecipeKey(item) == recipeKey) {
          total += item.amount;
        }
      }
    }
    return total;
  }

  int _estimateTimeSavings(int occurrences) {
    // Batch cooking saves time: cooking 4 portions takes ~1.5x time of cooking 1
    // So savings = (individual time × occurrences) - batch time
    const individualMinutes = 30; // Average cooking time
    final batchMultiplier = 1 + (occurrences - 1) * 0.2; // Each additional serving adds 20% time
    final batchMinutes = (individualMinutes * batchMultiplier).round();
    final individualTotal = individualMinutes * occurrences;
    return individualTotal - batchMinutes;
  }

  List<PrepDay> _recommendPrepDays(List<BatchOpportunity> opportunities) {
    // Smart recommendation based on meal distribution
    // For now, recommend Sunday and Wednesday
    return [
      PrepDay.sunday,
      PrepDay.wednesday,
    ];
  }

  PrepDay _assignPrepDay(BatchOpportunity opportunity, List<PrepDay> prepDays) {
    // Assign to earliest prep day by default
    // Could be more sophisticated based on storage duration
    return prepDays.first;
  }

  String _generateTaskId() {
    return 'task_${DateTime.now().millisecondsSinceEpoch}';
  }

  int _calculateContainersNeeded(BatchOpportunity opportunity) {
    // Assume 1 container per serving
    return opportunity.occurrences;
  }

  String _getStorageInstructions(String recipeName) {
    return 'Store in airtight containers. Refrigerate for up to 4 days or freeze for up to 3 months.';
  }

  String _getReheatingInstructions(String recipeName) {
    return 'Microwave: 2:30 on high, stir, 1:00 more. Or oven at 350°F for 15 minutes.';
  }

  int _compareTaskEfficiency(PrepTask a, PrepTask b) {
    // Sort by longest cook time first (start these early)
    return b.estimatedMinutes.compareTo(a.estimatedMinutes);
  }

  List<List<PrepTask>> _identifyParallelTasks(List<PrepTask> tasks) {
    // Group tasks that can be done simultaneously
    final groups = <List<PrepTask>>[];
    final used = <PrepTask>{};

    for (final task in tasks) {
      if (used.contains(task)) continue;

      final group = [task];
      used.add(task);

      // Find tasks that can be done in parallel
      for (final other in tasks) {
        if (used.contains(other)) continue;
        if (_canBeParallel(task, other)) {
          group.add(other);
          used.add(other);
        }
      }

      groups.add(group);
    }

    return groups;
  }

  bool _canBeParallel(PrepTask a, PrepTask b) {
    // Tasks can be parallel if they use different cooking methods
    // For example: oven + stovetop
    // Simplified logic for now
    return a.recipeName.toLowerCase() != b.recipeName.toLowerCase();
  }

  String _getTaskDescription(PrepTask task) {
    return 'Cook ${task.servings}x servings of ${task.recipeName}';
  }

  String _generateParallelDescription(List<PrepTask> tasks) {
    final names = tasks.map((t) => t.recipeName).join(', ');
    return 'Cook simultaneously: $names';
  }

  String _generateParallelTip(List<PrepTask> tasks) {
    return 'While ${tasks.first.recipeName} cooks, prepare ${tasks.last.recipeName}';
  }
}

// Models

enum PrepDay {
  sunday,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday;

  String get displayName {
    return toString().split('.').last.substring(0, 1).toUpperCase() +
        toString().split('.').last.substring(1);
  }
}

class BatchOpportunity {
  final String recipeName;
  final int occurrences;
  final double totalAmount;
  final int savingsMinutes;
  final List<Meal> meals;

  BatchOpportunity({
    required this.recipeName,
    required this.occurrences,
    required this.totalAmount,
    required this.savingsMinutes,
    required this.meals,
  });
}

class BatchCookingAnalysis {
  final List<BatchOpportunity> opportunities;
  final int totalTimeSavingsMinutes;
  final List<PrepDay> recommendedPrepDays;

  BatchCookingAnalysis({
    required this.opportunities,
    required this.totalTimeSavingsMinutes,
    required this.recommendedPrepDays,
  });
}

class PrepTask {
  final String id;
  final String recipeName;
  final double totalAmount;
  final int estimatedMinutes;
  final PrepDay prepDay;
  final int servings;
  final int containers;
  final String storageInstructions;
  final String reheatingInstructions;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? photoUrl;

  PrepTask({
    required this.id,
    required this.recipeName,
    required this.totalAmount,
    required this.estimatedMinutes,
    required this.prepDay,
    required this.servings,
    required this.containers,
    required this.storageInstructions,
    required this.reheatingInstructions,
    required this.isCompleted,
    this.completedAt,
    this.photoUrl,
  });

  PrepTask copyWith({
    bool? isCompleted,
    DateTime? completedAt,
    String? photoUrl,
  }) {
    return PrepTask(
      id: id,
      recipeName: recipeName,
      totalAmount: totalAmount,
      estimatedMinutes: estimatedMinutes,
      prepDay: prepDay,
      servings: servings,
      containers: containers,
      storageInstructions: storageInstructions,
      reheatingInstructions: reheatingInstructions,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

class PrepSchedule {
  final List<PrepDay> prepDays;
  final List<PrepTask> tasks;
  final Map<PrepDay, List<PrepTask>> tasksByDay;
  final int totalPrepTimeMinutes;
  final int containersNeeded;

  PrepSchedule({
    required this.prepDays,
    required this.tasks,
    required this.tasksByDay,
    required this.totalPrepTimeMinutes,
    required this.containersNeeded,
  });
}

class PrepInstruction {
  final int step;
  final String description;
  final int estimatedMinutes;
  final bool isParallel;
  final List<PrepTask> tasks;
  final String? parallelTip;

  PrepInstruction({
    required this.step,
    required this.description,
    required this.estimatedMinutes,
    required this.isParallel,
    required this.tasks,
    this.parallelTip,
  });
}

class StorageInfo {
  final String mealId;
  final DateTime preparedDate;
  final int refrigeratedDaysRemaining;
  final bool isFrozen;
  final String containerType;

  StorageInfo({
    required this.mealId,
    required this.preparedDate,
    required this.refrigeratedDaysRemaining,
    required this.isFrozen,
    required this.containerType,
  });
}

class StorageRecommendation {
  final int refrigeratedDays;
  final int freezerDays;
  final String containerType;
  final List<String> tips;

  StorageRecommendation({
    required this.refrigeratedDays,
    required this.freezerDays,
    required this.containerType,
    required this.tips,
  });
}

class ReheatingInstructions {
  final MicrowaveInstructions microwave;
  final OvenInstructions oven;
  final StovetopInstructions stovetop;

  ReheatingInstructions({
    required this.microwave,
    required this.oven,
    required this.stovetop,
  });
}

class MicrowaveInstructions {
  final String powerLevel;
  final String initialTime;
  final String stirInstructions;
  final String additionalTime;
  final List<String> tips;

  MicrowaveInstructions({
    required this.powerLevel,
    required this.initialTime,
    required this.stirInstructions,
    required this.additionalTime,
    required this.tips,
  });
}

class OvenInstructions {
  final int temperature;
  final int timeMinutes;
  final String preparation;
  final List<String> tips;

  OvenInstructions({
    required this.temperature,
    required this.timeMinutes,
    required this.preparation,
    required this.tips,
  });
}

class StovetopInstructions {
  final String heat;
  final int timeMinutes;
  final List<String> tips;

  StovetopInstructions({
    required this.heat,
    required this.timeMinutes,
    required this.tips,
  });
}

class PrepProgress {
  final int totalTasks;
  final int completedTasks;
  final int totalMinutes;
  final int completedMinutes;
  final List<PrepTask> remainingTasks;

  PrepProgress({
    required this.totalTasks,
    required this.completedTasks,
    required this.totalMinutes,
    required this.completedMinutes,
    required this.remainingTasks,
  });

  double get percentComplete =>
      totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0;

  int get remainingMinutes => totalMinutes - completedMinutes;
}