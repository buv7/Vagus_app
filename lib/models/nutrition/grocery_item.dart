// lib/models/nutrition/grocery_item.dart
import 'package:equatable/equatable.dart';

class GroceryItem extends Equatable {
  final String id;       // uuid
  final String listId;   // parent grocery_list id
  final String name;
  final String canonicalKey; // normalized key for dedup
  final double amount;   // numeric quantity relative to unit
  final String unit;     // 'g','ml','pcs'
  final String? aisle;   // 'produce','meat','dairy', etc.
  final bool checked;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroceryItem({
    required this.id,
    required this.listId,
    required this.name,
    required this.canonicalKey,
    required this.amount,
    required this.unit,
    this.aisle,
    this.checked = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// compat alias expected by some UIs
  bool get isChecked => checked;

  GroceryItem copyWith({
    String? id,
    String? listId,
    String? name,
    String? canonicalKey,
    double? amount,
    String? unit,
    String? aisle,
    bool? checked,
    bool? isChecked, // compat alias
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      canonicalKey: canonicalKey ?? this.canonicalKey,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      aisle: aisle ?? this.aisle,
      checked: checked ?? isChecked ?? this.checked,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'list_id': listId,
        'name': name,
        'canonical_key': canonicalKey,
        'amount': amount,
        'unit': unit,
        'aisle': aisle,
        'checked': checked,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory GroceryItem.fromMap(Map<String, dynamic> m) => GroceryItem(
        id: (m['id'] ?? '') as String,
        listId: (m['list_id'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        canonicalKey: (m['canonical_key'] ?? '') as String,
        amount: (m['amount'] as num).toDouble(),
        unit: (m['unit'] ?? 'g') as String,
        aisle: m['aisle'] as String?,
        checked: (m['checked'] as bool?) ?? false,
        notes: m['notes'] as String?,
        createdAt: DateTime.tryParse('${m['created_at']}') ?? DateTime.now(),
        updatedAt: DateTime.tryParse('${m['updated_at']}') ?? DateTime.now(),
      );

  String get displayAmount {
    switch (unit) {
      case 'g':
        return '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 0)} g';
      case 'kg':
        return '${amount.toStringAsFixed(2)} kg';
      case 'ml':
        return '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 0)} ml';
      case 'l':
        return '${amount.toStringAsFixed(2)} L';
      case 'pcs':
      default:
        return '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)} pcs';
    }
  }

  @override
  List<Object?> get props =>
      [id, listId, canonicalKey, amount, unit, aisle, checked];
}