import 'dart:developer' as developer;

/// PiiSanitizer — required wrapper for any payload sent to a third-party LLM
/// (Cerebras, Groq, Gemini, OpenRouter, etc.) or to an analytics sink.
///
/// VAULT enforces this in CI: any new call site that hits an LLM endpoint
/// without routing through one of the [sanitize], [sanitizeMessages], or
/// [assertSafe] entry points will fail the build.
///
/// Two layers:
///   1. [sanitize] performs scrubs (regex-based redaction of obvious PII).
///   2. [assertSafe] panics if the resulting text still contains a forbidden
///      combination — most importantly, full name + DOB in the same payload.
///
/// The forbidden combinations come from the project's medical-data and child-
/// safety guards (see COORDINATION_PROTOCOL.md).
class PiiSanitizer {
  PiiSanitizer._();

  // ---------------------------------------------------------------------------
  // Patterns
  // ---------------------------------------------------------------------------

  // Email — RFC-5322-lite, not perfect but catches the realistic shapes.
  static final RegExp _email = RegExp(
    r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}',
  );

  // Phone — international-ish. Catches +1 555 555 5555, 555-555-5555,
  // (555) 555-5555, +964 750 123 4567, etc. Deliberately conservative on
  // 7-digit-only sequences to avoid false positives on biomarker values.
  static final RegExp _phone = RegExp(
    r'(?:\+?\d{1,3}[\s\-.]?)?(?:\(\d{2,4}\)|\d{2,4})[\s\-.]?\d{3,4}[\s\-.]?\d{3,4}',
  );

  // Date of birth — many shapes. We match anything that *looks* like a date
  // because in an LLM payload we don't know context.
  // - 1990-05-12, 1990/05/12
  // - 12-05-1990, 12/05/1990
  // - May 12, 1990
  // - 12 May 1990
  static final RegExp _dobNumeric = RegExp(
    r'\b(?:19|20)\d{2}[\-/.](?:0?[1-9]|1[0-2])[\-/.](?:0?[1-9]|[12]\d|3[01])\b'
    r'|\b(?:0?[1-9]|[12]\d|3[01])[\-/.](?:0?[1-9]|1[0-2])[\-/.](?:19|20)\d{2}\b',
  );
  static final RegExp _dobMonthName = RegExp(
    r'\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{1,2},?\s+(?:19|20)\d{2}\b'
    r'|\b\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+(?:19|20)\d{2}\b',
    caseSensitive: false,
  );

  // US SSN, generic 9-digit national IDs, MRN-like sequences.
  static final RegExp _ssnLike = RegExp(r'\b\d{3}-\d{2}-\d{4}\b');
  static final RegExp _longId = RegExp(r'\b\d{9,12}\b');

  // Credit card (very loose — we redact anything that looks like 13–19 digits
  // grouped as cards usually are). We do NOT do Luhn here; better to over-
  // redact than under-redact for the LLM payload.
  static final RegExp _creditCard = RegExp(
    r'\b(?:\d[ \-]?){13,19}\b',
  );

  // Name detection is the hardest part. We do not try to detect arbitrary
  // names from free text (impossible without a model). Instead, the caller
  // passes [knownNames] when sanitizing — typically the user's full_name from
  // the profile and the coach's full_name. We strip those out by token.
  // For the assertSafe check we use [knownNames] together with date detection
  // to enforce the name+DOB rule.

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Sanitize a single string for transmission to an LLM or analytics sink.
  ///
  /// [knownNames] should include any human full-names that the caller knows
  /// about — typically the profile's `full_name` field for the current user
  /// and (if applicable) the coach. Names are removed token-by-token.
  ///
  /// Returns a sanitized copy. Does not mutate the input.
  static String sanitize(
    String input, {
    List<String> knownNames = const [],
  }) {
    if (input.isEmpty) return input;
    var out = input;

    // Order matters: scrub structured tokens first, then names.
    out = out.replaceAll(_email, '[redacted-email]');
    out = out.replaceAll(_creditCard, '[redacted-card]');
    out = out.replaceAll(_ssnLike, '[redacted-id]');
    out = out.replaceAll(_phone, '[redacted-phone]');
    out = out.replaceAll(_dobMonthName, '[redacted-date]');
    out = out.replaceAll(_dobNumeric, '[redacted-date]');
    out = out.replaceAll(_longId, '[redacted-id]');

    for (final name in knownNames) {
      final cleaned = name.trim();
      if (cleaned.isEmpty) continue;
      // Remove the full name as a single token first.
      out = _replaceWordBoundary(out, cleaned, '[redacted-name]');
      // Then remove individual name parts (first, middle, last).
      for (final part in cleaned.split(RegExp(r'\s+'))) {
        if (part.length < 2) continue; // skip initials and noise
        out = _replaceWordBoundary(out, part, '[redacted-name]');
      }
    }

    return out;
  }

  /// Sanitize an OpenAI-style messages list in place: each message's
  /// `content` is replaced with a sanitized version. The list itself is
  /// not mutated; a new list is returned.
  static List<Map<String, String>> sanitizeMessages(
    List<Map<String, String>> messages, {
    List<String> knownNames = const [],
  }) {
    return messages
        .map((m) => {
              ...m,
              if (m.containsKey('content'))
                'content': sanitize(m['content'] ?? '', knownNames: knownNames),
            })
        .toList(growable: false);
  }

  /// Throws [PiiViolation] if [input] still contains a forbidden combination
  /// after sanitization. Specifically: any of the [knownNames] together with
  /// anything that looks like a date in the same payload.
  ///
  /// Call this immediately before dispatching a network request to an LLM.
  ///
  /// In debug builds, this is a hard assertion. In release builds, the
  /// violation is logged via [developer.log] (which Crashlytics / Sentry can
  /// pick up) and the call is allowed to proceed — VAULT prefers a logged
  /// alert over a hard crash in production. The CI lint catches the issue
  /// before it ever reaches a user.
  static void assertSafe(
    String input, {
    List<String> knownNames = const [],
    String? site,
  }) {
    final hasDate = _dobNumeric.hasMatch(input) || _dobMonthName.hasMatch(input);
    final hasName = knownNames.any((n) {
      final cleaned = n.trim();
      if (cleaned.isEmpty) return false;
      if (_containsWordBoundary(input, cleaned)) return true;
      // any individual name token of length >= 3
      return cleaned
          .split(RegExp(r'\s+'))
          .any((p) => p.length >= 3 && _containsWordBoundary(input, p));
    });

    if (hasName && hasDate) {
      final violation = PiiViolation(
        kind: PiiViolationKind.nameAndDate,
        site: site ?? 'unknown',
        message:
            'Payload contains both a known name and a date — forbidden by VAULT '
            'policy (medical / child-safety guard). Sanitize before sending.',
      );
      assert(false, violation.toString());
      developer.log(
        violation.toString(),
        name: 'vault.pii_sanitizer',
        level: 1000, // SEVERE
      );
      throw violation;
    }
  }

  /// Convenience: sanitize then assert. Returns the sanitized string.
  /// This is the recommended entry point for new code.
  static String sanitizeAndAssert(
    String input, {
    List<String> knownNames = const [],
    String? site,
  }) {
    final sanitized = sanitize(input, knownNames: knownNames);
    assertSafe(sanitized, knownNames: knownNames, site: site);
    return sanitized;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _replaceWordBoundary(String haystack, String needle, String replacement) {
    if (needle.isEmpty) return haystack;
    final escaped = RegExp.escape(needle);
    final pattern = RegExp('\\b$escaped\\b', caseSensitive: false);
    return haystack.replaceAll(pattern, replacement);
  }

  static bool _containsWordBoundary(String haystack, String needle) {
    if (needle.isEmpty) return false;
    final escaped = RegExp.escape(needle);
    final pattern = RegExp('\\b$escaped\\b', caseSensitive: false);
    return pattern.hasMatch(haystack);
  }
}

enum PiiViolationKind { nameAndDate }

class PiiViolation implements Exception {
  PiiViolation({
    required this.kind,
    required this.site,
    required this.message,
  });

  final PiiViolationKind kind;
  final String site;
  final String message;

  @override
  String toString() => 'PiiViolation[$kind @ $site]: $message';
}
