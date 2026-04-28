// PRISM golden tests — 30 screens × 3 locales (en, ar, ku) = 90 snapshots.
//
// First run:  flutter test --update-goldens test/golden/
// Regression: flutter test test/golden/  (fails on pixel diff)
//
// Screens marked [PENDING] use PlaceholderScreen and must be updated when
// the real implementation lands (see comments inline).

import 'package:flutter/material.dart';
import 'package:vagus_app/models/workout/workout_plan.dart';
import 'package:vagus_app/screens/admin/admin_hub_screen.dart';
import 'package:vagus_app/screens/admin/admin_screen.dart';
import 'package:vagus_app/screens/auth/premium_login_screen.dart';
import 'package:vagus_app/screens/auth/signup_screen.dart';
import 'package:vagus_app/screens/calendar/calendar_screen.dart';
import 'package:vagus_app/screens/client/client_coach_marketplace.dart';
import 'package:vagus_app/screens/client/coach_profile_view_screen.dart';
import 'package:vagus_app/screens/coach/client_profile/coach_client_profile_screen.dart';
import 'package:vagus_app/screens/coach/modern_client_management_screen.dart';
import 'package:vagus_app/screens/dashboard/home_screen.dart';
import 'package:vagus_app/screens/dashboard/profile_screen.dart';
import 'package:vagus_app/screens/hydration/hydration_screen.dart';
import 'package:vagus_app/screens/messaging/client_messenger_screen.dart';
import 'package:vagus_app/screens/messaging/client_threads_screen.dart';
import 'package:vagus_app/screens/messaging/coach_threads_screen.dart';
import 'package:vagus_app/screens/nutrition/food_snap_screen.dart';
import 'package:vagus_app/screens/nutrition/nutrition_hub_screen.dart';
import 'package:vagus_app/screens/progress/modern_progress_tracker.dart';
import 'package:vagus_app/screens/progress/progress_entry_form.dart';
import 'package:vagus_app/screens/progress/progress_gallery.dart';
import 'package:vagus_app/screens/rank/rank_hub_screen.dart';
import 'package:vagus_app/screens/retention/daily_missions_screen.dart';
import 'package:vagus_app/screens/settings/user_settings_screen.dart';
import 'package:vagus_app/screens/supplements/supplement_list_screen.dart';
import 'package:vagus_app/screens/workout/client_workout_dashboard_screen.dart';
import 'package:vagus_app/screens/workout/modern_workout_plan_viewer.dart';
import 'package:vagus_app/screens/workout/workout_day_editor.dart';

import 'prism_harness.dart';

void main() {
  // 1. Home
  screenGoldens('home', (_) => const HomeScreen());

  // 2. Login
  screenGoldens('login', (_) => const PremiumLoginScreen());

  // 3. Signup
  screenGoldens('signup', (_) => const SignupScreen());

  // 4. Workout list
  screenGoldens('workout_list', (_) => const ClientWorkoutDashboardScreen());

  // 5. Workout detail
  screenGoldens('workout_detail', (_) => const ModernWorkoutPlanViewer());

  // 6. Exercise detail — WorkoutDayEditor requires a WorkoutDay stub.
  screenGoldens('exercise_detail', (_) {
    final stubDay = WorkoutDay(
      weekId: 'prism-week-1',
      dayNumber: 1,
      label: 'Push Day',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    return WorkoutDayEditor(day: stubDay, onDayChanged: (_) {});
  });

  // 7. Nutrition log
  screenGoldens('nutrition_log', (_) => const NutritionHubScreen());

  // 8. Food search
  screenGoldens('food_search', (_) => const FoodSnapScreen());

  // 9. Messaging list
  screenGoldens('messaging_list', (_) => const ClientThreadsScreen());

  // 10. Messaging detail
  screenGoldens('messaging_detail', (_) => const ClientMessengerScreen());

  // 11. Profile
  screenGoldens('profile', (_) => const ProfileScreen());

  // 12. Settings
  screenGoldens('settings', (_) => const UserSettingsScreen());

  // 13. Ranks
  screenGoldens('ranks', (_) => const RankHubScreen());

  // 14. Missions
  screenGoldens('missions', (_) => const DailyMissionsScreen());

  // 15. Calendar
  screenGoldens('calendar', (_) => const CalendarScreen());

  // 16. Marketplace browse
  screenGoldens('marketplace_browse', (_) => const ClientCoachMarketplace());

  // 17. Marketplace detail
  screenGoldens('marketplace_detail',
      (_) => const CoachProfileViewScreen(coachId: 'prism-coach-stub'));

  // 18. Periods log — PENDING: PERIODS-UI not yet merged.
  //     Replace PlaceholderScreen with the real screen class when available.
  screenGoldens(
    'periods_log',
    (_) => const PlaceholderScreen('Periods Log'),
  );

  // 19. Lab work view — PENDING: screen not yet implemented.
  screenGoldens(
    'lab_work',
    (_) => const PlaceholderScreen('Lab Work View'),
  );

  // 20. Hydration
  screenGoldens('hydration', (_) => const HydrationScreen());

  // 21. Sleep view — PENDING: screen not yet implemented.
  screenGoldens(
    'sleep_view',
    (_) => const PlaceholderScreen('Sleep View'),
  );

  // 22. Weight log
  screenGoldens('weight_log', (_) => const ProgressEntryForm());

  // 23. Progress photos
  screenGoldens(
      'progress_photos', (_) => const ProgressGallery(userId: 'prism-user-stub'));

  // 24. Body measurements
  screenGoldens('body_measurements', (_) => const ModernProgressTracker());

  // 25. Supplement log
  screenGoldens('supplement_log', (_) => const SupplementListScreen());

  // 26. Coach inbox
  screenGoldens('coach_inbox', (_) => const CoachThreadsScreen());

  // 27. Coach client list
  screenGoldens(
      'coach_client_list', (_) => const ModernClientManagementScreen());

  // 28. Coach client detail
  screenGoldens(
    'coach_client_detail',
    (_) => const CoachClientProfileScreen(
      clientId: 'prism-client-stub',
      clientName: 'Alex Smith',
    ),
  );

  // 29. Admin dashboard
  screenGoldens('admin_dashboard', (_) => const AdminScreen());

  // 30. Admin solutions hub
  screenGoldens('admin_solutions', (_) => const AdminHubScreen());
}
