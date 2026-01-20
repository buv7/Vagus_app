import 'package:flutter/foundation.dart';

enum ReportType {
  gdpr,
  dataExport,
  audit,
  userData;

  String get label {
    switch (this) {
      case ReportType.gdpr:
        return 'GDPR';
      case ReportType.dataExport:
        return 'Data Export';
      case ReportType.audit:
        return 'Audit';
      case ReportType.userData:
        return 'User Data';
    }
  }

  String toDb() {
    switch (this) {
      case ReportType.dataExport:
        return 'data_export';
      case ReportType.userData:
        return 'user_data';
      default:
        return name;
    }
  }

  static ReportType fromDb(String value) {
    switch (value) {
      case 'data_export':
        return ReportType.dataExport;
      case 'user_data':
        return ReportType.userData;
      case 'gdpr':
        return ReportType.gdpr;
      case 'audit':
        return ReportType.audit;
      default:
        return ReportType.audit;
    }
  }
}

enum ReportStatus {
  pending,
  generating,
  completed,
  failed;

  String toDb() => name;

  static ReportStatus fromDb(String value) {
    return ReportStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReportStatus.pending,
    );
  }
}

enum SafetyActionOnMatch {
  block,
  requireApproval,
  warn;

  String toDb() => name;

  static SafetyActionOnMatch fromDb(String value) {
    return SafetyActionOnMatch.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SafetyActionOnMatch.block,
    );
  }
}

enum SafetyAuditResult {
  allowed,
  blocked,
  requiresApproval,
  warned;

  String toDb() => name;

  static SafetyAuditResult fromDb(String value) {
    return SafetyAuditResult.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SafetyAuditResult.allowed,
    );
  }
}

@immutable
class AdminHierarchy {
  final String id;
  final String adminId;
  final int level; // 1-5
  final String? parentAdminId;
  final Map<String, dynamic> permissions;
  final String? assignedBy;
  final DateTime assignedAt;
  final DateTime createdAt;

  const AdminHierarchy({
    required this.id,
    required this.adminId,
    required this.level,
    this.parentAdminId,
    required this.permissions,
    this.assignedBy,
    required this.assignedAt,
    required this.createdAt,
  });

  factory AdminHierarchy.fromJson(Map<String, dynamic> json) {
    return AdminHierarchy(
      id: json['id'] as String,
      adminId: json['admin_id'] as String,
      level: json['level'] as int,
      parentAdminId: json['parent_admin_id'] as String?,
      permissions: json['permissions'] as Map<String, dynamic>? ?? {},
      assignedBy: json['assigned_by'] as String?,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'admin_id': adminId,
      'level': level,
      'parent_admin_id': parentAdminId,
      'permissions': permissions,
      'assigned_by': assignedBy,
      'assigned_at': assignedAt.toUtc().toIso8601String(),
    };
  }
}

@immutable
class ComplianceReport {
  final String id;
  final ReportType reportType;
  final String? userId;
  final String generatedBy;
  final Map<String, dynamic> reportData;
  final String? filePath;
  final String? fileUrl;
  final ReportStatus status;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? completedAt;

  const ComplianceReport({
    required this.id,
    required this.reportType,
    this.userId,
    required this.generatedBy,
    required this.reportData,
    this.filePath,
    this.fileUrl,
    required this.status,
    this.expiresAt,
    required this.createdAt,
    this.completedAt,
  });

  factory ComplianceReport.fromJson(Map<String, dynamic> json) {
    return ComplianceReport(
      id: json['id'] as String,
      reportType: ReportType.fromDb(json['report_type'] as String),
      userId: json['user_id'] as String?,
      generatedBy: json['generated_by'] as String,
      reportData: json['report_data'] as Map<String, dynamic>? ?? {},
      filePath: json['file_path'] as String?,
      fileUrl: json['file_url'] as String?,
      status: ReportStatus.fromDb(json['status'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'report_type': reportType.toDb(),
      'user_id': userId,
      'generated_by': generatedBy,
      'report_data': reportData,
      'file_path': filePath,
      'file_url': fileUrl,
      'status': status.toDb(),
      'expires_at': expiresAt?.toUtc().toIso8601String(),
      'completed_at': completedAt?.toUtc().toIso8601String(),
    };
  }
}

@immutable
class SafetyLayerRule {
  final String id;
  final String ruleName;
  final String actionPattern;
  final Map<String, dynamic> conditions;
  final SafetyActionOnMatch actionOnMatch;
  final int approvalRequiredLevel;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SafetyLayerRule({
    required this.id,
    required this.ruleName,
    required this.actionPattern,
    required this.conditions,
    required this.actionOnMatch,
    required this.approvalRequiredLevel,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SafetyLayerRule.fromJson(Map<String, dynamic> json) {
    return SafetyLayerRule(
      id: json['id'] as String,
      ruleName: json['rule_name'] as String,
      actionPattern: json['action_pattern'] as String,
      conditions: json['conditions'] as Map<String, dynamic>? ?? {},
      actionOnMatch: SafetyActionOnMatch.fromDb(json['action_on_match'] as String),
      approvalRequiredLevel: (json['approval_required_level'] as int?) ?? 5,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

@immutable
class SafetyLayerAudit {
  final String id;
  final String? ruleId;
  final String action;
  final Map<String, dynamic> payload;
  final String actorId;
  final SafetyAuditResult result;
  final String? reason;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;

  const SafetyLayerAudit({
    required this.id,
    this.ruleId,
    required this.action,
    required this.payload,
    required this.actorId,
    required this.result,
    this.reason,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
  });

  factory SafetyLayerAudit.fromJson(Map<String, dynamic> json) {
    return SafetyLayerAudit(
      id: json['id'] as String,
      ruleId: json['rule_id'] as String?,
      action: json['action'] as String,
      payload: json['payload'] as Map<String, dynamic>? ?? {},
      actorId: json['actor_id'] as String,
      result: SafetyAuditResult.fromDb(json['result'] as String),
      reason: json['reason'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
