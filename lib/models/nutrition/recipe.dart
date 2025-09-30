// lib/models/nutrition/recipe.dart
import 'dart:convert';
import 'package:equatable/equatable.dart';

/// --- Micros (typed vitamins/minerals map) ---
class Micros extends Equatable {
  final Map<String, double> values; // canonical snake_case -> amount (per serving)
  const Micros(this.values);
  factory Micros.empty() => const Micros({});
  Micros merge(Micros other) {
    final m = Map<String, double>.from(values);
    other.values.forEach((k, v) => m[k] = (m[k] ?? 0) + v);
    return Micros(m);
  }
  double getOrZero(String key) => values[key] ?? 0.0;
  Map<String, dynamic> toMap() => values;
  factory Micros.fromMap(dynamic src) {
    if (src == null) return Micros.empty();
    if (src is String) {
      try {
        final m = jsonDecode(src);
        if (m is Map<String, dynamic>) {
          return Micros(m.map((k, v) => MapEntry(k, (v as num).toDouble())));
        }
      } catch (_) {}
      return Micros.empty();
    }
    if (src is Map<String, dynamic>) {
      return Micros(src.map((k, v) => MapEntry(k, (v as num).toDouble())));
    }
    return Micros.empty();
  }
  String toJson() => jsonEncode(values);
  @override
  List<Object?> get props => [values];
}

/// --- Visibility ---
enum RecipeVisibility { private, client, team, public }

RecipeVisibility recipeVisibilityFromString(String? v) {
  switch (v) {
    case 'client':
      return RecipeVisibility.client;
    case 'team':
      return RecipeVisibility.team;
    case 'public':
      return RecipeVisibility.public;
    default:
      return RecipeVisibility.private;
  }
}
String recipeVisibilityToString(RecipeVisibility v) {
  switch (v) {
    case RecipeVisibility.client:
      return 'client';
    case RecipeVisibility.team:
      return 'team';
    case RecipeVisibility.public:
      return 'public';
    case RecipeVisibility.private:
      return 'private';
  }
}

/// Value getter expected by older UI
extension RecipeVisibilityCompat on RecipeVisibility {
  String get value => recipeVisibilityToString(this);
}

/// --- Step ---
class RecipeStep extends Equatable {
  final String id;        // <- compat: some UIs expect step id
  final String recipeId;
  final int stepIndex;    // legacy code often uses `index`
  final String instruction;
  final String? photoPath; // Supabase storage path
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecipeStep({
    required this.id,
    required this.recipeId,
    required this.stepIndex,
    required this.instruction,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// compat alias
  int get index => stepIndex;

  RecipeStep copyWith({
    String? id,
    String? recipeId,
    int? stepIndex,
    String? instruction,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecipeStep(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      stepIndex: stepIndex ?? this.stepIndex,
      instruction: instruction ?? this.instruction,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'recipe_id': recipeId,
        'step_index': stepIndex,
        'instruction': instruction,
        'photo_path': photoPath,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory RecipeStep.fromMap(Map<String, dynamic> m) => RecipeStep(
        id: (m['id'] ?? '') as String,
        recipeId: (m['recipe_id'] ?? '') as String,
        stepIndex: (m['step_index'] as num).toInt(),
        instruction: (m['instruction'] ?? '') as String,
        photoPath: m['photo_path'] as String?,
        createdAt: DateTime.tryParse('${m['created_at']}') ?? DateTime.now(),
        updatedAt: DateTime.tryParse('${m['updated_at']}') ?? DateTime.now(),
      );

  /// compat alias for older UI
  String? get photoUrl => photoPath;

  @override
  List<Object?> get props => [id, recipeId, stepIndex, instruction, photoPath];
}

/// --- Ingredient (now with optional id + cost fields) ---
class RecipeIngredient extends Equatable {
  final String? id;       // <- compat: some code expects an id
  final String recipeId;
  final String name;
  final double amount; // numeric quantity relative to `unit`
  final String unit;   // 'g','ml','pcs','tbsp','tsp', etc.

  // nutrition per ingredient amount (already scaled)
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sodiumMg;
  final double potassiumMg;
  final Micros micros;

  // costing (optional)
  final double? costPerUnit;
  final String? currency;

  final DateTime createdAt;
  final DateTime updatedAt;

  const RecipeIngredient({
    this.id,
    required this.recipeId,
    required this.name,
    required this.amount,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sodiumMg,
    required this.potassiumMg,
    this.micros = const Micros({}),
    this.costPerUnit,
    this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  RecipeIngredient copyWith({
    String? id,
    String? recipeId,
    String? name,
    double? amount,
    String? unit,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? sodiumMg,
    double? potassiumMg,
    Micros? micros,
    double? costPerUnit,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecipeIngredient(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      potassiumMg: potassiumMg ?? this.potassiumMg,
      micros: micros ?? this.micros,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'recipe_id': recipeId,
        'name': name,
        'amount': amount,
        'unit': unit,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'sodium_mg': sodiumMg,
        'potassium_mg': potassiumMg,
        'micros': micros.toMap(),
        'cost_per_unit': costPerUnit,
        'currency': currency,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory RecipeIngredient.fromMap(Map<String, dynamic> m) => RecipeIngredient(
        id: m['id'] as String?,
        recipeId: (m['recipe_id'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        amount: (m['amount'] as num).toDouble(),
        unit: (m['unit'] ?? 'g') as String,
        calories: (m['calories'] as num?)?.toDouble() ?? 0.0,
        protein: (m['protein'] as num?)?.toDouble() ?? 0.0,
        carbs: (m['carbs'] as num?)?.toDouble() ?? 0.0,
        fat: (m['fat'] as num?)?.toDouble() ?? 0.0,
        sodiumMg: (m['sodium_mg'] as num?)?.toDouble() ?? 0.0,
        potassiumMg: (m['potassium_mg'] as num?)?.toDouble() ?? 0.0,
        micros: Micros.fromMap(m['micros']),
        costPerUnit: (m['cost_per_unit'] as num?)?.toDouble(),
        currency: m['currency'] as String?,
        createdAt: DateTime.tryParse('${m['created_at']}') ?? DateTime.now(),
        updatedAt: DateTime.tryParse('${m['updated_at']}') ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [
        id, recipeId, name, amount, unit, calories, protein, carbs, fat,
        sodiumMg, potassiumMg, micros, costPerUnit, currency
      ];
}

/// --- Recipe ---
class Recipe extends Equatable {
  final String id;
  final String owner; // user_id
  final String? coachId;

  final String title;
  final String? summary;
  final List<String> cuisineTags;
  final List<String> dietTags;
  final List<String> allergens;
  final bool halal;

  final double servings;      // default 1.0
  final double? servingSize;  // optional, e.g., 150 g per serving
  final String? servingUnit;  // 'g', 'ml', 'pcs', etc.

  // totals per serving (not whole recipe)
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sodiumMg;
  final double potassiumMg;
  final Micros micros;

  final int? prepMinutes;
  final int? cookMinutes;

  final String? heroPhotoPath;     // storage path
  final RecipeVisibility visibility;

  final List<RecipeStep> steps;
  final List<RecipeIngredient> ingredients;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Recipe({
    required this.id,
    required this.owner,
    this.coachId,
    required this.title,
    this.summary,
    this.cuisineTags = const [],
    this.dietTags = const [],
    this.allergens = const [],
    this.halal = true,
    this.servings = 1.0,
    this.servingSize,
    this.servingUnit,
    this.calories = 0.0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.sodiumMg = 0.0,
    this.potassiumMg = 0.0,
    this.micros = const Micros({}),
    this.prepMinutes,
    this.cookMinutes,
    this.heroPhotoPath,
    this.visibility = RecipeVisibility.private,
    this.steps = const [],
    this.ingredients = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // ---------- Compat aliases expected by older UI ----------
  /// Older widgets expect a `sodium` (mg) double.
  double get sodium => sodiumMg;

  /// Older widgets expect a `totalMinutes` getter.
  int get totalMinutes => (prepMinutes ?? 0) + (cookMinutes ?? 0);

  /// Older widgets expect a `photoUrl` string. We return the storage path; rendering layers can resolve signed URLs.
  String? get photoUrl => heroPhotoPath;

  /// Convenience totals for current servings.
  double get kcalTotalForServings => calories * servings;
  double get proteinTotalForServings => protein * servings;
  double get carbsTotalForServings => carbs * servings;
  double get fatTotalForServings => fat * servings;

  Recipe scaled(double newServings) => copyWith(servings: newServings);
  
  // Compatibility alias for existing code
  Recipe scaleToServings(double s) => scaled(s);

  Recipe copyWith({
    String? id,
    String? owner,
    String? coachId,
    String? title,
    String? summary,
    List<String>? cuisineTags,
    List<String>? dietTags,
    List<String>? allergens,
    bool? halal,
    double? servings,
    double? servingSize,
    String? servingUnit,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? sodiumMg,
    double? potassiumMg,
    Micros? micros,
    int? prepMinutes,
    int? cookMinutes,
    String? heroPhotoPath,
    RecipeVisibility? visibility,
    List<RecipeStep>? steps,
    List<RecipeIngredient>? ingredients,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      owner: owner ?? this.owner,
      coachId: coachId ?? this.coachId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      cuisineTags: cuisineTags ?? this.cuisineTags,
      dietTags: dietTags ?? this.dietTags,
      allergens: allergens ?? this.allergens,
      halal: halal ?? this.halal,
      servings: servings ?? this.servings,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      potassiumMg: potassiumMg ?? this.potassiumMg,
      micros: micros ?? this.micros,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      cookMinutes: cookMinutes ?? this.cookMinutes,
      heroPhotoPath: heroPhotoPath ?? this.heroPhotoPath,
      visibility: visibility ?? this.visibility,
      steps: steps ?? this.steps,
      ingredients: ingredients ?? this.ingredients,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<String> _stringList(dynamic v) {
    if (v == null) return const [];
    if (v is List) return v.map((e) => '$e').toList();
    if (v is String) {
      try {
        final arr = jsonDecode(v);
        if (arr is List) return arr.map((e) => '$e').toList();
      } catch (_) {}
    }
    return const [];
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'owner': owner,
        'coach_id': coachId,
        'title': title,
        'summary': summary,
        'cuisine_tags': cuisineTags,
        'diet_tags': dietTags,
        'allergens': allergens,
        'halal': halal,
        'servings': servings,
        'serving_size': servingSize,
        'unit': servingUnit,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'sodium_mg': sodiumMg,
        'potassium_mg': potassiumMg,
        'micros': micros.toMap(),
        'prep_minutes': prepMinutes,
        'cook_minutes': cookMinutes,
        'hero_photo_path': heroPhotoPath,
        'visibility': recipeVisibilityToString(visibility),
        'steps': steps.map((e) => e.toMap()).toList(),
        'ingredients': ingredients.map((e) => e.toMap()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Recipe.fromMap(Map<String, dynamic> m) => Recipe(
        id: (m['id'] ?? '') as String,
        owner: (m['owner'] ?? m['user_id'] ?? '') as String,
        coachId: m['coach_id'] as String?,
        title: (m['title'] ?? '') as String,
        summary: m['summary'] as String?,
        cuisineTags: _stringList(m['cuisine_tags']),
        dietTags: _stringList(m['diet_tags']),
        allergens: _stringList(m['allergens']),
        halal: (m['halal'] as bool?) ?? true,
        servings: (m['servings'] as num?)?.toDouble() ?? 1.0,
        servingSize: (m['serving_size'] as num?)?.toDouble(),
        servingUnit: m['unit'] as String?,
        calories: (m['calories'] as num?)?.toDouble() ?? 0.0,
        protein: (m['protein'] as num?)?.toDouble() ?? 0.0,
        carbs: (m['carbs'] as num?)?.toDouble() ?? 0.0,
        fat: (m['fat'] as num?)?.toDouble() ?? 0.0,
        sodiumMg: (m['sodium_mg'] as num?)?.toDouble() ?? 0.0,
        potassiumMg: (m['potassium_mg'] as num?)?.toDouble() ?? 0.0,
        micros: Micros.fromMap(m['micros']),
        prepMinutes: (m['prep_minutes'] as num?)?.toInt(),
        cookMinutes: (m['cook_minutes'] as num?)?.toInt(),
        heroPhotoPath: m['hero_photo_path'] as String?,
        visibility: recipeVisibilityFromString(m['visibility'] as String?),
        steps: (m['steps'] as List?)
                ?.map((e) => RecipeStep.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        ingredients: (m['ingredients'] as List?)
                ?.map((e) => RecipeIngredient.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        createdAt: DateTime.tryParse('${m['created_at']}') ?? DateTime.now(),
        updatedAt: DateTime.tryParse('${m['updated_at']}') ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [
        id, owner, coachId, title, summary, cuisineTags, dietTags, allergens, halal,
        servings, servingSize, servingUnit, calories, protein, carbs, fat,
        sodiumMg, potassiumMg, micros, prepMinutes, cookMinutes, heroPhotoPath,
        visibility, steps, ingredients, createdAt, updatedAt,
      ];
}