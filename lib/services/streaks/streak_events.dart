import 'dart:async';

/// Service for emitting streak-related events
/// This allows different parts of the app to contribute to streak calculations
class StreakEvents {
  StreakEvents._();
  static final StreakEvents instance = StreakEvents._();

  // Stream controllers for different streak events
  final StreamController<SupplementTakenEvent> _supplementTakenController = 
      StreamController<SupplementTakenEvent>.broadcast();
  
  final StreamController<SupplementSkippedEvent> _supplementSkippedController = 
      StreamController<SupplementSkippedEvent>.broadcast();
  
  final StreamController<SupplementStreakBrokenEvent> _supplementStreakBrokenController = 
      StreamController<SupplementStreakBrokenEvent>.broadcast();

  // Streams for listening to events
  Stream<SupplementTakenEvent> get onSupplementTaken => _supplementTakenController.stream;
  Stream<SupplementSkippedEvent> get onSupplementSkipped => _supplementSkippedController.stream;
  Stream<SupplementStreakBrokenEvent> get onSupplementStreakBroken => _supplementStreakBrokenController.stream;

  /// Emit event when supplement is taken
  void recordSupplementTakenForDay({
    required String userId,
    required String supplementId,
    required DateTime date,
    String? notes,
  }) {
    final event = SupplementTakenEvent(
      userId: userId,
      supplementId: supplementId,
      date: date,
      notes: notes,
    );
    
    _supplementTakenController.add(event);
  }

  /// Emit event when supplement is skipped
  void recordSupplementSkippedForDay({
    required String userId,
    required String supplementId,
    required DateTime date,
    String? reason,
  }) {
    final event = SupplementSkippedEvent(
      userId: userId,
      supplementId: supplementId,
      date: date,
      reason: reason,
    );
    
    _supplementSkippedController.add(event);
  }

  /// Emit event when supplement streak is broken
  void recordSupplementStreakBroken({
    required String userId,
    required String supplementId,
    required DateTime date,
    required int previousStreak,
    String? reason,
  }) {
    final event = SupplementStreakBrokenEvent(
      userId: userId,
      supplementId: supplementId,
      date: date,
      previousStreak: previousStreak,
      reason: reason,
    );
    
    _supplementStreakBrokenController.add(event);
  }

  /// Dispose of all stream controllers
  void dispose() {
    _supplementTakenController.close();
    _supplementSkippedController.close();
    _supplementStreakBrokenController.close();
  }
}

/// Event emitted when a supplement is taken
class SupplementTakenEvent {
  final String userId;
  final String supplementId;
  final DateTime date;
  final String? notes;

  const SupplementTakenEvent({
    required this.userId,
    required this.supplementId,
    required this.date,
    this.notes,
  });

  @override
  String toString() {
    return 'SupplementTakenEvent(userId: $userId, supplementId: $supplementId, date: $date)';
  }
}

/// Event emitted when a supplement is skipped
class SupplementSkippedEvent {
  final String userId;
  final String supplementId;
  final DateTime date;
  final String? reason;

  const SupplementSkippedEvent({
    required this.userId,
    required this.supplementId,
    required this.date,
    this.reason,
  });

  @override
  String toString() {
    return 'SupplementSkippedEvent(userId: $userId, supplementId: $supplementId, date: $date)';
  }
}

/// Event emitted when a supplement streak is broken
class SupplementStreakBrokenEvent {
  final String userId;
  final String supplementId;
  final DateTime date;
  final int previousStreak;
  final String? reason;

  const SupplementStreakBrokenEvent({
    required this.userId,
    required this.supplementId,
    required this.date,
    required this.previousStreak,
    this.reason,
  });

  @override
  String toString() {
    return 'SupplementStreakBrokenEvent(userId: $userId, supplementId: $supplementId, date: $date, previousStreak: $previousStreak)';
  }
}
