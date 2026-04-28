import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/labkit/lab_work.dart';
import '../../models/labkit/biomarker_result.dart';
import 'lab_pii_detector.dart';
import 'lab_pdf_extractor.dart';
import 'lab_ocr_service.dart';
import 'lab_biomarker_extractor.dart';
import 'lab_dictionary_mapper.dart';

/// Orchestrates the full lab-work pipeline:
///   pick file → extract text → strip PII → extract biomarkers
///   → map to dictionary → encrypt + store → audit log
///
/// Safety invariants enforced here:
///   - LabPiiDetector.strip() always runs before any LLM call.
///   - insert_lab_work RPC encrypts before persisting (server-side).
///   - get_lab_detail RPC inserts an audit row on every read.
///   - delete_lab_work RPC performs a hard delete (GDPR).
class LabWorkService {
  static final LabWorkService _instance = LabWorkService._();
  factory LabWorkService() => _instance;
  LabWorkService._();

  final _supabase = Supabase.instance.client;
  final _ocr = LabOcrService();
  final _extractor = LabBiomarkerExtractor();
  final _mapper = LabDictionaryMapper();

  // ---------------------------------------------------------------------------
  // Upload pipeline
  // ---------------------------------------------------------------------------

  /// Full pipeline for a PDF file upload.
  ///
  /// Returns the new [LabWork.id] on success.
  Future<UploadResult> uploadPdf(
    File pdfFile,
    DateTime labDate, {
    List<String> knownNames = const [],
    String sex = 'male',
    String? storageUrl,
  }) async {
    try {
      // 1. Extract text
      final rawText = await LabPdfExtractor.extractText(pdfFile);
      if (rawText.isEmpty) {
        return UploadResult.failed('Could not extract text from PDF. '
            'If the PDF is scanned, try uploading a photo instead.');
      }

      return _runPipeline(
        rawText: rawText,
        source: 'pdf',
        labDate: labDate,
        knownNames: knownNames,
        sex: sex,
        storageUrl: storageUrl,
      );
    } on LabPdfExtractionException catch (e) {
      return UploadResult.failed(e.message);
    } catch (e) {
      developer.log('uploadPdf error: $e', name: 'labkit.service');
      return UploadResult.failed('Upload failed. Please try again.');
    }
  }

  /// Full pipeline for a photo upload (Gemini Vision OCR).
  Future<UploadResult> uploadPhoto(
    Uint8List imageBytes,
    DateTime labDate, {
    List<String> knownNames = const [],
    String sex = 'male',
    String? storageUrl,
  }) async {
    try {
      final ocrResult = await _ocr.extractFromImage(imageBytes);
      if (!ocrResult.ok) {
        return UploadResult.failed(
            'Photo OCR failed: ${ocrResult.error}. '
            'Ensure the image is clear and well-lit.');
      }

      return _runPipeline(
        rawText: ocrResult.text,
        source: 'photo',
        labDate: labDate,
        knownNames: knownNames,
        sex: sex,
        storageUrl: storageUrl,
      );
    } catch (e) {
      developer.log('uploadPhoto error: $e', name: 'labkit.service');
      return UploadResult.failed('Upload failed. Please try again.');
    }
  }

  Future<UploadResult> _runPipeline({
    required String rawText,
    required String source,
    required DateTime labDate,
    required List<String> knownNames,
    required String sex,
    String? storageUrl,
  }) async {
    // 2. Strip PII (always before LLM)
    final sanitized = LabPiiDetector.strip(rawText, knownNames: knownNames);

    // 3. Extract biomarkers via LLM
    final extracted = await _extractor.extract(sanitized, knownNames: knownNames);
    if (extracted.isEmpty) {
      return UploadResult.failed(
          'No biomarkers could be extracted from this document. '
          'Ensure it is a standard lab report.');
    }

    // 4. Map to dictionary
    final mapped = await _mapper.map(extracted, sex: sex);

    // 5. Store via RPC (server-side encryption + audit)
    final biomarkersJson = mapped.map((b) => b.toJson()).toList();
    final newId = await _supabase.rpc('insert_lab_work', params: {
      'p_lab_date': labDate.toIso8601String().split('T').first,
      'p_source': source,
      if (storageUrl != null) 'p_raw_pdf_url': storageUrl,
      'p_biomarkers_json': biomarkersJson,
    }) as String;

    final needsReviewCount = mapped.where((b) => b.needsReview).length;
    developer.log(
      'LabWorkService: stored $newId — ${mapped.length} markers, '
      '$needsReviewCount need review',
      name: 'labkit.service',
    );

    return UploadResult.success(
      labWorkId: newId,
      biomarkerCount: mapped.length,
      needsReviewCount: needsReviewCount,
    );
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Returns the authenticated user's lab list (metadata only, no decryption).
  /// Audit-logged server-side via list_my_labs().
  Future<List<LabWork>> listMyLabs() async {
    final rows = await _supabase.rpc('list_my_labs') as List;
    return rows
        .map((r) => LabWork.fromListJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Returns full lab detail with decrypted biomarkers.
  /// Audit-logged server-side via get_lab_detail().
  Future<LabWork> getLabDetail(String labWorkId) async {
    final result = await _supabase
        .rpc('get_lab_detail', params: {'p_lab_work_id': labWorkId});
    return LabWork.fromDetailJson(result as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // Consent management
  // ---------------------------------------------------------------------------

  Future<void> grantCoachConsent(String labWorkId, String coachUserId) async {
    await _supabase.rpc('grant_lab_consent', params: {
      'p_lab_work_id': labWorkId,
      'p_coach_user_id': coachUserId,
    });
  }

  Future<void> revokeCoachConsent(
      String labWorkId, String coachUserId) async {
    await _supabase.rpc('revoke_lab_consent', params: {
      'p_lab_work_id': labWorkId,
      'p_coach_user_id': coachUserId,
    });
  }

  /// Returns active consent grants for the given lab (client view).
  Future<List<Map<String, dynamic>>> getConsentGrants(
      String labWorkId) async {
    final rows = await _supabase
        .from('lab_consent_grants')
        .select('id, coach_user_id, granted_at')
        .eq('lab_work_id', labWorkId)
        .isFilter('revoked_at', null);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  // ---------------------------------------------------------------------------
  // Delete (GDPR hard delete)
  // ---------------------------------------------------------------------------

  Future<void> deleteLab(String labWorkId) async {
    await _supabase
        .rpc('delete_lab_work', params: {'p_lab_work_id': labWorkId});
  }

  // ---------------------------------------------------------------------------
  // Coach view
  // ---------------------------------------------------------------------------

  /// Coach fetches a specific client lab (consent-checked + audited server-side).
  Future<LabWork> getLabForCoach(String labWorkId) async {
    return getLabDetail(labWorkId);
  }

  /// Returns consented labs visible to this coach for a given client.
  Future<List<LabWork>> getConsentedLabsForClient(String clientUserId) async {
    final rows = await _supabase
        .from('lab_consent_grants')
        .select('lab_work_id, lab_work(id, lab_date, source, parsed_at, created_at)')
        .eq('coach_user_id', _supabase.auth.currentUser!.id)
        .isFilter('revoked_at', null);

    return (rows as List).map((r) {
      final lw = r['lab_work'] as Map<String, dynamic>;
      return LabWork.fromListJson(lw);
    }).toList();
  }
}

class UploadResult {
  const UploadResult._({
    required this.ok,
    this.labWorkId,
    this.biomarkerCount = 0,
    this.needsReviewCount = 0,
    this.error,
  });

  factory UploadResult.success({
    required String labWorkId,
    required int biomarkerCount,
    int needsReviewCount = 0,
  }) =>
      UploadResult._(
        ok: true,
        labWorkId: labWorkId,
        biomarkerCount: biomarkerCount,
        needsReviewCount: needsReviewCount,
      );

  factory UploadResult.failed(String error) =>
      UploadResult._(ok: false, error: error);

  final bool ok;
  final String? labWorkId;
  final int biomarkerCount;
  final int needsReviewCount;
  final String? error;
}
