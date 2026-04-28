import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'config/env_config.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/workout/client_workout_dashboard_screen.dart'; // ✅ import workout screen
import 'screens/workout/workout_plan_builder_screen.dart'; // ✅ import workout editor
import 'screens/splash/animated_splash_screen.dart';
// OneSignal service archived - no longer in use
// import 'services/notifications/onesignal_service.dart';
import 'services/notifications/notification_helper.dart';
import 'services/settings/settings_controller.dart';
import 'services/settings/reduce_motion.dart';
import 'services/motion_service.dart';
import 'services/deep_link_service.dart';
import 'theme/app_theme.dart';
import 'screens/settings/user_settings_screen.dart';
import 'screens/billing/billing_settings.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/workout/cardio_log_screen.dart';
// Additional screen imports for navigation routes
import 'screens/messaging/coach_threads_screen.dart';
import 'screens/messaging/client_threads_screen.dart';
import 'screens/nutrition/nutrition_plan_viewer.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/progress/client_check_in_calendar.dart';
import 'screens/files/file_manager_screen.dart';
import 'screens/account_switch_screen.dart';
import 'screens/settings/ai_usage_screen.dart';
import 'screens/settings/data_export_screen.dart';
import 'screens/settings/devices_screen.dart';
import 'screens/settings/profile_edit_screen.dart';
import 'screens/support/support_screen.dart';
import 'screens/coaches/coach_application_screen.dart';
import 'services/wearables/wearable_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable semantics on web for accessibility + test automation.
  // Flutter web does not build the semantics tree by default.
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }

  // Surface framework errors to the console instead of swallowing them.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kIsWeb) {
      debugPrint('FlutterError: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
    }
  };

  // Catch unhandled async / zone errors.
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error: $error');
    debugPrint('Stack: $stack');
    return false; // let Flutter handle normally
  };

  // Load environment variables from .env file
  await EnvConfig.init();

  // Initialize Supabase with credentials from environment
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );

  // Debug: Check initial session state
  final session = Supabase.instance.client.auth.currentSession;
  debugPrint('🧪 Initial session check: ${session?.user.id ?? "null"}');
  debugPrint('🧪 Has access token: ${session?.accessToken != null}');

  // OneSignal notifications disabled - service archived
  // await OneSignalService.instance.init();

  // Initialize local notifications for calendar reminders.
  // flutter_local_notifications has no web implementation — skip on web.
  if (!kIsWeb) {
    await NotificationHelper.instance.init();
  }

  // Initialize settings controller
  final settings = SettingsController();
  await settings.load();

  // Wearable background sync — on launch + every 4 h thereafter.
  // Runs only when a user is already signed in; re-triggered on auth change.
  if (!kIsWeb && Supabase.instance.client.auth.currentUser != null) {
    unawaited(WearableService.instance.init());
  }

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

class VagusMainApp extends StatefulWidget {
  final SettingsController settings;

  const VagusMainApp({super.key, required this.settings});

  @override
  State<VagusMainApp> createState() => _VagusMainAppState();
}

class _VagusMainAppState extends State<VagusMainApp> {
  @override
  void initState() {
    super.initState();
    // app_links plugin uses platform channels not available on web.
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeDeepLinks();
      });
    }
  }

  void _initializeDeepLinks() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      DeepLinkService().initialize(context);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      DeepLinkService().dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settings,
      builder: (_, __) {
        return MaterialApp(
          title: 'VAGUS',
          navigatorKey: navigatorKey,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: widget.settings.themeMode,
          locale: widget.settings.locale,
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
          onGenerateRoute: (settings) {
            // Handle routes with arguments
            if (settings.name == '/workout-editor') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => WorkoutPlanBuilderScreen(
                  planId: args?['id']?.toString(),
                  clientId: args?['client_id']?.toString(),
                ),
              );
            }
            return null; // Let the routes table handle other routes
          },
          routes: {
            // Workout routes
            '/client-workout': (context) => const ClientWorkoutDashboardScreen(),
            '/cardio-log': (context) => const CardioLogScreen(),

            // Messaging routes
            '/messages/coach': (context) => const CoachThreadsScreen(),
            '/messages/client': (context) => const ClientThreadsScreen(),
            '/messages': (context) => const ClientThreadsScreen(), // Default to client view

            // Nutrition routes
            '/nutrition': (context) => const NutritionPlanViewer(),

            // Calendar and Progress routes
            '/calendar': (context) => const CalendarScreen(),
            '/progress': (context) => const ClientCheckInCalendar(),

            // File management
            '/files': (context) => const FileManagerScreen(),

            // Account management
            '/account-switch': (context) => const AccountSwitchScreen(),

            // Settings and Admin routes
            '/settings': (context) => const UserSettingsScreen(),
            '/billing': (context) => const BillingSettings(),
            '/admin': (context) => const AdminScreen(),

            // Side menu items
            '/profile/edit': (context) => const ProfileEditScreen(),
            '/devices': (context) => const DevicesScreen(),
            '/ai-usage': (context) => const AiUsageScreen(),
            '/export': (context) => const DataExportScreen(),
            '/apply-coach': (context) => const CoachApplicationScreen(),
            '/support': (context) => const SupportScreen(),
          },
        );
      },
    );
  }
}
