import 'biomarker_result.dart';

class LabWork {
  const LabWork({
    required this.id,
    required this.userId,
    required this.labDate,
    required this.source,
    required this.createdAt,
    this.parsedAt,
    this.biomarkers = const [],
    this.biomarkerCount = 0,
  });

  final String id;
  final String userId;
  final DateTime labDate;
  final String source;
  final DateTime? parsedAt;
  final List<BiomarkerResult> biomarkers;
  final int biomarkerCount;
  final DateTime createdAt;

  /// Constructs a list item (no biomarker decryption — use [fromDetailJson] for full detail).
  factory LabWork.fromListJson(Map<String, dynamic> json) {
    return LabWork(
      id: json['id'] as String,
      userId: '',
      labDate: DateTime.parse(json['lab_date'] as String),
      source: json['source'] as String,
      parsedAt: json['parsed_at'] != null
          ? DateTime.parse(json['parsed_at'] as String)
          : null,
      biomarkerCount: json['biomarker_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Constructs a full detail record from get_lab_detail() RPC response.
  factory LabWork.fromDetailJson(Map<String, dynamic> json) {
    final rawBiomarkers = json['biomarkers'] as List<dynamic>? ?? [];
    return LabWork(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      labDate: DateTime.parse(json['lab_date'] as String),
      source: json['source'] as String,
      parsedAt: json['parsed_at'] != null
          ? DateTime.parse(json['parsed_at'] as String)
          : null,
      biomarkers: rawBiomarkers
          .map((e) => BiomarkerResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      biomarkerCount: rawBiomarkers.length,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get sourceLabel => switch (source) {
        'pdf' => 'PDF',
        'photo' => 'Photo',
        'manual' => 'Manual',
        _ => source,
      };

  int get flaggedCount =>
      biomarkers.where((b) => b.flag != BiomarkerFlag.normal).length;
}
