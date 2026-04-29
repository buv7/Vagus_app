import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// OCR service for lab-work photos.
///
/// BRAIN dependency note: when BRAIN's ai_client.dart exposes a
/// `visionExtract(imageBytes, prompt)` method, replace _analyzeWithGemini
/// with a BRAIN call. Until then, this service calls Gemini Vision directly
/// using the same key as FoodVisionService.
///
/// The prompt instructs Gemini to return ONLY tabular lab data —
/// no patient names, no DOBs, no physician names. The caller must also
/// run LabPiiDetector.strip() on the returned text before using it.
class LabOcrService {
  static final LabOcrService _instance = LabOcrService._();
  factory LabOcrService() => _instance;
  LabOcrService._();

  GenerativeModel? _model;
  bool _initialized = false;

  static const String _extractionPrompt = '''
You are processing a medical lab report image.

Your ONLY task: extract the laboratory test data table.
Return ONLY the following structure as plain text (no JSON, no markdown):

TEST NAME | VALUE | UNIT | REFERENCE RANGE | FLAG
----------------------------------------------------
[one row per biomarker]

Rules (NON-NEGOTIABLE):
- Do NOT include patient name, date of birth, MRN, physician name, address, or any patient identifier.
- Do NOT include the lab facility name or logo text.
- Do NOT interpret results. Do NOT say "high" or "low" in plain language — use only H, L, or leave blank.
- If a value is a text result (e.g. "Negative", "Reactive"), include it as-is.
- If you cannot read a value clearly, write "UNREADABLE" in that cell.
- Output only the table. No preamble. No explanations. No diagnosis.
''';

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      developer.log(
        'GEMINI_API_KEY not set — OCR unavailable',
        name: 'labkit.ocr',
      );
      return;
    }
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(temperature: 0.0),
      );
      _initialized = true;
    } catch (e) {
      developer.log('LabOcrService init error: $e', name: 'labkit.ocr');
    }
  }

  /// OCR a lab-work image and return raw extracted table text.
  ///
  /// The caller is responsible for running [LabPiiDetector.strip] on the result
  /// before passing it to [LabBiomarkerExtractor].
  Future<OcrResult> extractFromImage(Uint8List imageBytes) async {
    await _ensureInitialized();

    if (_model == null) {
      return OcrResult.failed('Gemini not configured');
    }

    try {
      final content = Content.multi([
        TextPart(_extractionPrompt),
        DataPart('image/jpeg', imageBytes),
      ]);

      final response = await _model!.generateContent([content]);
      final text = response.text ?? '';

      if (text.trim().isEmpty) {
        return OcrResult.failed('Empty OCR response');
      }

      developer.log(
        'LabOcrService: extracted ${text.length} chars',
        name: 'labkit.ocr',
      );

      return OcrResult.success(text);
    } catch (e) {
      debugPrint('LabOcrService error: $e');
      return OcrResult.failed('OCR failed: $e');
    }
  }

  bool get isAvailable => _initialized && _model != null;
}

class OcrResult {
  const OcrResult._({required this.text, required this.ok, this.error});

  factory OcrResult.success(String text) =>
      OcrResult._(text: text, ok: true);

  factory OcrResult.failed(String error) =>
      OcrResult._(text: '', ok: false, error: error);

  final String text;
  final bool ok;
  final String? error;
}
