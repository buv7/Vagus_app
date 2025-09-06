// lib/models/nutrition/grocery_list.dart
import 'package:equatable/equatable.dart';
// Use relative import to avoid package path issues flagged by analyzer.
import 'grocery_item.dart';

class GroceryList extends Equatable {
  final String id; // uuid
  final String planId;
  final int weekIndex;
  final String ownerId;
  final List<GroceryItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroceryList({
    required this.id,
    required this.planId,
    required this.weekIndex,
    required this.ownerId,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  GroceryList copyWith({
    String? id,
    String? planId,
    int? weekIndex,
    String? ownerId,
    List<GroceryItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroceryList(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      weekIndex: weekIndex ?? this.weekIndex,
      ownerId: ownerId ?? this.ownerId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'plan_id': planId,
        'week_index': weekIndex,
        'owner_id': ownerId,
        'items': items.map((e) => e.toMap()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory GroceryList.fromMap(Map<String, dynamic> m) => GroceryList(
        id: (m['id'] ?? '') as String,
        planId: (m['plan_id'] ?? '') as String,
        weekIndex: (m['week_index'] as num?)?.toInt() ?? 0,
        ownerId: (m['owner_id'] ?? '') as String,
        items: (m['items'] as List?)
                ?.map((e) => GroceryItem.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        createdAt: DateTime.tryParse('${m['created_at']}') ?? DateTime.now(),
        updatedAt: DateTime.tryParse('${m['updated_at']}') ?? DateTime.now(),
      );

  Map<String, List<GroceryItem>> byAisle() {
    final Map<String, List<GroceryItem>> out = {};
    for (final it in items) {
      final k = it.aisle ?? 'other';
      (out[k] ??= []).add(it);
    }
    return out;
  }

  double progress() {
    if (items.isEmpty) return 0;
    final done = items.where((e) => e.checked).length;
    return done / items.length;
  }

  @override
  List<Object?> get props =>
      [id, planId, weekIndex, ownerId, items, createdAt, updatedAt];
}