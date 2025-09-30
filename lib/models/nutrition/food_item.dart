import 'package:equatable/equatable.dart';

/// Represents a food item with nutritional information
class FoodItem extends Equatable {
  final String? id;
  final String name;
  final double protein;
  final double carbs;
  final double fat;
  final double kcal;
  final double sodium;
  final double potassium;
  final double amount;
  final String? unit;
  final bool estimated;
  final String? source; // 'photo', 'barcode', 'manual', etc.
  final String? imageUrl;
  final String? brand;

  const FoodItem({
    this.id,
    required this.name,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.kcal,
    required this.sodium,
    required this.potassium,
    required this.amount,
    this.unit,
    this.estimated = false,
    this.source,
    this.imageUrl,
    this.brand,
  });

  /// Getter for calories (alias for kcal)
  double get calories => kcal;

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      kcal: (map['kcal'] as num?)?.toDouble() ?? 0.0,
      sodium: (map['sodium'] as num?)?.toDouble() ?? 0.0,
      potassium: (map['potassium'] as num?)?.toDouble() ?? 0.0,
      amount: (map['amount'] as num?)?.toDouble() ?? 100.0,
      unit: map['unit']?.toString(),
      estimated: map['estimated'] == true,
      source: map['source']?.toString(),
      imageUrl: map['image_url']?.toString(),
      brand: map['brand']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'kcal': kcal,
      'sodium': sodium,
      'potassium': potassium,
      'amount': amount,
      'unit': unit,
      'estimated': estimated,
      'source': source,
      'image_url': imageUrl,
      'brand': brand,
    };
  }

  /// Alias for toMap (for compatibility)
  Map<String, dynamic> toJson() => toMap();

  /// Alias for fromMap (for compatibility)
  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem.fromMap(json);

  FoodItem copyWith({
    String? id,
    String? name,
    double? protein,
    double? carbs,
    double? fat,
    double? kcal,
    double? sodium,
    double? potassium,
    double? amount,
    String? unit,
    bool? estimated,
    String? source,
    String? imageUrl,
    String? brand,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      kcal: kcal ?? this.kcal,
      sodium: sodium ?? this.sodium,
      potassium: potassium ?? this.potassium,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      estimated: estimated ?? this.estimated,
      source: source ?? this.source,
      imageUrl: imageUrl ?? this.imageUrl,
      brand: brand ?? this.brand,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        protein,
        carbs,
        fat,
        kcal,
        sodium,
        potassium,
        amount,
        unit,
        estimated,
        source,
        imageUrl,
        brand,
      ];
}
