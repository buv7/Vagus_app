class NutritionPlan {
  final String? id;
  final String clientId;
  final String name;
  final String lengthType; // 'daily', 'weekly', 'program'
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Meal> meals;
  final DailySummary dailySummary;
  final bool aiGenerated;
  final bool unseenUpdate;

  NutritionPlan({
    this.id,
    required this.clientId,
    required this.name,
    required this.lengthType,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.meals,
    required this.dailySummary,
    this.aiGenerated = false,
    this.unseenUpdate = false,
  });

  factory NutritionPlan.fromMap(Map<String, dynamic> map) {
    return NutritionPlan(
      id: map['id']?.toString(),
      clientId: map['client_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      lengthType: map['length_type']?.toString() ?? 'daily',
      createdBy: map['created_by']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
      meals: (map['meals'] as List<dynamic>?)
              ?.map((meal) => Meal.fromMap(meal as Map<String, dynamic>))
              .toList() ??
          [],
      dailySummary: DailySummary.fromMap(map['daily_summary'] as Map<String, dynamic>? ?? {}),
      aiGenerated: map['ai_generated'] as bool? ?? false,
      unseenUpdate: map['unseen_update'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'client_id': clientId,
      'name': name,
      'length_type': lengthType,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'meals': meals.map((meal) => meal.toMap()).toList(),
      'daily_summary': dailySummary.toMap(),
      'ai_generated': aiGenerated,
      'unseen_update': unseenUpdate,
    };
  }

  NutritionPlan copyWith({
    String? id,
    String? clientId,
    String? name,
    String? lengthType,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Meal>? meals,
    DailySummary? dailySummary,
    bool? aiGenerated,
    bool? unseenUpdate,
  }) {
    return NutritionPlan(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      lengthType: lengthType ?? this.lengthType,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      meals: meals ?? this.meals,
      dailySummary: dailySummary ?? this.dailySummary,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      unseenUpdate: unseenUpdate ?? this.unseenUpdate,
    );
  }

  // Helper methods
  static double calcKcal(double protein, double carbs, double fat) {
    return (protein * 4) + (carbs * 4) + (fat * 9);
  }

  static MealSummary recalcMealSummary(Meal meal) {
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalKcal = 0;
    double totalSodium = 0;
    double totalPotassium = 0;

    for (final item in meal.items) {
      totalProtein += item.protein;
      totalCarbs += item.carbs;
      totalFat += item.fat;
      totalKcal += item.kcal;
      totalSodium += item.sodium;
      totalPotassium += item.potassium;
    }

    return MealSummary(
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      totalKcal: totalKcal,
      totalSodium: totalSodium,
      totalPotassium: totalPotassium,
    );
  }

  static DailySummary recalcDailySummary(List<Meal> meals) {
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalKcal = 0;
    double totalSodium = 0;
    double totalPotassium = 0;

    for (final meal in meals) {
      final summary = recalcMealSummary(meal);
      totalProtein += summary.totalProtein;
      totalCarbs += summary.totalCarbs;
      totalFat += summary.totalFat;
      totalKcal += summary.totalKcal;
      totalSodium += summary.totalSodium;
      totalPotassium += summary.totalPotassium;
    }

    return DailySummary(
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      totalKcal: totalKcal,
      totalSodium: totalSodium,
      totalPotassium: totalPotassium,
    );
  }
}

class Meal {
  final String label;
  final List<FoodItem> items;
  final MealSummary mealSummary;
  final String clientComment;
  final List<String> attachments;

  Meal({
    required this.label,
    required this.items,
    required this.mealSummary,
    this.clientComment = '',
    this.attachments = const [],
  });

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      label: map['label']?.toString() ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => FoodItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      mealSummary: MealSummary.fromMap(map['mealSummary'] as Map<String, dynamic>? ?? {}),
      clientComment: map['clientComment']?.toString() ?? '',
      attachments: (map['attachments'] as List<dynamic>?)
              ?.map((attachment) => attachment.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'items': items.map((item) => item.toMap()).toList(),
      'mealSummary': mealSummary.toMap(),
      'clientComment': clientComment,
      'attachments': attachments,
    };
  }

  Meal copyWith({
    String? label,
    List<FoodItem>? items,
    MealSummary? mealSummary,
    String? clientComment,
    List<String>? attachments,
  }) {
    return Meal(
      label: label ?? this.label,
      items: items ?? this.items,
      mealSummary: mealSummary ?? this.mealSummary,
      clientComment: clientComment ?? this.clientComment,
      attachments: attachments ?? this.attachments,
    );
  }
}

class FoodItem {
  final String name;
  final double amount; // Amount of food needed after cooking (in grams)
  final double protein;
  final double carbs;
  final double fat;
  final double kcal;
  final double sodium;
  final double potassium;
  // Recipe integration fields
  final String? recipeId;
  final double servings;
  // Cost fields
  final double? costPerUnit;
  final String? currency;
  // AI estimation flag
  final bool estimated;

  FoodItem({
    required this.name,
    this.amount = 0.0,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.kcal,
    required this.sodium,
    required this.potassium,
    this.recipeId,
    this.servings = 1.0,
    this.costPerUnit,
    this.currency,
    this.estimated = false,
  });

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      name: map['name']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      kcal: (map['kcal'] as num?)?.toDouble() ?? 0.0,
      sodium: (map['sodium'] as num?)?.toDouble() ?? 0.0,
      potassium: (map['potassium'] as num?)?.toDouble() ?? 0.0,
      recipeId: map['recipe_id']?.toString(),
      servings: (map['servings'] as num?)?.toDouble() ?? 1.0,
      costPerUnit: (map['cost_per_unit'] as num?)?.toDouble(),
      currency: map['currency']?.toString(),
      estimated: map['estimated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'kcal': kcal,
      'sodium': sodium,
      'potassium': potassium,
      if (recipeId != null) 'recipe_id': recipeId,
      'servings': servings,
      if (costPerUnit != null) 'cost_per_unit': costPerUnit,
      if (currency != null) 'currency': currency,
      'estimated': estimated,
    };
  }

  FoodItem copyWith({
    String? name,
    double? amount,
    double? protein,
    double? carbs,
    double? fat,
    double? kcal,
    double? sodium,
    double? potassium,
    String? recipeId,
    double? servings,
    double? costPerUnit,
    String? currency,
    bool? estimated,
  }) {
    return FoodItem(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      kcal: kcal ?? this.kcal,
      sodium: sodium ?? this.sodium,
      potassium: potassium ?? this.potassium,
      recipeId: recipeId ?? this.recipeId,
      servings: servings ?? this.servings,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      currency: currency ?? this.currency,
      estimated: estimated ?? this.estimated,
    );
  }
}

class MealSummary {
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalKcal;
  final double totalSodium;
  final double totalPotassium;

  MealSummary({
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalKcal,
    required this.totalSodium,
    required this.totalPotassium,
  });

  factory MealSummary.fromMap(Map<String, dynamic> map) {
    return MealSummary(
      totalProtein: (map['totalProtein'] as num?)?.toDouble() ?? 0.0,
      totalCarbs: (map['totalCarbs'] as num?)?.toDouble() ?? 0.0,
      totalFat: (map['totalFat'] as num?)?.toDouble() ?? 0.0,
      totalKcal: (map['totalKcal'] as num?)?.toDouble() ?? 0.0,
      totalSodium: (map['totalSodium'] as num?)?.toDouble() ?? 0.0,
      totalPotassium: (map['totalPotassium'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'totalKcal': totalKcal,
      'totalSodium': totalSodium,
      'totalPotassium': totalPotassium,
    };
  }
}

class DailySummary {
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalKcal;
  final double totalSodium;
  final double totalPotassium;

  DailySummary({
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalKcal,
    required this.totalSodium,
    required this.totalPotassium,
  });

  factory DailySummary.fromMap(Map<String, dynamic> map) {
    return DailySummary(
      totalProtein: (map['totalProtein'] as num?)?.toDouble() ?? 0.0,
      totalCarbs: (map['totalCarbs'] as num?)?.toDouble() ?? 0.0,
      totalFat: (map['totalFat'] as num?)?.toDouble() ?? 0.0,
      totalKcal: (map['totalKcal'] as num?)?.toDouble() ?? 0.0,
      totalSodium: (map['totalSodium'] as num?)?.toDouble() ?? 0.0,
      totalPotassium: (map['totalPotassium'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'totalKcal': totalKcal,
      'totalSodium': totalSodium,
      'totalPotassium': totalPotassium,
    };
  }
}
