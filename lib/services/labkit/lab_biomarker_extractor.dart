import 'dart:convert';
import 'dart:developer' as developer;
import '../ai/ai_client.dart';
import '../ai/pii_sanitizer.dart';
import '../../models/labkit/biomarker_result.dart';
import 'lab_pii_detector.dart';

/// Sends sanitized lab text to the LLM and parses the structured extraction.
///
/// Safety contract:
///   1. [LabPiiDetector.strip] MUST have run on [sanitizedText] before calling [extract].
///   2. [extract] calls [PiiSanitizer.assertSafe] immediately before the network request.
///   3. The prompt explicitly forbids diagnosis language.
///   4. No raw PDF or unfiltered patient text is ever forwarded.
class LabBiomarkerExtractor {
  static final LabBiomarkerExtractor _instance =
      LabBiomarkerExtractor._();
  factory LabBiomarkerExtractor() => _instance;
  LabBiomarkerExtractor._();

  final _ai = AIClient();

  static const String _systemPrompt = '''
You are a structured lab-data parser. Your ONLY job is to extract biomarker rows from the provided text.

Return a JSON array. Each element must have exactly these keys:
{
  "name": "<canonical biomarker name, in English>",
  "raw_value": "<value exactly as it appears in the text>",
  "value": <numeric value as a number, or null if non-numeric>,
  "unit": "<unit string>",
  "reference_range": "<range string as it appears, e.g. 3.5-5.0 or <100>",
  "flag": "<low|normal|high|unknown>"
}

Rules (NON-NEGOTIABLE):
- Return ONLY the JSON array. No preamble, no markdown fences, no explanation.
- Do NOT include patient identifiers (name, DOB, MRN, physician) in any field.
- Do NOT interpret, diagnose, or comment on values. Only extract.
- If a flag is not present in the source text, infer it: if value < lower bound → "low", if > upper bound → "high", otherwise → "normal". If you cannot determine bounds → "unknown".
- If a row is unreadable or has no numeric association, skip it.
''';

  /// Extracts biomarkers from [sanitizedText] (must already be PII-stripped).
  ///
  /// Returns an empty list on LLM failure — callers should handle gracefully.
  Future<List<BiomarkerResult>> extract(
    String sanitizedText, {
    List<String> knownNames = const [],
  }) async {
    if (sanitizedText.trim().isEmpty) return [];

    // Final safety gate — throws PiiViolation if PII still present.
    PiiSanitizer.assertSafe(
      sanitizedText,
      knownNames: knownNames,
      site: 'LabBiomarkerExtractor.extract',
    );

    final messages = PiiSanitizer.sanitizeMessages(
      [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': sanitizedText},
      ],
      knownNames: knownNames,
    );

    try {
      final rawResponse = await _ai.chat(
        model: 'google/gemini-flash-1.5',
        messages: messages,
        options: {'temperature': 0.0, 'max_tokens': 4096},
      );

      return _parseResponse(rawResponse);
    } catch (e) {
      developer.log(
        'LabBiomarkerExtractor: extraction failed — $e',
        name: 'labkit.extractor',
      );
      return [];
    }
  }

  List<BiomarkerResult> _parseResponse(String rawResponse) {
    final jsonText = _extractJson(rawResponse);
    if (jsonText == null) return [];

    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! List) return [];

      final results = <BiomarkerResult>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        try {
          results.add(BiomarkerResult.fromJson(item));
        } catch (_) {
          // skip malformed rows
        }
      }

      developer.log(
        'LabBiomarkerExtractor: parsed ${results.length} biomarkers',
        name: 'labkit.extractor',
      );
      return results;
    } catch (e) {
      developer.log(
        'LabBiomarkerExtractor: JSON parse error — $e',
        name: 'labkit.extractor',
      );
      return [];
    }
  }

  String? _extractJson(String text) {
    // Direct parse
    try {
      jsonDecode(text);
      return text;
    } catch (_) {}

    // Strip markdown fences
    final fenceMatch =
        RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(text);
    if (fenceMatch != null) {
      try {
        jsonDecode(fenceMatch.group(1)!);
        return fenceMatch.group(1);
      } catch (_) {}
    }

    // Find first '[' ... ']' block
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start != -1 && end > start) {
      final candidate = text.substring(start, end + 1);
      try {
        jsonDecode(candidate);
        return candidate;
      } catch (_) {}
    }

    return null;
  }
}
