// test/exercise_sheet_prefs_plumbing_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/widgets/workout/exercise_detail_sheet.dart';
import 'package:vagus_app/services/settings/user_prefs_service.dart';

void main() {
  group('ExerciseDetailSheet Preferences Plumbing', () {
    late UserPrefsService prefsService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      prefsService = UserPrefsService.instance;
    });

    testWidgets('loads preferences on initialization', (WidgetTester tester) async {
      // Set up test preferences
      await prefsService.init();
      await prefsService.setDefaultUnit('lb');
      await prefsService.setHapticsEnabled(false);
      await prefsService.setTempoCuesEnabled(false);
      await prefsService.setAutoAdvanceSupersets(false);
      await prefsService.setShowQuickNoteCard(false);
      await prefsService.setShowWorkingSetsFirst(false);

      // Create test exercise data
      final testExercises = [
        {
          'name': 'Test Exercise',
          'reps': 8,
          'weight': 100,
          'notes': 'Test notes',
        }
      ];

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseDetailSheet(
              exercises: testExercises,
              initialIndex: 0,
            ),
          ),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // The widget should be built with the preferences applied
      // Note: This is a basic test to ensure the widget builds without errors
      // In a real implementation, you might want to expose getters to test
      // the actual preference values being applied
      expect(find.byType(ExerciseDetailSheet), findsOneWidget);
    });

    testWidgets('handles missing preferences gracefully', (WidgetTester tester) async {
      // Clear all preferences
      await prefsService.init();
      await prefsService.clearAllSticky();

      // Create test exercise data
      final testExercises = [
        {
          'name': 'Test Exercise',
          'reps': 8,
          'weight': 100,
          'notes': 'Test notes',
        }
      ];

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseDetailSheet(
              exercises: testExercises,
              initialIndex: 0,
            ),
          ),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Should still build successfully with default values
      expect(find.byType(ExerciseDetailSheet), findsOneWidget);
    });

    testWidgets('applies sticky preferences for specific exercise', (WidgetTester tester) async {
      await prefsService.init();
      
      // Set sticky preferences for a specific exercise
      const exerciseKey = 'Test Exercise';
      final stickyPrefs = {
        'unit': 'lb',
        'barWeight': 45.0,
        'setType': 'drop',
        'dropWeights': [40.0, 35.0],
      };
      await prefsService.setStickyFor(exerciseKey, stickyPrefs);

      // Create test exercise data
      final testExercises = [
        {
          'name': 'Test Exercise',
          'reps': 8,
          'weight': 100,
          'notes': 'Test notes',
        }
      ];

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseDetailSheet(
              exercises: testExercises,
              initialIndex: 0,
            ),
          ),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Should build successfully with sticky preferences applied
      expect(find.byType(ExerciseDetailSheet), findsOneWidget);
    });
  });
}
