# OneSignal Push Notifications Setup for VAGUS

This guide explains how to set up OneSignal push notifications for the VAGUS mobile app.

## Overview

VAGUS uses OneSignal for cross-platform push notifications instead of Firebase Cloud Messaging (FCM). This approach provides:

- ✅ No Firebase dependencies
- ✅ Cross-platform support (iOS, Android, Web)
- ✅ Advanced segmentation and targeting
- ✅ In-app messaging capabilities
- ✅ Webhook support for automated notifications

## Prerequisites

1. **OneSignal Account**: Sign up at [onesignal.com](https://onesignal.com)
2. **Supabase Project**: Your VAGUS Supabase instance
3. **Flutter Development Environment**: Flutter SDK and development tools

## Step 1: OneSignal Setup

### 1.1 Create OneSignal App

1. Log into your OneSignal dashboard
2. Click "New App/Website"
3. Choose "Mobile Push" as the platform
4. Enter app details:
   - **App Name**: VAGUS
   - **Platform**: iOS & Android
   - **Bundle ID**: `com.example.vagus_app` (update to match your app)

### 1.2 Get OneSignal Credentials

After creating your app, you'll need:

- **App ID**: Found in Settings → Keys & IDs
- **REST API Key**: Found in Settings → Keys & IDs

### 1.3 Configure Platforms

#### Android Setup
1. In OneSignal dashboard, go to Settings → Android
2. Download `google-services.json` and place it in `android/app/`
3. Update your Android app's package name if needed

#### iOS Setup
1. In OneSignal dashboard, go to Settings → iOS
2. Download `GoogleService-Info.plist` and place it in `ios/Runner/`
3. Enable Push Notifications capability in Xcode

## Step 2: Update VAGUS Configuration

### 2.1 Update OneSignal App ID

Edit `lib/services/notifications/onesignal_service.dart`:

```dart
// Replace YOUR-ONESIGNAL-APP-ID with your actual App ID
OneSignal.initialize("YOUR-ONESIGNAL-APP-ID");
```

### 2.2 Update Supabase Edge Function

Edit `supabase/functions/send-notification/index.ts`:

```typescript
// Replace with your actual OneSignal credentials
const ONESIGNAL_APP_ID = Deno.env.get("ONESIGNAL_APP_ID") || "YOUR-ONESIGNAL-APP-ID";
const ONESIGNAL_REST_API_KEY = Deno.env.get("ONESIGNAL_REST_API_KEY") || "YOUR-ONESIGNAL-REST-API-KEY";
```

### 2.3 Set Environment Variables

In your Supabase dashboard:

1. Go to Settings → Edge Functions
2. Add environment variables:
   - `ONESIGNAL_APP_ID`: Your OneSignal App ID
   - `ONESIGNAL_REST_API_KEY`: Your OneSignal REST API Key

## Step 3: Database Setup

### 3.1 Run Migration

Execute the SQL migration in `supabase/migrations/create_user_devices_table.sql`:

```sql
-- Run this in your Supabase SQL editor
-- The migration creates the user_devices table and related functions
```

### 3.2 Verify Table Creation

Check that the following were created:
- `user_devices` table
- `user_devices_view` view
- `get_user_onesignal_ids()` function
- `get_role_onesignal_ids()` function

## Step 4: Deploy Edge Function

### 4.1 Deploy to Supabase

```bash
# From your project root
supabase functions deploy send-notification
```

### 4.2 Test the Function

Test the Edge Function with a simple notification:

```bash
curl -X POST https://your-project.supabase.co/functions/v1/send-notification \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "user",
    "userId": "test-user-id",
    "title": "Test Notification",
    "message": "This is a test notification from VAGUS"
  }'
```

## Step 5: Test in VAGUS App

### 5.1 Build and Run

```bash
flutter pub get
flutter run
```

### 5.2 Verify Device Registration

1. Sign in to the app
2. Check console logs for OneSignal initialization
3. Verify device registration in Supabase `user_devices` table

### 5.3 Test Notifications

1. Send a test notification from OneSignal dashboard
2. Verify notification appears on device
3. Test notification tap navigation

## Step 6: Integration Examples

### 6.1 Send Message Notification

```dart
import 'package:vagus_app/services/notifications/notification_helper.dart';

// When a new message is sent
await NotificationHelper.instance.sendMessageNotification(
  recipientId: recipientUserId,
  senderName: currentUserName,
  message: messageText,
  threadId: threadId,
);
```

### 6.2 Send Workout Plan Notification

```dart
// When a new workout plan is created
await NotificationHelper.instance.sendWorkoutNotification(
  clientId: clientUserId,
  coachName: coachName,
  planName: planName,
  planId: planId,
);
```

### 6.3 Send Role-Based Notification

```dart
// Send to all coaches
await NotificationHelper.instance.sendToRole(
  role: 'coach',
  title: 'System Update',
  message: 'New features are available for coaches',
);
```

## Step 7: Advanced Features

### 7.1 User Segmentation

```dart
// Add custom tags for targeting
await OneSignalService.instance.addUserTag('subscription', 'premium');
await OneSignalService.instance.addUserTag('location', 'US');
```

### 7.2 Topic Subscriptions

```dart
// Subscribe to specific topics
await OneSignalService.instance.subscribeToTopic('workout-reminders');
await OneSignalService.instance.subscribeToTopic('nutrition-tips');
```

### 7.3 In-App Messaging

```dart
// Send in-app messages (requires OneSignal dashboard setup)
await OneSignalService.instance.sendInAppMessage('Welcome to VAGUS!');
```

## Troubleshooting

### Common Issues

1. **Notifications not appearing**
   - Check OneSignal dashboard for delivery status
   - Verify device registration in Supabase
   - Check notification permissions on device

2. **Edge Function errors**
   - Verify environment variables are set
   - Check OneSignal API key permissions
   - Review function logs in Supabase dashboard

3. **Device not registering**
   - Ensure OneSignal is properly initialized
   - Check internet connectivity
   - Verify OneSignal App ID is correct

### Debug Mode

Enable verbose logging in `onesignal_service.dart`:

```dart
OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
```

## Security Considerations

1. **API Key Protection**: Never expose REST API keys in client code
2. **User Authentication**: All notification requests require valid Supabase auth
3. **Rate Limiting**: Implement rate limiting in your Edge Functions
4. **Data Validation**: Validate all notification payloads

## Performance Optimization

1. **Batch Notifications**: Group multiple notifications when possible
2. **Smart Targeting**: Use tags and segments for precise delivery
3. **Offline Handling**: OneSignal handles offline message queuing
4. **Analytics**: Monitor delivery rates and user engagement

## Next Steps

After basic setup:

1. **Customize Notification Templates**: Create branded notification designs
2. **Implement A/B Testing**: Test different notification strategies
3. **Add Analytics**: Track notification performance and user behavior
4. **Automate Workflows**: Set up webhooks for automated notifications

## Support

- **OneSignal Documentation**: [docs.onesignal.com](https://docs.onesignal.com)
- **Supabase Edge Functions**: [supabase.com/docs/guides/functions](https://supabase.com/docs/guides/functions)
- **VAGUS Issues**: Create an issue in the project repository

---

**Note**: This setup guide assumes you have basic familiarity with Flutter, Supabase, and OneSignal. Adjust the configuration based on your specific requirements and environment.
