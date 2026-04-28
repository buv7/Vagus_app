enum PeriodSymptom {
  cramps,
  headache,
  mood,
  fatigue,
  bloating,
  breastTenderness,
  acne,
  foodCraving,
  libido;

  static PeriodSymptom? fromKey(String key) {
    return PeriodSymptom.values.cast<PeriodSymptom?>().firstWhere(
      (s) => s?.name == key,
      orElse: () => null,
    );
  }

  String get displayName {
    switch (this) {
      case PeriodSymptom.cramps:           return 'Cramps';
      case PeriodSymptom.headache:         return 'Headache';
      case PeriodSymptom.mood:             return 'Mood Changes';
      case PeriodSymptom.fatigue:          return 'Fatigue';
      case PeriodSymptom.bloating:         return 'Bloating';
      case PeriodSymptom.breastTenderness: return 'Breast Tenderness';
      case PeriodSymptom.acne:             return 'Acne';
      case PeriodSymptom.foodCraving:      return 'Food Cravings';
      case PeriodSymptom.libido:           return 'Libido Changes';
    }
  }

  static List<PeriodSymptom> fromJsonList(String json) {
    try {
      final List<dynamic> decoded = List<dynamic>.from(
        _parseJsonArray(json),
      );
      return decoded
          .map((k) => fromKey(k.toString()))
          .whereType<PeriodSymptom>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  static List<dynamic> _parseJsonArray(String json) {
    // Minimal JSON array parser to avoid importing dart:convert in model layer.
    // The service layer encodes using jsonEncode before writing.
    final trimmed = json.trim();
    if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) return [];
    final inner = trimmed.substring(1, trimmed.length - 1);
    if (inner.isEmpty) return [];
    return inner.split(',').map((s) {
      final clean = s.trim();
      if (clean.startsWith('"') && clean.endsWith('"')) {
        return clean.substring(1, clean.length - 1);
      }
      return clean;
    }).toList();
  }
}
