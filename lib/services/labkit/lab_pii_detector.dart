import 'dart:developer' as developer;
import '../ai/pii_sanitizer.dart';

/// Lab-specific PII stripping layer on top of VAULT's PiiSanitizer.
///
/// Handles structured PII that appears in lab report headers — patient name
/// fields, MRN, ordering physician, address lines — before the extracted
/// text is sent to any LLM endpoint.
///
/// Contract: only biomarker text (name, value, unit, reference range) should
/// survive. No patient-identifying context goes upstream.
class LabPiiDetector {
  LabPiiDetector._();

  // "Patient Name: John Doe" / "Patient: John Doe"
  static final RegExp _patientNameLabel = RegExp(
    r'(?:Patient\s*(?:Name)?|Name)\s*:\s*([^\n\r,;]+)',
    caseSensitive: false,
  );

  // "DOB: ..." / "Date of Birth: ..."
  static final RegExp _dobLabel = RegExp(
    r'(?:D\.?O\.?B\.?|Date\s+of\s+Birth)\s*:\s*[^\n\r]+',
    caseSensitive: false,
  );

  // MRN / Patient ID / Accession Number
  static final RegExp _mrnLabel = RegExp(
    r'(?:MRN|Patient\s*I\.?D\.?|Accession(?:\s*No\.?)?|Chart\s*(?:No\.?|#)?)\s*[:#]?\s*\S+',
    caseSensitive: false,
  );

  // "Ordering Physician: Dr. Jane Smith" / "Referring: ..."
  static final RegExp _physicianLabel = RegExp(
    r'(?:Ordering|Referring|Attending|Provider|Physician|Doctor|Dr\.?)\s*(?:Physician|Provider|Name)?\s*:\s*[^\n\r]+',
    caseSensitive: false,
  );

  // Street addresses: "123 Main St", "456 Oak Ave, City, ST 12345"
  static final RegExp _streetAddress = RegExp(
    r'\b\d{1,5}\s+[A-Za-z][A-Za-z0-9\s]{3,40}(?:St|Ave|Blvd|Dr|Rd|Ln|Ct|Way|Pl)\.?(?:\s*,\s*[^\n\r]{0,60})?\b',
    caseSensitive: false,
  );

  // Phone numbers already handled by PiiSanitizer; duplicate fax labels
  static final RegExp _faxLabel = RegExp(
    r'(?:Fax|Tel|Phone)\s*(?:No\.?|#)?\s*:\s*[\d\s\-().+]+',
    caseSensitive: false,
  );

  /// Strip lab-header PII from [rawText] and run through VAULT's PiiSanitizer.
  ///
  /// [knownNames] should include the authenticated user's full name and any
  /// coach name in context — forwarded verbatim to [PiiSanitizer.sanitize].
  ///
  /// Returns the sanitized text, safe to pass to an LLM.
  static String strip(String rawText, {List<String> knownNames = const []}) {
    if (rawText.isEmpty) return rawText;

    var out = rawText;

    // Extract patient names from labels BEFORE the name tokens are lost,
    // so we can add them to knownNames for PiiSanitizer.
    final extractedNames = <String>[];
    for (final m in _patientNameLabel.allMatches(out)) {
      final candidate = m.group(1)?.trim() ?? '';
      if (candidate.isNotEmpty) extractedNames.add(candidate);
    }

    // Replace labelled PII fields with placeholders.
    out = out.replaceAll(_patientNameLabel, '[redacted-patient-name]');
    out = out.replaceAll(_dobLabel, '[redacted-dob]');
    out = out.replaceAll(_mrnLabel, '[redacted-mrn]');
    out = out.replaceAll(_physicianLabel, '[redacted-physician]');
    out = out.replaceAll(_streetAddress, '[redacted-address]');
    out = out.replaceAll(_faxLabel, '[redacted-contact]');

    // Pass through VAULT's generic PiiSanitizer with all known names.
    final allNames = [...knownNames, ...extractedNames];
    out = PiiSanitizer.sanitizeAndAssert(
      out,
      knownNames: allNames,
      site: 'LabPiiDetector.strip',
    );

    developer.log(
      'LabPiiDetector: stripped ${rawText.length - out.length} chars of PII',
      name: 'labkit.pii_detector',
    );

    return out;
  }

  /// Returns true if [text] still appears to contain raw patient identifiers
  /// after stripping — used as a pre-send safety gate.
  static bool hasSuspectedPii(String text) {
    return _patientNameLabel.hasMatch(text) ||
        _mrnLabel.hasMatch(text) ||
        _physicianLabel.hasMatch(text);
  }
}
