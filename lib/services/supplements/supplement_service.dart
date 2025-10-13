import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../models/supplements/supplement_models.dart';
import '../notifications/notification_helper.dart';
import '../billing/plan_access_manager.dart';
import '../streaks/streak_events.dart';
import '../streaks/streak_service.dart';

/// Service for managing supplements, schedules, and logs
class SupplementService {
  SupplementService._();
  static final SupplementService instance = SupplementService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final PlanAccessManager _planAccessManager = PlanAccessManager.instance;

  // ===== SUPPLEMENTS CRUD =====

  /// Create a new supplement
  Future<Supplement> createSupplement(Supplement supplement) async {
    try {
      final response = await _supabase
          .from('supplements')
          .insert(supplement.toMap())
          .select()
          .single();

      final createdSupplement = Supplement.fromMap(response);
      
      // Debug logging for analytics
      debugPrint('📊 ANALYTICS: Supplement created - User: ${supplement.createdBy}, Supplement: ${createdSupplement.id}, Name: ${createdSupplement.name}');
      
      return createdSupplement;
    } catch (e) {
      throw Exception('Failed to create supplement: $e');
    }
  }

  /// Get supplement by ID
  Future<Supplement?> getSupplement(String id) async {
    try {
      final response = await _supabase
          .from('supplements')
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? Supplement.fromMap(response) : null;
    } catch (e) {
      throw Exception('Failed to get supplement: $e');
    }
  }

  /// Update supplement
  Future<Supplement> updateSupplement(Supplement supplement) async {
    try {
      final response = await _supabase
          .from('supplements')
          .update(supplement.toMap())
          .eq('id', supplement.id)
          .select()
          .single();

      return Supplement.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update supplement: $e');
    }
  }

  /// Delete supplement
  Future<void> deleteSupplement(String id) async {
    try {
      await _supabase
          .from('supplements')
          .delete()
          .eq('id', id);
      
      // Debug logging for analytics
      debugPrint('📊 ANALYTICS: Supplement deleted - ID: $id');
    } catch (e) {
      throw Exception('Failed to delete supplement: $e');
    }
  }

  /// List supplements for a user or client
  /// For coaches viewing client supplements, pass clientId
  Future<List<Supplement>> listSupplements({
    String? userId,
    String? clientId,
    bool? isActive,
  }) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;
      if (user == null) {
        debugPrint('⚠️ SUPPLEMENTS: No user ID provided, returning empty list');
        return [];
      }

      var query = _supabase
          .from('supplements')
          .select();

      // If clientId is specified (coach viewing client), scope to that client
      if (clientId != null) {
        debugPrint('📊 SUPPLEMENTS: Fetching supplements for client: $clientId (requested by: $user)');
        query = query.eq('owner_id', clientId);
      } else {
        // Otherwise, fetch user's own supplements (RLS will handle coach access)
        debugPrint('📊 SUPPLEMENTS: Fetching supplements for user: $user');
        query = query.eq('owner_id', user);
      }

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query.order('name');
      
      if (response.isEmpty) {
        debugPrint('📊 SUPPLEMENTS: No supplements found - User: $user, ClientId: $clientId');
        return [];
      }
      
      final supplements = response.map((map) => Supplement.fromMap(map)).toList();
      
      // Debug logging for analytics
      debugPrint('✅ SUPPLEMENTS: Listed ${supplements.length} supplements - User: $user, ClientId: $clientId, Active filter: $isActive');
      
      return supplements;
    } catch (e, stackTrace) {
      debugPrint('❌ SUPPLEMENTS ERROR: Failed to list supplements - User: $userId, ClientId: $clientId');
      debugPrint('❌ Error details: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      throw Exception('Failed to list supplements: $e');
    }
  }

  // ===== SUPPLEMENT SCHEDULES =====

  /// Create a new schedule
  Future<SupplementSchedule> createSchedule(SupplementSchedule schedule) async {
    try {
      // Check if user can create "every N hours" schedule (Pro feature)
      if (schedule.intervalHours != null) {
        final isPro = await _planAccessManager.isProUser();
        if (!isPro) {
          // Debug logging for analytics
          debugPrint('📊 ANALYTICS: Pro feature blocked - User attempted "every N hours" schedule without Pro access');
          throw Exception('"Every N hours" schedules are only available for Pro users');
        }
        
        // Debug logging for analytics
        debugPrint('📊 ANALYTICS: Pro feature used - User created "every ${schedule.intervalHours} hours" schedule');
      }

      // Check active schedule limit for free users (max 2 active schedules)
      final isPro = await _planAccessManager.isProUser();
      if (!isPro) {
        final activeSchedules = await getActiveSchedulesForUser(schedule.createdBy);
        if (activeSchedules.length >= 2) {
          // Debug logging for analytics
          debugPrint('📊 ANALYTICS: Free user limit blocked - User attempted to create schedule beyond 2 active limit');
          throw Exception('Free users can have a maximum of 2 active supplement schedules. Upgrade to Pro for unlimited schedules.');
        }
      }

      final response = await _supabase
          .from('supplement_schedules')
          .insert(schedule.toMap())
          .select()
          .single();

      final createdSchedule = SupplementSchedule.fromMap(response);
      
      // Debug logging for analytics
      debugPrint('📊 ANALYTICS: Schedule created - User: ${schedule.createdBy}, Supplement: ${schedule.supplementId}, Type: ${schedule.scheduleType}, Frequency: ${schedule.frequency}');
      
      return createdSchedule;
    } catch (e) {
      throw Exception('Failed to create schedule: $e');
    }
  }

  /// Get schedule by ID
  Future<SupplementSchedule?> getSchedule(String id) async {
    try {
      final response = await _supabase
          .from('supplement_schedules')
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? SupplementSchedule.fromMap(response) : null;
    } catch (e) {
      throw Exception('Failed to get schedule: $e');
    }
  }

  /// Update schedule
  Future<SupplementSchedule> updateSchedule(SupplementSchedule schedule) async {
    try {
      // Check if user can update to "every N hours" schedule (Pro feature)
      if (schedule.intervalHours != null) {
        final isPro = await _planAccessManager.isProUser();
        if (!isPro) {
          // Debug logging for analytics
          debugPrint('📊 ANALYTICS: Pro feature blocked - User attempted to update to "every N hours" schedule without Pro access');
          throw Exception('"Every N hours" schedules are only available for Pro users');
        }
        
        // Debug logging for analytics
        debugPrint('📊 ANALYTICS: Pro feature used - User updated to "every ${schedule.intervalHours} hours" schedule');
      }

      final response = await _supabase
          .from('supplement_schedules')
          .update(schedule.toMap())
          .eq('id', schedule.id)
          .select()
          .single();

      return SupplementSchedule.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update schedule: $e');
    }
  }

  /// Delete schedule
  Future<void> deleteSchedule(String id) async {
    try {
      await _supabase
          .from('supplement_schedules')
          .delete()
          .eq('id', id);
      
      // Debug logging for analytics
      debugPrint('📊 ANALYTICS: Schedule deleted - ID: $id');
    } catch (e) {
      throw Exception('Failed to delete schedule: $e');
    }
  }

  /// Get schedules for a supplement
  Future<List<SupplementSchedule>> getSchedulesForSupplement(String supplementId) async {
    try {
      final response = await _supabase
          .from('supplement_schedules')
          .select()
          .eq('supplement_id', supplementId)
          .order('created_at');

      final schedules = response.map((map) => SupplementSchedule.fromMap(map)).toList();
      
      // Debug logging for analytics
      debugPrint('📊 ANALYTICS: Schedules listed - Supplement: $supplementId, Count: ${schedules.length}');
      
      return schedules;
    } catch (e) {
      throw Exception('Failed to get schedules for supplement: $e');
    }
  }

  /// Get active schedules for a user (for free user limit checking)
  Future<List<SupplementSchedule>> getActiveSchedulesForUser(String userId) async {
    try {
      final response = await _supabase
          .from('supplement_schedules')
          .select()
          .eq('created_by', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response.map((map) => SupplementSchedule.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get active schedules for user: $e');
    }
  }

  // ===== SUPPLEMENT LOGS =====

  /// Create a new log entry
  Future<SupplementLog> createLog(SupplementLog log) async {
    try {
      final response = await _supabase
          .from('supplement_logs')
          .insert(log.toMap())
          .select()
          .single();

      final createdLog = SupplementLog.fromMap(response);
      
      // Emit streak events for analytics
      if (log.status == 'taken') {
        StreakEvents.instance.recordSupplementTakenForDay(
          userId: log.userId,
          supplementId: log.supplementId,
          date: log.takenAt,
          notes: log.notes,
        );
        
        // Mark day as compliant for streaks (first taken per local day)
        try {
          await StreakService.instance.markCompliant(
            localDay: log.takenAt,
            source: StreakSource.supplement,
            userId: log.userId,
          );
        } catch (e) {
          // Don't fail supplement logging if streak marking fails
          debugPrint('Failed to mark day compliant for streak: $e');
        }
        
        // Debug logging for analytics
        debugPrint('📊 ANALYTICS: Supplement taken - User: ${log.userId}, Supplement: ${log.supplementId}, Date: ${log.takenAt}');
      } else if (log.status == 'skipped') {
        StreakEvents.instance.recordSupplementSkippedForDay(
          userId: log.userId,
          supplementId: log.supplementId,
          date: log.takenAt,
          reason: log.notes,
        );
        
        // Debug logging for analytics
        debugPrint('📊 ANALYTICS: Supplement skipped - User: ${log.userId}, Supplement: ${log.supplementId}, Date: ${log.takenAt}, Reason: ${log.notes}');
      }

      return createdLog;
    } catch (e) {
      throw Exception('Failed to create log: $e');
    }
  }

  /// Get log by ID
  Future<SupplementLog?> getLog(String id) async {
    try {
      final response = await _supabase
          .from('supplement_logs')
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? SupplementLog.fromMap(response) : null;
    } catch (e) {
      throw Exception('Failed to get log: $e');
    }
  }

  /// Update log
  Future<SupplementLog> updateLog(SupplementLog log) async {
    try {
      final response = await _supabase
          .from('supplement_logs')
          .update(log.toMap())
          .eq('id', log.id)
          .select()
          .single();

      return SupplementLog.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update log: $e');
    }
  }

  /// Delete log
  Future<void> deleteLog(String id) async {
    try {
      await _supabase
          .from('supplement_logs')
          .delete()
          .eq('id', id);
      
      // Debug logging for analytics
      debugPrint('📊 ANALYTICS: Log deleted - ID: $id');
    } catch (e) {
      throw Exception('Failed to delete log: $e');
    }
  }

  /// Get logs for a user
  Future<List<SupplementLog>> getLogsForUser({
    String? userId,
    String? supplementId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;
      if (user == null) return [];

      var query = _supabase
          .from('supplement_logs')
          .select()
          .eq('user_id', user);

      if (supplementId != null) {
        query = query.eq('supplement_id', supplementId);
      }

      if (startDate != null) {
        query = query.gte('taken_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('taken_at', endDate.toIso8601String());
      }

      final response = await query
          .order('taken_at', ascending: false)
          .limit(limit);
      final logs = response.map((map) => SupplementLog.fromMap(map)).toList();
      
      // Debug logging for analytics
      debugPrint('📊 ANALYTICS: Logs listed - User: $user, Count: ${logs.length}, Period: ${startDate != null ? startDate.toIso8601String() : 'all'} to ${endDate != null ? endDate.toIso8601String() : 'now'}');
      
      return logs;
    } catch (e) {
      throw Exception('Failed to get logs for user: $e');
    }
  }

  // ===== OCCURRENCE GENERATION =====

  /// Generate occurrences for a schedule within a date range
  List<DateTime> generateOccurrences({
    required SupplementSchedule schedule,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final occurrences = <DateTime>[];
    final currentDate = startDate;

    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      if (schedule.isActiveForDate(currentDate)) {
        if (schedule.intervalHours != null) {
          // "Every N hours" schedule
          final occurrencesForDay = _generateIntervalOccurrences(
            schedule: schedule,
            date: currentDate,
            startDate: startDate,
          );
          occurrences.addAll(occurrencesForDay);
        } else if (schedule.specificTimes != null) {
          // Daily schedule with specific times
          final occurrencesForDay = _generateDailyOccurrences(
            schedule: schedule,
            date: currentDate,
          );
          occurrences.addAll(occurrencesForDay);
        }
      }

      // Move to next day
      currentDate.add(const Duration(days: 1));
    }
    
    // Debug logging for analytics
          debugPrint('📊 ANALYTICS: Occurrences generated - Schedule: ${schedule.id}, Count: ${occurrences.length}, Period: $startDate to $endDate');
    
    return occurrences;
  }

  /// Generate interval-based occurrences for a specific date
  List<DateTime> _generateIntervalOccurrences({
    required SupplementSchedule schedule,
    required DateTime date,
    required DateTime startDate,
  }) {
    if (schedule.intervalHours == null) return [];

    final occurrences = <DateTime>[];
    final startOfDay = DateTime(date.year, date.month, date.day);
    
    // If this is the start date, use the actual start time
    DateTime currentTime = date.isAtSameMomentAs(startDate) 
        ? startDate 
        : startOfDay;

    while (currentTime.isBefore(startOfDay.add(const Duration(days: 1)))) {
      occurrences.add(currentTime);
      currentTime = currentTime.add(Duration(hours: schedule.intervalHours!));
    }

    return occurrences;
  }

  /// Generate daily occurrences for a specific date
  List<DateTime> _generateDailyOccurrences({
    required SupplementSchedule schedule,
    required DateTime date,
  }) {
    if (schedule.specificTimes == null) return [];

    final occurrences = <DateTime>[];
    final startOfDay = DateTime(date.year, date.month, date.day);

    for (final time in schedule.specificTimes!) {
      final occurrence = startOfDay.add(Duration(
        hours: time.hour,
        minutes: time.minute,
      ));
      occurrences.add(occurrence);
    }

    return occurrences;
  }

  // ===== REMINDER HELPERS =====

  /// Schedule reminder for next supplement due
  Future<String?> scheduleNextReminder({
    required String supplementId,
    required String userId,
    required String supplementName,
    required DateTime nextDue,
  }) async {
    try {
      // Calculate reminder time (15 minutes before due)
      final reminderTime = nextDue.subtract(const Duration(minutes: 15));
      
      // Don't schedule if reminder time is in the past
      if (reminderTime.isBefore(DateTime.now())) {
        return null;
      }

      // Create deterministic reminder ID
      final reminderId = 'supplement:$supplementId:$userId';
      
      // Schedule local notification
      final notificationId = await NotificationHelper.instance.scheduleCalendarReminder(
        eventId: reminderId,
        userId: userId,
        eventTitle: 'Supplement Reminder',
        eventTime: nextDue,
        reminderOffset: const Duration(minutes: 15),
      );
      
      // Debug logging for analytics
      debugPrint('📊 ANALYTICS: Supplement reminder scheduled - User: $userId, Supplement: $supplementId, Next Due: $nextDue, Reminder ID: $notificationId');
      
      return notificationId;
    } catch (e) {
      debugPrint('Failed to schedule supplement reminder: $e');
      return null;
    }
  }

  /// Cancel reminder for a supplement
  Future<void> cancelReminder({
    required String supplementId,
    required String userId,
  }) async {
    try {
      final reminderId = 'supplement:$supplementId:$userId';
      await NotificationHelper.instance.cancelCalendarReminder(reminderId);
      
      // Debug logging for analytics
      debugPrint('📊 ANALYTICS: Supplement reminder cancelled - User: $userId, Supplement: $supplementId, Reminder ID: $reminderId');
    } catch (e) {
      debugPrint('Failed to cancel supplement reminder: $e');
    }
  }

  // ===== BATCHING =====

  /// Mark multiple supplements as taken
  Future<List<SupplementLog>> batchMarkTaken({
    required List<String> supplementIds,
    required String userId,
    DateTime? takenAt,
    String? notes,
  }) async {
    try {
      final logs = <SupplementLog>[];
      final now = takenAt ?? DateTime.now();

      for (final supplementId in supplementIds) {
        final log = SupplementLog.create(
          supplementId: supplementId,
          userId: userId,
          takenAt: now,
          notes: notes,
        );

        final createdLog = await createLog(log);
        logs.add(createdLog);
      }
      
      // Debug logging for analytics
      debugPrint('📊 ANALYTICS: Batch supplements marked taken - User: $userId, Count: ${supplementIds.length}, Supplements: $supplementIds');

      return logs;
    } catch (e) {
      throw Exception('Failed to batch mark supplements as taken: $e');
    }
  }

  /// Get supplements due today for a user or client
  /// For coaches viewing client supplements, pass clientId
  Future<List<SupplementDueToday>> getSupplementsDueToday({
    String? userId,
    String? clientId,
  }) async {
    try {
      // Use clientId if provided (coach viewing client), otherwise use userId
      final targetUser = clientId ?? userId ?? _supabase.auth.currentUser?.id;
      if (targetUser == null) {
        debugPrint('⚠️ SUPPLEMENTS: No user ID provided for getSupplementsDueToday');
        return [];
      }

      debugPrint('📊 SUPPLEMENTS: Fetching supplements due today for: $targetUser');
      
      final response = await _supabase.rpc('get_supplements_due_today', params: {
        'p_user_id': targetUser,
      });

      if (response is List) {
        final supplements = response.map((map) => SupplementDueToday.fromMap(map)).toList();
        
        // Debug logging for analytics
        debugPrint('✅ SUPPLEMENTS: Found ${supplements.length} supplements due today - User: $targetUser');
        
        return supplements;
      }

      debugPrint('📊 SUPPLEMENTS: No supplements due today - User: $targetUser');
      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ SUPPLEMENTS ERROR: Failed to get supplements due today - User: $userId, ClientId: $clientId');
      debugPrint('❌ Error details: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      throw Exception('Failed to get supplements due today: $e');
    }
  }

  // ===== CALENDAR OVERLAY API =====

  /// Get supplement events for calendar overlay
  Future<List<Map<String, dynamic>>> getCalendarEvents({
    required DateTime start,
    required DateTime end,
    String? userId,
  }) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;
      if (user == null) return [];

      // Get supplements with schedules in the date range
      final supplements = await listSupplements(userId: user, isActive: true);
      final events = <Map<String, dynamic>>[];

      for (final supplement in supplements) {
        final schedules = await getSchedulesForSupplement(supplement.id);
        
        for (final schedule in schedules) {
          if (schedule.isActive) {
            final occurrences = generateOccurrences(
              schedule: schedule,
              startDate: start,
              endDate: end,
            );

            for (final occurrence in occurrences) {
              events.add({
                'id': 'supplement_${supplement.id}_${occurrence.millisecondsSinceEpoch}',
                'title': '${supplement.name} (${supplement.dosage})',
                'description': supplement.instructions ?? 'Take supplement',
                'startAt': occurrence,
                'endAt': occurrence.add(const Duration(minutes: 15)),
                'allDay': false,
                'type': 'supplement',
                'supplementId': supplement.id,
                'category': supplement.category,
                'color': supplement.color,
                'icon': supplement.icon,
              });
            }
          }
        }
      }

      // Debug logging for analytics
      debugPrint('📊 ANALYTICS: Calendar events generated - User: $userId, Events Count: ${events.length}, Date Range: $start to $end');
      
      return events;
    } catch (e) {
      throw Exception('Failed to get calendar events: $e');
    }
  }

  // ===== ANALYTICS & REPORTING =====

  /// Get adherence statistics for a user
  Future<Map<String, dynamic>> getAdherenceStats({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;
      if (user == null) return {};

      final end = endDate ?? DateTime.now();
      final start = startDate ?? end.subtract(const Duration(days: 30));

      final logs = await getLogsForUser(
        userId: user,
        startDate: start,
        endDate: end,
        limit: 1000,
      );

      final totalScheduled = 0; // TODO: Calculate from schedules
      final totalTaken = logs.where((log) => log.status == 'taken').length;
      final totalSkipped = logs.where((log) => log.status == 'skipped').length;
      final adherenceRate = totalScheduled > 0 ? (totalTaken / totalScheduled) : 0.0;

      final stats = {
        'totalScheduled': totalScheduled,
        'totalTaken': totalTaken,
        'totalSkipped': totalSkipped,
        'adherenceRate': adherenceRate,
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      };
      
      // Debug logging for analytics
      debugPrint('📊 ANALYTICS: Adherence stats calculated - User: $userId, Taken: $totalTaken, Skipped: $totalSkipped, Rate: ${(adherenceRate * 100).toStringAsFixed(1)}%');
      
      return stats;
    } catch (e) {
      throw Exception('Failed to get adherence stats: $e');
    }
  }

  /// Get streak information for a supplement
  Future<Map<String, dynamic>> getSupplementStreak({
    required String supplementId,
    String? userId,
  }) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;
      if (user == null) return {};

      final logs = await getLogsForUser(
        userId: user,
        supplementId: supplementId,
        limit: 100,
      );

      // Sort by date and calculate streak
      logs.sort((a, b) => b.takenAt.compareTo(a.takenAt));
      
      int currentStreak = 0;
      int longestStreak = 0;
      int tempStreak = 0;
      
      DateTime? lastDate;
      
      for (final log in logs) {
        if (log.status == 'taken') {
          final logDate = DateTime(log.takenAt.year, log.takenAt.month, log.takenAt.day);
          
          if (lastDate == null) {
            // First log
            currentStreak = 1;
            tempStreak = 1;
            lastDate = logDate;
          } else {
            final daysDiff = lastDate.difference(logDate).inDays;
            
            if (daysDiff == 1) {
              // Consecutive day
              tempStreak++;
              if (currentStreak == 0) currentStreak = tempStreak;
            } else if (daysDiff == 0) {
              // Same day, multiple logs
              continue;
            } else {
              // Gap in streak
              if (tempStreak > longestStreak) {
                longestStreak = tempStreak;
              }
              tempStreak = 1;
              if (currentStreak > 0) currentStreak = 0;
            }
            
            lastDate = logDate;
          }
        }
      }
      
      // Check if current streak is the longest
      if (tempStreak > longestStreak) {
        longestStreak = tempStreak;
      }

      final streakInfo = {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastTaken': logs.isNotEmpty ? logs.first.takenAt.toIso8601String() : null,
      };
      
      // Debug logging for analytics
      debugPrint('📊 ANALYTICS: Streak calculated - User: $userId, Supplement: $supplementId, Current: $currentStreak, Longest: $longestStreak');
      
      return streakInfo;
    } catch (e) {
      throw Exception('Failed to get supplement streak: $e');
    }
  }
}
