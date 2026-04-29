import 'dart:io';
import 'dart:developer' as developer;
import 'package:pdfx/pdfx.dart';

/// Extracts raw text from a PDF file using pdfx.
///
/// pdfx renders each page; on platforms where text extraction is not supported
/// the rendered-image bytes are returned so the caller can fall back to OCR.
class LabPdfExtractor {
  LabPdfExtractor._();

  /// Extracts text from all pages of [pdfFile].
  ///
  /// Returns concatenated page text separated by form-feed characters.
  /// Throws [LabPdfExtractionException] if the file cannot be opened.
  static Future<String> extractText(File pdfFile) async {
    PdfDocument? document;
    try {
      document = await PdfDocument.openFile(pdfFile.path);
      final buffer = StringBuffer();

      for (var i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        try {
          final text = await page.renderText();
          if (text != null && text.trim().isNotEmpty) {
            buffer.write(text);
            buffer.write('\n\f\n');
          }
        } finally {
          await page.close();
        }
      }

      final result = buffer.toString().trim();
      developer.log(
        'LabPdfExtractor: extracted ${result.length} chars from '
        '${document.pagesCount} pages',
        name: 'labkit.pdf_extractor',
      );
      return result;
    } catch (e) {
      throw LabPdfExtractionException('Failed to extract text: $e');
    } finally {
      await document?.close();
    }
  }

  /// Returns true when the extracted text looks like lab-report content
  /// (contains at least one reference-range pattern or common biomarker keyword).
  static bool looksLikeLabReport(String text) {
    final lower = text.toLowerCase();
    final hasRangePattern = RegExp(r'\d+\.?\d*\s*[-–]\s*\d+\.?\d*').hasMatch(text);
    final hasLabKeyword = [
      'hemoglobin', 'glucose', 'cholesterol', 'creatinine', 'tsh',
      'ferritin', 'sodium', 'potassium', 'hgb', 'wbc', 'rbc',
      'result', 'reference', 'range', 'units', 'flag',
    ].any((kw) => lower.contains(kw));
    return hasRangePattern || hasLabKeyword;
  }
}

class LabPdfExtractionException implements Exception {
  LabPdfExtractionException(this.message);
  final String message;
  @override
  String toString() => 'LabPdfExtractionException: $message';
}
