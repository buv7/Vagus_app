import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/admin/admin_models.dart';

class ComplianceService {
  ComplianceService._();
  static final ComplianceService I = ComplianceService._();

  final _db = Supabase.instance.client;

  /// Generate a compliance report
  Future<String> generateReport({
    required ReportType reportType,
    String? userId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final currentUser = _db.auth.currentUser;
      if (currentUser == null) throw Exception('Not authenticated');

      // Update status to generating
      final report = ComplianceReport(
        id: 'temp',
        reportType: reportType,
        userId: userId,
        generatedBy: currentUser.id,
        reportData: additionalData ?? {},
        status: ReportStatus.generating,
        createdAt: DateTime.now(),
      );

      final res = await _db
          .from('compliance_reports')
          .insert(report.toInsertJson())
          .select()
          .single();

      final reportId = res['id'] as String;

      // TODO: In production, trigger background job to generate actual report
      // For now, mark as completed immediately
      await _db
          .from('compliance_reports')
          .update({
            'status': ReportStatus.completed.toDb(),
            'completed_at': DateTime.now().toUtc().toIso8601String(),
            'file_url': 'https://example.com/reports/$reportId.pdf', // Placeholder
          })
          .eq('id', reportId);

      return reportId;
    } catch (e) {
      debugPrint('Failed to generate compliance report: $e');
      rethrow;
    }
  }

  /// Get compliance report by ID
  Future<ComplianceReport?> getReport(String reportId) async {
    try {
      final res = await _db
          .from('compliance_reports')
          .select()
          .eq('id', reportId)
          .maybeSingle();

      if (res == null) return null;
      return ComplianceReport.fromJson(res);
    } catch (e) {
      debugPrint('Failed to get compliance report: $e');
      return null;
    }
  }

  /// List compliance reports
  Future<List<ComplianceReport>> listReports({
    ReportType? reportType,
    String? userId,
    int limit = 50,
  }) async {
    try {
      var query = _db
          .from('compliance_reports')
          .select();

      if (reportType != null) {
        query = query.eq('report_type', reportType.toDb());
      }

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final res = await query.order('created_at', ascending: false).limit(limit);

      return (res as List)
          .map((e) => ComplianceReport.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to list compliance reports: $e');
      return [];
    }
  }
}
