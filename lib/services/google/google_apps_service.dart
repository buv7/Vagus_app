import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/google/google_models.dart';

/// Service for Google Apps integration (Sheets, Drive, Forms)
class GoogleAppsService {
  static final GoogleAppsService _instance = GoogleAppsService._internal();
  factory GoogleAppsService() => _instance;
  GoogleAppsService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if user has connected Google account
  Future<bool> isConnected() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      
      await _supabase
          .from('integrations_google_accounts')
          .select()
          .eq('user_id', userId)
          .single();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get connected Google account
  Future<GoogleAccount?> getConnectedAccount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;
      
      final response = await _supabase
          .from('integrations_google_accounts')
          .select()
          .eq('user_id', userId)
          .single();
      
      return GoogleAccount.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Connect coach account to Google
  Future<bool> connectCoachAccount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // TODO: call edge function 'google_connect'
      // For now, simulate OAuth flow with delay
      await Future.delayed(const Duration(seconds: 2));

      // Simulate successful connection
      final mockEmail = 'coach${Random().nextInt(1000)}@example.com';
      
      await _supabase.from('integrations_google_accounts').upsert({
        'user_id': userId,
        'kind': 'coach',
        'email': mockEmail,
        'connected_at': DateTime.now().toIso8601String(),
        'creds_meta': {'status': 'connected'},
      });

      // Log analytics
      _logAnalytics('google_connect', {'kind': 'coach'});
      
      return true;
    } catch (e) {
      debugPrint('Error connecting Google account: $e');
      return false;
    }
  }

  /// Disconnect Google account
  Future<bool> disconnect() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('integrations_google_accounts')
          .delete()
          .eq('user_id', userId);

      // Log analytics
      _logAnalytics('google_disconnect', {});
      
      return true;
    } catch (e) {
      debugPrint('Error disconnecting Google account: $e');
      return false;
    }
  }

  /// Update workspace folder
  Future<bool> updateWorkspaceFolder(String folder) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('integrations_google_accounts')
          .update({'workspace_folder': folder})
          .eq('user_id', userId);

      return true;
    } catch (e) {
      debugPrint('Error updating workspace folder: $e');
      return false;
    }
  }

  /// Attach Drive link to target
  Future<bool> attachDriveLink({
    required DriveAttachmentTarget target,
    required GoogleFileLink link,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Save to google_file_links table
      await _supabase.from('google_file_links').insert({
        'owner_id': userId,
        'google_id': link.googleId,
        'mime': link.mime,
        'name': link.name,
        'web_url': link.webUrl,
      });

      // TODO: Also save to generic attachment table if exists
      // This would link the Google file to the specific target (note, workout, etc.)

      // Log analytics
      _logAnalytics('google_attach_drive', {
        'target': target.name,
        'mime': link.mime,
      });

      return true;
    } catch (e) {
      debugPrint('Error attaching Drive link: $e');
      return false;
    }
  }

  /// Export data to Google Sheets
  Future<String?> exportToSheets(String kind) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // Create export record
      final response = await _supabase.from('google_exports').insert({
        'owner_id': userId,
        'kind': kind,
        'status': 'queued',
      }).select().single();

      final exportId = response['id'];

      // TODO: call edge function 'google_export'
      // For now, simulate export process
      await Future.delayed(const Duration(seconds: 3));

      // Simulate successful export
      final mockSheetUrl = 'https://docs.google.com/spreadsheets/d/mock_${Random().nextInt(10000)}';
      
      await _supabase
          .from('google_exports')
          .update({
            'status': 'done',
            'sheet_url': mockSheetUrl,
          })
          .eq('id', exportId);

      // Log analytics
      _logAnalytics('google_export_done', {'kind': kind});

      return mockSheetUrl;
    } catch (e) {
      debugPrint('Error exporting to Sheets: $e');
      
      // Log error analytics
      _logAnalytics('google_export_error', {'kind': kind, 'error': e.toString()});
      
      return null;
    }
  }

  /// List recent exports
  Future<List<GoogleExport>> listExports(String kind) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('google_exports')
          .select()
          .eq('owner_id', userId)
          .eq('kind', kind)
          .order('created_at', ascending: false)
          .limit(10);

      return response.map((json) => GoogleExport.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error listing exports: $e');
      return [];
    }
  }

  /// Save export schedule (Pro feature)
  Future<bool> saveExportSchedule(String kind, String cron) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('google_export_schedules').upsert({
        'owner_id': userId,
        'kind': kind,
        'cron': cron,
        'active': true,
      });

      return true;
    } catch (e) {
      debugPrint('Error saving export schedule: $e');
      return false;
    }
  }

  /// Delete export schedule
  Future<bool> deleteExportSchedule(String id) async {
    try {
      await _supabase
          .from('google_export_schedules')
          .delete()
          .eq('id', id);

      return true;
    } catch (e) {
      debugPrint('Error deleting export schedule: $e');
      return false;
    }
  }

  /// List export schedules
  Future<List<GoogleExportSchedule>> listExportSchedules() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('google_export_schedules')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      return response.map((json) => GoogleExportSchedule.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error listing export schedules: $e');
      return [];
    }
  }

  /// Save Forms mapping for coach
  Future<bool> saveFormsMapping(String coachId, String externalId, Map<String, dynamic> mapJson) async {
    try {
      final webhookSecret = _generateWebhookSecret();
      
      await _supabase.from('forms_mappings').upsert({
        'coach_id': coachId,
        'external_id': externalId,
        'map_json': mapJson,
        'webhook_secret': webhookSecret,
      });

      // Log analytics
      _logAnalytics('google_forms_mapping_saved', {
        'coach_id': coachId,
        'external_id': externalId,
      });

      return true;
    } catch (e) {
      debugPrint('Error saving Forms mapping: $e');
      return false;
    }
  }

  /// Verify webhook secret
  bool webhookVerify(String secret) {
    // TODO: Implement proper verification
    return secret.isNotEmpty;
  }

  /// Apply Forms payload (stub)
  Future<bool> applyFormsPayload(Map<String, dynamic> payload) async {
    try {
      // TODO: Implement Forms payload processing
      // This would create/update client data based on form responses
      
      // Log analytics
      _logAnalytics('google_forms_webhook_received', {
        'form_id': payload['form_id'],
        'response_count': payload['responses']?.length ?? 0,
      });

      return true;
    } catch (e) {
      debugPrint('Error applying Forms payload: $e');
      return false;
    }
  }

  /// List Forms mappings for coach
  Future<List<FormsMapping>> listFormsMappings(String coachId) async {
    try {
      final response = await _supabase
          .from('forms_mappings')
          .select()
          .eq('coach_id', coachId)
          .order('created_at', ascending: false);

      return response.map((json) => FormsMapping.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error listing Forms mappings: $e');
      return [];
    }
  }

  /// Open URL in browser
  Future<bool> openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error opening URL: $e');
      return false;
    }
  }

  /// Generate webhook secret
  String _generateWebhookSecret() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(32, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  /// Log analytics events
  void _logAnalytics(String event, Map<String, dynamic> properties) {
    try {
      // TODO: Implement proper analytics logging
      debugPrint('Analytics: $event - ${jsonEncode(properties)}');
    } catch (e) {
      debugPrint('Error logging analytics: $e');
    }
  }
}
