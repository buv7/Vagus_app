# Handoff from PERIODS-FORGE to PERIODS-INTEGRATE

**Date:** 2026-04-28
**Branch:** agent/periods-forge
**PR:** [PERIODS-FORGE] Periods schema + service + cycle prediction

## What's now available

### Coach access to client period data

Guarded by a two-condition consent check (`opted_in = true AND coach_share = true`).
One audit row is written per batch read.

```dart
// Call from coach session
final rows = await supabase.rpc('periods_get_logs_for_coach', params: {
  'p_client_user_id': clientUserId,
  'p_start_date': '2026-04-01',
  'p_end_date': '2026-04-28',
  'p_justification': 'coach_view',
}) as List<dynamic>;
// Each row: { id, log_date, flow (text), symptoms (json-text), notes (text) }
```

The RPC raises an exception if `coach_share = false` — catch it and render a
"client has not shared cycle data" message, not an error screen.

### Checking client consent (from coach side)

```dart
final row = await supabase
    .from('period_tracking_consent')
    .select('opted_in, coach_share')
    .eq('user_id', clientUserId)
    .maybeSingle();
final canSee = (row?['opted_in'] as bool? ?? false) &&
               (row?['coach_share'] as bool? ?? false);
```

### Phase hook for cycle-aware programming

```dart
// Call on client session — returns the current phase based on their cycle history
final phase = await PeriodsService().currentPhase();
// null if no cycle data
```

Use `phase?.description` to surface a brief coaching hint in session planning:

| Phase | `CyclePhase.description` |
|-------|--------------------------|
| Menstrual | Menstruation. Energy may be lower; prioritise recovery. |
| Follicular | Estrogen rising. Good window for higher-intensity training. |
| Ovulation | Peak energy and strength. Ideal for personal records. |
| Luteal | Progesterone dominant. Moderate intensity; watch for fatigue. |

`phase?.color` gives a consistent `Color` accent per phase — reuse it across
cycle widgets for visual consistency.

### Prediction integration

```dart
final p = await PeriodsService().computePrediction();
```

| Field | Integration use case |
|-------|---------------------|
| `nextPeriodStart` | Suggest deload week starting ~2 days before |
| `nextPeriodEarliest` / `Latest` | Widen scheduling window for irregular cycles |
| `ovulationEstimate` | Flag as peak-strength window in workout plan |
| `currentPhase` | Phase-aware session template selection |
| `daysUntilNextPeriod` | Countdown display in coach dashboard |
| `isIrregular` | Soften language; widen scheduling windows |

**IMPORTANT:** The prediction is derived from plaintext cycle dates on the client.
Do NOT pass it to any third-party LLM or analytics endpoint.
See `VAULT-to-PERIODS-FORGE.md` for the rationale.

### Symptom presets (9 coach-relevant)

```dart
// PeriodSymptom enum keys (used in JSON stored in symptoms_enc)
// cramps, headache, mood, fatigue, bloating,
// breastTenderness, acne, foodCraving, libido
```

All are considered coach-relevant for programming adjustments.

## Database

| Table | What PERIODS-INTEGRATE reads |
|-------|------------------------------|
| `period_tracking_consent` | `coach_share`, `opted_in` flags |
| `cycles` | All columns — no encryption, user-scoped RLS |
| `period_logs` | Via `periods_get_logs_for_coach` RPC **only** |

## Integration checklist

- [ ] Gate all period-data UI on `coach_share = true` before rendering
- [ ] Use descriptive `p_justification` when calling the RPC
- [ ] Surface `CyclePhase.description` in session planning view
- [ ] Flag predicted ovulation window as strength-peak in workout template
- [ ] Flag predicted period start as suggested deload / recovery week
- [ ] Handle "client has not shared cycle data" RPC exception gracefully
- [ ] Never pass cycle dates or predictions to an LLM endpoint
