// Guard test: fails CI if any source file under lib/ contains the literal
// `'current_user_id'` placeholder string. The real user ID must come from
// `AuthContext.currentUserId` (lib/services/auth/auth_context.dart).
//
// This stands in for a custom_lint rule — same outcome, no extra dependency.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no `current_user_id` literal placeholders in lib/', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib/ must exist');

    final offenders = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Match the string literal in either quote style.
        if (line.contains("'current_user_id'") ||
            line.contains('"current_user_id"')) {
          offenders.add('${entity.path}:${i + 1}: $line');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Found `current_user_id` placeholder(s). Use AuthContext.currentUserId '
          '(lib/services/auth/auth_context.dart) instead:\n${offenders.join('\n')}',
    );
  });
}
