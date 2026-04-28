// SIGNAL v2: NotificationsSettingsScreen is now a thin shim that renders the
// new FCM-based NotificationPreferencesScreen. Existing call-sites in
// modern_client_dashboard and modern_coach_menu continue to compile unchanged.
import 'package:flutter/material.dart';
import 'notification_preferences_screen.dart';

export 'notification_preferences_screen.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const NotificationPreferencesScreen();
}
