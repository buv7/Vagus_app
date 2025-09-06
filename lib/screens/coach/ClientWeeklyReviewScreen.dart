import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/coach/weekly_review_service.dart';
import '../../services/coach/weekly_ai_insights_service.dart';
import '../../widgets/coach/weekly_summary_card.dart';
import '../../widgets/coach/compliance_donut.dart';
import '../../widgets/coach/energy_balance_card.dart';
import '../../widgets/coach/trend_chart.dart';
import '../../widgets/coach/weekly_photos_grid.dart';
import '../../widgets/coach/WeeklyAIInsightsCard.dart';
import '../../widgets/coach/weekly_delta_badges.dart';
import '../../widgets/coach/mini_day_card.dart';
import '../../widgets/coach/photo_compare_slider.dart';
import '../../utils/capture_widget_bitmap.dart';

class ClientWeeklyReviewScreen extends StatefulWidget {
  final String clientId;
  final String clientName;
  final DateTime? weekStartDate;

  const ClientWeeklyReviewScreen({
    super.key,
    required this.clientId,
    required this.clientName,
    this.weekStartDate,
  });

  @override
  State<ClientWeeklyReviewScreen> createState() => _ClientWeeklyReviewScreenState();
}

class _ClientWeeklyReviewScreenState extends State<ClientWeeklyReviewScreen> {
  final _service = WeeklyReviewService();
  final _aiService = WeeklyAIInsightsService();
  DateTime? _weekStart;
  WeeklyAIInsights? _insights;
  bool _aiBusy = false;
  WeeklyComparison? _cmp;
  bool _cmpBusy = false;
  
  // Chart capture keys
  final GlobalKey _keySleep = GlobalKey();
  final GlobalKey _keySteps = GlobalKey();
  final GlobalKey _keyIn = GlobalKey();
  final GlobalKey _keyOut = GlobalKey();

  @override
  void initState() {
    super.initState();
    _weekStart = widget.weekStartDate;
  }

  Future<WeeklyReviewData> _load() => _service.getWeeklyReview(widget.clientId, _weekStart);

  void _shiftWeek(int deltaWeeks) {
    setState(() {
      final base = _weekStart ?? DateTime.now();
      _weekStart = base.add(Duration(days: deltaWeeks * 7));
      // Reset insights and comparison when changing weeks
      _insights = null;
      _aiBusy = false;
      _cmp = null;
      _cmpBusy = false;
    });
  }

  Future<void> _computeInsights(WeeklyReviewData data) async {
    setState(() => _aiBusy = true);

    // OPTIONAL AI bridge: if you have an OpenRouter gateway wrapper, plug it here.
    // Leave `ai` as null to get heuristic-only insights.
    AiTextFn? ai;
    String? modelHint;

    // Example (uncomment & adapt if you already have a gateway class):
    // ai = (String prompt) => OpenRouterGateway.instance.generateText(
    //        model: 'openrouter/anthropic/claude-3.5-sonnet',
    //        prompt: prompt,
    //        maxTokens: 400);
    // modelHint = 'Claude 3.5 Sonnet';

    final insights = await _aiService.analyze(
      data: data,
      ai: ai,
      aiModelHint: modelHint,
    );

    if (mounted) {
      setState(() {
        _insights = insights;
        _aiBusy = false;
      });
    }
  }

  Future<void> _computeComparison(String clientId) async {
    setState(() => _cmpBusy = true);
    try {
      final c = await _service.compareWithPrevious(clientId, _weekStart);
      if (mounted) setState(() => _cmp = c);
    } finally {
      if (mounted) setState(() => _cmpBusy = false);
    }
  }

  Widget _buildStreaksCard(BuildContext context, WeeklyReviewData data, bool isDark) {
    final currentStreak = _service.currentStreak(data.dailyCompliance);
    final bestStreak = _service.longestStreak(data.dailyCompliance);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Text(
            'Current streak: $currentStreak days • Best: $bestStreak days',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Weekly Review — ${widget.clientName}'),
        backgroundColor: isDark ? Colors.black : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0.5,
      ),
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : Colors.white,
      body: FutureBuilder(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load weekly data.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }
          final data = snapshot.data as WeeklyReviewData;
          final range = '${DateFormat('MMM d').format(data.weekStart)} – ${DateFormat('MMM d, yyyy').format(data.weekEnd)}';

          // Kick off insights generation once per load
          if (_insights == null && !_aiBusy) {
            Future.microtask(() => _computeInsights(data));
          }

          // Kick off comparison computation once per load
          if (_cmp == null && !_cmpBusy) {
            Future.microtask(() => _computeComparison(widget.clientId));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Week selector
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _shiftWeek(-1),
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Previous week',
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          range,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _shiftWeek(1),
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Next week',
                    ),
                  ],
                ),
                
                // Streaks display
                const SizedBox(height: 8),
                _buildStreaksCard(context, data, isDark),
                const SizedBox(height: 12),

                // Summary + Compliance donut row
                Row(
                  children: [
                    Expanded(child: WeeklySummaryCard(summary: data.summary)),
                    const SizedBox(width: 12),
                    Expanded(child: ComplianceDonut(compliance: data.compliance)),
                  ],
                ),
                
                // Week-over-week comparison badges
                if (_cmp != null) ...[
                  const SizedBox(height: 12),
                  WeeklyDeltaBadges(cmp: _cmp!),
                ],
                
                const SizedBox(height: 16),

                // Trend charts (responsive: 2 per row)
                _ChartsGrid(
                  data: data,
                  keySleep: _keySleep,
                  keySteps: _keySteps,
                  keyIn: _keyIn,
                  keyOut: _keyOut,
                ),

                const SizedBox(height: 16),
                _ScrollingDayRow(data: data),
                const SizedBox(height: 16),
                EnergyBalanceCard(energy: data.energyBalance),
                
                // AI Insights Card
                if (_insights != null) ...[
                  const SizedBox(height: 16),
                  WeeklyAIInsightsCard(
                    insights: _insights!,
                    onRegenerate: _aiBusy ? null : () => _computeInsights(data),
                  ),
                ]
                else if (_aiBusy) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Generating insights…'),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                WeeklyPhotosGrid(photos: data.photos),

                // Photo Compare demo block (if 2+ photos available)
                if (data.photos.length >= 2) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Photo Compare', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 8),
                  AspectRatio(
                    aspectRatio: 3/4,
                    child: PhotoCompareSlider(
                      beforeUrl: data.photos.first.url,
                      afterUrl: data.photos.last.url,
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _exportPdf(context, data),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Export PDF'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final csv = _service.toCsv(data);
                          // Use Printing.sharePdf or a platform share for text; simplest is show a dialog with copy.
                          await showDialog(context: context, builder: (_) {
                            return AlertDialog(
                              title: const Text('Weekly CSV'),
                              content: SingleChildScrollView(child: SelectableText(csv)),
                              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                            );
                          });
                        },
                        icon: const Icon(Icons.table_view_outlined),
                        label: const Text('Export CSV'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, WeeklyReviewData data) async {
    // Capture charts as PNG images
    final chartImages = await _captureCharts();
    
    try {
      final doc = pw.Document();
      final fmt = DateFormat('yyyy-MM-dd');

      doc.addPage(
        pw.MultiPage(
          build: (ctx) => [
            pw.Header(level: 0, child: pw.Text('Weekly Review — ${widget.clientName}', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
            pw.Text('Range: ${fmt.format(data.weekStart)} to ${fmt.format(data.weekEnd)}'),
            pw.SizedBox(height: 12),
            
            // Summary section
            pw.Text('Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Bullet(text: 'Compliance: ${data.summary.compliancePercent.toStringAsFixed(1)}%'),
            pw.Bullet(text: 'Sessions: done ${data.summary.sessionsDone} / skipped ${data.summary.sessionsSkipped}'),
            pw.Bullet(text: 'Total tonnage: ${data.summary.totalTonnage.toStringAsFixed(0)} kg'),
            pw.Bullet(text: 'Cardio minutes: ${data.summary.cardioMinutes}'),
            pw.SizedBox(height: 12),
            
            // Energy Balance section
            pw.Text('Energy Balance', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Bullet(text: 'Total in: ${data.energyBalance.totalIn.toStringAsFixed(0)} kcal'),
            pw.Bullet(text: 'Total out: ${data.energyBalance.totalOut.toStringAsFixed(0)} kcal'),
            pw.Bullet(text: 'Net: ${data.energyBalance.net.toStringAsFixed(0)} kcal'),
            pw.SizedBox(height: 12),
            
            // Charts Snapshot section
            if (chartImages.isNotEmpty) ...[
              pw.Text('Charts Snapshot', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              _buildChartsGrid(chartImages),
              pw.SizedBox(height: 12),
            ],
            
            // AI Insights section
            if (_insights != null) ...[
              pw.Text('AI Weekly Insights', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              if (_insights!.usedAI) pw.Text('Generated with AI${_insights!.aiModel != null ? ' — ${_insights!.aiModel}' : ''}'),
              if (!_insights!.usedAI) pw.Text('Heuristic summary (AI unavailable).'),
              pw.SizedBox(height: 6),
              if (_insights!.wins.isNotEmpty) ...[
                pw.Text('Key Wins', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ..._insights!.wins.map((w) => pw.Bullet(text: w)),
                pw.SizedBox(height: 6),
              ],
              if (_insights!.risks.isNotEmpty) ...[
                pw.Text('Risk Flags', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ..._insights!.risks.map((r) => pw.Bullet(text: r)),
                pw.SizedBox(height: 6),
              ],
              if (_insights!.suggestions.isNotEmpty) ...[
                pw.Text('Suggestions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ..._insights!.suggestions.map((s) => pw.Bullet(text: s)),
                pw.SizedBox(height: 6),
              ],
              if (_insights!.rationale.isNotEmpty) pw.Text('Rationale: ${_insights!.rationale}'),
              pw.SizedBox(height: 12),
            ],
            
            // Daily Trends table
            pw.Text('Daily Trends (values per day)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              children: [
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Date')),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Sleep (h)')),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Steps')),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Kcal In')),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Kcal Out')),
                ]),
                ...List.generate(7, (i) {
                  final d = DateTime(data.weekStart.year, data.weekStart.month, data.weekStart.day).add(Duration(days: i));
                  double getVal(List<DailyPoint> xs) {
                    return xs.firstWhere((p) =>
                      p.day.year == d.year && p.day.month == d.month && p.day.day == d.day,
                    orElse: () => DailyPoint(d, 0)).value;
                  }
                  return pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(fmt.format(d))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(getVal(data.trends.sleepHours).toStringAsFixed(1))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(getVal(data.trends.steps).toStringAsFixed(0))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(getVal(data.trends.caloriesIn).toStringAsFixed(0))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(getVal(data.trends.caloriesOut).toStringAsFixed(0))),
                  ]);
                }),
              ],
            ),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => doc.save());
    } finally {
      // Memory guard: Clear chart images after PDF generation
      chartImages.clear();
    }
  }

  /// Captures all four charts as PNG images
  Future<Map<String, Uint8List>> _captureCharts() async {
    final Map<String, Uint8List> images = {};
    Uint8List? sleepBytes;
    Uint8List? stepsBytes;
    Uint8List? inBytes;
    Uint8List? outBytes;
    
    try {
      // Capture each chart with a small delay to ensure rendering
      await Future.delayed(const Duration(milliseconds: 500));
      
      sleepBytes = await CaptureWidgetBitmap.capturePng(_keySleep);
      if (sleepBytes != null) images['sleep'] = sleepBytes;
      
      stepsBytes = await CaptureWidgetBitmap.capturePng(_keySteps);
      if (stepsBytes != null) images['steps'] = stepsBytes;
      
      inBytes = await CaptureWidgetBitmap.capturePng(_keyIn);
      if (inBytes != null) images['in'] = inBytes;
      
      outBytes = await CaptureWidgetBitmap.capturePng(_keyOut);
      if (outBytes != null) images['out'] = outBytes;
      
    } catch (e) {
      print('Error capturing charts: $e');
    } finally {
      // Memory guard: Clear individual Uint8List objects after capture
      sleepBytes = null;
      stepsBytes = null;
      inBytes = null;
      outBytes = null;
    }
    
    return images;
  }

  /// Builds a 2x2 grid of chart images in the PDF
  pw.Widget _buildChartsGrid(Map<String, Uint8List> images) {
    return pw.Column(
      children: [
        // First row: Sleep and Steps
        pw.Row(
          children: [
            if (images.containsKey('sleep'))
              pw.Expanded(
                child: pw.Container(
                  height: 150,
                  child: pw.Image(pw.MemoryImage(images['sleep']!),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
            if (images.containsKey('sleep') && images.containsKey('steps'))
              pw.SizedBox(width: 12),
            if (images.containsKey('steps'))
              pw.Expanded(
                child: pw.Container(
                  height: 150,
                  child: pw.Image(pw.MemoryImage(images['steps']!),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 12),
        // Second row: Calories In and Out
        pw.Row(
          children: [
            if (images.containsKey('in'))
              pw.Expanded(
                child: pw.Container(
                  height: 150,
                  child: pw.Image(pw.MemoryImage(images['in']!),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
            if (images.containsKey('in') && images.containsKey('out'))
              pw.SizedBox(width: 12),
            if (images.containsKey('out'))
              pw.Expanded(
                child: pw.Container(
                  height: 150,
                  child: pw.Image(pw.MemoryImage(images['out']!),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChartsGrid extends StatelessWidget {
  final WeeklyReviewData data;
  final GlobalKey keySleep;
  final GlobalKey keySteps;
  final GlobalKey keyIn;
  final GlobalKey keyOut;
  
  const _ChartsGrid({
    required this.data,
    required this.keySleep,
    required this.keySteps,
    required this.keyIn,
    required this.keyOut,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (ctx, c) {
        final twoPerRow = c.maxWidth > 680;
        final chartCards = <Widget>[
          RepaintBoundary(
            key: keySleep,
            child: TrendChart(
              title: 'Sleep (h)',
              points: data.trends.sleepHours,
              type: TrendType.line,
            ),
          ),
          RepaintBoundary(
            key: keySteps,
            child: TrendChart(
              title: 'Steps',
              points: data.trends.steps,
              type: TrendType.bar,
            ),
          ),
          RepaintBoundary(
            key: keyIn,
            child: TrendChart(
              title: 'Calories In',
              points: data.trends.caloriesIn,
              type: TrendType.line,
            ),
          ),
          RepaintBoundary(
            key: keyOut,
            child: TrendChart(
              title: 'Calories Out',
              points: data.trends.caloriesOut,
              type: TrendType.line,
            ),
          ),
        ];

        if (twoPerRow) {
          return Column(
            children: [
              Row(children: [Expanded(child: chartCards[0]), const SizedBox(width: 12), Expanded(child: chartCards[1])]),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: chartCards[2]), const SizedBox(width: 12), Expanded(child: chartCards[3])]),
            ],
          );
        }
        return Column(
          children: [
            ...chartCards.expand((w) => [w, const SizedBox(height: 12)]).toList()..removeLast(),
          ],
        );
      },
    );
  }
}

class _ScrollingDayRow extends StatelessWidget {
  final WeeklyReviewData data;
  const _ScrollingDayRow({required this.data});

  double _get(List<DailyPoint> xs, DateTime d) {
    for (final p in xs) {
      if (p.day.year == d.year && p.day.month == d.month && p.day.day == d.day) {
        return p.value;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => DateTime(data.weekStart.year, data.weekStart.month, data.weekStart.day).add(Duration(days: i)));
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final d = days[i];
          
          // Find the corresponding daily compliance for this day
          final dayCompliance = data.dailyCompliance.firstWhere(
            (dc) => dc.day.year == d.year && dc.day.month == d.month && dc.day.day == d.day,
            orElse: () => DayCompliance(day: d, done: false),
          );
          
          // Use actual daily compliance (100% if done, 0% if not)
          final compliancePct = dayCompliance.done ? 100.0 : 0.0;
          
          return MiniDayCard(
            day: d,
            sleepH: _get(data.trends.sleepHours, d),
            steps: _get(data.trends.steps, d),
            kcalIn: _get(data.trends.caloriesIn, d),
            kcalOut: _get(data.trends.caloriesOut, d),
            compliancePct: compliancePct, // Real daily compliance
          );
        },
      ),
    );
  }
}
