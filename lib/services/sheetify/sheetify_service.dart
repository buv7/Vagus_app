import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vagus_app/models/sheetify/sheet_sync_models.dart';

/// Bidirectional Google Sheets sync service.
///
/// Usage:
///   final service = SheetifyService.instance;
///   await service.connectGoogle(coachId);           // open OAuth flow
///   await service.onClientAdded(coachId, clientId, clientName);
///   await service.pushCheckin(coachId, clientId, {...});
///   service.startPolling(coachId);
///   service.stopPolling();
///   await service.disconnectGoogle(coachId);
class SheetifyService {
  SheetifyService._();
  static final SheetifyService instance = SheetifyService._();

  static final _sb = Supabase.instance.client;

  // 60-second poll interval (Google quota constraint — do not lower)
  static const _pollInterval = Duration(seconds: 60);

  Timer? _pollTimer;
  String? _pollingCoachId;

  final _stateController = StreamController<SheetSyncState>.broadcast();

  Stream<SheetSyncState> get syncStateStream => _stateController.stream;

  SheetSyncState _state = SheetSyncState.idle;
  SheetSyncState get currentState => _state;

  void _emit(SheetSyncState s) {
    _state = s;
    _stateController.add(s);
  }

  // ============================================================================
  // OAuth connect / disconnect
  // ============================================================================

  /// Launches the Google OAuth consent screen in the device browser.
  /// The OAuth callback redirects to `vagus://sheetify/connected`.
  /// Call [handleOAuthCallback] from your deep-link handler when that URI fires.
  Future<void> connectGoogle(String coachId) async {
    try {
      final result = await _sb.functions.invoke(
        'sheetify-oauth',
        body: {'action': 'get_auth_url', 'coach_id': coachId},
      );
      final url = (result.data as Map<String, dynamic>?)?['url'] as String?;
      if (url == null) throw Exception('No auth URL returned');

      final uri = Uri.parse(url);
      if (!await canLaunchUrl(uri)) throw Exception('Cannot launch OAuth URL');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _emit(_state.copyWith(status: SyncStatus.error, errorMessage: e.toString()));
      rethrow;
    }
  }

  /// Call this from your app's deep-link handler when you receive
  /// `vagus://sheetify/connected?status=ok` (or `status=error`).
  Future<void> handleOAuthCallback(Uri callbackUri) async {
    final status = callbackUri.queryParameters['status'];
    if (status == 'ok') {
      _emit(_state.copyWith(status: SyncStatus.idle, errorMessage: null));
    } else {
      final reason = callbackUri.queryParameters['reason'] ?? 'unknown error';
      _emit(_state.copyWith(status: SyncStatus.error, errorMessage: reason));
    }
  }

  /// Revoke Google access. Leaves sheets in the coach's Drive (per spec).
  Future<void> disconnectGoogle(String coachId) async {
    try {
      await _sb.functions.invoke('sheetify-sync', body: {'action': 'revoke'});
      stopPolling();
      _emit(SheetSyncState.idle);
    } catch (e) {
      debugPrint('SheetifyService: disconnect error — $e');
      rethrow;
    }
  }

  // ============================================================================
  // Sheet creation
  // ============================================================================

  /// Called when a new client is added. Creates the 3-tab Google Sheet for that
  /// client and stores the sheet_id in client_sheets.
  Future<ClientSheet?> onClientAdded({
    required String clientId,
    required String clientName,
  }) async {
    try {
      final result = await _sb.functions.invoke(
        'sheetify-sync',
        body: {
          'action': 'create_sheet',
          'client_id': clientId,
          'client_name': clientName,
        },
      );
      final data = result.data as Map<String, dynamic>?;
      if (data == null) return null;

      // Re-fetch from DB to get the full row
      final row = await _sb
          .from('client_sheets')
          .select()
          .eq('client_id', clientId)
          .maybeSingle();

      if (row == null) return null;
      return ClientSheet.fromJson(row);
    } catch (e) {
      debugPrint('SheetifyService: create_sheet error — $e');
      return null;
    }
  }

  // ============================================================================
  // App → Sheet sync  (push)
  // ============================================================================

  /// Push a check-in row to the sheet.
  ///
  /// [row] must include `_row_id` (the Supabase row UUID) and the fields:
  ///   date, weight_kg, body_fat_percent, mood, notes, photo_urls
  Future<void> pushCheckin({
    required String clientId,
    required Map<String, dynamic> row,
  }) => _pushRows(clientId: clientId, tab: SyncTab.checkIns, rows: [row]);

  /// Push a workout row.
  ///
  /// [row] must include `_row_id` and:
  ///   date, exercise, sets, reps, weight_kg, rpe, notes
  Future<void> pushWorkout({
    required String clientId,
    required Map<String, dynamic> row,
  }) => _pushRows(clientId: clientId, tab: SyncTab.workout, rows: [row]);

  /// Push a nutrition/food-log row.
  ///
  /// [row] must include `_row_id` and:
  ///   date, meal, food, calories, protein_g, carbs_g, fat_g
  Future<void> pushNutrition({
    required String clientId,
    required Map<String, dynamic> row,
  }) => _pushRows(clientId: clientId, tab: SyncTab.nutrition, rows: [row]);

  /// Push multiple rows for a given tab. Queues them for the edge function to drain.
  Future<void> _pushRows({
    required String clientId,
    required SyncTab tab,
    required List<Map<String, dynamic>> rows,
  }) async {
    // Get the sheet_id for this client (owned by the currently-authenticated coach)
    final sheetRow = await _sb
        .from('client_sheets')
        .select('sheet_id, coach_id')
        .eq('client_id', clientId)
        .maybeSingle();

    if (sheetRow == null) return; // no sheet → silently skip

    // Enqueue in sheets_sync_queue for fault-tolerant delivery
    await _sb.from('sheets_sync_queue').insert({
      'coach_id': sheetRow['coach_id'],
      'client_id': clientId,
      'sheet_id': sheetRow['sheet_id'],
      'tab': tab.dbName,
      'payload': rows,
      'status': 'queued',
    });

    // Flush immediately (best-effort)
    _flushQueueSilently();
  }

  void _flushQueueSilently() {
    _sb.functions
        .invoke('sheetify-sync', body: {'action': 'flush_queue'})
        .catchError((e) => debugPrint('SheetifyService: flush error — $e'));
  }

  // ============================================================================
  // Sheet → App sync  (poll)
  // ============================================================================

  /// Start polling for sheet edits at the 60-second minimum interval.
  /// [coachId] is the currently-authenticated coach.
  ///
  /// Typically called when the coach enters a screen that shows sync status,
  /// and stopped when they leave.
  void startPolling(String coachId) {
    if (_pollTimer != null && _pollingCoachId == coachId) return;
    stopPolling();
    _pollingCoachId = coachId;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _doPoll(coachId));
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollingCoachId = null;
  }

  Future<void> _doPoll(String coachId) async {
    _emit(_state.copyWith(status: SyncStatus.syncing));
    try {
      // Get all client sheets for this coach
      final sheets = await _sb
          .from('client_sheets')
          .select('client_id')
          .order('last_synced_at', ascending: true)
          .limit(20);

      int totalConflicts = 0;
      for (final sheet in sheets as List<dynamic>) {
        final clientId = sheet['client_id'] as String;
        try {
          final result = await _sb.functions.invoke(
            'sheetify-sync',
            body: {'action': 'poll_changes', 'client_id': clientId},
          );
          final data = result.data as Map<String, dynamic>?;
          if (data?['changed'] == true) {
            final conflicts = data?['conflicts'] as List<dynamic>? ?? [];
            totalConflicts += conflicts.length;
          }
        } catch (e) {
          debugPrint('SheetifyService: poll error for $clientId — $e');
        }
      }

      final conflictCount = await _fetchUnresolvedConflictCount(coachId);
      _emit(_state.copyWith(
        status: conflictCount > 0 ? SyncStatus.conflicted : SyncStatus.idle,
        pendingConflicts: conflictCount,
        lastSyncedAt: DateTime.now(),
        errorMessage: null,
      ));
    } catch (e) {
      _emit(_state.copyWith(status: SyncStatus.error, errorMessage: e.toString()));
    }
  }

  Future<int> _fetchUnresolvedConflictCount(String coachId) async {
    final result = await _sb
        .from('sheets_sync_conflicts')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('coach_id', coachId)
        .isFilter('resolved_at', null);
    return result.count ?? 0;
  }

  // ============================================================================
  // Conflict management
  // ============================================================================

  /// Fetch all unresolved conflicts for the coach.
  Future<List<SyncConflict>> getConflicts(String coachId) async {
    final rows = await _sb
        .from('sheets_sync_conflicts')
        .select()
        .eq('coach_id', coachId)
        .isFilter('resolved_at', null)
        .order('detected_at', ascending: false);
    return (rows as List<dynamic>)
        .map((r) => SyncConflict.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Resolve a conflict by keeping the app value (dismisses the sheet edit).
  Future<void> keepAppValue(String conflictId) =>
      _resolveConflict(conflictId, 'keep_app');

  /// Resolve a conflict by importing the sheet value into the app.
  /// NOTE: the app is source of truth — use this only when coach explicitly
  /// approves the sheet edit.
  Future<void> keepSheetValue(String conflictId) =>
      _resolveConflict(conflictId, 'keep_sheet');

  Future<void> _resolveConflict(String conflictId, String resolution) async {
    await _sb.functions.invoke(
      'sheetify-sync',
      body: {
        'action': 'resolve_conflict',
        'conflict_id': conflictId,
        'resolution': resolution,
      },
    );
    // Refresh pending count
    if (_pollingCoachId != null) {
      final count = await _fetchUnresolvedConflictCount(_pollingCoachId!);
      _emit(_state.copyWith(
        status: count > 0 ? SyncStatus.conflicted : SyncStatus.idle,
        pendingConflicts: count,
      ));
    }
  }

  // ============================================================================
  // Status
  // ============================================================================

  /// Returns the coach's connection status and their client sheets list.
  Future<Map<String, dynamic>> getConnectionStatus() async {
    final result = await _sb.functions.invoke(
      'sheetify-sync',
      body: {'action': 'status'},
    );
    return (result.data as Map<String, dynamic>?) ?? {};
  }

  /// Returns the ClientSheet record for a given client, or null if none.
  Future<ClientSheet?> getClientSheet(String clientId) async {
    final row = await _sb
        .from('client_sheets')
        .select()
        .eq('client_id', clientId)
        .maybeSingle();
    if (row == null) return null;
    return ClientSheet.fromJson(row as Map<String, dynamic>);
  }

  void dispose() {
    stopPolling();
    _stateController.close();
  }
}
