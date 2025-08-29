import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../services/progress/progress_service.dart';

class ExportCard extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> metrics;
  final List<Map<String, dynamic>> photos;
  final List<Map<String, dynamic>> checkins;
  final String userName;

  const ExportCard({
    super.key,
    required this.userId,
    required this.metrics,
    required this.photos,
    required this.checkins,
    required this.userName,
  });

  @override
  State<ExportCard> createState() => _ExportCardState();
}

class _ExportCardState extends State<ExportCard> {
  final ProgressService _progressService = ProgressService();
  bool _isExporting = false;

  Future<void> _exportMetricsToCsv() async {
    setState(() => _isExporting = true);

    try {
      final csvData = await _progressService.exportMetricsToCsv(widget.metrics);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'progress_metrics_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(csvData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ CSV exported to: ${file.path}'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                // You could add file opening functionality here
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to export CSV: $e')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportProgressToPdf() async {
    setState(() => _isExporting = true);

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) => [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Progress Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    DateFormat('MMM dd, yyyy').format(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Client info
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Client: ${widget.userName}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Report Date: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Metrics summary
            if (widget.metrics.isNotEmpty) ...[
              pw.Text(
                'Progress Metrics',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildMetricsTable(),
              pw.SizedBox(height: 20),
            ],

            // Photos summary
            if (widget.photos.isNotEmpty) ...[
              pw.Text(
                'Progress Photos',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Total photos: ${widget.photos.length}'),
              pw.Text('Latest photo: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.photos.first['taken_at']))}'),
              pw.SizedBox(height: 20),
            ],

            // Check-ins summary
            if (widget.checkins.isNotEmpty) ...[
              pw.Text(
                'Weekly Check-ins',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Total check-ins: ${widget.checkins.length}'),
              pw.Text('Latest check-in: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.checkins.first['checkin_date']))}'),
              pw.SizedBox(height: 20),
            ],

            // Footer
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Generated by VAGUS App',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Progress_Report_${widget.userName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to export PDF: $e')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  pw.Widget _buildMetricsTable() {
    if (widget.metrics.isEmpty) {
      return pw.Text(
        'No metrics recorded yet.',
        style: pw.TextStyle(
          color: PdfColors.grey600,
          fontStyle: pw.FontStyle.italic,
        ),
      );
    }

    // Get the most recent metrics (last 8 entries)
    final recentMetrics = widget.metrics.take(8).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Weight', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Body Fat', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Waist', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Notes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        // Data rows
        ...recentMetrics.map((metric) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(DateFormat('MM/dd/yyyy').format(DateTime.parse(metric['date']))),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(metric['weight_kg']?.toString() ?? '-'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(metric['body_fat_percent']?.toString() ?? '-'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(metric['waist_cm']?.toString() ?? '-'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(metric['notes']?.toString() ?? '-'),
            ),
          ],
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.download, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Export Progress Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exportMetricsToCsv,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.table_chart),
                    label: const Text('Export CSV (Metrics)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exportProgressToPdf,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF (Progress)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Summary:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('• ${widget.metrics.length} metric entries'),
                  Text('• ${widget.photos.length} progress photos'),
                  Text('• ${widget.checkins.length} check-ins'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
