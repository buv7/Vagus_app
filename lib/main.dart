import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/workout/client_workout_dashboard_screen.dart'; // ✅ import workout screen
// NEW: Import OneSignal service
import 'services/notifications/onesignal_service.dart';
import 'services/notifications/notification_helper.dart';
import 'services/settings/settings_controller.dart';
import 'services/motion_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kydrpnrmqbedjflklgue.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5ZHJwbnJtcWJlZGpmbGtsZ3VlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMjUxODAsImV4cCI6MjA2OTgwMTE4MH0.qlpGUiy17IbDsfgOf3-F2XBjOajjwxfy2NLMlUZWaqo',
  );

  // NEW: Initialize OneSignal notifications
  await OneSignalService.instance.init();

  // Initialize local notifications for calendar reminders
  await NotificationHelper.instance.init();

  // Initialize settings controller
  final settings = SettingsController();
  await settings.load();

  runApp(VagusMainApp(settings: settings));
}

class VagusMainApp extends StatelessWidget {
  final SettingsController settings;

  const VagusMainApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (_, __) {
        return MaterialApp(
          title: 'VAGUS',
          navigatorKey: navigatorKey,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.themeMode,
          locale: settings.locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
            Locale('ku'),
          ],
          home: const AuthGate(),
          routes: {
            // ✅ Add this route for client workout plan viewer
            '/client-workout': (context) => const ClientWorkoutDashboardScreen(),
          },
        );
      },
    );
  }
}
