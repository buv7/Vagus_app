import 'dart:collection';

/// Lightweight in-memory store shared across the SHIELD subsystem.
/// Tracks error history, last sync time, and pending sync queue length so the
/// diagnostics screen can surface them without touching the database.
class ShieldStore {
  ShieldStore._();
  static final ShieldStore instance = ShieldStore._();

  DateTime? lastSyncTime;
  int pendingSyncItems = 0;

  final _errorLog = Queue<ShieldError>();
  static const _maxErrors = 20;

  ShieldError? get lastError =>
      _errorLog.isNotEmpty ? _errorLog.last : null;

  List<ShieldError> get recentErrors => List.unmodifiable(_errorLog);

  void recordError(Object error, StackTrace stack, {String? context}) {
    if (_errorLog.length >= _maxErrors) _errorLog.removeFirst();
    _errorLog.addLast(ShieldError(
      message: error.toString(),
      stack: stack.toString(),
      context: context,
      timestamp: DateTime.now(),
    ));
  }

  void recordSync({required int pendingItems}) {
    lastSyncTime = DateTime.now();
    pendingSyncItems = pendingItems;
  }
}

class ShieldError {
  final String message;
  final String stack;
  final String? context;
  final DateTime timestamp;

  const ShieldError({
    required this.message,
    required this.stack,
    this.context,
    required this.timestamp,
  });
}
