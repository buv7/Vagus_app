# Intelligent Workout Progression System

Comprehensive automated progression system with multiple periodization models, plateau detection, and PR tracking.

## Overview

The Progression System provides:
- **5 Periodization Models** (Linear, Wave, Block, DUP, Percentage-based)
- **Auto-Progression Rules** based on performance data
- **Plateau Detection** with confidence scoring
- **Deload Timing** recommendations
- **PR Detection** and celebration
- **Progression Analytics** and visualizations
- **Volume Tracking** and estimation

---

## Architecture

### Core Components

1. **ProgressionService** (`progression_service.dart`)
   - Core progression algorithms
   - Periodization model implementations
   - Auto-progression decision making
   - Deload generation

2. **ProgressionAnalyticsService** (`progression_analytics_service.dart`)
   - Progression rate tracking
   - Volume analysis
   - Strength gains estimation
   - PR detection
   - Plateau alerts

3. **Progression Models** (`progression_models.dart`)
   - Data models and enums
   - Settings and configurations
   - Result types

---

## Periodization Models

### 1. Linear Progression

**Best For**: Beginners, novice lifters
**Duration**: 8-16 weeks until plateau
**Progression**: Add fixed weight each week (2.5-5%)

```dart
final settings = ProgressionSettings(
  type: ProgressionType.linear,
  linearIncreasePercentage: 2.5, // 2.5% per week
  minimumWeightIncrement: 2.5, // Round to 2.5kg
);

final nextWeek = await progressionService.calculateNextWeekProgression(
  currentWeek,
  clientId: clientId,
  settings: settings,
);
```

**Example**:
```
Week 1: Bench Press 100kg × 5 × 3
Week 2: Bench Press 102.5kg × 5 × 3  (+2.5%)
Week 3: Bench Press 105kg × 5 × 3     (+2.5%)
Week 4: Bench Press 107.5kg × 5 × 3   (+2.5%)
```

---

### 2. Wave/Undulating Periodization

**Best For**: Intermediate lifters, breaking plateaus
**Duration**: Continuous cycling (4-week waves)
**Progression**: Vary intensity week-to-week

```dart
final settings = ProgressionSettings(
  type: ProgressionType.waveUndulating,
);

// Uses standard wave pattern by default
// Week 1: 100% (Medium)
// Week 2: 90%  (Light)
// Week 3: 105% (Heavy)
// Week 4: 85%  (Deload)

final weeks = await progressionService.applyWaveProgression(
  weeks,
  pattern: WavePattern.standard,
);
```

**Wave Patterns**:

| Pattern | Week 1 | Week 2 | Week 3 | Week 4 |
|---------|--------|--------|--------|--------|
| Standard | 100% | 90% | 105% | 85% |
| Aggressive | 100% | 105% | 110% | 80% |
| Conservative | 100% | 95% | 100% | 90% |

**Example**:
```
Week 1: Squat 150kg × 5 × 3    (Medium)
Week 2: Squat 135kg × 8 × 3    (Light)
Week 3: Squat 157.5kg × 3 × 3  (Heavy)
Week 4: Squat 127.5kg × 10 × 2 (Deload)
```

---

### 3. Block Periodization

**Best For**: Advanced lifters, powerlifters, athletes
**Duration**: 10-week cycles (4+3+2+1)
**Progression**: Focus on different qualities in blocks

```dart
final settings = ProgressionSettings(
  type: ProgressionType.blockPeriodization,
);

// Standard cycle:
// Phase 1 (4 weeks): Accumulation - High volume, moderate intensity
// Phase 2 (3 weeks): Intensification - Moderate volume, high intensity
// Phase 3 (2 weeks): Realization - Low volume, peak intensity
// Phase 4 (1 week): Deload - Recovery
```

**Block Multipliers**:

| Phase | Volume | Intensity | Focus |
|-------|--------|-----------|-------|
| Accumulation | 120% | 85% | Hypertrophy, Work Capacity |
| Intensification | 90% | 110% | Strength Building |
| Realization | 70% | 120% | Peak Performance |
| Deload | 50% | 60% | Recovery |

**Example**:
```
Accumulation (Weeks 1-4):
  Bench Press: 80kg × 10 × 5 (high volume)

Intensification (Weeks 5-7):
  Bench Press: 95kg × 5 × 4 (moderate volume, higher weight)

Realization (Weeks 8-9):
  Bench Press: 105kg × 3 × 3 (low volume, peak weight)

Deload (Week 10):
  Bench Press: 65kg × 8 × 2 (recovery)
```

---

### 4. DUP (Daily Undulating Periodization)

**Best For**: Intermediate/advanced, high frequency training
**Duration**: Continuous cycling
**Progression**: Vary intensity day-to-day within same week

```dart
final settings = ProgressionSettings(
  type: ProgressionType.dup,
);

// Standard week:
// Day 1: Heavy (100% intensity, 80% volume)
// Day 2: Moderate (85% intensity, 100% volume)
// Day 3: Light (70% intensity, 120% volume)
```

**Example Week**:
```
Monday (Heavy Day):
  Squat: 160kg × 3 × 4

Wednesday (Moderate Day):
  Squat: 136kg × 5 × 5

Friday (Light Day):
  Squat: 112kg × 8 × 6
```

---

### 5. Percentage-Based Progression

**Best For**: Powerlifters, strength athletes
**Duration**: Flexible (8-12 week cycles)
**Progression**: Based on % of 1RM

```dart
final settings = ProgressionSettings(
  type: ProgressionType.percentageBased,
);

// Exercises programmed with %1RM
// Example: 5x5 @ 80% 1RM
// Service auto-calculates weights based on current 1RM
```

**Example Cycle**:
```
Week 1: 5×5 @ 75% 1RM
Week 2: 5×4 @ 80% 1RM
Week 3: 5×3 @ 85% 1RM
Week 4: 3×5 @ 70% 1RM (Deload)
Week 5: 5×5 @ 77.5% 1RM
...
```

---

## Auto-Progression Rules

The system makes intelligent decisions based on performance data:

### Rule 1: Successful Completion at Low RPE
```
IF: Client completes all sets and reps
AND: Average RPE < 8
THEN: Increase weight by 2.5-5%
```

```dart
final decision = await progressionService.makeProgressionDecision(
  exercise,
  history,
);

if (decision.shouldProgress) {
  // Apply suggested weight increase
  final newExercise = exercise.copyWith(
    weight: exercise.weight! + decision.suggestedWeightChange,
  );
}
```

### Rule 2: Failed Multiple Sets
```
IF: Client fails 2+ sets
THEN: Suggest deload (reduce weight by 10%)
```

### Rule 3: High RPE Despite Completion
```
IF: Client completes all sets
AND: Average RPE >= 9
THEN: Maintain current weight
```

### Rule 4: Stagnation Detection
```
IF: Weight unchanged for 4+ sessions
THEN: Try small increase (2.5%) or suggest variation
```

---

## Plateau Detection

Intelligent plateau detection with confidence scoring:

```dart
final plateau = await progressionService.detectPlateau(exerciseHistory);

if (plateau.isPlateaued && plateau.isHighConfidence) {
  // Show alert to coach
  print('Plateau detected: ${plateau.reason}');
  print('Weeks stagnant: ${plateau.weeksStagnant}');
  print('Suggestions: ${plateau.suggestions.join(", ")}');
}
```

**Plateau Indicators**:
- No weight increase for 3+ weeks
- No volume increase for 3+ weeks
- Multiple failed sets in recent sessions
- High RPE with no progress

**Confidence Scoring**:
```
High Confidence (0.8+):
  - No weight increase: +0.3
  - No volume increase: +0.3
  - 3+ weeks stagnant: +0.2
  - 2+ recent failures: +0.2

Medium Confidence (0.5-0.8):
  - Some but not all indicators

Low Confidence (<0.5):
  - Insufficient data or mixed signals
```

**Suggested Solutions**:
1. Schedule deload week
2. Change exercise variation
3. Increase training frequency
4. Check recovery factors (sleep, nutrition, stress)
5. Add volume (more sets/exercises)

---

## Deload Timing

Automatic deload recommendations based on training history:

```dart
final deloadRec = await progressionService.suggestDeloadTiming(
  weekHistory,
  settings: settings,
);

if (deloadRec.shouldDeload) {
  print('Deload recommended: ${deloadRec.reason}');
  print('Schedule for week: ${deloadRec.recommendedWeekNumber}');

  // Generate deload week
  final deloadWeek = progressionService.generateDeloadWeek(
    normalWeek,
    intensityReduction: deloadRec.intensityReduction,
  );
}
```

**Deload Triggers**:
1. **Scheduled**: Every 4-6 weeks (configurable)
2. **Volume Spike**: >30% increase from average
3. **Fatigue Signs**: Multiple indicators of overtraining
4. **Performance Decline**: Failing sets, high RPE

**Deload Protocol** (50% intensity reduction):
```
Normal Week:
  Bench Press: 100kg × 5 × 5

Deload Week:
  Bench Press: 50kg × 3-4 × 5  (50% weight, 30% less sets, +2 RIR)
```

---

## PR Detection and Celebration

Automatic PR detection with celebration messages:

```dart
final prs = await analyticsService.detectNewPRs(
  clientId: clientId,
  sinceDate: DateTime.now().subtract(Duration(days: 7)),
);

for (final pr in prs) {
  print(pr.celebrationMessage);
  // Show notification to client
  _showPRCelebration(pr);
}
```

**PR Types Tracked**:

1. **Weight PR**: New max weight for exercise
   ```
   🎉 New Weight PR! Bench Press: 105.0kg (5.0% increase)
   ```

2. **Volume PR**: New max total volume (sets × reps × weight)
   ```
   💪 New Volume PR! Squat: 12,500kg total volume
   ```

3. **Reps PR**: New max reps at given weight
   ```
   🔥 New Reps PR! Pull-ups: 15 reps
   ```

4. **1RM PR**: New estimated 1RM
   ```
   💪 New 1RM PR! Deadlift: 180.0kg estimated
   ```

5. **Tonnage PR**: New total weight lifted in period
   ```
   🏋️ New Tonnage PR! Total lifted: 25.3 tons this week
   ```

---

## Progression Analytics

### Progression Rate Tracking

```dart
final rate = await analyticsService.calculateProgressionRate(
  clientId: clientId,
  exerciseName: 'Bench Press',
  weeksToAnalyze: 12,
);

print('Weekly gain: ${rate.weeklyGainPercentage}%');
print('Total gain: ${rate.totalGainPercentage}%');
print('Trend: ${rate.trend}'); // 'improving', 'stable', 'declining'
```

**Metrics Included**:
- Weekly gain percentage
- Total gain percentage
- Trend analysis
- Max weight achieved
- Max volume achieved
- Total sessions
- Average RPE
- Consistency score

### Volume Progression Graphs

```dart
final volumeData = await analyticsService.getVolumeProgressionData(
  clientId: clientId,
  exerciseName: 'Squat',
  weeksToShow: 12,
);

// Use chart_data for visualization
final chartPoints = volumeData['chart_data'] as List;
for (final point in chartPoints) {
  print('Week ${point['week']}: ${point['volume']}kg volume');
}
```

**Data Structure**:
```dart
{
  'chart_data': [
    {
      'week': 1,
      'volume': 5000.0,
      'avg_weight': 100.0,
      'total_sets': 15,
      'sessions': 3,
    },
    // ... more weeks
  ],
  'total_volume': 60000.0,
  'avg_weekly_volume': 5000.0,
  'weeks_tracked': 12,
}
```

### Strength Gains Estimation

```dart
final gains = await analyticsService.estimateStrengthGains(
  clientId: clientId,
  exerciseName: 'Bench Press',
  weeksToAnalyze: 12,
);

if (gains['success']) {
  print('Starting 1RM: ${gains['starting_1rm']}kg');
  print('Current 1RM: ${gains['current_1rm']}kg');
  print('Gain: ${gains['gain_kg']}kg (${gains['gain_percentage']}%)');
  print('Projected 12 weeks: ${gains['projected_1rm_12weeks']}kg');
}
```

**Projections** (assuming linear progression continues):
- 4-week projection
- 8-week projection
- 12-week projection

---

## UI Integration Examples

### 1. Apply Auto-Progression Button

```dart
// In CoachPlanBuilderScreen
ElevatedButton.icon(
  onPressed: () async {
    final result = await _showProgressionPreview();
    if (result == true) {
      await _applyProgression();
    }
  },
  icon: Icon(Icons.trending_up),
  label: Text('Apply Auto-Progression'),
)

Future<bool?> _showProgressionPreview() async {
  final nextWeek = await progressionService.calculateNextWeekProgression(
    currentWeek,
    clientId: clientId,
    settings: progressionSettings,
  );

  return showDialog<bool>(
    context: context,
    builder: (context) => ProgressionPreviewDialog(
      currentWeek: currentWeek,
      nextWeek: nextWeek,
      onApply: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    ),
  );
}
```

### 2. Progression Preview Dialog

```dart
class ProgressionPreviewDialog extends StatelessWidget {
  final WorkoutWeek currentWeek;
  final WorkoutWeek nextWeek;
  final VoidCallback onApply;
  final VoidCallback onCancel;

  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Progression Preview'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Text('Week ${nextWeek.weekNumber}'),
            SizedBox(height: 16),
            ...nextWeek.days.expand((day) => [
              Text(day.label, style: TextStyle(fontWeight: FontWeight.bold)),
              ...day.exercises.map((exercise) => _buildExerciseComparison(exercise)),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onApply,
          child: Text('Apply Progression'),
        ),
      ],
    );
  }

  Widget _buildExerciseComparison(Exercise newExercise) {
    final oldExercise = _findMatchingExercise(newExercise, currentWeek);

    return ListTile(
      title: Text(newExercise.name),
      subtitle: Text(
        'Old: ${oldExercise?.weight}kg → New: ${newExercise.weight}kg',
      ),
      trailing: Icon(
        Icons.trending_up,
        color: Colors.green,
      ),
    );
  }
}
```

### 3. Manual Override Options

```dart
// Allow coach to manually adjust suggested progression
class ManualProgressionOverride extends StatefulWidget {
  final Exercise exercise;
  final double suggestedWeight;

  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adjust Progression'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Suggested: ${suggestedWeight}kg'),
          TextField(
            decoration: InputDecoration(labelText: 'Custom Weight (kg)'),
            keyboardType: TextInputType.number,
            controller: _weightController,
          ),
          SwitchListTile(
            title: Text('Apply to all similar exercises'),
            value: _applyToAll,
            onChanged: (value) => setState(() => _applyToAll = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _applyManualProgression(),
          child: Text('Apply'),
        ),
      ],
    );
  }
}
```

### 4. Plateau Alert Widget

```dart
class PlateauAlertBanner extends StatelessWidget {
  final PlateauDetection plateau;

  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plateau Detected',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(plateau.reason),
                SizedBox(height: 8),
                TextButton(
                  onPressed: () => _showPlateauSolutions(plateau),
                  child: Text('View Solutions'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 5. PR Celebration Animation

```dart
class PRCelebrationWidget extends StatefulWidget {
  final VolumeLandmark pr;

  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      content: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.blue],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            SizedBox(height: 16),
            Text(
              pr.celebrationMessage,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _shareToSocial(pr),
              child: Text('Share Achievement'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Configuration

### Default Settings

```dart
final defaultSettings = ProgressionSettings(
  type: ProgressionType.linear,
  linearIncreasePercentage: 2.5,
  minimumWeightIncrement: 2.5,
  deloadFrequency: 4,
  deloadIntensity: 0.5,
  autoDetectPlateau: true,
  targetRPE: 7.5,
);
```

### Custom Settings Per Client

```dart
final advancedSettings = ProgressionSettings(
  type: ProgressionType.blockPeriodization,
  deloadFrequency: 6,
  deloadIntensity: 0.4,
  autoDetectPlateau: true,
  targetRPE: 8.0,
  customSettings: {
    'block_duration': [4, 3, 2, 1],
    'intensity_curve': 'aggressive',
  },
);
```

---

## Best Practices

### 1. Start Conservative
```dart
// For new clients, start with linear progression
final beginnerSettings = ProgressionSettings(
  type: ProgressionType.linear,
  linearIncreasePercentage: 2.0, // Lower percentage
  deloadFrequency: 4,
);
```

### 2. Monitor RPE Data
```dart
// Ensure clients are tracking RPE
// Auto-progression is more accurate with RPE data
final decision = await progressionService.makeProgressionDecision(
  exercise,
  history,
);

if (decision.confidence < 0.5) {
  // Encourage RPE tracking
  _showRPEImportanceMessage();
}
```

### 3. Review Before Applying
```dart
// Always preview progression before applying
// Allow manual override
await _showProgressionPreview();
```

### 4. Respect Deload Timing
```dart
// Don't skip deloads
final deloadRec = await progressionService.suggestDeloadTiming(weekHistory);
if (deloadRec.shouldDeload) {
  // Schedule deload, don't push through fatigue
  _scheduleDeload(deloadRec.recommendedWeekNumber);
}
```

### 5. Celebrate PRs
```dart
// Show PR celebrations to motivate clients
final prs = await analyticsService.detectNewPRs(clientId: clientId);
for (final pr in prs) {
  _showPRCelebration(pr);
  _sendPushNotification(pr.celebrationMessage);
}
```

---

## Testing Checklist

- [ ] Linear progression calculates correctly
- [ ] Wave progression applies multipliers properly
- [ ] Block periodization transitions phases correctly
- [ ] DUP varies intensity day-to-day
- [ ] Percentage-based uses current 1RM
- [ ] Plateau detection identifies stagnation
- [ ] Deload timing triggers appropriately
- [ ] Auto-progression rules work as expected
- [ ] PR detection finds new records
- [ ] Volume tracking calculates totals
- [ ] Progression rate trends are accurate
- [ ] Manual overrides save correctly
- [ ] Preview shows before/after comparison

---

## Future Enhancements

1. **Machine Learning**: Train models on successful progressions
2. **Personalized Algorithms**: Adapt to individual response patterns
3. **Fatigue Monitoring**: Integrate HRV, sleep data
4. **Competition Peaking**: Auto-generate meet prep cycles
5. **Exercise Swapping**: Suggest variations when plateaued
6. **Social Features**: Share PRs, compare progressions
7. **Nutrition Integration**: Adjust progression based on surplus/deficit
8. **Injury Prevention**: Detect overuse patterns, suggest deloads earlier

---

## Support

For questions or issues:
1. Review this documentation
2. Check service implementations
3. Test with example data
4. Review progression models documentation