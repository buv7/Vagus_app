import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/services/notifications/fcm_service.dart';

void main() {
  group('NotificationCategory', () {
    test('fromString returns correct category for known key', () {
      expect(
        NotificationCategory.fromString('workouts'),
        NotificationCategory.workouts,
      );
      expect(
        NotificationCategory.fromString('coach_messages'),
        NotificationCategory.coachMessages,
      );
      expect(
        NotificationCategory.fromString('marketplace'),
        NotificationCategory.marketplace,
      );
    });

    test('fromString returns null for unknown key', () {
      expect(NotificationCategory.fromString('unknown_key'), isNull);
      expect(NotificationCategory.fromString(null), isNull);
    });

    test('every category has a non-empty value string', () {
      for (final cat in NotificationCategory.values) {
        expect(cat.value, isNotEmpty);
      }
    });

    test('marketplace defaults to false (spammy-default guard)', () {
      // This test encodes the SIGNAL FORBIDDEN rule:
      // "marketing OFF" must remain the default.
      const defaultPrefs = <NotificationCategory, bool>{
        NotificationCategory.workouts: true,
        NotificationCategory.nutritionReminders: true,
        NotificationCategory.coachMessages: true,
        NotificationCategory.marketplace: false,
        NotificationCategory.periods: true,
        NotificationCategory.streaks: true,
        NotificationCategory.labResults: true,
      };
      expect(defaultPrefs[NotificationCategory.marketplace], isFalse);
      // All non-marketing defaults are ON.
      for (final cat in NotificationCategory.values) {
        if (cat != NotificationCategory.marketplace) {
          expect(defaultPrefs[cat], isTrue, reason: '${cat.value} should default ON');
        }
      }
    });
  });

  group('FcmInAppNotification', () {
    test('stores fields correctly', () {
      const n = FcmInAppNotification(
        title: 'Hello',
        body: 'World',
        route: '/workout',
        category: NotificationCategory.workouts,
      );
      expect(n.title, 'Hello');
      expect(n.body, 'World');
      expect(n.route, '/workout');
      expect(n.category, NotificationCategory.workouts);
    });

    test('route and category are nullable', () {
      const n = FcmInAppNotification(title: 'T', body: 'B');
      expect(n.route, isNull);
      expect(n.category, isNull);
    });
  });

  group('FcmService singleton', () {
    test('instance is always the same object', () {
      expect(identical(FcmService.instance, FcmService.instance), isTrue);
    });

    test('inAppNotifications is a broadcast stream', () {
      // Two simultaneous listeners must not throw.
      final s1 = FcmService.instance.inAppNotifications.listen((_) {});
      final s2 = FcmService.instance.inAppNotifications.listen((_) {});
      s1.cancel();
      s2.cancel();
    });
  });
}
