import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/workout/workout_service.dart';
import 'exercise_completion_widget.dart';

/// Manages offline data storage and synchronization
class OfflineSyncManager extends ChangeNotifier {
  static const String _completionQueueKey = 'workout_completion_queue';
  static const String _lastSyncKey = 'workout_last_sync';
  static const Duration _syncInterval = Duration(minutes: 5);

  final WorkoutService _workoutService = WorkoutService();

  Timer? _syncTimer;
  bool _isOnline = true;
  bool _isSyncing = false;
  List<PendingSyncItem> _pendingItems = [];
  DateTime? _lastSyncTime;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingItems.length;
  DateTime? get lastSyncTime => _lastSyncTime;

  OfflineSyncManager() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadPendingItems();
    await _loadLastSyncTime();
    _startSyncTimer();
  }

  /// Start periodic sync timer
  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      syncPendingData();
    });
  }

  /// Stop sync timer
  void stopSyncTimer() {
    _syncTimer?.cancel();
  }

  /// Queue exercise completion for syncing
  Future<void> queueExerciseCompletion({
    required String clientId,
    required ExerciseCompletionData data,
  }) async {
    final item = PendingSyncItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: SyncItemType.exerciseCompletion,
      clientId: clientId,
      data: data.toMap(),
      createdAt: DateTime.now(),
    );

    _pendingItems.add(item);
    await _savePendingItems();
    notifyListeners();

    // Try immediate sync if online
    if (_isOnline) {
      await syncPendingData();
    }
  }

  /// Queue day comment for syncing
  Future<void> queueDayComment({
    required String dayId,
    required String comment,
    required String clientId,
  }) async {
    final item = PendingSyncItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: SyncItemType.dayComment,
      clientId: clientId,
      data: {
        'day_id': dayId,
        'comment': comment,
      },
      createdAt: DateTime.now(),
    );

    _pendingItems.add(item);
    await _savePendingItems();
    notifyListeners();

    // Try immediate sync if online
    if (_isOnline) {
      await syncPendingData();
    }
  }

  /// Sync all pending data to server
  Future<bool> syncPendingData() async {
    if (_isSyncing || _pendingItems.isEmpty) return false;

    _isSyncing = true;
    notifyListeners();

    try {
      final successfulItems = <String>[];

      for (final item in _pendingItems) {
        try {
          await _syncItem(item);
          successfulItems.add(item.id);
        } catch (e) {
          // Item failed to sync, will retry next time
          debugPrint('Failed to sync item ${item.id}: $e');
        }
      }

      // Remove successfully synced items
      if (successfulItems.isNotEmpty) {
        _pendingItems.removeWhere((item) => successfulItems.contains(item.id));
        await _savePendingItems();
      }

      // Update sync status
      _isOnline = true;
      _lastSyncTime = DateTime.now();
      await _saveLastSyncTime();

      _isSyncing = false;
      notifyListeners();

      return successfulItems.length == _pendingItems.length;
    } catch (e) {
      _isOnline = false;
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Sync individual item
  Future<void> _syncItem(PendingSyncItem item) async {
    switch (item.type) {
      case SyncItemType.exerciseCompletion:
        await _syncExerciseCompletion(item);
        break;
      case SyncItemType.dayComment:
        await _syncDayComment(item);
        break;
    }
  }

  /// Sync exercise completion to server
  Future<void> _syncExerciseCompletion(PendingSyncItem item) async {
    await _workoutService.recordExerciseCompletion(
      clientId: item.clientId,
      exerciseId: item.data['exercise_id'] as String,
      completedSets: item.data['completed_sets'] as int,
      completedReps: item.data['completed_reps'] as String,
      weightUsed: (item.data['weight_used'] as num).toDouble(),
      rirActual: item.data['rir_actual'] as int?,
      formRating: item.data['form_rating'] as int?,
      difficultyRating: item.data['difficulty_rating'] as int?,
      notes: item.data['notes'] as String?,
    );
  }

  /// Sync day comment to server
  Future<void> _syncDayComment(PendingSyncItem item) async {
    await _workoutService.updateDayComment(
      item.data['plan_id'] as String,
      item.data['week_number'] as int,
      item.data['day_number'] as int,
      item.data['comment'] as String,
    );
  }

  /// Load pending items from storage
  Future<void> _loadPendingItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_completionQueueKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _pendingItems = jsonList
            .map((json) => PendingSyncItem.fromMap(json))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to load pending items: $e');
      _pendingItems = [];
    }
  }

  /// Save pending items to storage
  Future<void> _savePendingItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _pendingItems.map((item) => item.toMap()).toList();
      await prefs.setString(_completionQueueKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Failed to save pending items: $e');
    }
  }

  /// Load last sync time from storage
  Future<void> _loadLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSyncKey);
      if (timestamp != null) {
        _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      debugPrint('Failed to load last sync time: $e');
    }
  }

  /// Save last sync time to storage
  Future<void> _saveLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncKey, _lastSyncTime!.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Failed to save last sync time: $e');
    }
  }

  /// Clear all pending items (for testing/debugging)
  Future<void> clearPendingItems() async {
    _pendingItems.clear();
    await _savePendingItems();
    notifyListeners();
  }

  /// Force offline mode (for testing)
  void setOfflineMode(bool offline) {
    _isOnline = !offline;
    notifyListeners();
  }

  /// Get sync status summary
  SyncStatus getSyncStatus() {
    return SyncStatus(
      isOnline: _isOnline,
      isSyncing: _isSyncing,
      pendingCount: _pendingItems.length,
      lastSyncTime: _lastSyncTime,
      oldestPendingItem: _pendingItems.isNotEmpty
          ? _pendingItems
              .map((item) => item.createdAt)
              .reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
    );
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

/// Pending sync item
class PendingSyncItem {
  final String id;
  final SyncItemType type;
  final String clientId;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  PendingSyncItem({
    required this.id,
    required this.type,
    required this.clientId,
    required this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'client_id': clientId,
      'data': data,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PendingSyncItem.fromMap(Map<String, dynamic> map) {
    return PendingSyncItem(
      id: map['id'] as String,
      type: SyncItemType.values.firstWhere(
        (e) => e.toString() == map['type'],
      ),
      clientId: map['client_id'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Sync item type
enum SyncItemType {
  exerciseCompletion,
  dayComment,
}

/// Sync status summary
class SyncStatus {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final DateTime? oldestPendingItem;

  SyncStatus({
    required this.isOnline,
    required this.isSyncing,
    required this.pendingCount,
    this.lastSyncTime,
    this.oldestPendingItem,
  });

  String get statusMessage {
    if (isSyncing) {
      return 'Syncing...';
    } else if (!isOnline) {
      return 'Offline - $pendingCount items pending';
    } else if (pendingCount > 0) {
      return 'Online - $pendingCount items pending';
    } else {
      return 'All data synced';
    }
  }

  String get lastSyncDisplay {
    if (lastSyncTime == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastSyncTime!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Sync status widget for displaying sync state
class SyncStatusWidget extends StatelessWidget {
  final OfflineSyncManager syncManager;
  final VoidCallback? onTap;

  const SyncStatusWidget({
    Key? key,
    required this.syncManager,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: syncManager,
      builder: (context, child) {
        final status = syncManager.getSyncStatus();

        return InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(status),
                  size: 16,
                  color: _getStatusColor(status),
                ),
                const SizedBox(width: 8),
                Text(
                  status.statusMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(SyncStatus status) {
    if (status.isSyncing) {
      return Icons.sync;
    } else if (!status.isOnline) {
      return Icons.cloud_off;
    } else if (status.pendingCount > 0) {
      return Icons.cloud_upload;
    } else {
      return Icons.cloud_done;
    }
  }

  Color _getStatusColor(SyncStatus status) {
    if (status.isSyncing) {
      return Colors.blue;
    } else if (!status.isOnline) {
      return Colors.orange;
    } else if (status.pendingCount > 0) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }
}