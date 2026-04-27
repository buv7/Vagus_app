// Multi-user scope test for AuthContext.
//
// The full integration form of this test signs two real Supabase users in
// back-to-back and asserts that AuthContext.currentUserId reflects the
// active session at each step (i.e. user-scoped reads/writes don't leak
// across sign-out). That requires a Supabase test instance plus two seeded
// test users — credentials supplied via env vars below. When those aren't
// present (default CI), the integration block is skipped with a clear reason
// and the unit-level contract for AuthContext is still exercised.
//
// Env vars consumed when running the integration block:
//   SUPABASE_TEST_URL          - e.g. https://<project>.supabase.co
//   SUPABASE_TEST_ANON_KEY     - anon key for the test project
//   SUPABASE_TEST_USER_A_EMAIL - email of seeded test user A
//   SUPABASE_TEST_USER_A_PASS  - password of test user A
//   SUPABASE_TEST_USER_B_EMAIL - email of seeded test user B
//   SUPABASE_TEST_USER_B_PASS  - password of test user B
//
// TESTBED owns wiring these credentials into the GH Actions runner.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vagus_app/services/auth/auth_context.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthContext contract', () {
    test('currentUserIdOrNull throws when Supabase is not initialized', () {
      // Without Supabase.initialize, instance access throws — AuthContext
      // deliberately does not silently swallow that into null.
      expect(
        () => AuthContext.currentUserIdOrNull,
        throwsA(isA<Error>()),
      );
    });
  });

  group('Two-user scope (integration)', () {
    final url = Platform.environment['SUPABASE_TEST_URL'];
    final anonKey = Platform.environment['SUPABASE_TEST_ANON_KEY'];
    final userAEmail = Platform.environment['SUPABASE_TEST_USER_A_EMAIL'];
    final userAPass = Platform.environment['SUPABASE_TEST_USER_A_PASS'];
    final userBEmail = Platform.environment['SUPABASE_TEST_USER_B_EMAIL'];
    final userBPass = Platform.environment['SUPABASE_TEST_USER_B_PASS'];

    final fixturesPresent = url != null &&
        anonKey != null &&
        userAEmail != null &&
        userAPass != null &&
        userBEmail != null &&
        userBPass != null;

    setUpAll(() async {
      if (!fixturesPresent) return;
      await Supabase.initialize(url: url, anonKey: anonKey);
    });

    test(
      'AuthContext follows the active session across sign-in/sign-out',
      () async {
        final auth = Supabase.instance.client.auth;

        await auth.signInWithPassword(email: userAEmail!, password: userAPass!);
        final idA = AuthContext.currentUserId;
        expect(idA, isNotEmpty);

        await auth.signOut();
        expect(AuthContext.currentUserIdOrNull, isNull);
        expect(() => AuthContext.currentUserId, throwsA(isA<AuthException>()));

        await auth.signInWithPassword(email: userBEmail!, password: userBPass!);
        final idB = AuthContext.currentUserId;
        expect(idB, isNotEmpty);
        expect(idB, isNot(equals(idA)),
            reason: 'User B id must differ from user A — confirms scoping');

        await auth.signOut();
      },
      skip: fixturesPresent
          ? false
          : 'Requires SUPABASE_TEST_URL + test user credentials. TESTBED to '
              'wire env vars in CI.',
    );
  });
}
