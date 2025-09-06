import 'package:equatable/equatable.dart';

class PantryItem extends Equatable {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final String unit;
  final DateTime? expiresAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PantryItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.unit,
    this.expiresAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PantryItem.fromMap(Map<String, dynamic> map) {
    return PantryItem(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit']?.toString() ?? 'g',
      expiresAt: map['expires_at'] != null 
          ? DateTime.tryParse(map['expires_at'].toString())
          : null,
      notes: map['notes']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'amount': amount,
      'unit': unit,
      'expires_at': expiresAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PantryItem copyWith({
    String? id,
    String? userId,
    String? name,
    double? amount,
    String? unit,
    DateTime? expiresAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PantryItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      expiresAt: expiresAt ?? this.expiresAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Compatibility getters for existing UI
  String get displayQuantity => '$amount $unit';
  double get qty => amount;
  String get key => id; // Use id as key for compatibility
  
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  bool get isExpiringSoon {
    if (expiresAt == null) return false;
    final now = DateTime.now();
    final threeDaysFromNow = now.add(const Duration(days: 3));
    return expiresAt!.isBefore(threeDaysFromNow) && !isExpired;
  }

  // Unit conversion method for compatibility
  PantryItem convertToUnit(String newUnit) {
    // Simple conversion logic - in a real app, you'd have proper conversion factors
    double newAmount = amount;
    if (unit == 'g' && newUnit == 'kg') {
      newAmount = amount / 1000;
    } else if (unit == 'kg' && newUnit == 'g') {
      newAmount = amount * 1000;
    } else if (unit == 'ml' && newUnit == 'l') {
      newAmount = amount / 1000;
    } else if (unit == 'l' && newUnit == 'ml') {
      newAmount = amount * 1000;
    }
    
    return copyWith(
      amount: newAmount,
      unit: newUnit,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    amount,
    unit,
    expiresAt,
    notes,
    createdAt,
    updatedAt,
  ];
}