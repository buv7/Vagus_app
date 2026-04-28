enum BiomarkerFlag { low, normal, high, unknown }

class BiomarkerResult {
  const BiomarkerResult({
    required this.name,
    required this.rawValueStr,
    required this.unit,
    required this.flag,
    this.dictionaryId,
    this.value,
    this.referenceRange,
    this.needsReview = false,
  });

  final String name;
  final String? dictionaryId;
  final double? value;
  final String rawValueStr;
  final String unit;
  final String? referenceRange;
  final BiomarkerFlag flag;
  final bool needsReview;

  factory BiomarkerResult.fromJson(Map<String, dynamic> json) {
    return BiomarkerResult(
      name: json['name'] as String,
      dictionaryId: json['dictionary_id'] as String?,
      value: (json['value'] as num?)?.toDouble(),
      rawValueStr: json['raw_value'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      referenceRange: json['reference_range'] as String?,
      flag: _parseFlag(json['flag'] as String?),
      needsReview: json['needs_review'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (dictionaryId != null) 'dictionary_id': dictionaryId,
        if (value != null) 'value': value,
        'raw_value': rawValueStr,
        'unit': unit,
        if (referenceRange != null) 'reference_range': referenceRange,
        'flag': flag.name,
        'needs_review': needsReview,
      };

  static BiomarkerFlag _parseFlag(String? s) => switch (s) {
        'low' => BiomarkerFlag.low,
        'normal' => BiomarkerFlag.normal,
        'high' => BiomarkerFlag.high,
        _ => BiomarkerFlag.unknown,
      };

  BiomarkerResult copyWith({
    String? dictionaryId,
    BiomarkerFlag? flag,
    bool? needsReview,
    String? referenceRange,
  }) =>
      BiomarkerResult(
        name: name,
        dictionaryId: dictionaryId ?? this.dictionaryId,
        value: value,
        rawValueStr: rawValueStr,
        unit: unit,
        referenceRange: referenceRange ?? this.referenceRange,
        flag: flag ?? this.flag,
        needsReview: needsReview ?? this.needsReview,
      );
}
