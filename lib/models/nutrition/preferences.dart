class Preferences {
  final String userId;
  final int? calorieTarget;
  final int? proteinG;
  final int? carbsG;
  final int? fatG;
  final int? sodiumMaxMg;
  final int? potassiumMinMg;
  final List<String> dietTags;
  final List<String> cuisinePrefs;
  final String? costTier;
  final String? preferredCurrency;
  final bool? halal;
  final Map<String, dynamic>? fastingWindow;
  final DateTime? updatedAt;

  Preferences({
    required this.userId,
    this.calorieTarget,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.sodiumMaxMg,
    this.potassiumMinMg,
    this.dietTags = const [],
    this.cuisinePrefs = const [],
    this.costTier,
    this.preferredCurrency,
    this.halal,
    this.fastingWindow,
    this.updatedAt,
  });

  factory Preferences.fromMap(Map<String, dynamic> map) {
    return Preferences(
      userId: map['user_id']?.toString() ?? '',
      calorieTarget: map['calorie_target'] as int?,
      proteinG: map['protein_g'] as int?,
      carbsG: map['carbs_g'] as int?,
      fatG: map['fat_g'] as int?,
      sodiumMaxMg: map['sodium_max_mg'] as int?,
      potassiumMinMg: map['potassium_min_mg'] as int?,
      dietTags: (map['diet_tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      cuisinePrefs: (map['cuisine_prefs'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      costTier: map['cost_tier']?.toString(),
      preferredCurrency: map['preferred_currency']?.toString(),
      halal: map['halal'] as bool?,
      fastingWindow: map['fasting_window'] as Map<String, dynamic>?,
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      if (calorieTarget != null) 'calorie_target': calorieTarget,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (sodiumMaxMg != null) 'sodium_max_mg': sodiumMaxMg,
      if (potassiumMinMg != null) 'potassium_min_mg': potassiumMinMg,
      if (dietTags.isNotEmpty) 'diet_tags': dietTags,
      if (cuisinePrefs.isNotEmpty) 'cuisine_prefs': cuisinePrefs,
      if (costTier != null) 'cost_tier': costTier,
      if (preferredCurrency != null) 'preferred_currency': preferredCurrency,
      if (halal != null) 'halal': halal,
      if (fastingWindow != null) 'fasting_window': fastingWindow,
      if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Preferences copyWith({
    String? userId,
    int? calorieTarget,
    int? proteinG,
    int? carbsG,
    int? fatG,
    int? sodiumMaxMg,
    int? potassiumMinMg,
    List<String>? dietTags,
    List<String>? cuisinePrefs,
    String? costTier,
    String? preferredCurrency,
    bool? halal,
    Map<String, dynamic>? fastingWindow,
    DateTime? updatedAt,
  }) {
    return Preferences(
      userId: userId ?? this.userId,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      sodiumMaxMg: sodiumMaxMg ?? this.sodiumMaxMg,
      potassiumMinMg: potassiumMinMg ?? this.potassiumMinMg,
      dietTags: dietTags ?? this.dietTags,
      cuisinePrefs: cuisinePrefs ?? this.cuisinePrefs,
      costTier: costTier ?? this.costTier,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      halal: halal ?? this.halal,
      fastingWindow: fastingWindow ?? this.fastingWindow,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Preferences &&
        other.userId == userId &&
        other.calorieTarget == calorieTarget &&
        other.proteinG == proteinG &&
        other.carbsG == carbsG &&
        other.fatG == fatG &&
        other.sodiumMaxMg == sodiumMaxMg &&
        other.potassiumMinMg == potassiumMinMg &&
        _listEquals(other.dietTags, dietTags) &&
        _listEquals(other.cuisinePrefs, cuisinePrefs) &&
        other.costTier == costTier &&
        other.preferredCurrency == preferredCurrency &&
        other.halal == halal &&
        _mapEquals(other.fastingWindow, fastingWindow) &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        calorieTarget.hashCode ^
        proteinG.hashCode ^
        carbsG.hashCode ^
        fatG.hashCode ^
        sodiumMaxMg.hashCode ^
        potassiumMinMg.hashCode ^
        dietTags.hashCode ^
        cuisinePrefs.hashCode ^
        costTier.hashCode ^
        preferredCurrency.hashCode ^
        halal.hashCode ^
        fastingWindow.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'Preferences(userId: $userId, calorieTarget: $calorieTarget, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG, sodiumMaxMg: $sodiumMaxMg, potassiumMinMg: $potassiumMinMg, dietTags: $dietTags, cuisinePrefs: $cuisinePrefs, costTier: $costTier, preferredCurrency: $preferredCurrency, halal: $halal, fastingWindow: $fastingWindow, updatedAt: $updatedAt)';
  }

  // Helper methods for list comparison
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  // Helper methods for map comparison
  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  // Compatibility getters for existing code
  String get currency => preferredCurrency ?? 'USD'; // Default currency
  int get hydrationTargetMl => 3000; // Default 3L hydration target
}

class PreferencesWarnings {
  final bool sodiumExceeded;
  final bool notHalal;
  final List<String> allergens; // names matched

  const PreferencesWarnings({
    this.sodiumExceeded = false,
    this.notHalal = false,
    this.allergens = const [],
  });

  bool get hasWarnings => sodiumExceeded || notHalal || allergens.isNotEmpty;

  PreferencesWarnings copyWith({
    bool? sodiumExceeded,
    bool? notHalal,
    List<String>? allergens,
  }) {
    return PreferencesWarnings(
      sodiumExceeded: sodiumExceeded ?? this.sodiumExceeded,
      notHalal: notHalal ?? this.notHalal,
      allergens: allergens ?? this.allergens,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PreferencesWarnings &&
        other.sodiumExceeded == sodiumExceeded &&
        other.notHalal == notHalal &&
        _listEquals(other.allergens, allergens);
  }

  @override
  int get hashCode {
    return sodiumExceeded.hashCode ^
        notHalal.hashCode ^
        allergens.hashCode;
  }

  @override
  String toString() {
    return 'PreferencesWarnings(sodiumExceeded: $sodiumExceeded, notHalal: $notHalal, allergens: $allergens)';
  }

  // Helper method for list comparison
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
