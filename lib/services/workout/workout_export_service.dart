import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../models/workout/analytics_models.dart';

/// Workout analytics export service
///
/// Provides functionality to:
/// - Export reports as PDF
/// - Export charts as images (PNG)
/// - Share reports via email/messaging
/// - Generate printable summaries
class WorkoutExportService {
  /// Export comprehensive report as PDF
  Future<File> exportReportAsPDF(ComprehensiveReport report) async {
    final pdf = pw.Document();

    // Add pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Title page
          _buildPDFTitle(report),
          pw.SizedBox(height: 24),

          // Summary
          _buildPDFSection('Summary', [
            pw.Text(report.summary),
          ]),
          pw.SizedBox(height: 16),

          // Achievements
          if (report.achievements.isNotEmpty)
            _buildPDFSection('Achievements', [
              ...report.achievements.map((achievement) => pw.Row(
                    children: [
                      pw.Text('✓ ', style: const pw.TextStyle(color: PdfColors.green)),
                      pw.Expanded(child: pw.Text(achievement)),
                    ],
                  )),
            ]),
          pw.SizedBox(height: 16),

          // Volume metrics
          _buildPDFSection('Volume Metrics', [
            _buildPDFMetricRow('Total Volume', report.volumeMetrics.totalVolumeDisplay),
            _buildPDFMetricRow('Avg per Session', '${report.volumeMetrics.avgVolumePerSession.toStringAsFixed(0)} kg'),
            _buildPDFMetricRow('Total Sets', report.volumeMetrics.totalSets.toString()),
            _buildPDFMetricRow('Total Reps', report.volumeMetrics.totalReps.toString()),
            pw.SizedBox(height: 8),
            pw.Text('Volume by Muscle Group:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            ...report.volumeMetrics.volumeByMuscleGroup.entries
                .toList()
                ..sort((a, b) => b.value.compareTo(a.value))
                ..take(5)
                ..map((entry) => pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('  ${entry.key.toUpperCase()}'),
                        pw.Text('${entry.value.toStringAsFixed(0)} kg'),
                      ],
                    )),
          ]),
          pw.SizedBox(height: 16),

          // Strength gains
          _buildPDFSection('Strength Gains', [
            _buildPDFMetricRow('Overall Gain', '${report.gainsReport.overallGainPercentage.toStringAsFixed(1)}%'),
            _buildPDFMetricRow('Total PRs', report.gainsReport.totalPRs.toString()),
            if (report.gainsReport.bestGainingExercise.isNotEmpty)
              _buildPDFMetricRow('Best Gaining', report.gainsReport.bestGainingExercise),
            pw.SizedBox(height: 8),
            pw.Text('Top Exercises:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            ...report.gainsReport.gainsByExercise.entries
                .toList()
                ..sort((a, b) => b.value.gainPercentage.compareTo(a.value.gainPercentage))
                ..take(5)
                ..map((entry) => pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(child: pw.Text('  ${entry.key}')),
                        pw.Text('${entry.value.gainPercentage >= 0 ? '+' : ''}${entry.value.gainPercentage.toStringAsFixed(1)}%'),
                      ],
                    )),
          ]),
          pw.SizedBox(height: 16),

          // Training patterns
          _buildPDFSection('Training Patterns', [
            _buildPDFMetricRow('Sessions/Week', report.patterns.avgSessionsPerWeek.toStringAsFixed(1)),
            _buildPDFMetricRow('Consistency Score', '${report.patterns.consistencyScore}/100'),
            _buildPDFMetricRow('Avg Duration', '${report.patterns.avgSessionDuration.toStringAsFixed(0)} min'),
            pw.SizedBox(height: 8),
            pw.Text('Insights:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            ...report.patterns.patterns.map((pattern) => pw.Text('  • $pattern')),
          ]),
          pw.SizedBox(height: 16),

          // Compliance
          _buildPDFSection('Compliance', [
            _buildPDFMetricRow('Completion Rate', report.compliance.completionRateDisplay),
            _buildPDFMetricRow('Completed Sessions', report.compliance.completedSessions.toString()),
            _buildPDFMetricRow('Planned Sessions', report.compliance.plannedSessions.toString()),
            _buildPDFMetricRow('Trend', report.compliance.trend.toUpperCase()),
          ]),
          pw.SizedBox(height: 16),

          // Muscle distribution
          _buildPDFSection('Muscle Balance', [
            _buildPDFMetricRow('Balance Status', report.distribution.isBalanced ? 'BALANCED' : 'NEEDS ADJUSTMENT'),
            _buildPDFMetricRow('Push/Pull Ratio', '${report.distribution.pushPullRatio.toStringAsFixed(2)}:1'),
            _buildPDFMetricRow('Upper/Lower Ratio', '${report.distribution.upperLowerRatio.toStringAsFixed(2)}:1'),
            if (report.distribution.recommendations.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text('Recommendations:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              ...report.distribution.recommendations.map((rec) => pw.Text('  • $rec', style: const pw.TextStyle(fontSize: 10))),
            ],
          ]),
          pw.SizedBox(height: 16),

          // Personal records
          if (report.personalRecords.isNotEmpty)
            _buildPDFSection('Recent Personal Records', [
              ...report.personalRecords.take(10).map((pr) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(pr.exerciseName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.Text(pr.displayValue, style: const pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                        pw.Text(DateFormat('MMM d').format(pr.achievedDate), style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  )),
            ]),
          pw.SizedBox(height: 16),

          // Areas for improvement
          if (report.areasForImprovement.isNotEmpty)
            _buildPDFSection('Areas for Improvement', [
              ...report.areasForImprovement.map((area) => pw.Text('  • $area')),
            ]),

          // Footer
          pw.SizedBox(height: 32),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Report generated on ${DateFormat('MMMM d, y').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    );

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'workout_report_${report.clientName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Export chart widget as PNG image
  Future<File> exportChartAsImage(
    GlobalKey repaintBoundaryKey,
    String fileName,
  ) async {
    try {
      // Get the render object
      RenderRepaintBoundary boundary = repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // Capture the image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.png');
      await file.writeAsBytes(pngBytes);

      return file;
    } catch (e) {
      throw Exception('Failed to export chart as image: $e');
    }
  }

  /// Share report via system share dialog
  Future<void> shareReport(ComprehensiveReport report) async {
    try {
      // Generate PDF
      final pdfFile = await exportReportAsPDF(report);

      // Share
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        subject: 'Workout Progress Report - ${report.clientName}',
        text: 'Here is the workout progress report for ${report.clientName} '
            '(${DateFormat('MMM d, y').format(report.periodStart)} - ${DateFormat('MMM d, y').format(report.periodEnd)})',
      );
    } catch (e) {
      throw Exception('Failed to share report: $e');
    }
  }

  /// Share chart image
  Future<void> shareChartImage(
    GlobalKey repaintBoundaryKey,
    String chartName,
  ) async {
    try {
      // Export chart
      final imageFile = await exportChartAsImage(
        repaintBoundaryKey,
        'chart_${chartName}_${DateFormat('yyyyMMdd').format(DateTime.now())}',
      );

      // Share
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        subject: 'Workout Analytics - $chartName',
        text: 'Check out this workout analytics chart!',
      );
    } catch (e) {
      throw Exception('Failed to share chart: $e');
    }
  }

  /// Export summary text for quick sharing
  String exportSummaryText(ComprehensiveReport report) {
    final buffer = StringBuffer();

    buffer.writeln('WORKOUT PROGRESS REPORT');
    buffer.writeln('========================');
    buffer.writeln('Client: ${report.clientName}');
    buffer.writeln('Period: ${DateFormat('MMM d, y').format(report.periodStart)} - ${DateFormat('MMM d, y').format(report.periodEnd)}');
    buffer.writeln();

    buffer.writeln('SUMMARY');
    buffer.writeln('-------');
    buffer.writeln(report.summary);
    buffer.writeln();

    if (report.achievements.isNotEmpty) {
      buffer.writeln('ACHIEVEMENTS');
      buffer.writeln('------------');
      for (final achievement in report.achievements) {
        buffer.writeln('✓ $achievement');
      }
      buffer.writeln();
    }

    buffer.writeln('KEY METRICS');
    buffer.writeln('-----------');
    buffer.writeln('Volume: ${report.volumeMetrics.totalVolumeDisplay}');
    buffer.writeln('Strength Gain: ${report.gainsReport.overallGainPercentage.toStringAsFixed(1)}%');
    buffer.writeln('PRs: ${report.gainsReport.totalPRs}');
    buffer.writeln('Consistency: ${report.patterns.consistencyScore}/100');
    buffer.writeln('Completion: ${report.compliance.completionRateDisplay}');
    buffer.writeln();

    if (report.areasForImprovement.isNotEmpty) {
      buffer.writeln('AREAS FOR IMPROVEMENT');
      buffer.writeln('---------------------');
      for (final area in report.areasForImprovement) {
        buffer.writeln('• $area');
      }
      buffer.writeln();
    }

    buffer.writeln('Report generated on ${DateFormat('MMMM d, y').format(DateTime.now())}');

    return buffer.toString();
  }

  /// Share summary text
  Future<void> shareSummaryText(ComprehensiveReport report) async {
    final text = exportSummaryText(report);
    await Share.share(
      text,
      subject: 'Workout Progress Report - ${report.clientName}',
    );
  }

  /// Email report (opens email client with attachment)
  Future<void> emailReport(
    ComprehensiveReport report,
    String recipientEmail,
  ) async {
    try {
      // Generate PDF
      final pdfFile = await exportReportAsPDF(report);

      // Share via email
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        subject: 'Workout Progress Report - ${report.clientName}',
        text: 'Please find attached your workout progress report.\n\n'
            'Period: ${DateFormat('MMM d, y').format(report.periodStart)} - ${DateFormat('MMM d, y').format(report.periodEnd)}\n\n'
            '${report.summary}',
      );
    } catch (e) {
      throw Exception('Failed to email report: $e');
    }
  }

  // Helper methods for PDF generation

  pw.Widget _buildPDFTitle(ComprehensiveReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'WORKOUT PROGRESS REPORT',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          report.clientName,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '${DateFormat('MMMM d, y').format(report.periodStart)} - ${DateFormat('MMMM d, y').format(report.periodEnd)}',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  pw.Widget _buildPDFSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
            ),
          ),
          child: pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        ...children,
      ],
    );
  }

  pw.Widget _buildPDFMetricRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}