import 'package:flutter/material.dart';
import 'notification_helper.dart';
import 'onesignal_service.dart';

/// Test class for demonstrating notification functionality
/// This can be used during development to test notifications
class NotificationTest {
  static final NotificationTest _instance = NotificationTest._();
  static NotificationTest get instance => _instance;
  NotificationTest._();

  /// Test basic notification functionality
  Future<void> testBasicNotification() async {
    try {
      // Test sending a notification to the current user
      final currentUser = OneSignalService.instance.currentPlayerId;
      if (currentUser == null) {
        debugPrint('❌ No current user for testing');
        return;
      }

      final success = await NotificationHelper.instance.sendToUser(
        userId: currentUser,
        title: 'Test Notification',
        message: 'This is a test notification from VAGUS',
        route: '/test',
        screen: 'test',
        additionalData: {
          'type': 'test',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (success) {
        debugPrint('✅ Test notification sent successfully');
      } else {
        debugPrint('❌ Test notification failed');
      }
    } catch (e) {
      debugPrint('❌ Test notification error: $e');
    }
  }

  /// Test message notification
  Future<void> testMessageNotification() async {
    try {
      final currentUser = OneSignalService.instance.currentPlayerId;
      if (currentUser == null) {
        debugPrint('❌ No current user for testing');
        return;
      }

      final success = await NotificationHelper.instance.sendMessageNotification(
        recipientId: currentUser,
        senderName: 'Test Coach',
        message: 'Great progress on your workout today!',
        threadId: 'test-thread-123',
      );

      if (success) {
        debugPrint('✅ Test message notification sent successfully');
      } else {
        debugPrint('❌ Test message notification failed');
      }
    } catch (e) {
      debugPrint('❌ Test message notification error: $e');
    }
  }

  /// Test workout plan notification
  Future<void> testWorkoutNotification() async {
    try {
      final currentUser = OneSignalService.instance.currentPlayerId;
      if (currentUser == null) {
        debugPrint('❌ No current user for testing');
        return;
      }

      final success = await NotificationHelper.instance.sendWorkoutNotification(
        clientId: currentUser,
        coachName: 'Coach Sarah',
        planName: 'Beginner Strength Program',
        planId: 'workout-plan-456',
      );

      if (success) {
        debugPrint('✅ Test workout notification sent successfully');
      } else {
        debugPrint('❌ Test workout notification failed');
      }
    } catch (e) {
      debugPrint('❌ Test workout notification error: $e');
    }
  }

  /// Test nutrition plan notification
  Future<void> testNutritionNotification() async {
    try {
      final currentUser = OneSignalService.instance.currentPlayerId;
      if (currentUser == null) {
        debugPrint('❌ No current user for testing');
        return;
      }

      final success = await NotificationHelper.instance.sendNutritionNotification(
        clientId: currentUser,
        coachName: 'Coach Mike',
        planName: 'Mediterranean Diet Plan',
        planId: 'nutrition-plan-789',
      );

      if (success) {
        debugPrint('✅ Test nutrition notification sent successfully');
      } else {
        debugPrint('❌ Test nutrition notification failed');
      }
    } catch (e) {
      debugPrint('❌ Test nutrition notification error: $e');
    }
  }

  /// Test calendar reminder notification
  Future<void> testCalendarNotification() async {
    try {
      final currentUser = OneSignalService.instance.currentPlayerId;
      if (currentUser == null) {
        debugPrint('❌ No current user for testing');
        return;
      }

      final success = await NotificationHelper.instance.sendCalendarReminder(
        userId: currentUser,
        eventTitle: 'Workout Session',
        eventTime: DateTime.now().add(const Duration(hours: 1)),
        eventId: 'event-101',
      );

      if (success) {
        debugPrint('✅ Test calendar notification sent successfully');
      } else {
        debugPrint('❌ Test calendar notification failed');
      }
    } catch (e) {
      debugPrint('❌ Test calendar notification error: $e');
    }
  }

  /// Test role-based notification
  Future<void> testRoleNotification() async {
    try {
      final success = await NotificationHelper.instance.sendToRole(
        role: 'coach',
        title: 'System Update',
        message: 'New coaching features are now available!',
        route: '/coach-features',
        screen: 'coach_features',
      );

      if (success) {
        debugPrint('✅ Test role notification sent successfully');
      } else {
        debugPrint('❌ Test role notification failed');
      }
    } catch (e) {
      debugPrint('❌ Test role notification error: $e');
    }
  }

  /// Test topic notification
  Future<void> testTopicNotification() async {
    try {
      final success = await NotificationHelper.instance.sendToTopic(
        topic: 'all-users',
        title: 'App Update',
        message: 'VAGUS has been updated with new features!',
        route: '/whats-new',
        screen: 'whats_new',
      );

      if (success) {
        debugPrint('✅ Test topic notification sent successfully');
      } else {
        debugPrint('❌ Test topic notification failed');
      }
    } catch (e) {
      debugPrint('❌ Test topic notification error: $e');
    }
  }

  /// Test OneSignal service features
  Future<void> testOneSignalFeatures() async {
    try {
      // Test topic subscription
      await OneSignalService.instance.subscribeToTopic('test-topic');
      debugPrint('✅ Subscribed to test-topic');

      // Test user tags
      await OneSignalService.instance.addUserTag('test-user', 'true');
      debugPrint('✅ Added test user tag');

      // Test in-app message
      await OneSignalService.instance.sendInAppMessage('Testing in-app messaging');
      debugPrint('✅ Sent test in-app message');

    } catch (e) {
      debugPrint('❌ Test OneSignal features error: $e');
    }
  }

  /// Run all tests
  Future<void> runAllTests() async {
    debugPrint('🧪 Starting notification tests...');
    
    await testBasicNotification();
    await Future.delayed(const Duration(seconds: 2));
    
    await testMessageNotification();
    await Future.delayed(const Duration(seconds: 2));
    
    await testWorkoutNotification();
    await Future.delayed(const Duration(seconds: 2));
    
    await testNutritionNotification();
    await Future.delayed(const Duration(seconds: 2));
    
    await testCalendarNotification();
    await Future.delayed(const Duration(seconds: 2));
    
    await testRoleNotification();
    await Future.delayed(const Duration(seconds: 2));
    
    await testTopicNotification();
    await Future.delayed(const Duration(seconds: 2));
    
    await testOneSignalFeatures();
    
    debugPrint('🧪 All notification tests completed!');
  }

  /// Get current OneSignal status
  Map<String, dynamic> getStatus() {
    return {
      'initialized': OneSignalService.instance.isInitialized,
      'currentPlayerId': OneSignalService.instance.currentPlayerId,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Widget for testing notifications in the UI
class NotificationTestWidget extends StatefulWidget {
  const NotificationTestWidget({super.key});

  @override
  State<NotificationTestWidget> createState() => _NotificationTestWidgetState();
}

class _NotificationTestWidgetState extends State<NotificationTestWidget> {
  bool _isRunning = false;
  String _status = 'Ready';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notification Testing',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Status: $_status',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : _runAllTests,
                    child: Text(_isRunning ? 'Running...' : 'Run All Tests'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : _runBasicTest,
                    child: const Text('Basic Test'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : _runMessageTest,
                    child: const Text('Message Test'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : _runWorkoutTest,
                    child: const Text('Workout Test'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : _runNutritionTest,
                    child: const Text('Nutrition Test'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : _runCalendarTest,
                    child: const Text('Calendar Test'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : _runRoleTest,
                    child: const Text('Role Test'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : _runTopicTest,
                    child: const Text('Topic Test'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isRunning ? null : _runOneSignalTest,
              child: const Text('OneSignal Features Test'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunning = true;
      _status = 'Running all tests...';
    });

    try {
      await NotificationTest.instance.runAllTests();
      setState(() {
        _status = 'All tests completed successfully!';
      });
    } catch (e) {
      setState(() {
        _status = 'Tests failed: $e';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _runBasicTest() async {
    await _runTest('Basic notification test', () => NotificationTest.instance.testBasicNotification());
  }

  Future<void> _runMessageTest() async {
    await _runTest('Message notification test', () => NotificationTest.instance.testMessageNotification());
  }

  Future<void> _runWorkoutTest() async {
    await _runTest('Workout notification test', () => NotificationTest.instance.testWorkoutNotification());
  }

  Future<void> _runNutritionTest() async {
    await _runTest('Nutrition notification test', () => NotificationTest.instance.testNutritionNotification());
  }

  Future<void> _runCalendarTest() async {
    await _runTest('Calendar notification test', () => NotificationTest.instance.testCalendarNotification());
  }

  Future<void> _runRoleTest() async {
    await _runTest('Role notification test', () => NotificationTest.instance.testRoleNotification());
  }

  Future<void> _runTopicTest() async {
    await _runTest('Topic notification test', () => NotificationTest.instance.testTopicNotification());
  }

  Future<void> _runOneSignalTest() async {
    await _runTest('OneSignal features test', () => NotificationTest.instance.testOneSignalFeatures());
  }

  Future<void> _runTest(String testName, Future<void> Function() testFunction) async {
    setState(() {
      _isRunning = true;
      _status = 'Running $testName...';
    });

    try {
      await testFunction();
      setState(() {
        _status = '$testName completed successfully!';
      });
    } catch (e) {
      setState(() {
        _status = '$testName failed: $e';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }
}
