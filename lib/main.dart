import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/workout/client_workout_dashboard_screen.dart'; // ✅ import workout screen
import 'screens/splash/animated_splash_screen.dart';
// NEW: Import OneSignal service
import 'services/notifications/onesignal_service.dart';
import 'services/notifications/notification_helper.dart';
import 'services/settings/settings_controller.dart';
import 'services/settings/reduce_motion.dart';
import 'services/motion_service.dart';
import 'theme/app_theme.dart';
import 'screens/settings/user_settings_screen.dart';
import 'screens/billing/billing_settings.dart';
import 'screens/admin/admin_screen.dart';

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReduceMotion()),
        // keep other providers if any
      ],
      child: VagusMainApp(settings: settings),
    ),
  );
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
          home: AnimatedSplashScreen(
            nextBuilder: (_) => const AuthGate(),
          ),
          routes: {
            // ✅ Add this route for client workout plan viewer
            '/client-workout': (context) => const ClientWorkoutDashboardScreen(),
            // Side menu routes
            '/settings': (context) => const UserSettingsScreen(),
            '/billing': (context) => const BillingSettings(),
            '/admin': (context) => const AdminScreen(),
            '/profile/edit': (context) => const UserSettingsScreen(), // Redirect to settings for now
            '/devices': (context) => const UserSettingsScreen(), // Redirect to settings for now
            '/ai-usage': (context) => const AdminScreen(), // Redirect to admin for now
            '/export': (context) => const UserSettingsScreen(), // Redirect to settings for now
            '/apply-coach': (context) => const AdminScreen(), // Redirect to admin for now
            '/support': (context) => const UserSettingsScreen(), // Redirect to settings for now
          },
        );
      },
    );
  }
}
