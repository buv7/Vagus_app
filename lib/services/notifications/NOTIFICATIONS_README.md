# Workout Notifications System

Comprehensive push notification system for workout reminders, achievements, coach feedback, and progress tracking using OneSignal.

## Table of Contents

1. [Overview](#overview)
2. [Notification Types](#notification-types)
3. [Architecture](#architecture)
4. [Setup & Configuration](#setup--configuration)
5. [Usage Examples](#usage-examples)
6. [Deep Linking](#deep-linking)
7. [Notification Preferences](#notification-preferences)
8. [Edge Functions](#edge-functions)
9. [Testing](#testing)
10. [Troubleshooting](#troubleshooting)

---

## Overview

The Workout Notifications System provides:

- **8 Notification Types**: Plan assigned, workout reminders, rest days, deload weeks, PRs, coach feedback, missed workouts, weekly summaries
- **Smart Scheduling**: Timezone-aware scheduling with user preferences
- **Deep Linking**: Navigate directly to relevant screens from notifications
- **Snooze & Quick Actions**: Interactive notification buttons
- **Preferences Management**: Granular control over notification settings
- **OneSignal Integration**: Reliable push notification delivery

---

## Notification Types

### 1. Plan Assigned Notification
**Trigger**: Coach assigns new workout plan
**Content**: Coach name, plan name, total weeks, start date
**Actions**: [View Plan]
**Deep Link**: `/workout/plan/{plan_id}`

**Example:**
```dart
await oneSignalService.sendPlanAssignedNotification(
  clientId,
  'Hypertrophy 8-Week',
  'John Coach',
  planId: planId,
  totalWeeks: 8,
  startDate: DateTime.now(),
);
```

### 2. Workout Reminder Notification
**Trigger**: Scheduled before workout time
**Content**: Day label, exercise count, muscle groups, estimated duration
**Actions**: [Start Workout] [Snooze 15min]
**Deep Link**: `/workout/day/{day_id}`

**Example:**
```dart
await oneSignalService.sendWorkoutReminder(
  clientId,
  'Chest & Triceps',
  scheduledTime,
  exerciseCount: 8,
  estimatedDuration: 60,
  muscleGroups: ['Chest', 'Triceps'],
);
```

### 3. Rest Day Reminder
**Trigger**: On scheduled rest days
**Content**: Motivational message, optional recovery activities
**Actions**: None
**Deep Link**: Dialog with rest day info

**Example:**
```dart
await oneSignalService.sendRestDayReminder(
  clientId,
  'Recovery is where the magic happens! 💤',
  isActiveRecovery: true,
  recoveryActivities: ['Light walk', 'Stretching', 'Foam rolling'],
);
```

### 4. Deload Week Alert
**Trigger**: Start of deload week
**Content**: Week number, reason, intensity reduction, recommendations
**Actions**: None
**Deep Link**: `/workout/week/{week_number}`

**Example:**
```dart
await oneSignalService.sendDeloadWeekAlert(
  clientId,
  4,
  'Accumulated fatigue from 3 weeks of training',
  intensityReduction: 0.5,
  recommendations: ['Reduce weight by 50%', 'Focus on form', 'Extra sleep'],
);
```

### 5. PR Celebration Notification
**Trigger**: New personal record achieved
**Content**: Exercise name, PR type, previous/new value, improvement
**Actions**: None
**Deep Link**: PR celebration dialog → analytics/prs
**Sound**: celebration.wav
**Icon**: Trophy

**Example:**
```dart
await oneSignalService.sendPRCelebration(
  clientId,
  'Barbell Bench Press',
  'weight_pr',
  prType: 'weight',
  previousValue: 80.0,
  newValue: 85.0,
  improvement: 6.25,
);
```

### 6. Coach Feedback Notification
**Trigger**: Coach comments on exercise
**Content**: Coach name, exercise name, comment text
**Actions**: [Reply] [View Exercise]
**Deep Link**: `/workout/exercise/{exercise_id}`

**Example:**
```dart
await oneSignalService.sendCoachFeedback(
  clientId,
  'Barbell Squat',
  'Great depth on your squats! Try to keep your knees out more.',
  coachId: coachId,
  coachName: 'John Coach',
  exerciseId: exerciseId,
  videoUrl: 'https://...',
);
```

### 7. Missed Workout Follow-up
**Trigger**: 24 hours after missed workout
**Content**: Day label, motivational message based on consecutive missed
**Actions**: [Reschedule] [Start Now]
**Deep Link**: `/workout/missed`

**Example:**
```dart
await oneSignalService.sendMissedWorkoutNotification(
  clientId,
  'Leg Day',
  dayId: dayId,
  consecutiveMissed: 1,
);
```

### 8. Weekly Summary Notification
**Trigger**: Scheduled day/time (default: Sunday 6 PM)
**Content**: Completed/total sessions, volume, PRs, consistency score
**Actions**: [View Details]
**Deep Link**: `/analytics?week={week_number}`

**Example:**
```dart
await oneSignalService.sendWeeklySummary(
  clientId,
  {
    'week_number': 3,
    'week_start': '2024-01-15',
    'week_end': '2024-01-21',
    'completed_sessions': 4,
    'total_sessions': 5,
    'total_volume': 12500.0,
    'new_prs': 2,
    'consistency_score': 85.0,
    'summary_text': 'Great week! You completed 4 of 5 workouts...',
  },
);
```

---

## Architecture

```
lib/
├── models/notifications/
│   └── workout_notification_types.dart    # Models and enums
│
├── services/
│   ├── notifications/
│   │   └── onesignal_service.dart         # OneSignal integration
│   └── navigation/
│       └── notification_deep_link_handler.dart  # Deep linking
│
├── screens/settings/
│   └── notification_preferences_screen.dart   # Preferences UI
│
└── supabase/functions/
    ├── schedule-workout-reminders/          # Cron scheduler
    ├── send-notification/                   # Immediate send
    └── cancel-workout-reminders/            # Cancel scheduled
```

---

## Setup & Configuration

### Step 1: OneSignal Setup

1. Create OneSignal account at [onesignal.com](https://onesignal.com)
2. Create new app for Android/iOS
3. Get App ID and REST API Key
4. Configure FCM (Firebase Cloud Messaging) for Android
5. Configure APNs (Apple Push Notification service) for iOS

### Step 2: Environment Variables

Add to Supabase Edge Function secrets:

```bash
supabase secrets set ONESIGNAL_APP_ID=your-app-id
supabase secrets set ONESIGNAL_API_KEY=your-api-key
```

### Step 3: Update OneSignal Service

```dart
// lib/services/notifications/onesignal_service.dart
class OneSignalService {
  static const String _appId = 'YOUR_ONESIGNAL_APP_ID'; // Replace
}
```

### Step 4: Initialize in main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(...);

  // Initialize OneSignal
  await OneSignalService.instance.init();

  // Set navigator key for deep linking
  final navigatorKey = GlobalKey<NavigatorState>();
  NotificationDeepLinkHandler.instance.navigatorKey = navigatorKey;

  runApp(MyApp(navigatorKey: navigatorKey));
}
```

### Step 5: Set External User ID on Login

```dart
// After successful login
final userId = Supabase.instance.client.auth.currentUser?.id;
if (userId != null) {
  await OneSignalService.instance.setExternalUserId(userId);
}
```

### Step 6: Create Database Table

```sql
CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  preferences JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS scheduled_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id UUID REFERENCES workout_plans(id) ON DELETE CASCADE,
  day_id UUID,
  notification_type TEXT NOT NULL,
  send_at TIMESTAMPTZ NOT NULL,
  onesignal_notification_id TEXT,
  status TEXT DEFAULT 'scheduled', -- 'scheduled', 'sent', 'cancelled', 'failed'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  cancelled_at TIMESTAMPTZ
);

-- Add onesignal_player_id to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS onesignal_player_id TEXT;
```

---

## Usage Examples

### Basic Notification

```dart
final oneSignal = OneSignalService.instance;

// Send workout reminder
await oneSignal.sendWorkoutReminder(
  clientId,
  'Push Day',
  DateTime.now().add(Duration(hours: 1)),
  exerciseCount: 6,
  estimatedDuration: 45,
  muscleGroups: ['Chest', 'Shoulders', 'Triceps'],
);
```

### Schedule Plan Reminders

```dart
// When coach assigns plan
await oneSignal.scheduleWorkoutReminders(
  planId,
  {
    'timezone': 'America/New_York',
    'reminder_minutes_before': 30,
  },
);
```

### Cancel Reminders

```dart
// When plan is cancelled or updated
await oneSignal.cancelScheduledReminders(planId);
```

### Send PR Celebration

```dart
// After completing exercise with PR
if (isNewPR) {
  await oneSignal.sendPRCelebration(
    userId,
    exerciseName,
    'weight_pr',
    prType: 'weight',
    previousValue: previousWeight,
    newValue: currentWeight,
    improvement: ((currentWeight - previousWeight) / previousWeight) * 100,
  );
}
```

### Send Coach Feedback

```dart
// When coach adds comment
await oneSignal.sendCoachFeedback(
  clientId,
  exerciseName,
  commentText,
  coachId: currentUser.id,
  coachName: currentUser.fullName,
  exerciseId: exerciseId,
);
```

---

## Deep Linking

### Setup Navigator Key

```dart
class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      routes: {
        '/workout/plan': (context) => WorkoutPlanScreen(),
        '/workout/day': (context) => WorkoutDayScreen(),
        '/workout/exercise': (context) => ExerciseScreen(),
        '/analytics': (context) => AnalyticsScreen(),
        // ... other routes
      },
    );
  }
}
```

### Handle Notification Click

The OneSignal service automatically handles clicks via:

```dart
void _handleNotificationClick(OSNotificationClickEvent event) {
  final type = event.notification.additionalData?['type'];
  final payload = event.notification.additionalData?['payload'];

  NotificationDeepLinkHandler.instance.handleNotificationClick(
    WorkoutNotificationType.fromString(type),
    {'payload': payload, 'action_id': event.action?.actionId},
  );
}
```

### Custom Deep Link Handling

```dart
// Add custom handler in NotificationDeepLinkHandler
Future<void> handleCustomNotification(
  BuildContext context,
  Map<String, dynamic> data,
) async {
  Navigator.of(context).pushNamed(
    '/custom/route',
    arguments: data,
  );
}
```

---

## Notification Preferences

### Access Preferences Screen

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NotificationPreferencesScreen(),
  ),
);
```

### Available Preferences

- **Workout Reminders**
  - Enable/disable
  - Default reminder time (e.g., 8:00 AM)
  - Minutes before workout (0-120)

- **Rest Day Reminders**
  - Enable/disable

- **PR Celebrations**
  - Enable/disable

- **Coach Feedback**
  - Enable/disable

- **Missed Workout Follow-ups**
  - Enable/disable

- **Weekly Summary**
  - Enable/disable
  - Day of week (Sunday-Saturday)
  - Time (e.g., 18:00)

- **Sound & Vibration**
  - Enable sound
  - Enable vibration

- **Timezone**
  - Auto-detected or manual selection

### Programmatic Access

```dart
// Get preferences
final prefs = await oneSignal.getNotificationPreferences(userId);

// Update preferences
final updated = prefs.copyWith(
  workoutRemindersEnabled: false,
  weeklySummaryTime: '20:00',
);
await oneSignal.saveNotificationPreferences(userId, updated);
```

---

## Edge Functions

### schedule-workout-reminders

**Purpose**: Schedule all workout reminders for a plan
**Trigger**: Called when plan is assigned or updated
**Cron**: Optional daily cron to check upcoming workouts

**Request:**
```json
{
  "plan_id": "uuid",
  "schedule": {
    "timezone": "America/New_York",
    "reminder_minutes_before": 30
  }
}
```

**Response:**
```json
{
  "success": true,
  "scheduled_count": 24,
  "notifications": [
    {
      "day_id": "uuid",
      "day_label": "Push Day",
      "send_time": "2024-01-15T07:30:00Z",
      "notification_id": "onesignal-id"
    }
  ]
}
```

### send-notification

**Purpose**: Send immediate notification
**Trigger**: Called for PR celebrations, coach feedback, etc.

**Request:**
```json
{
  "user_ids": ["uuid1", "uuid2"],
  "title": "New Personal Record!",
  "body": "You lifted 85kg on Bench Press!",
  "data": {
    "type": "pr_celebration",
    "payload": { ... }
  },
  "buttons": [
    {"id": "view", "text": "View Details"}
  ]
}
```

### cancel-workout-reminders

**Purpose**: Cancel scheduled reminders
**Trigger**: Plan cancelled or updated

**Request:**
```json
{
  "plan_id": "uuid"
}
```

**Response:**
```json
{
  "success": true,
  "cancelled_count": 24,
  "total_scheduled": 24
}
```

---

## Testing

### Send Test Notification

```dart
// From preferences screen
await oneSignalService.sendTestNotification(userId);
```

### Test Deep Links

```dart
// Manually trigger deep link handler
NotificationDeepLinkHandler.instance.handleNotificationClick(
  WorkoutNotificationType.prCelebration,
  {
    'payload': {
      'exercise_name': 'Bench Press',
      'pr_type': 'weight',
      'previous_value': 80.0,
      'new_value': 85.0,
      'improvement': 6.25,
      'achieved_date': DateTime.now().toIso8601String(),
    },
  },
);
```

### Test Scheduled Reminders

1. Create test plan with workout tomorrow
2. Call `scheduleWorkoutReminders(planId, {})`
3. Check `scheduled_notifications` table
4. Wait for notification or adjust `send_at` timestamp

### OneSignal Dashboard

- View all sent notifications
- See delivery rates
- Test segments and tags
- Check user subscriptions

---

## Troubleshooting

### Notifications Not Receiving

**Issue**: User not receiving notifications

**Solutions:**
1. Check OneSignal player ID is synced:
   ```sql
   SELECT onesignal_player_id FROM profiles WHERE id = 'user-id';
   ```

2. Verify notification permissions:
   ```dart
   final status = await OneSignal.Notifications.permission;
   if (!status) {
     await OneSignal.Notifications.requestPermission(true);
   }
   ```

3. Check OneSignal tags:
   ```dart
   final tags = await OneSignal.User.getTags();
   print(tags);
   ```

4. Verify external user ID:
   ```dart
   final userId = await OneSignal.User.getOnesignalId();
   print('Player ID: $userId');
   ```

### Deep Links Not Working

**Issue**: Clicking notification doesn't navigate

**Solutions:**
1. Ensure navigator key is set:
   ```dart
   NotificationDeepLinkHandler.instance.navigatorKey = navigatorKey;
   ```

2. Check route is defined:
   ```dart
   routes: {
     '/workout/plan': (context) => WorkoutPlanScreen(),
   }
   ```

3. Verify notification data structure:
   ```dart
   print(event.notification.additionalData);
   ```

### Scheduled Notifications Not Sending

**Issue**: Reminders not being sent at scheduled time

**Solutions:**
1. Check `scheduled_notifications` table:
   ```sql
   SELECT * FROM scheduled_notifications
   WHERE status = 'scheduled' AND send_at < NOW();
   ```

2. Verify OneSignal notification ID:
   ```sql
   SELECT onesignal_notification_id FROM scheduled_notifications
   WHERE id = 'notification-id';
   ```

3. Check OneSignal API response:
   - View logs in Supabase Edge Functions dashboard
   - Check OneSignal delivery reports

4. Ensure timezone is correct:
   ```dart
   print(preferences.timezone); // Should match user's actual timezone
   ```

### Preferences Not Saving

**Issue**: Notification preferences not persisting

**Solutions:**
1. Check table exists:
   ```sql
   SELECT * FROM notification_preferences WHERE user_id = 'user-id';
   ```

2. Verify RLS policies:
   ```sql
   -- Allow users to update their own preferences
   CREATE POLICY "Users can update own preferences"
   ON notification_preferences FOR UPDATE
   USING (auth.uid() = user_id);
   ```

3. Check error logs:
   ```dart
   try {
     await oneSignal.saveNotificationPreferences(userId, prefs);
   } catch (e) {
     print('Error: $e');
   }
   ```

---

## Best Practices

### 1. Respect User Preferences
Always check preferences before sending:
```dart
final prefs = await oneSignal.getNotificationPreferences(userId);
if (!prefs.prCelebrationEnabled) {
  return; // Don't send PR notification
}
```

### 2. Timezone Awareness
Always use user's timezone for scheduling:
```dart
final userTz = prefs.timezone; // e.g., 'America/Los_Angeles'
```

### 3. Notification Frequency
Avoid notification fatigue:
- Max 2-3 notifications per day
- Space out reminders by at least 4 hours
- Don't send late night notifications (after 10 PM user time)

### 4. Clear Call-to-Actions
Use actionable buttons:
- ✅ Good: [Start Workout] [Snooze]
- ❌ Bad: [OK] [Dismiss]

### 5. Personalization
Include user-specific data:
- User name
- Exercise names they use
- Their PR values
- Personalized motivational messages

### 6. Error Handling
Always handle failures gracefully:
```dart
try {
  await oneSignal.sendWorkoutReminder(...);
} catch (e) {
  // Log error but don't crash app
  logger.error('Failed to send notification: $e');
}
```

---

## Analytics

### Track Notification Performance

```dart
// Track opens
OneSignal.Notifications.addClickListener((event) {
  analytics.logEvent('notification_opened', {
    'type': event.notification.additionalData?['type'],
    'action': event.action?.actionId,
  });
});

// Track conversions
if (userStartedWorkoutFromNotification) {
  analytics.logEvent('notification_conversion', {
    'type': 'workout_reminder',
    'time_to_action': timeDiff.inMinutes,
  });
}
```

### Key Metrics
- Open rate by notification type
- Action button click rate
- Time from notification to action
- Snooze rate
- Unsubscribe rate per type

---

## Future Enhancements

- **Rich Media**: Add images to PR celebrations
- **Grouped Notifications**: Group daily reminders
- **Notification History**: In-app notification center
- **Smart Timing**: ML-based optimal send times
- **A/B Testing**: Test different message formats
- **Localization**: Multi-language support
- **Wearables**: Apple Watch/Android Wear notifications
- **Voice Reminders**: Alexa/Google Home integration

---

**Last Updated:** 2024-01-15
**Version:** 1.0.0