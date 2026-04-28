import 'flow_level.dart';
import 'period_symptom.dart';

class PeriodLog {
  final String id;
  final String userId;
  final DateTime logDate;
  final FlowLevel? flow;
  final List<PeriodSymptom> symptoms;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PeriodLog({
    required this.id,
    required this.userId,
    required this.logDate,
    this.flow,
    required this.symptoms,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Build from the decrypted row returned by periods_get_logs_decrypted RPC.
  factory PeriodLog.fromDecryptedMap(Map<String, dynamic> map, String userId) {
    final flowStr = map['flow']?.toString();
    final symptomsStr = map['symptoms']?.toString();

    return PeriodLog(
      id: map['id']?.toString() ?? '',
      userId: userId,
      logDate: DateTime.tryParse(map['log_date']?.toString() ?? '') ?? DateTime.now(),
      flow: flowStr != null ? FlowLevel.fromKey(flowStr) : null,
      symptoms: symptomsStr != null
          ? PeriodSymptom.fromJsonList(symptomsStr)
          : const [],
      notes: map['notes']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  bool get hasSymptoms => symptoms.isNotEmpty;
  bool get hasNotes => notes != null && notes!.isNotEmpty;
  bool get hasFlow => flow != null && flow != FlowLevel.none;
}
