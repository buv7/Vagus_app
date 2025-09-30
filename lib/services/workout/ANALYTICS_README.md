# Workout Analytics System

Comprehensive analytics and reporting system for tracking client workout progress, performance trends, and generating detailed reports.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Services](#services)
4. [Data Models](#data-models)
5. [Screens](#screens)
6. [Widgets](#widgets)
7. [Export & Reporting](#export--reporting)
8. [Usage Examples](#usage-examples)
9. [Integration Guide](#integration-guide)

---

## Overview

The Workout Analytics System provides:

- **Volume Tracking**: Total volume, sets, reps, breakdown by muscle group and exercise
- **Strength Gains Analysis**: Per-exercise gains, 1RM estimates, trend detection
- **Muscle Distribution**: Balance analysis, push/pull and upper/lower ratios
- **Training Patterns**: Frequency, consistency, preferred days, behavioral insights
- **Compliance Metrics**: Completion rates, missed sessions, trend analysis
- **PR Tracking**: Personal records with celebration and timeline
- **Comprehensive Reports**: AI-generated summaries with achievements and recommendations
- **Export Capabilities**: PDF reports, image exports, sharing functionality

---

## Architecture

```
lib/
├── models/workout/
│   ├── analytics_models.dart          # Analytics data models
│   └── progression_models.dart         # Progression-related models
│
├── services/workout/
│   ├── workout_analytics_service.dart  # Core analytics service
│   ├── workout_export_service.dart     # Export and sharing service
│   └── progression_analytics_service.dart # Progression analytics
│
├── screens/workout/
│   └── workout_analytics_screen.dart   # Main analytics screen
│
└── widgets/workout/
    ├── volume_progress_chart.dart      # Volume trend line chart
    ├── muscle_group_balance_chart.dart # Muscle distribution pie/radar chart
    ├── strength_gain_table.dart        # Sortable strength gains table
    ├── training_heatmap.dart           # GitHub-style frequency heatmap
    └── pr_timeline_widget.dart         # Personal records timeline
```

---

## Services

### WorkoutAnalyticsService

Core service for calculating analytics metrics.

**Methods:**

#### `calculateWeeklyVolume(String planId, int weekNumber)`
Calculates comprehensive volume metrics for a specific week.

**Returns:** `VolumeMetrics`
- Total volume (kg)
- Average volume per session
- Total sets and reps
- Volume breakdown by muscle group
- Volume breakdown by exercise

**Example:**
```dart
final analyticsService = WorkoutAnalyticsService();
final metrics = await analyticsService.calculateWeeklyVolume(planId, 1);

print('Total Volume: ${metrics.totalVolumeDisplay}');
print('Avg per Session: ${metrics.avgVolumePerSession}kg');
print('Chest Volume: ${metrics.volumeByMuscleGroup['chest']}kg');
```

#### `analyzeMuscleGroupDistribution(String planId)`
Analyzes muscle group balance across entire plan.

**Returns:** `DistributionReport`
- Percentage by muscle group
- Exercise count by muscle group
- Overdeveloped/underdeveloped groups
- Push/pull ratio
- Upper/lower ratio
- Balance recommendations

**Example:**
```dart
final distribution = await analyticsService.analyzeMuscleGroupDistribution(planId);

if (distribution.isBalanced) {
  print('Muscle groups are balanced!');
} else {
  print('Recommendations:');
  distribution.recommendations.forEach(print);
}
```

#### `calculateStrengthGains(String clientId, String timeframe)`
Calculates strength gains over specified timeframe.

**Timeframes:** `'4weeks'`, `'12weeks'`, `'6months'`, `'1year'`

**Returns:** `GainsReport`
- Gains by exercise
- Overall gain percentage
- Best gaining exercise
- Slowest gaining exercise
- Total PRs

**Example:**
```dart
final gains = await analyticsService.calculateStrengthGains(clientId, '12weeks');

print('Overall Gain: ${gains.overallGainPercentage.toStringAsFixed(1)}%');
print('Best Exercise: ${gains.bestGainingExercise}');
print('Total PRs: ${gains.totalPRs}');
```

#### `detectTrainingPatterns(String clientId, {int weeksToAnalyze = 12})`
Detects training patterns and behavioral insights.

**Returns:** `PatternAnalysis`
- Average sessions per week
- Consistency score (0-100)
- Preferred training days
- Average session duration
- Exercise frequency
- Pattern insights

**Example:**
```dart
final patterns = await analyticsService.detectTrainingPatterns(clientId);

print('Consistency: ${patterns.consistencyScore}/100');
print('Avg Sessions/Week: ${patterns.avgSessionsPerWeek.toStringAsFixed(1)}');
print('Insights:');
patterns.patterns.forEach(print);
```

#### `generateProgressReport(String clientId, {String timeframe = '12weeks'})`
Generates comprehensive progress report combining all metrics.

**Returns:** `ComprehensiveReport`
- Volume metrics
- Gains report
- Distribution analysis
- Training patterns
- Compliance metrics
- Personal records
- AI-generated summary
- Achievements list
- Areas for improvement

**Example:**
```dart
final report = await analyticsService.generateProgressReport(clientId);

print('Summary: ${report.summary}');
print('\nAchievements:');
report.achievements.forEach((a) => print('✓ $a'));
print('\nAreas for Improvement:');
report.areasForImprovement.forEach((a) => print('• $a'));
```

#### `comparePlans(String plan1Id, String plan2Id)`
Compares two workout plans side-by-side.

**Returns:** `ComparisonReport`
- Volume difference
- Intensity difference
- Frequency difference
- Key differences map
- Similarities list
- Recommendation

**Example:**
```dart
final comparison = await analyticsService.comparePlans(plan1Id, plan2Id);

print('Volume Difference: ${comparison.volumeDifference.toStringAsFixed(1)}%');
print('Recommendation: ${comparison.recommendation}');
```

#### `predictFutureProgress(String clientId, String exerciseName, {int weeksToProject = 8})`
Predicts future progress using linear regression.

**Returns:** `ProjectionData`
- Exercise projections (date, weight, bounds)
- Confidence score (0-1)
- Methodology ('linear', 'polynomial', 'exponential')

**Example:**
```dart
final projection = await analyticsService.predictFutureProgress(
  clientId,
  'Barbell Bench Press',
  weeksToProject: 12,
);

print('Confidence: ${(projection.confidenceScore * 100).toStringAsFixed(1)}%');
for (final point in projection.exerciseProjections['Barbell Bench Press']!) {
  print('Week ${point.date}: ${point.projectedWeight.toStringAsFixed(1)}kg '
        '(${point.lowerBound.toStringAsFixed(1)} - ${point.upperBound.toStringAsFixed(1)})');
}
```

---

### WorkoutExportService

Service for exporting and sharing reports.

**Methods:**

#### `exportReportAsPDF(ComprehensiveReport report)`
Generates PDF report with all metrics.

**Returns:** `File` (PDF file)

**Example:**
```dart
final exportService = WorkoutExportService();
final pdfFile = await exportService.exportReportAsPDF(report);
print('PDF saved to: ${pdfFile.path}');
```

#### `exportChartAsImage(GlobalKey repaintBoundaryKey, String fileName)`
Exports chart widget as PNG image.

**Returns:** `File` (PNG file)

**Example:**
```dart
final chartKey = GlobalKey();

// In widget build:
RepaintBoundary(
  key: chartKey,
  child: VolumeProgressChart(trendData: data),
);

// Export:
final imageFile = await exportService.exportChartAsImage(chartKey, 'volume_chart');
```

#### `shareReport(ComprehensiveReport report)`
Opens system share dialog with PDF report.

**Example:**
```dart
await exportService.shareReport(report);
```

#### `shareChartImage(GlobalKey repaintBoundaryKey, String chartName)`
Shares chart as image via system share dialog.

**Example:**
```dart
await exportService.shareChartImage(chartKey, 'Volume Progress');
```

#### `shareSummaryText(ComprehensiveReport report)`
Shares report summary as plain text.

**Example:**
```dart
await exportService.shareSummaryText(report);
```

#### `emailReport(ComprehensiveReport report, String recipientEmail)`
Opens email client with report attachment.

**Example:**
```dart
await exportService.emailReport(report, 'client@example.com');
```

---

## Data Models

### VolumeMetrics
```dart
class VolumeMetrics {
  final double totalVolume;                    // Total volume in kg
  final double avgVolumePerSession;            // Average per session
  final int totalSets;                         // Total sets performed
  final int totalReps;                         // Total reps performed
  final Map<String, double> volumeByMuscleGroup; // Breakdown by muscle
  final Map<String, double> volumeByExercise;    // Breakdown by exercise
  final DateTime startDate;
  final DateTime endDate;

  String get totalVolumeDisplay;  // "X.X tons" or "XXXX kg"
}
```

### DistributionReport
```dart
class DistributionReport {
  final Map<String, double> percentageByMuscleGroup;  // %age distribution
  final Map<String, int> exerciseCountByMuscleGroup;  // Exercise count
  final List<String> overdevelopedGroups;             // >25%
  final List<String> underdevelopedGroups;            // <5%
  final double pushPullRatio;                         // Push:Pull
  final double upperLowerRatio;                       // Upper:Lower
  final List<String> recommendations;                 // Balance tips

  bool get isBalanced;  // No over/underdeveloped groups
}
```

### GainsReport
```dart
class GainsReport {
  final Map<String, ExerciseGains> gainsByExercise;
  final double overallGainPercentage;
  final String bestGainingExercise;
  final String slowestGainingExercise;
  final int totalPRs;
  final DateTime startDate;
  final DateTime endDate;
}

class ExerciseGains {
  final String exerciseName;
  final double startingWeight;
  final double currentWeight;
  final double gainKg;
  final double gainPercentage;
  final double starting1RM;
  final double current1RM;
  final String trend;  // 'improving', 'stable', 'declining'
}
```

### PatternAnalysis
```dart
class PatternAnalysis {
  final double avgSessionsPerWeek;
  final int totalWeeks;
  final int consistencyScore;              // 0-100
  final List<int> preferredTrainingDays;   // 0=Monday, 6=Sunday
  final double avgSessionDuration;         // minutes
  final Map<String, int> exerciseFrequency;
  final List<String> patterns;             // Behavioral insights
}
```

### ComplianceMetrics
```dart
class ComplianceMetrics {
  final int plannedSessions;
  final int completedSessions;
  final double completionRate;          // 0.0 to 1.0
  final int missedSessions;
  final List<DateTime> missedDates;
  final String trend;  // 'improving', 'stable', 'declining'

  String get completionRateDisplay;  // "XX.X%"
}
```

### ComprehensiveReport
```dart
class ComprehensiveReport {
  final String clientId;
  final String clientName;
  final DateTime reportDate;
  final DateTime periodStart;
  final DateTime periodEnd;

  // Metrics
  final VolumeMetrics volumeMetrics;
  final GainsReport gainsReport;
  final DistributionReport distribution;
  final PatternAnalysis patterns;
  final ComplianceMetrics compliance;
  final List<PRRecord> personalRecords;

  // Summary
  final String summary;                    // AI-generated summary
  final List<String> achievements;         // Positive highlights
  final List<String> areasForImprovement;  // Action items
}
```

---

## Screens

### WorkoutAnalyticsScreen

Main analytics screen with comprehensive visualizations.

**Features:**
- Timeframe selector (4 weeks, 12 weeks, 6 months, 1 year)
- Summary card with AI-generated insights
- Achievements section with checkmarks
- Volume metrics card with progress bars
- Strength gains card with top exercises
- Muscle distribution with balance indicator
- Training patterns with consistency score
- Compliance metrics with trend indicator
- PR timeline with filtering
- Areas for improvement
- Export button

**Usage:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => WorkoutAnalyticsScreen(
      clientId: currentUserId,
      isCoachView: false,
    ),
  ),
);
```

---

## Widgets

### VolumeProgressChart

Line chart showing volume trends over time.

**Features:**
- Line chart with curved lines
- Touch tooltips with detailed data
- Average line indicator (dashed)
- Gradient fill under line
- Trend badge (increasing/stable/decreasing)
- Legend with color coding

**Usage:**
```dart
VolumeProgressChart(
  trendData: volumeTrendData,
  lineColor: Colors.blue,
  showAverageLine: true,
  showGrid: true,
)
```

### MuscleGroupBalanceChart

Pie or radar chart for muscle distribution.

**Features:**
- Interactive pie chart with touch
- Color-coded segments
- Percentage labels
- Legend with overdeveloped/underdeveloped indicators
- Optional radar chart view

**Usage:**
```dart
MuscleGroupBalanceChart(
  distribution: distributionReport,
  chartType: ChartType.pie,  // or ChartType.radar
)
```

### StrengthGainTable

Sortable table showing per-exercise strength gains.

**Features:**
- Sortable columns (exercise, starting, current, gain, 1RM)
- Color-coded gain indicators
- Trend badges (improving/stable/declining)
- 1RM estimates
- Clickable exercise names

**Usage:**
```dart
StrengthGainTable(
  gainsByExercise: gainsReport.gainsByExercise,
  showEstimated1RM: true,
  onExerciseTap: (exerciseName) {
    // Navigate to exercise details
  },
)
```

### TrainingHeatmap

GitHub-style contribution calendar showing training frequency.

**Features:**
- Daily activity grid
- Color intensity based on sessions/volume
- Touch interaction for daily details
- Week labels
- Legend (less → more)
- Selected day details popup

**Usage:**
```dart
TrainingHeatmap(
  dataPoints: frequencyDataPoints,
  startDate: DateTime.now().subtract(Duration(days: 90)),
  endDate: DateTime.now(),
  metric: HeatmapMetric.sessions,  // or HeatmapMetric.volume
)
```

### PRTimelineWidget

Achievement timeline for personal records.

**Features:**
- Chronological PR list
- PR type badges (weight, volume, reps, 1RM, tonnage)
- Date timeline markers
- Filterable by type
- Searchable by exercise
- Trophy icons

**Usage:**
```dart
PRTimelineWidget(
  records: personalRecords,
  showFilters: true,
  onRecordTap: (record) {
    // Show PR details
  },
)
```

---

## Export & Reporting

### PDF Report Structure

Generated PDF includes:
1. **Title Page**: Client name, date range
2. **Summary**: AI-generated overview
3. **Achievements**: Bullet list with checkmarks
4. **Volume Metrics**: Total volume, sets, reps, breakdown
5. **Strength Gains**: Overall gain, top exercises, gains table
6. **Training Patterns**: Sessions/week, consistency, insights
7. **Compliance**: Completion rate, trend
8. **Muscle Balance**: Ratios, recommendations
9. **Personal Records**: Recent PRs with dates
10. **Areas for Improvement**: Action items
11. **Footer**: Generation date

### Image Export

Charts can be exported as high-resolution PNG images (3x pixel ratio) for:
- Social media sharing
- Presentation slides
- Client emails
- Progress tracking

### Sharing Options

- **System Share Dialog**: Share via any installed app
- **Email**: Opens email client with attachment
- **Messaging**: Share via SMS, WhatsApp, etc.
- **Cloud Storage**: Save to Google Drive, Dropbox, etc.

---

## Usage Examples

### Basic Analytics Flow

```dart
// 1. Initialize service
final analyticsService = WorkoutAnalyticsService();

// 2. Generate report
final report = await analyticsService.generateProgressReport(clientId);

// 3. Display in UI
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => WorkoutAnalyticsScreen(clientId: clientId),
  ),
);
```

### Coach Dashboard Integration

```dart
// Fetch analytics for multiple clients
final coachId = currentUser.id;
final clients = await supabase
    .from('profiles')
    .select()
    .eq('coach_id', coachId);

// Generate summary for each
for (final client in clients) {
  final report = await analyticsService.generateProgressReport(
    client['id'],
    timeframe: '4weeks',
  );

  // Display in dashboard
  clientSummaries.add(ClientSummaryCard(report: report));
}
```

### Automated Weekly Reports

```dart
// Schedule weekly report generation
Timer.periodic(Duration(days: 7), (timer) async {
  final report = await analyticsService.generateProgressReport(clientId);
  final exportService = WorkoutExportService();

  // Email to client
  await exportService.emailReport(report, clientEmail);
});
```

### Custom Timeframe Analysis

```dart
// Analyze specific date range
final startDate = DateTime(2024, 1, 1);
final endDate = DateTime(2024, 3, 31);

// Calculate gains for Q1
final gains = await analyticsService.calculateStrengthGains(
  clientId,
  '3months',  // Custom timeframe
);
```

---

## Integration Guide

### Step 1: Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  fl_chart: ^0.66.0
  pdf: ^3.10.0
  path_provider: ^2.1.0
  share_plus: ^7.0.0
  intl: ^0.18.0
```

### Step 2: Import Models and Services

```dart
import 'package:your_app/models/workout/analytics_models.dart';
import 'package:your_app/services/workout/workout_analytics_service.dart';
import 'package:your_app/services/workout/workout_export_service.dart';
```

### Step 3: Initialize Services

```dart
class AnalyticsProvider extends ChangeNotifier {
  final WorkoutAnalyticsService _analyticsService = WorkoutAnalyticsService();
  final WorkoutExportService _exportService = WorkoutExportService();

  ComprehensiveReport? currentReport;
  bool isLoading = false;

  Future<void> loadReport(String clientId) async {
    isLoading = true;
    notifyListeners();

    try {
      currentReport = await _analyticsService.generateProgressReport(clientId);
    } catch (e) {
      // Handle error
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> exportReport() async {
    if (currentReport == null) return;
    await _exportService.shareReport(currentReport!);
  }
}
```

### Step 4: Add to Navigation

```dart
// In drawer/menu
ListTile(
  leading: Icon(Icons.analytics),
  title: Text('Analytics'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutAnalyticsScreen(clientId: userId),
      ),
    );
  },
),
```

### Step 5: Add Localization Strings

```dart
// In locale helper
'workout_analytics': {'en': 'Workout Analytics', 'ar': 'تحليلات التمرين'},
'volume_metrics': {'en': 'Volume Metrics', 'ar': 'مقاييس الحجم'},
'strength_gains': {'en': 'Strength Gains', 'ar': 'مكاسب القوة'},
'training_patterns': {'en': 'Training Patterns', 'ar': 'أنماط التدريب'},
'compliance': {'en': 'Compliance', 'ar': 'الالتزام'},
// ... add all required strings
```

---

## Database Requirements

Analytics system requires these tables:
- `workout_plans`
- `workout_weeks`
- `workout_days`
- `exercises`
- `workout_sessions`
- `exercise_history`
- `profiles`

**Key columns for analytics:**
- `exercise_history.weight`, `reps`, `sets`, `completed_at`
- `workout_sessions.duration_minutes`, `completed_at`
- `exercises.muscle_group`, `name`
- `workout_days.date`

---

## Performance Considerations

### Optimization Tips

1. **Cache Reports**: Cache generated reports for 24 hours
2. **Pagination**: Load PRs and history with pagination
3. **Lazy Loading**: Load charts only when visible
4. **Background Generation**: Generate PDFs in isolate
5. **Index Database**: Ensure indexes on `completed_at`, `user_id`

### Example: Report Caching

```dart
class CachedAnalyticsService {
  Map<String, ComprehensiveReport> _cache = {};
  Map<String, DateTime> _cacheTimestamps = {};

  Future<ComprehensiveReport> getReport(String clientId) async {
    final cached = _cache[clientId];
    final timestamp = _cacheTimestamps[clientId];

    if (cached != null &&
        timestamp != null &&
        DateTime.now().difference(timestamp) < Duration(hours: 24)) {
      return cached;
    }

    final report = await _analyticsService.generateProgressReport(clientId);
    _cache[clientId] = report;
    _cacheTimestamps[clientId] = DateTime.now();

    return report;
  }
}
```

---

## Testing

### Unit Tests

```dart
test('calculateWeeklyVolume returns correct metrics', () async {
  final service = WorkoutAnalyticsService();
  final metrics = await service.calculateWeeklyVolume(testPlanId, 1);

  expect(metrics.totalVolume, greaterThan(0));
  expect(metrics.totalSets, greaterThan(0));
  expect(metrics.volumeByMuscleGroup, isNotEmpty);
});

test('detectPlateau identifies stagnation', () async {
  final service = WorkoutAnalyticsService();
  final gains = await service.calculateStrengthGains(clientId, '12weeks');

  expect(gains.gainsByExercise, isNotEmpty);
  // Add assertions for expected behavior
});
```

### Widget Tests

```dart
testWidgets('VolumeProgressChart displays correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: VolumeProgressChart(trendData: mockTrendData),
    ),
  );

  expect(find.byType(LineChart), findsOneWidget);
  expect(find.text('Volume Trend'), findsOneWidget);
});
```

---

## Troubleshooting

### Common Issues

**Issue:** PDF generation fails
- **Solution**: Ensure `path_provider` has storage permissions

**Issue:** Charts not exporting as images
- **Solution**: Wrap chart in `RepaintBoundary` with `GlobalKey`

**Issue:** Analytics loading slowly
- **Solution**: Add database indexes, implement caching

**Issue:** Missing data in reports
- **Solution**: Check `exercise_history` has sufficient data (min 2 entries per exercise)

---

## Future Enhancements

- **AI Insights**: GPT-4 integration for personalized recommendations
- **Video Progress**: Before/after video comparisons
- **Body Metrics**: Integration with weight, body fat, measurements
- **Social Features**: Share PRs to social media with graphics
- **Leaderboards**: Compare with other clients (anonymized)
- **Advanced Charts**: 3D visualizations, animated transitions
- **Mobile Widgets**: Home screen widgets for quick stats
- **Wearable Integration**: Sync with Apple Watch, Garmin

---

## Support

For issues or questions:
- GitHub Issues: [vagus_app/issues](https://github.com/yourorg/vagus_app/issues)
- Documentation: [docs.vagusapp.com](https://docs.vagusapp.com)
- Email: support@vagusapp.com

---

**Last Updated:** 2024-01-15
**Version:** 1.0.0