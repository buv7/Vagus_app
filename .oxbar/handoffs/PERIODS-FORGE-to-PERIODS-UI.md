# Handoff from PERIODS-FORGE to PERIODS-UI

**Date:** 2026-04-28
**Branch:** agent/periods-forge
**PR:** [PERIODS-FORGE] Periods schema + service + cycle prediction

## What's now available

### Consent gate

Before rendering **any** period data, check consent and show the opt-in screen:

```dart
import 'package:vagus_app/screens/periods/period_consent_screen.dart';
import 'package:vagus_app/services/periods_service.dart';

final hasConsent = await PeriodsService().hasPeriodTrackingConsent();
if (!hasConsent) {
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => PeriodConsentScreen(
      onConsented: () { /* proceed to tracking UI */ },
      onDeclined: () { /* stay on current screen */ },
    ),
  ));
}
```

`PeriodConsentScreen` (`lib/screens/periods/period_consent_screen.dart`) handles the
`grantPeriodTrackingConsent()` call internally, including a separate coach-share checkbox
that defaults to **unchecked**.

### Daily log entry

```dart
final id = await PeriodsService().logPeriodDay(
  date: DateTime.now(),
  flow: FlowLevel.medium,
  symptoms: [PeriodSymptom.cramps, PeriodSymptom.fatigue],
  notes: 'Mild discomfort today',
);
```

All sensitive fields are encrypted server-side — the UI never touches ciphertext.

### Reading logs (with decryption + audit)

```dart
final logs = await PeriodsService().getPeriodLogs(
  startDate: DateTime(2026, 4, 1),
  endDate: DateTime(2026, 4, 28),
  justification: 'cycle_chart_render', // one audit row per UI session
);
// logs → List<PeriodLog>
// .flow: FlowLevel?        (none/light/medium/heavy)
// .symptoms: List<PeriodSymptom>
// .notes: String?
// .logDate: DateTime
```

### Cycle management

```dart
// Start a new cycle (automatically closes any open cycle)
final cycleId = await PeriodsService().startNewCycle(DateTime.now());

// Get cycle history
final cycles = await PeriodsService().getCycles(limit: 6);
// List<MenstrualCycle>: .cycleStart, .cycleEnd?, .avgLengthDays?, .irregularFlag
```

### Prediction

```dart
final p = await PeriodsService().computePrediction();
if (p != null) {
  p.nextPeriodStart          // DateTime — predicted next period
  p.confidenceIntervalDays   // int — ± days around prediction
  p.nextPeriodEarliest       // DateTime
  p.nextPeriodLatest         // DateTime
  p.ovulationEstimate        // DateTime
  p.daysUntilNextPeriod      // int
  p.currentPhase             // CyclePhase
  p.cycleDay                 // int — day within current cycle
  p.avgCycleLengthDays       // double
  p.isIrregular              // bool — soften language when true
}
```

**IMPORTANT:** Do NOT pass `CyclePrediction` data to any third-party LLM or API.
See `VAULT-to-PERIODS-FORGE.md` for the rationale.

### Phase awareness for training UI

```dart
final phase = await PeriodsService().currentPhase();
// CyclePhase.menstrual | .follicular | .ovulation | .luteal
// phase?.displayName   — "Follicular"
// phase?.description   — short coaching hint (safe to display)
// phase?.color         — Color for accent tinting
```

## Models summary

| File | Key type |
|------|----------|
| `lib/models/periods/flow_level.dart` | `FlowLevel` enum: none/light/medium/heavy |
| `lib/models/periods/period_symptom.dart` | `PeriodSymptom` enum — 9 presets |
| `lib/models/periods/cycle_phase.dart` | `CyclePhase` enum — 4 phases with color/description |
| `lib/models/periods/period_log.dart` | `PeriodLog` — decrypted daily log |
| `lib/models/periods/menstrual_cycle.dart` | `MenstrualCycle` — cycle record |
| `lib/models/periods/cycle_prediction.dart` | `CyclePrediction` — prediction output |

## Database tables (read-only for UI)

| Table | Notes |
|-------|-------|
| `period_tracking_consent` | Opt-in state; always read via service |
| `period_logs` | Read ONLY via `periods_get_logs_decrypted` RPC |
| `cycles` | No encrypted columns — readable directly |

## Audit requirement

When rendering a chart or list that reads encrypted period_logs, pass a
descriptive `justification` string per render session:

```dart
justification: 'cycle_chart_render'  // not 'self_view'
```

One call to `getPeriodLogs()` per screen render is enough — do not loop.

## Settings screen hook

To let users change coach-share consent after first opt-in:

```dart
await PeriodsService().setCoachShareConsent(true);   // enable
await PeriodsService().setCoachShareConsent(false);  // disable

await PeriodsService().revokePeriodTrackingConsent(); // opt out entirely
```

## UX notes

- When `prediction.isIrregular == true`, use softened language:
  "estimated" rather than "expected", "around" rather than "on".
- The consent screen deliberately has no pre-checked boxes — no opt-in by default.
