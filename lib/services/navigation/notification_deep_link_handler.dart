import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/notifications/workout_notification_types.dart';

/// Deep link handler for workout notifications
///
/// Handles navigation when user taps on notifications
class NotificationDeepLinkHandler {
  static final NotificationDeepLinkHandler instance =
      NotificationDeepLinkHandler._();

  NotificationDeepLinkHandler._();

  // Global navigator key - should be set in main.dart
  GlobalKey<NavigatorState>? navigatorKey;

  /// Handle notification click with deep linking
  Future<void> handleNotificationClick(
    WorkoutNotificationType type,
    Map<String, dynamic> data,
  ) async {
    final context = navigatorKey?.currentContext;
    if (context == null) {
      debugPrint('⚠️ Navigator context not available');
      return;
    }

    debugPrint('🔗 Handling deep link: $type');

    switch (type) {
      case WorkoutNotificationType.planAssigned:
        await _handlePlanAssigned(context, data);
        break;

      case WorkoutNotificationType.workoutReminder:
        await _handleWorkoutReminder(context, data);
        break;

      case WorkoutNotificationType.restDayReminder:
        await _handleRestDayReminder(context, data);
        break;

      case WorkoutNotificationType.deloadWeekAlert:
        await _handleDeloadWeekAlert(context, data);
        break;

      case WorkoutNotificationType.prCelebration:
        await _handlePRCelebration(context, data);
        break;

      case WorkoutNotificationType.coachFeedback:
        await _handleCoachFeedback(context, data);
        break;

      case WorkoutNotificationType.missedWorkout:
        await _handleMissedWorkout(context, data);
        break;

      case WorkoutNotificationType.weeklySummary:
        await _handleWeeklySummary(context, data);
        break;

      default:
        debugPrint('⚠️ Unknown notification type: $type');
    }
  }

  /// Handle plan assigned notification
  Future<void> _handlePlanAssigned(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final payload = PlanAssignedNotification.fromJson(data['payload']);

    // Navigate to workout plan details screen
    if (!context.mounted) return;
    unawaited(Navigator.of(context).pushNamed(
      '/workout/plan',
      arguments: {
        'plan_id': payload.planId,
        'show_welcome': true,
      },
    ));
  }

  /// Handle workout reminder notification
  Future<void> _handleWorkoutReminder(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final payload = WorkoutReminderNotification.fromJson(data['payload']);

    // Check for quick action
    final actionId = data['action_id'] as String?;

    if (actionId == 'start') {
      // Start workout immediately
      if (!context.mounted) return;
      unawaited(Navigator.of(context).pushNamed(
        '/workout/session/start',
        arguments: {
          'day_id': payload.dayId,
          'day_label': payload.dayLabel,
        },
      ));
    } else if (actionId == 'snooze') {
      // Snooze reminder
      await _snoozeReminder(payload.dayId, 15);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder snoozed for 15 minutes'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Navigate to workout day details
      if (!context.mounted) return;
      unawaited(Navigator.of(context).pushNamed(
        '/workout/day',
        arguments: {'day_id': payload.dayId},
      ));
    }
  }

  /// Handle rest day reminder
  Future<void> _handleRestDayReminder(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final payload = RestDayNotification.fromJson(data['payload']);

    // Navigate to recovery screen or show dialog
    if (!context.mounted) return;
    unawaited(showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.bedtime, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Rest Day'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(payload.motivationalMessage),
            if (payload.isActiveRecovery && payload.recoveryActivities != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Suggested Recovery Activities:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...payload.recoveryActivities!.map((activity) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Text('• $activity'),
                  )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    ));
  }

  /// Handle deload week alert
  Future<void> _handleDeloadWeekAlert(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final payload = DeloadWeekNotification.fromJson(data['payload']);

    // Navigate to week overview with deload info
    if (!context.mounted) return;
    unawaited(Navigator.of(context).pushNamed(
      '/workout/week',
      arguments: {
        'week_number': payload.weekNumber,
        'is_deload': true,
        'reason': payload.reason,
        'recommendations': payload.recommendations,
      },
    ));
  }

  /// Handle PR celebration
  Future<void> _handlePRCelebration(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final payload = PRCelebrationNotification.fromJson(data['payload']);

    // Show celebration dialog
    if (!context.mounted) return;
    unawaited(showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber[700], size: 32),
            const SizedBox(width: 8),
            const Text('New PR!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              payload.exerciseName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(payload.body),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('Previous', style: TextStyle(fontSize: 12)),
                    Text(
                      '${payload.previousValue.toStringAsFixed(1)}kg',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward, color: Colors.green),
                Column(
                  children: [
                    const Text('New', style: TextStyle(fontSize: 12)),
                    Text(
                      '${payload.newValue.toStringAsFixed(1)}kg',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/analytics/prs');
            },
            child: const Text('View All PRs'),
          ),
        ],
      ),
    ));
  }

  /// Handle coach feedback
  Future<void> _handleCoachFeedback(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final payload = CoachFeedbackNotification.fromJson(data['payload']);

    final actionId = data['action_id'] as String?;

    if (actionId == 'reply') {
      // Open reply dialog
      if (!context.mounted) return;
      _showReplyDialog(context, payload);
    } else {
      // Navigate to exercise details with comment highlighted
      if (!context.mounted) return;
      unawaited(Navigator.of(context).pushNamed(
        '/workout/exercise',
        arguments: {
          'exercise_id': payload.exerciseId,
          'highlight_comment': true,
        },
      ));
    }
  }

  /// Handle missed workout notification
  Future<void> _handleMissedWorkout(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final payload = MissedWorkoutNotification.fromJson(data['payload']);

    final actionId = data['action_id'] as String?;

    if (actionId == 'reschedule') {
      // Show reschedule dialog
      if (!context.mounted) return;
      _showRescheduleDialog(context, payload);
    } else if (actionId == 'start_now') {
      // Start workout now
      if (!context.mounted) return;
      unawaited(Navigator.of(context).pushNamed(
        '/workout/session/start',
        arguments: {'day_id': payload.dayId},
      ));
    } else {
      // Navigate to missed workouts overview
      if (!context.mounted) return;
      unawaited(Navigator.of(context).pushNamed('/workout/missed'));
    }
  }

  /// Handle weekly summary
  Future<void> _handleWeeklySummary(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final payload = WeeklySummaryNotification.fromJson(data['payload']);

    // Navigate to analytics screen with week details
    if (!context.mounted) return;
    unawaited(Navigator.of(context).pushNamed(
      '/analytics',
      arguments: {
        'week_number': payload.weekNumber,
        'week_start': payload.weekStart,
        'week_end': payload.weekEnd,
      },
    ));
  }

  // Helper methods

  /// Snooze reminder for X minutes
  Future<void> _snoozeReminder(String dayId, int minutes) async {
    // TODO: Implement snooze logic via backend
    debugPrint('Snoozed reminder for day $dayId for $minutes minutes');
  }

  /// Show reply dialog for coach feedback
  void _showReplyDialog(
    BuildContext context,
    CoachFeedbackNotification payload,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to ${payload.coachName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(payload.comment),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Your reply...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Send reply to coach
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reply sent!')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  /// Show reschedule dialog
  void _showRescheduleDialog(
    BuildContext context,
    MissedWorkoutNotification payload,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Workout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('When would you like to do ${payload.dayLabel}?'),
            const SizedBox(height: 16),
            // TODO: Add date/time picker
            const Text('Date/Time picker coming soon'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Workout rescheduled!')),
              );
            },
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );
  }
}
