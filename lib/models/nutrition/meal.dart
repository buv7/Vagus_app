import 'food_item.dart';

/// Meal model for nutrition tracking
class Meal {
  final String? id;
  final String label;
  final String? mealType;
  final DateTime? time;
  final String? notes;
  final List<MealItem> items;

  Meal({
    this.id,
    required this.label,
    this.mealType,
    this.time,
    this.notes,
    this.items = const [],
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'],
      label: json['label'] ?? '',
      mealType: json['meal_type'],
      time: json['time'] != null ? DateTime.parse(json['time']) : null,
      notes: json['notes'],
      items: (json['items'] as List?)
          ?.map((item) => MealItem.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'meal_type': mealType,
      'time': time?.toIso8601String(),
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  Meal copyWith({
    String? id,
    String? label,
    String? mealType,
    DateTime? time,
    String? notes,
    List<MealItem>? items,
  }) {
    return Meal(
      id: id ?? this.id,
      label: label ?? this.label,
      mealType: mealType ?? this.mealType,
      time: time ?? this.time,
      notes: notes ?? this.notes,
      items: items ?? this.items,
    );
  }

  /// Get last updated timestamp (placeholder)
  DateTime get updatedAt => time ?? DateTime.now();
}

/// Meal item (food within a meal)
class MealItem {
  final String foodId;
  final String name;
  final double quantity;
  final String unit;
  final Map<String, dynamic>? nutrition;

  MealItem({
    required this.foodId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.nutrition,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      foodId: json['food_id'] ?? '',
      name: json['name'] ?? '',
      quantity: (json['quantity'] ?? 1.0).toDouble(),
      unit: json['unit'] ?? 'g',
      nutrition: json['nutrition'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_id': foodId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'nutrition': nutrition,
    };
  }

  /// Get associated FoodItem (stub - would normally fetch from DB)
  FoodItem get foodItem {
    return FoodItem(
      id: foodId,
      name: name,
      protein: (nutrition?['protein'] ?? 0.0).toDouble(),
      carbs: (nutrition?['carbs'] ?? 0.0).toDouble(),
      fat: (nutrition?['fat'] ?? 0.0).toDouble(),
      kcal: (nutrition?['kcal'] ?? 0.0).toDouble(),
      sodium: (nutrition?['sodium'] ?? 0.0).toDouble(),
      potassium: (nutrition?['potassium'] ?? 0.0).toDouble(),
      amount: quantity,
      unit: unit,
    );
  }
}