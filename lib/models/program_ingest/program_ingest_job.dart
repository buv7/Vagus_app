class ProgramIngestJob {
  final String id;
  final String clientId;
  final String coachId;
  final String source; // 'file' or 'text'
  final String? storagePath;
  final String? rawText;
  final String status; // 'queued', 'processing', 'succeeded', 'failed'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? error;

  ProgramIngestJob({
    required this.id,
    required this.clientId,
    required this.coachId,
    required this.source,
    this.storagePath,
    this.rawText,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.error,
  });

  factory ProgramIngestJob.fromJson(Map<String, dynamic> json) {
    return ProgramIngestJob(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      coachId: json['coach_id'] as String,
      source: json['source'] as String,
      storagePath: json['storage_path'] as String?,
      rawText: json['raw_text'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'coach_id': coachId,
      'source': source,
      'storage_path': storagePath,
      'raw_text': rawText,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'error': error,
    };
  }

  bool get isCompleted => status == 'succeeded' || status == 'failed';
  bool get isProcessing => status == 'processing';
  bool get isQueued => status == 'queued';
  bool get hasError => status == 'failed';
}

class ProgramIngestResult {
  final String id;
  final String jobId;
  final Map<String, dynamic> parsedJson;
  final String? modelHint;
  final DateTime createdAt;

  ProgramIngestResult({
    required this.id,
    required this.jobId,
    required this.parsedJson,
    this.modelHint,
    required this.createdAt,
  });

  factory ProgramIngestResult.fromJson(Map<String, dynamic> json) {
    return ProgramIngestResult(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      parsedJson: json['parsed_json'] as Map<String, dynamic>,
      modelHint: json['model_hint'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'parsed_json': parsedJson,
      'model_hint': modelHint,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper getters for structured data
  String? get notes => parsedJson['notes'] as String?;
  List<Map<String, dynamic>> get supplements => 
      (parsedJson['supplements'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  Map<String, dynamic>? get nutritionPlan => parsedJson['nutrition_plan'] as Map<String, dynamic>?;
  Map<String, dynamic>? get workoutPlan => parsedJson['workout_plan'] as Map<String, dynamic>?;
}
