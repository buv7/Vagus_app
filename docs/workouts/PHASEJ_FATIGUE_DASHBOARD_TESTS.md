# Phase J: Fatigue Dashboard Testing Checklist

**Date**: 2025-01-22  
**Status**: Testing Guide

---

## Overview

This document provides a comprehensive testing checklist for the Phase J Fatigue Dashboard implementation.

---

## Pre-Testing Setup

### 1. Database Migrations
- [ ] Run migration: `20250122090000_fatigue_snapshots.sql`
- [ ] Run migration: `20250122090001_rpc_refresh_fatigue_snapshot.sql`
- [ ] Verify `fatigue_snapshots` table exists
- [ ] Verify RPC function `refresh_fatigue_snapshot` exists
- [ ] Verify RLS policies are active

### 2. Test Data
- [ ] Create test user (client)
- [ ] Create test coach user
- [ ] Link coach-client relationship in `coach_clients` table
- [ ] Create workout sessions with `exercise_logs` for test dates
- [ ] Ensure exercise logs have: reps, weight, rpe/rir, notes (for intensifiers)

---

## Client Dashboard Tests

### Basic Functionality
- [ ] Dashboard loads without errors
- [ ] Shows "No data available" when no snapshots exist
- [ ] Date selector works (Today, Yesterday, Pick date)
- [ ] Refresh button triggers snapshot computation
- [ ] Loading states display correctly
- [ ] Error states display correctly

### Snapshot Display
- [ ] Fatigue score (0-100) displays correctly
- [ ] Status label shows: Fresh (0-29), Accumulating (30-59), High (60-79), Critical (80-100)
- [ ] Status color matches score range
- [ ] CNS, Local, Joint component scores display
- [ ] Component chips show correct values

### Trend Chart
- [ ] 7-day trend loads (default)
- [ ] 14-day trend toggle works
- [ ] 28-day trend toggle works
- [ ] Chart displays data points correctly
- [ ] Empty state shows when no trend data
- [ ] Chart scales correctly (0-100)

### Muscle Fatigue List
- [ ] Muscles sorted by fatigue (descending)
- [ ] Progress bars show correct values
- [ ] Color coding: Green (<20), Blue (20-40), Orange (40-60), Red (60+)
- [ ] Empty state shows when no muscle data
- [ ] Muscle names formatted correctly (capitalize, replace underscores)

### Intensifier Contribution
- [ ] Top 5 intensifiers displayed
- [ ] Sorted by contribution (descending)
- [ ] Icons match intensifier type
- [ ] Empty state shows when no intensifier data
- [ ] Intensifier names formatted correctly

### Recommendations Panel
- [ ] Recommendations appear based on fatigue scores
- [ ] Overall fatigue recommendations (Fresh/Accumulating/High/Critical)
- [ ] CNS-specific recommendations when CNS > 40
- [ ] Joint-specific recommendations when Joint > 40
- [ ] Local-specific recommendations when Local > 40
- [ ] Panel hidden when all scores are low

### Data Persistence
- [ ] Snapshot created after refresh
- [ ] Snapshot retrievable on subsequent loads
- [ ] Cache works (5-minute TTL)
- [ ] Multiple date snapshots can coexist

---

## Coach Dashboard Tests

### Basic Functionality
- [ ] Dashboard loads without errors
- [ ] Client selector dropdown works
- [ ] Shows "No clients linked" when no clients
- [ ] Selected client name displays
- [ ] Refresh button works
- [ ] Loading states display correctly

### Multi-Client Access
- [ ] Coach can view Client A's fatigue
- [ ] Coach can view Client B's fatigue
- [ ] Switching clients updates dashboard
- [ ] Each client's data is independent
- [ ] Coach cannot access non-linked clients (RLS test)

### Data Display
- [ ] All client dashboard components work (same as client tests)
- [ ] Trend chart shows selected client's data
- [ ] Muscle fatigue shows selected client's data
- [ ] Intensifier contribution shows selected client's data

---

## RLS (Row Level Security) Tests

### Client Access
- [ ] Client can view own snapshots
- [ ] Client cannot view other clients' snapshots
- [ ] Client can insert own snapshots (via RPC)
- [ ] Client cannot insert snapshots for other users

### Coach Access
- [ ] Coach can view linked clients' snapshots
- [ ] Coach cannot view non-linked clients' snapshots
- [ ] Coach cannot insert snapshots (only via RPC with own user_id)

### Admin Access
- [ ] Admin can view all snapshots
- [ ] Admin can insert snapshots for any user (via RPC)

---

## Snapshot Computation Tests

### Data Fetching
- [ ] Fetches `exercise_logs` for selected date
- [ ] Falls back to `workout_logs` if `exercise_logs` unavailable
- [ ] Handles missing data gracefully
- [ ] Handles empty workout days

### Fatigue Calculation
- [ ] Uses existing `FatigueEngine` correctly
- [ ] Computes base set fatigue
- [ ] Applies intensifier multipliers
- [ ] Applies failure penalties (if detected)
- [ ] Aggregates per-muscle fatigue
- [ ] Aggregates per-intensifier fatigue
- [ ] Normalizes scores to 0-100 range

### Aggregates
- [ ] Volume load calculated (weight × reps)
- [ ] Hard sets counted (RIR ≤ 2)
- [ ] Near-failure sets counted (RIR ≤ 1)
- [ ] High-fatigue intensifier uses counted

### Snapshot Storage
- [ ] Snapshot upserted via RPC
- [ ] Unique constraint works (user_id, snapshot_date)
- [ ] Updates existing snapshot if date exists
- [ ] Creates new snapshot if date doesn't exist

---

## Edge Cases

### Empty Data
- [ ] No workout logs → Empty snapshot (all zeros)
- [ ] No exercise_logs → Falls back to workout_logs
- [ ] No workout_logs → Empty snapshot
- [ ] Missing RIR → Uses default multiplier
- [ ] Missing weight → Uses default multiplier
- [ ] Missing intensifier data → Base fatigue only

### Date Handling
- [ ] Today's date works
- [ ] Yesterday's date works
- [ ] Past dates work (within 365 days)
- [ ] Future dates rejected
- [ ] Date format correct (YYYY-MM-DD)

### Performance
- [ ] Large number of exercise_logs handled
- [ ] Multiple snapshots loaded quickly
- [ ] Cache reduces redundant queries
- [ ] Trend chart renders smoothly with 28 days

### Error Handling
- [ ] Network errors handled gracefully
- [ ] Database errors show user-friendly messages
- [ ] Invalid data doesn't crash app
- [ ] Missing permissions show appropriate message

---

## Integration Tests

### With Phase 4.8 Fatigue Engine
- [ ] Fatigue calculation matches Phase 4.8 logic
- [ ] Intensifier multipliers applied correctly
- [ ] Failure penalties applied correctly
- [ ] Density penalties applied correctly (if rest data available)

### With Workout Logging
- [ ] New workout session creates snapshot on refresh
- [ ] Multiple sessions in one day aggregate correctly
- [ ] Exercise logs with intensifiers tracked correctly

### With Coach-Client Relationships
- [ ] New coach-client link allows access
- [ ] Removed coach-client link denies access
- [ ] Inactive coach-client link denies access

---

## UI/UX Tests

### Visual Design
- [ ] Matches existing theme (DesignTokens)
- [ ] Colors consistent with app style
- [ ] Icons appropriate and clear
- [ ] Typography readable
- [ ] Spacing consistent

### Responsiveness
- [ ] Works on small screens
- [ ] Works on large screens
- [ ] Chart scales appropriately
- [ ] Lists scroll smoothly

### Accessibility
- [ ] Text readable (contrast)
- [ ] Touch targets adequate size
- [ ] Screen reader compatible (if applicable)

---

## Performance Benchmarks

### Snapshot Computation
- [ ] Single day computation < 2 seconds
- [ ] 7-day trend load < 3 seconds
- [ ] 28-day trend load < 5 seconds

### Memory
- [ ] No memory leaks on repeated loads
- [ ] Cache size reasonable (< 10MB)

---

## Regression Tests

### Existing Features
- [ ] Workout logging still works
- [ ] Exercise detail sheet still works
- [ ] Phase 4.8 fatigue engine unchanged
- [ ] Coach dashboard other features unaffected
- [ ] Client dashboard other features unaffected

---

## Known Limitations / TODOs

1. **Intensifier Detection**: Currently relies on exercise notes JSON or text parsing. May miss some intensifiers if not stored properly.

2. **Expected Rest**: Not stored in `exercise_logs`, so density penalties may not be accurate for historical data.

3. **Failure Detection**: Relies on notes or metadata. May not detect all failure sets.

4. **Muscle Group Mapping**: Uses `primary_muscles` and `secondary_muscles` from exercises. If exercise data missing, defaults to "unknown".

5. **Normalization**: Uses fixed `maxDailyFatigue = 100.0`. May need adjustment based on real-world data.

---

## Test Data Examples

### Example Snapshot JSON
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "snapshot_date": "2025-01-22",
  "fatigue_score": 45,
  "cns_score": 18,
  "local_score": 25,
  "joint_score": 12,
  "volume_load": 12500.0,
  "hard_sets": 8,
  "near_failure_sets": 3,
  "high_fatigue_intensifier_uses": 2,
  "muscle_fatigue": {
    "chest": 18,
    "back": 12,
    "shoulders": 8
  },
  "intensifier_fatigue": {
    "rest_pause": 14,
    "drop_sets": 8
  },
  "notes": {
    "computed_at": "2025-01-22T10:30:00Z",
    "sets_processed": 24
  }
}
```

---

**End of Testing Checklist**
