// test/user_prefs_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vagus_app/services/settings/user_prefs_service.dart';
import 'package:vagus_app/services/workout/exercise_local_log_service.dart';

void main() {
  group('UserPrefsService', () {
    late UserPrefsService prefsService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() {
      prefsService = UserPrefsService.instance;
    });

    test('global preferences round-trip', () async {
      await prefsService.init();
      
      // Test haptics
      await prefsService.setHapticsEnabled(false);
      expect(prefsService.hapticsEnabled, false);
      await prefsService.setHapticsEnabled(true);
      expect(prefsService.hapticsEnabled, true);
      
      // Test tempo cues
      await prefsService.setTempoCuesEnabled(false);
      expect(prefsService.tempoCuesEnabled, false);
      await prefsService.setTempoCuesEnabled(true);
      expect(prefsService.tempoCuesEnabled, true);
      
      // Test auto-advance supersets
      await prefsService.setAutoAdvanceSupersets(false);
      expect(prefsService.autoAdvanceSupersets, false);
      await prefsService.setAutoAdvanceSupersets(true);
      expect(prefsService.autoAdvanceSupersets, true);
      
      // Test default unit
      await prefsService.setDefaultUnit('lb');
      expect(prefsService.defaultUnit, 'lb');
      await prefsService.setDefaultUnit('kg');
      expect(prefsService.defaultUnit, 'kg');
      
      // Test show quick note card
      await prefsService.setShowQuickNoteCard(false);
      expect(prefsService.showQuickNoteCard, false);
      await prefsService.setShowQuickNoteCard(true);
      expect(prefsService.showQuickNoteCard, true);
      
      // Test show working sets first
      await prefsService.setShowWorkingSetsFirst(false);
      expect(prefsService.showWorkingSetsFirst, false);
      await prefsService.setShowWorkingSetsFirst(true);
      expect(prefsService.showWorkingSetsFirst, true);
    });

    test('sticky preferences write/read with mixed advanced fields', () async {
      await prefsService.init();
      
      const exerciseKey = 'test_exercise';
      
      // Test basic sticky data
      final basicSticky = {
        'unit': 'lb',
        'barWeight': 45.0,
      };
      await prefsService.setStickyFor(exerciseKey, basicSticky);
      final retrieved = prefsService.getStickyFor(exerciseKey);
      expect(retrieved['unit'], 'lb');
      expect(retrieved['barWeight'], 45.0);
      
      // Test advanced set type data
      final advancedSticky = {
        'unit': 'kg',
        'barWeight': 20.0,
        'setType': 'drop',
        'dropWeights': [18.0, 16.0],
        'dropPercents': [-10.0, -10.0],
      };
      await prefsService.setStickyFor(exerciseKey, advancedSticky);
      final retrievedAdvanced = prefsService.getStickyFor(exerciseKey);
      expect(retrievedAdvanced['unit'], 'kg');
      expect(retrievedAdvanced['barWeight'], 20.0);
      expect(retrievedAdvanced['setType'], 'drop');
      expect(retrievedAdvanced['dropWeights'], [18.0, 16.0]);
      expect(retrievedAdvanced['dropPercents'], [-10.0, -10.0]);
      
      // Test rest-pause data
      final rpSticky = {
        'unit': 'kg',
        'setType': 'restPause',
        'rpBursts': [8, 3, 2],
        'rpRestSec': 20,
      };
      await prefsService.setStickyFor(exerciseKey, rpSticky);
      final retrievedRP = prefsService.getStickyFor(exerciseKey);
      expect(retrievedRP['setType'], 'restPause');
      expect(retrievedRP['rpBursts'], [8, 3, 2]);
      expect(retrievedRP['rpRestSec'], 20);
      
      // Test cluster data
      final clusterSticky = {
        'unit': 'kg',
        'setType': 'cluster',
        'clusterSize': 3,
        'clusterRestSec': 15,
        'clusterTotalReps': 15,
      };
      await prefsService.setStickyFor(exerciseKey, clusterSticky);
      final retrievedCluster = prefsService.getStickyFor(exerciseKey);
      expect(retrievedCluster['setType'], 'cluster');
      expect(retrievedCluster['clusterSize'], 3);
      expect(retrievedCluster['clusterRestSec'], 15);
      expect(retrievedCluster['clusterTotalReps'], 15);
    });

    test('sticky data validation and trimming', () async {
      await prefsService.init();
      
      const exerciseKey = 'test_exercise';
      
      // Test invalid data gets filtered out
      final invalidSticky = {
        'unit': 'invalid_unit', // Should be filtered out
        'barWeight': -5.0, // Should be filtered out
        'setType': 'invalid_type', // Should be filtered out
        'dropWeights': [0, -5, 18.0, 16.0], // Should filter out 0 and -5
        'rpBursts': [0, -2, 8, 3], // Should filter out 0 and -2
        'rpRestSec': 200, // Should be clamped to 60
        'clusterSize': 1, // Should be clamped to 2
        'clusterRestSec': 200, // Should be clamped to 60
        'clusterTotalReps': 2, // Should be clamped to 6
      };
      await prefsService.setStickyFor(exerciseKey, invalidSticky);
      final retrieved = prefsService.getStickyFor(exerciseKey);
      
      // Should only contain valid data
      expect(retrieved.containsKey('unit'), false); // Invalid unit filtered out
      expect(retrieved.containsKey('barWeight'), false); // Invalid weight filtered out
      expect(retrieved.containsKey('setType'), false); // Invalid setType filtered out
      expect(retrieved.containsKey('dropWeights'), false); // No valid setType, so no dropWeights
      expect(retrieved.containsKey('rpBursts'), false); // No valid setType, so no rpBursts
      expect(retrieved.containsKey('rpRestSec'), false); // No valid setType, so no rpRestSec
      expect(retrieved.containsKey('clusterSize'), false); // No valid setType, so no clusterSize
      expect(retrieved.containsKey('clusterRestSec'), false); // No valid setType, so no clusterRestSec
      expect(retrieved.containsKey('clusterTotalReps'), false); // No valid setType, so no clusterTotalReps
    });

    test('preferences version notifier', () async {
      await prefsService.init();
      
      int changeCount = 0;
      prefsService.prefsVersion.addListener(() {
        changeCount++;
      });
      
      // Make some changes
      await prefsService.setHapticsEnabled(false);
      await prefsService.setTempoCuesEnabled(false);
      await prefsService.setDefaultUnit('lb');
      
      // Should have been notified 3 times
      expect(changeCount, 3);
    });

    test('clear all sticky preferences', () async {
      await prefsService.init();
      
      // Set some sticky data
      await prefsService.setStickyFor('exercise1', {'unit': 'kg'});
      await prefsService.setStickyFor('exercise2', {'unit': 'lb'});
      
      // Verify they exist
      expect(prefsService.getStickyFor('exercise1')['unit'], 'kg');
      expect(prefsService.getStickyFor('exercise2')['unit'], 'lb');
      
      // Clear all sticky
      await prefsService.clearAllSticky();
      
      // Verify they're gone
      expect(prefsService.getStickyFor('exercise1').isEmpty, true);
      expect(prefsService.getStickyFor('exercise2').isEmpty, true);
    });
  });
}
