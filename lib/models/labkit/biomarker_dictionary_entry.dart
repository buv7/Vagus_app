class BiomarkerDictionaryEntry {
  const BiomarkerDictionaryEntry({
    required this.id,
    required this.name,
    required this.category,
    this.nameAr,
    this.nameKu,
    this.unit,
    this.referenceRangeMale,
    this.referenceRangeFemale,
    this.optimalRange,
    this.aliases = const [],
  });

  final String id;
  final String name;
  final String? nameAr;
  final String? nameKu;
  final String category;
  final String? unit;
  final String? referenceRangeMale;
  final String? referenceRangeFemale;
  final String? optimalRange;
  final List<String> aliases;

  factory BiomarkerDictionaryEntry.fromJson(Map<String, dynamic> json) {
    return BiomarkerDictionaryEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String?,
      nameKu: json['name_ku'] as String?,
      category: json['category'] as String,
      unit: json['unit'] as String?,
      referenceRangeMale: json['reference_range_male'] as String?,
      referenceRangeFemale: json['reference_range_female'] as String?,
      optimalRange: json['optimal_range'] as String?,
      aliases: (json['aliases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  List<String> get allSearchTerms => [
        name.toLowerCase(),
        ...aliases.map((a) => a.toLowerCase()),
      ];
}
