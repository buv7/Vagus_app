import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/logger.dart';

class AccountLifecycleStatus {
  final String lifecycleId;
  final String action; // 'deactivate' or 'delete'
  final DateTime requestedAt;
  final DateTime scheduledPurgeAt;
  final int daysRemaining;

  const AccountLifecycleStatus({
    required this.lifecycleId,
    required this.action,
    required this.requestedAt,
    required this.scheduledPurgeAt,
    required this.daysRemaining,
  });

  bool get isDeactivation => action == 'deactivate';
  bool get isDeletion => action == 'delete';
}

class AccountLifecycleService {
  final _supabase = Supabase.instance.client;

  /// Returns the current pending lifecycle action for the signed-in user,
  /// or null if no action is pending.
  Future<AccountLifecycleStatus?> getStatus() async {
    try {
      final rows = await _supabase.rpc('get_account_lifecycle_status');
      final list = rows as List<dynamic>;
      if (list.isEmpty) return null;

      final row = list.first as Map<String, dynamic>;
      return AccountLifecycleStatus(
        lifecycleId:       row['lifecycle_id'] as String,
        action:            row['action'] as String,
        requestedAt:       DateTime.parse(row['requested_at'] as String),
        scheduledPurgeAt:  DateTime.parse(row['scheduled_purge_at'] as String),
        daysRemaining:     (row['days_remaining'] as num).toInt(),
      );
    } catch (e, st) {
      Logger.error('AccountLifecycleService.getStatus failed', error: e, stackTrace: st);
      return null;
    }
  }

  /// Verifies [password] against Supabase Auth. Throws on failure.
  Future<void> verifyPassword(String password) async {
    final email = _supabase.auth.currentUser?.email;
    if (email == null) throw Exception('No email on current user');
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  /// Initiates a 30-day deactivation grace period. Throws on failure.
  Future<void> requestDeactivation({String? reason}) async {
    final lifecycleId = await _supabase.rpc(
      'request_account_deactivation',
      params: {'p_reason': reason},
    );

    Logger.warning('Account deactivation requested', data: {
      'userId':      _supabase.auth.currentUser?.id,
      'lifecycleId': lifecycleId,
    });

    await _sendOnRequestPush(
      title:   'Account deactivation scheduled',
      message: 'Your account will be deactivated in 30 days. Sign in any time before then to cancel.',
    );
  }

  /// Initiates a 7-day deletion grace period. Throws on failure.
  Future<void> requestDeletion({String? reason}) async {
    final lifecycleId = await _supabase.rpc(
      'request_account_deletion',
      params: {'p_reason': reason},
    );

    Logger.warning('Account deletion requested', data: {
      'userId':      _supabase.auth.currentUser?.id,
      'lifecycleId': lifecycleId,
    });

    await _sendOnRequestPush(
      title:   'Account deletion scheduled',
      message: 'Your account will be permanently deleted in 7 days. Sign in any time before then to cancel.',
    );
  }

  /// Cancels any pending deactivation or deletion. Returns true if a pending
  /// action existed and was cancelled.
  Future<bool> restore() async {
    final result = await _supabase.rpc('restore_account');
    final cancelled = result as bool? ?? false;

    if (cancelled) {
      Logger.info('Account lifecycle restored', data: {
        'userId': _supabase.auth.currentUser?.id,
      });
    }
    return cancelled;
  }

  Future<void> _sendOnRequestPush({
    required String title,
    required String message,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.functions.invoke('send-notification', body: {
        'type':    'user',
        'userId':  userId,
        'title':   title,
        'message': message,
        'additionalData': {'screen': 'AccountSettings'},
      });
    } catch (e) {
      // Non-critical: push failure must not block the lifecycle action.
      Logger.error('AccountLifecycleService: push notification failed', error: e);
    }
  }
}
