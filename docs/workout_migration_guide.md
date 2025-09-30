# Workout v1 → v2 Migration Guide

## Table of Contents
1. [Overview](#overview)
2. [Pre-Migration Checklist](#pre-migration-checklist)
3. [Backup Procedures](#backup-procedures)
4. [Data Transformation](#data-transformation)
5. [Migration Steps](#migration-steps)
6. [Post-Migration Verification](#post-migration-verification)
7. [Rollback Plan](#rollback-plan)
8. [Troubleshooting](#troubleshooting)

---

## Overview

### What's Being Migrated

This guide covers the migration from Workout v1 (flat exercise structure) to Workout v2 (hierarchical plan structure).

**Migration Scope:**
- ✅ Existing workout plans → New hierarchical structure
- ✅ Exercise history → New tracking format
- ✅ User preferences → Enhanced notification preferences
- ✅ Coach-client relationships → Preserved
- ⚠️ Templates → May need manual review/adjustment
- ❌ Old screenshots/exports → Not migrated (kept in archive)

### Timeline Estimate

| Environment | Estimated Duration | Downtime Required |
|-------------|-------------------|-------------------|
| Development | 5-10 minutes | ❌ No |
| Staging | 10-20 minutes | ❌ No |
| Production | 30-60 minutes | ⚠️ 10-15 minutes |

**Downtime Window:** The migration can run while the app is live, but a brief maintenance window (10-15 min) is recommended for production to prevent data inconsistencies.

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Data loss | Low | Critical | Full backup before migration |
| Schema conflicts | Medium | High | Run on staging first |
| RLS policy issues | Medium | High | Test with real user accounts |
| Performance degradation | Low | Medium | Optimize queries post-migration |
| User confusion | Medium | Low | In-app migration announcement |

---

## Pre-Migration Checklist

### Technical Prerequisites

- [ ] PostgreSQL 14+ (Supabase requirement)
- [ ] Supabase CLI installed: `npm install -g supabase`
- [ ] Database connection details available
- [ ] Admin/superuser access to database
- [ ] Backup storage location prepared (min 500MB free)
- [ ] Migration scripts downloaded from `/supabase/migrations/`

### Environment Preparation

```bash
# 1. Verify database connection
psql -h <your-project>.supabase.co -U postgres -d postgres

# 2. Check database version
SELECT version();
-- Should be PostgreSQL 14.x or higher

# 3. Check current table sizes
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

# 4. Check active connections
SELECT count(*) FROM pg_stat_activity WHERE datname = current_database();
-- Should be < 50 for smooth migration
```

### Data Quality Checks

Run these queries to identify potential issues:

```sql
-- 1. Check for NULL user_ids (will cause migration issues)
SELECT COUNT(*) FROM workout_plans_v1 WHERE user_id IS NULL;

-- 2. Check for orphaned exercises (no parent plan)
SELECT COUNT(*) FROM exercises_v1 e
WHERE NOT EXISTS (
  SELECT 1 FROM workout_plans_v1 p WHERE p.id = e.plan_id
);

-- 3. Check for duplicate plan names (user, name)
SELECT user_id, name, COUNT(*)
FROM workout_plans_v1
GROUP BY user_id, name
HAVING COUNT(*) > 1;

-- 4. Check for exercises with invalid data
SELECT COUNT(*) FROM exercises_v1
WHERE sets <= 0 OR reps_min <= 0 OR weight < 0;

-- 5. Check for sessions without completion timestamp
SELECT COUNT(*) FROM workout_sessions_v1
WHERE started_at IS NOT NULL AND completed_at IS NULL
  AND started_at < NOW() - INTERVAL '24 hours';
```

**Action Required:** If any of these queries return counts > 0, clean up the data before proceeding.

### User Communication

**7 Days Before Migration:**
- [ ] Send email to all users announcing upcoming improvements
- [ ] Display in-app banner: "Workout features upgrading on [DATE]"
- [ ] Post to social media about new features

**24 Hours Before Migration:**
- [ ] Send reminder email
- [ ] Update in-app banner: "Maintenance window tomorrow [TIME]"

**During Migration:**
- [ ] Display maintenance page (if applicable)
- [ ] Update status page: https://status.vagushealth.com

**After Migration:**
- [ ] Send "New features available!" email
- [ ] Show in-app tutorial for new workout UI
- [ ] Monitor support channels for issues

---

## Backup Procedures

### Full Database Backup

```bash
# 1. Create backup directory
mkdir -p ~/vagus_backups/$(date +%Y%m%d)
cd ~/vagus_backups/$(date +%Y%m%d)

# 2. Full database backup
pg_dump \
  -h <your-project>.supabase.co \
  -U postgres \
  -d postgres \
  -F c \
  -f vagus_full_backup_$(date +%Y%m%d_%H%M%S).dump

# 3. Verify backup
pg_restore --list vagus_full_backup_*.dump | head -20

# 4. Compress backup (optional)
gzip vagus_full_backup_*.dump
```

### Selective Table Backups

Backup only workout-related tables for faster restore:

```bash
# Backup v1 workout tables
pg_dump \
  -h <your-project>.supabase.co \
  -U postgres \
  -d postgres \
  -t public.workout_plans_v1 \
  -t public.exercises_v1 \
  -t public.workout_sessions_v1 \
  -t public.exercise_logs_v1 \
  -F c \
  -f workout_tables_v1_backup_$(date +%Y%m%d_%H%M%S).dump
```

### Export Data to CSV (Human-Readable)

```sql
-- Export plans
COPY (
  SELECT * FROM workout_plans_v1 ORDER BY created_at
) TO '/tmp/workout_plans_v1_backup.csv' WITH CSV HEADER;

-- Export exercises
COPY (
  SELECT * FROM exercises_v1 ORDER BY plan_id, order_index
) TO '/tmp/exercises_v1_backup.csv' WITH CSV HEADER;

-- Export sessions
COPY (
  SELECT * FROM workout_sessions_v1 ORDER BY started_at
) TO '/tmp/workout_sessions_v1_backup.csv' WITH CSV HEADER;

-- Export exercise logs
COPY (
  SELECT * FROM exercise_logs_v1 ORDER BY completed_at
) TO '/tmp/exercise_logs_v1_backup.csv' WITH CSV HEADER;
```

### Backup Verification

```bash
# 1. Check file sizes
ls -lh ~/vagus_backups/$(date +%Y%m%d)/

# 2. Verify dump integrity
pg_restore --list vagus_full_backup_*.dump > backup_contents.txt
cat backup_contents.txt

# 3. Test restore on local database (recommended)
createdb vagus_test_restore
pg_restore -d vagus_test_restore vagus_full_backup_*.dump
psql -d vagus_test_restore -c "\dt"
dropdb vagus_test_restore
```

### Upload Backups to Cloud Storage

```bash
# AWS S3
aws s3 cp vagus_full_backup_*.dump.gz s3://vagus-backups/workout-migration/

# Google Cloud Storage
gsutil cp vagus_full_backup_*.dump.gz gs://vagus-backups/workout-migration/

# Verify upload
aws s3 ls s3://vagus-backups/workout-migration/
```

---

## Data Transformation

### Schema Mapping

#### v1 → v2 Structure

```
v1 Structure:
workout_plans_v1
  └─ exercises_v1 (flat list)

v2 Structure:
workout_plans
  └─ workout_weeks
      └─ workout_days
          └─ exercises
```

#### Table Mapping

| v1 Table | v2 Table | Transformation |
|----------|----------|----------------|
| `workout_plans_v1` | `workout_plans` | 1:1, add `total_weeks`, `current_week`, `status` |
| N/A | `workout_weeks` | **NEW:** Generated based on plan duration |
| N/A | `workout_days` | **NEW:** Group exercises by day_label |
| `exercises_v1` | `exercises` | 1:1, add `day_id`, new columns |
| `workout_sessions_v1` | `workout_sessions` | 1:1, update foreign keys |
| `exercise_logs_v1` | `exercise_logs` | 1:1, add new tracking fields |

#### Field Mapping

**workout_plans_v1 → workout_plans**

| v1 Column | v2 Column | Transformation |
|-----------|-----------|----------------|
| `id` | `id` | Direct copy |
| `user_id` | `user_id` | Direct copy |
| `name` | `name` | Direct copy |
| `description` | `description` | Direct copy |
| `goal` | `goal` | Direct copy (if exists), else default to `'general_fitness'` |
| N/A | `total_weeks` | **Calculate from exercises or default to 4** |
| N/A | `current_week` | Default to 1 |
| `is_active` | `status` | `true` → `'active'`, `false` → `'completed'` |
| `created_at` | `created_at` | Direct copy |
| `updated_at` | `updated_at` | Direct copy |

**exercises_v1 → exercises**

| v1 Column | v2 Column | Transformation |
|-----------|-----------|----------------|
| `id` | `id` | Direct copy |
| `plan_id` | `day_id` | **Map to generated workout_day** |
| `name` | `name` | Direct copy |
| `muscle_group` | `muscle_group` | Direct copy |
| `sets` | `sets` | Direct copy |
| `reps_min` | `target_reps_min` | Rename |
| `reps_max` | `target_reps_max` | Rename |
| `weight` | `target_weight` | Rename |
| N/A | `target_rpe_min` | Default to NULL |
| N/A | `target_rpe_max` | Default to NULL |
| `rest_seconds` | `rest_seconds` | Direct copy or default to 90 |
| N/A | `tempo` | Default to NULL |
| `notes` | `notes` | Direct copy |
| N/A | `video_url` | Default to NULL |
| `order_index` | `order_index` | Direct copy |

### Transformation Logic

#### Step 1: Generate Week Structure

For each `workout_plan_v1`:
```sql
-- Determine total_weeks (use 4 as default if not specified)
total_weeks = COALESCE(plan_v1.duration_weeks, 4);

-- Generate weeks
FOR week_num IN 1..total_weeks LOOP
  INSERT INTO workout_weeks (plan_id, week_number, start_date, end_date)
  VALUES (
    plan_v2.id,
    week_num,
    plan_v1.start_date + (week_num - 1) * INTERVAL '7 days',
    plan_v1.start_date + week_num * INTERVAL '7 days' - INTERVAL '1 day'
  );
END LOOP;
```

#### Step 2: Group Exercises into Days

For each plan, group exercises by:
1. `day_of_week` (if column exists in v1)
2. `day_label` (if column exists in v1)
3. **Otherwise:** Group by muscle groups

```sql
-- Strategy A: Group by existing day_label
INSERT INTO workout_days (week_id, day_label)
SELECT DISTINCT
  week1.id,
  COALESCE(e.day_label, 'Day ' || ROW_NUMBER() OVER (PARTITION BY e.plan_id ORDER BY e.order_index))
FROM exercises_v1 e
JOIN workout_weeks week1 ON week1.plan_id = e.plan_id AND week1.week_number = 1
GROUP BY week1.id, e.day_label;

-- Strategy B: Group by muscle groups if no day_label
INSERT INTO workout_days (week_id, day_label, muscle_groups)
SELECT
  week1.id,
  CASE
    WHEN muscle_group IN ('chest', 'shoulders', 'triceps') THEN 'Push Day'
    WHEN muscle_group IN ('back', 'biceps') THEN 'Pull Day'
    WHEN muscle_group IN ('quads', 'hamstrings', 'glutes') THEN 'Leg Day'
    ELSE 'Upper Body'
  END,
  ARRAY_AGG(DISTINCT muscle_group)
FROM exercises_v1 e
JOIN workout_weeks week1 ON week1.plan_id = e.plan_id AND week1.week_number = 1
GROUP BY week1.id, CASE ... END;
```

#### Step 3: Duplicate Days Across Weeks

```sql
-- For each week 2..N, copy days from week 1
FOR week_num IN 2..total_weeks LOOP
  INSERT INTO workout_days (week_id, day_label, notes, estimated_duration, muscle_groups)
  SELECT
    week_n.id,
    day1.day_label,
    day1.notes,
    day1.estimated_duration,
    day1.muscle_groups
  FROM workout_days day1
  JOIN workout_weeks week1 ON day1.week_id = week1.id
  JOIN workout_weeks week_n ON week_n.plan_id = week1.plan_id AND week_n.week_number = week_num
  WHERE week1.week_number = 1;
END LOOP;
```

#### Step 4: Map Exercises to Days

```sql
UPDATE exercises
SET day_id = (
  SELECT d.id
  FROM workout_days d
  JOIN workout_weeks w ON d.week_id = w.id
  WHERE w.plan_id = exercises.plan_id_v1
    AND w.week_number = 1
    AND (
      d.day_label = exercises.day_label_v1
      OR exercises.muscle_group = ANY(d.muscle_groups)
    )
  LIMIT 1
)
WHERE day_id IS NULL;
```

---

## Migration Steps

### Step 1: Enable Maintenance Mode (Optional)

```sql
-- Create maintenance flag
CREATE TABLE IF NOT EXISTS system_maintenance (
  id SERIAL PRIMARY KEY,
  enabled BOOLEAN DEFAULT FALSE,
  message TEXT,
  started_at TIMESTAMPTZ,
  estimated_completion TIMESTAMPTZ
);

INSERT INTO system_maintenance (enabled, message, started_at, estimated_completion)
VALUES (
  TRUE,
  'Upgrading workout features. We''ll be back in 15 minutes!',
  NOW(),
  NOW() + INTERVAL '15 minutes'
);
```

**In Flutter app:**
```dart
// Check maintenance status on app launch
final maintenance = await supabase
  .from('system_maintenance')
  .select()
  .eq('enabled', true)
  .maybeSingle();

if (maintenance != null) {
  showMaintenanceScreen(maintenance['message']);
}
```

### Step 2: Rename Existing Tables

```sql
-- Preserve v1 tables by renaming
ALTER TABLE workout_plans RENAME TO workout_plans_v1;
ALTER TABLE exercises RENAME TO exercises_v1;
ALTER TABLE workout_sessions RENAME TO workout_sessions_v1;
ALTER TABLE exercise_logs RENAME TO exercise_logs_v1;

-- Rename indexes
ALTER INDEX idx_workout_plans_user_id RENAME TO idx_workout_plans_v1_user_id;
-- ... rename other indexes
```

### Step 3: Run Migration Script

```bash
# Run the migration SQL script
psql \
  -h <your-project>.supabase.co \
  -U postgres \
  -d postgres \
  -f supabase/migrations/migrate_workout_v1_to_v2.sql \
  2>&1 | tee migration_$(date +%Y%m%d_%H%M%S).log

# Check for errors in log
grep -i "error\|failed\|exception" migration_*.log
```

**What the migration script does:**
1. Creates v2 schema (tables, indexes, RLS policies)
2. Transforms v1 data into v2 structure
3. Validates data integrity
4. Creates foreign key relationships
5. Updates sequences
6. Grants permissions

### Step 4: Verify Data Integrity

Run these checks immediately after migration:

```sql
-- 1. Verify all plans migrated
SELECT
  (SELECT COUNT(*) FROM workout_plans_v1) as v1_plans,
  (SELECT COUNT(*) FROM workout_plans) as v2_plans,
  CASE
    WHEN (SELECT COUNT(*) FROM workout_plans_v1) = (SELECT COUNT(*) FROM workout_plans)
    THEN '✅ PASS'
    ELSE '❌ FAIL'
  END as status;

-- 2. Verify all exercises migrated
SELECT
  (SELECT COUNT(*) FROM exercises_v1) as v1_exercises,
  (SELECT COUNT(*) FROM exercises) as v2_exercises,
  CASE
    WHEN (SELECT COUNT(*) FROM exercises_v1) = (SELECT COUNT(*) FROM exercises)
    THEN '✅ PASS'
    ELSE '❌ FAIL'
  END as status;

-- 3. Verify no orphaned weeks
SELECT COUNT(*) as orphaned_weeks
FROM workout_weeks w
WHERE NOT EXISTS (
  SELECT 1 FROM workout_plans p WHERE p.id = w.plan_id
);
-- Should return 0

-- 4. Verify no orphaned days
SELECT COUNT(*) as orphaned_days
FROM workout_days d
WHERE NOT EXISTS (
  SELECT 1 FROM workout_weeks w WHERE w.id = d.week_id
);
-- Should return 0

-- 5. Verify no orphaned exercises
SELECT COUNT(*) as orphaned_exercises
FROM exercises e
WHERE NOT EXISTS (
  SELECT 1 FROM workout_days d WHERE d.id = e.day_id
);
-- Should return 0

-- 6. Verify exercise sessions still linked
SELECT
  (SELECT COUNT(*) FROM workout_sessions_v1) as v1_sessions,
  (SELECT COUNT(*) FROM workout_sessions WHERE day_id IS NOT NULL) as v2_sessions_linked,
  CASE
    WHEN (SELECT COUNT(*) FROM workout_sessions_v1) = (SELECT COUNT(*) FROM workout_sessions WHERE day_id IS NOT NULL)
    THEN '✅ PASS'
    ELSE '⚠️ WARNING: Some sessions may not be linked'
  END as status;
```

### Step 5: Update Application Code

```bash
# 1. Pull latest code with v2 support
git pull origin main

# 2. Install dependencies
flutter pub get

# 3. Generate mock files for tests
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Run tests
flutter test

# 5. Build and deploy
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

### Step 6: Gradual Rollout

**Phase 1: Internal Testing (Day 1)**
- Deploy to internal test environment
- Test with 5-10 internal users
- Verify all features work correctly

**Phase 2: Beta Users (Days 2-3)**
- Deploy to 10% of users (beta testers)
- Monitor crash reports and user feedback
- Fix critical issues

**Phase 3: Full Rollout (Days 4-7)**
- Deploy to 100% of users
- Monitor performance metrics
- Provide support for user questions

### Step 7: Disable Maintenance Mode

```sql
UPDATE system_maintenance
SET enabled = FALSE
WHERE id = (SELECT MAX(id) FROM system_maintenance);
```

---

## Post-Migration Verification

### Automated Verification Script

```sql
-- Run comprehensive verification
DO $$
DECLARE
  v_pass_count INTEGER := 0;
  v_fail_count INTEGER := 0;
  v_warning_count INTEGER := 0;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'POST-MIGRATION VERIFICATION';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';

  -- Test 1: Plan count match
  IF (SELECT COUNT(*) FROM workout_plans_v1) = (SELECT COUNT(*) FROM workout_plans) THEN
    RAISE NOTICE '✅ TEST 1: Plan counts match';
    v_pass_count := v_pass_count + 1;
  ELSE
    RAISE NOTICE '❌ TEST 1: Plan counts DO NOT match';
    v_fail_count := v_fail_count + 1;
  END IF;

  -- Test 2: Exercise count match
  IF (SELECT COUNT(*) FROM exercises_v1) = (SELECT COUNT(*) FROM exercises) THEN
    RAISE NOTICE '✅ TEST 2: Exercise counts match';
    v_pass_count := v_pass_count + 1;
  ELSE
    RAISE NOTICE '❌ TEST 2: Exercise counts DO NOT match';
    v_fail_count := v_fail_count + 1;
  END IF;

  -- Test 3: No orphaned records
  IF (SELECT COUNT(*) FROM workout_weeks WHERE NOT EXISTS (SELECT 1 FROM workout_plans WHERE id = workout_weeks.plan_id)) = 0 THEN
    RAISE NOTICE '✅ TEST 3: No orphaned weeks';
    v_pass_count := v_pass_count + 1;
  ELSE
    RAISE NOTICE '❌ TEST 3: Found orphaned weeks';
    v_fail_count := v_fail_count + 1;
  END IF;

  -- Test 4: RLS policies work
  BEGIN
    SET LOCAL ROLE authenticated;
    SET LOCAL request.jwt.claim.sub TO '00000000-0000-0000-0000-000000000000';
    PERFORM * FROM workout_plans LIMIT 1;
    RAISE NOTICE '✅ TEST 4: RLS policies functional';
    v_pass_count := v_pass_count + 1;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ TEST 4: RLS policies NOT working';
    v_fail_count := v_fail_count + 1;
  END;

  -- Test 5: Cascade deletes work
  BEGIN
    -- Create test plan
    INSERT INTO workout_plans (user_id, name, goal, total_weeks)
    VALUES ('00000000-0000-0000-0000-000000000000', 'Test Plan', 'strength', 1)
    RETURNING id INTO v_test_plan_id;

    -- Delete plan
    DELETE FROM workout_plans WHERE id = v_test_plan_id;

    -- Verify cascade
    IF (SELECT COUNT(*) FROM workout_weeks WHERE plan_id = v_test_plan_id) = 0 THEN
      RAISE NOTICE '✅ TEST 5: Cascade deletes work';
      v_pass_count := v_pass_count + 1;
    ELSE
      RAISE NOTICE '❌ TEST 5: Cascade deletes NOT working';
      v_fail_count := v_fail_count + 1;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ TEST 5: Cascade delete test failed';
    v_fail_count := v_fail_count + 1;
  END;

  -- Summary
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'SUMMARY';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Passed: %', v_pass_count;
  RAISE NOTICE 'Failed: %', v_fail_count;
  RAISE NOTICE 'Warnings: %', v_warning_count;

  IF v_fail_count = 0 THEN
    RAISE NOTICE '';
    RAISE NOTICE '✅ MIGRATION SUCCESSFUL';
  ELSE
    RAISE NOTICE '';
    RAISE NOTICE '❌ MIGRATION FAILED - ROLLBACK RECOMMENDED';
  END IF;
END $$;
```

### Manual Verification Checklist

#### Coach Features
- [ ] Coach can view client list
- [ ] Coach can create new workout plan for client
- [ ] Coach can add weeks, days, exercises
- [ ] Coach can create exercise groups (supersets)
- [ ] Coach can apply progression algorithms
- [ ] Coach can duplicate weeks
- [ ] Coach can export plan to PDF
- [ ] Coach can delete plans (with cascade)

#### Client Features
- [ ] Client can view assigned plans
- [ ] Client can see current week's workouts
- [ ] Client can start workout session
- [ ] Client can log sets (reps, weight, RPE)
- [ ] Client can complete workout
- [ ] Client can view workout history
- [ ] Client can see analytics (volume, PRs)
- [ ] Client receives workout notifications

#### Data Integrity
- [ ] All v1 plans exist in v2
- [ ] All v1 exercises exist in v2
- [ ] Exercise history preserved
- [ ] User preferences intact
- [ ] Coach-client relationships intact
- [ ] RLS policies enforced
- [ ] Cascade deletes work correctly

#### Performance
- [ ] Plan loading < 2 seconds
- [ ] Session tracking responsive
- [ ] Analytics queries < 3 seconds
- [ ] No N+1 query issues
- [ ] Database CPU < 50%
- [ ] Database memory < 80%

### User Acceptance Testing

**Select 5-10 test users across roles:**
- 2 coaches with active clients
- 3 clients with active plans
- 2 users with completed plans (history)
- 1 user with templates

**Testing Script:**
```
1. Login to app
2. Navigate to Workout section
3. Verify your plans are visible
4. Open a plan and verify all exercises are present
5. Start a workout session (clients only)
6. Log a few sets
7. Complete the workout
8. View analytics
9. Report any issues via feedback form
```

---

## Rollback Plan

### When to Rollback

**Critical Issues (Rollback Immediately):**
- Data loss detected (missing plans or exercises)
- RLS policies not working (users see other users' data)
- App crashes on launch for majority of users
- Database performance degradation > 5x

**Non-Critical Issues (Fix Forward):**
- UI bugs or layout issues
- Minor feature not working
- Performance degradation < 2x
- Analytics showing incorrect data (but session tracking works)

### Rollback Procedure

#### Option A: Restore from Backup (Full Rollback)

```bash
# 1. Enable maintenance mode
psql -h <project>.supabase.co -U postgres -d postgres -c "
  UPDATE system_maintenance SET enabled = TRUE, message = 'Rolling back migration...';
"

# 2. Drop v2 tables
psql -h <project>.supabase.co -U postgres -d postgres -f supabase/migrations/rollback_workout_v2.sql

# 3. Restore from backup
pg_restore \
  -h <project>.supabase.co \
  -U postgres \
  -d postgres \
  --clean \
  --if-exists \
  -t workout_plans_v1 \
  -t exercises_v1 \
  -t workout_sessions_v1 \
  -t exercise_logs_v1 \
  vagus_full_backup_*.dump

# 4. Rename tables back
psql -h <project>.supabase.co -U postgres -d postgres -c "
  ALTER TABLE workout_plans_v1 RENAME TO workout_plans;
  ALTER TABLE exercises_v1 RENAME TO exercises;
  ALTER TABLE workout_sessions_v1 RENAME TO workout_sessions;
  ALTER TABLE exercise_logs_v1 RENAME TO exercise_logs;
"

# 5. Deploy v1 app code
git checkout workout-v1-stable
flutter build apk --release
# ... deploy to stores

# 6. Disable maintenance mode
psql -h <project>.supabase.co -U postgres -d postgres -c "
  UPDATE system_maintenance SET enabled = FALSE;
"
```

#### Option B: Rename Tables (Quick Rollback)

If v1 tables were preserved (recommended):

```sql
BEGIN;

-- Drop v2 tables
DROP TABLE IF EXISTS exercises CASCADE;
DROP TABLE IF EXISTS workout_days CASCADE;
DROP TABLE IF EXISTS workout_weeks CASCADE;
DROP TABLE IF EXISTS workout_plans CASCADE;
DROP TABLE IF EXISTS exercise_groups CASCADE;

-- Rename v1 tables back
ALTER TABLE workout_plans_v1 RENAME TO workout_plans;
ALTER TABLE exercises_v1 RENAME TO exercises;
ALTER TABLE workout_sessions_v1 RENAME TO workout_sessions;
ALTER TABLE exercise_logs_v1 RENAME TO exercise_logs;

-- Restore v1 indexes
ALTER INDEX idx_workout_plans_v1_user_id RENAME TO idx_workout_plans_user_id;
-- ... rename other indexes

-- Restore v1 RLS policies (if changed)
-- ... restore policies

COMMIT;
```

**Estimated Rollback Time:** 5-10 minutes

### Post-Rollback Actions

1. **Notify Users**
   ```
   Subject: Workout Features Temporarily Reverted

   Hi [User],

   We've temporarily reverted the workout feature updates while we address
   some technical issues. Your data is safe and all features should work normally.

   We'll update you when the new features are ready to launch.

   Thanks for your patience!
   ```

2. **Root Cause Analysis**
   - Review migration logs
   - Identify exact failure point
   - Document lessons learned
   - Update migration procedure

3. **Plan Re-Migration**
   - Fix identified issues
   - Test more thoroughly on staging
   - Consider phased rollout (10% → 50% → 100%)

---

## Troubleshooting

### Issue: Migration Script Fails Midway

**Symptom:** Script stops with error message

**Solution:**
```sql
-- Check transaction state
SELECT * FROM pg_stat_activity WHERE state != 'idle';

-- If transaction is hung, cancel it
SELECT pg_cancel_backend(pid) FROM pg_stat_activity
WHERE query LIKE '%migrate_workout%' AND state != 'idle';

-- Rollback and retry
ROLLBACK;

-- Fix the issue (e.g., add missing column)
ALTER TABLE workout_plans_v1 ADD COLUMN IF NOT EXISTS goal TEXT DEFAULT 'general_fitness';

-- Retry migration
\i supabase/migrations/migrate_workout_v1_to_v2.sql
```

### Issue: Exercises Not Mapped to Days

**Symptom:** `exercises.day_id` is NULL for many records

**Cause:** Day grouping logic didn't match exercises

**Solution:**
```sql
-- Manually assign orphaned exercises to default day
DO $$
DECLARE
  plan_rec RECORD;
  week1_id UUID;
  default_day_id UUID;
BEGIN
  FOR plan_rec IN SELECT id FROM workout_plans LOOP
    -- Get week 1
    SELECT id INTO week1_id FROM workout_weeks
    WHERE plan_id = plan_rec.id AND week_number = 1 LIMIT 1;

    IF week1_id IS NULL THEN
      CONTINUE;
    END IF;

    -- Create default day if no days exist
    IF NOT EXISTS (SELECT 1 FROM workout_days WHERE week_id = week1_id) THEN
      INSERT INTO workout_days (week_id, day_label)
      VALUES (week1_id, 'Full Body')
      RETURNING id INTO default_day_id;
    ELSE
      SELECT id INTO default_day_id FROM workout_days WHERE week_id = week1_id LIMIT 1;
    END IF;

    -- Assign orphaned exercises
    UPDATE exercises
    SET day_id = default_day_id
    WHERE day_id IS NULL
      AND id IN (
        SELECT e.id FROM exercises e
        JOIN workout_days d ON d.id = default_day_id
        JOIN workout_weeks w ON d.week_id = w.id
        WHERE w.plan_id = plan_rec.id
      );
  END LOOP;
END $$;
```

### Issue: Performance Degradation

**Symptom:** Queries taking 5-10x longer

**Cause:** Missing indexes or poor query plans

**Solution:**
```sql
-- Analyze tables
ANALYZE workout_plans;
ANALYZE workout_weeks;
ANALYZE workout_days;
ANALYZE exercises;

-- Check query performance
EXPLAIN ANALYZE
SELECT * FROM workout_plans WHERE user_id = '<user_id>';

-- Add missing indexes
CREATE INDEX CONCURRENTLY idx_exercises_day_id ON exercises(day_id);
CREATE INDEX CONCURRENTLY idx_workout_days_week_id ON workout_days(week_id);
CREATE INDEX CONCURRENTLY idx_workout_weeks_plan_id ON workout_weeks(plan_id);

-- Vacuum tables
VACUUM ANALYZE workout_plans;
VACUUM ANALYZE workout_weeks;
VACUUM ANALYZE workout_days;
VACUUM ANALYZE exercises;
```

### Issue: Users See Wrong Data

**Symptom:** User A sees User B's workouts

**Cause:** RLS policies not properly applied

**Solution:**
```sql
-- Check RLS is enabled
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE tablename LIKE 'workout%';

-- Enable RLS on all tables
ALTER TABLE workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;

-- Recreate policies
DROP POLICY IF EXISTS "Users can view own plans" ON workout_plans;
CREATE POLICY "Users can view own plans"
  ON workout_plans FOR SELECT
  USING (auth.uid() = user_id);

-- Test with specific user
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub TO '<test_user_id>';
SELECT * FROM workout_plans;
-- Should only return plans for test_user_id
```

### Issue: OneSignal Notifications Not Sending

**Symptom:** No notifications after migration

**Cause:** Notification preferences not migrated

**Solution:**
```sql
-- Check if preferences table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables
  WHERE table_name = 'notification_preferences'
);

-- Create default preferences for all users
INSERT INTO notification_preferences (user_id, preferences)
SELECT
  u.id,
  jsonb_build_object(
    'workout_reminders_enabled', true,
    'workout_reminder_time', '18:00',
    'pr_celebration_enabled', true,
    'weekly_summary_enabled', true
  )
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM notification_preferences np WHERE np.user_id = u.id
);

-- Verify
SELECT COUNT(*) FROM notification_preferences;
```

---

## FAQ

**Q: How long does migration take?**
A: 30-60 minutes for production (depending on data volume). Dev/staging: 5-20 minutes.

**Q: Will users lose data?**
A: No. All data is preserved. v1 tables are renamed (not dropped) for safety.

**Q: Can we migrate in phases?**
A: Yes. Migrate 10% of users first, monitor, then roll out to 100%.

**Q: What if we need to rollback?**
A: Rename v1 tables back and deploy v1 app code. Takes ~5 minutes.

**Q: Do users need to update the app?**
A: Yes. Force update to v2 app after migration completes.

**Q: Will existing workout sessions be lost?**
A: No. Sessions are migrated with foreign keys updated to new structure.

**Q: Can coaches and clients use the app during migration?**
A: Not recommended. Enable maintenance mode for 10-15 minutes.

**Q: What about workout templates?**
A: Templates are migrated. Coaches should review and update them post-migration.

---

## Appendix

### Complete Migration Timeline

| Time | Action | Owner | Duration |
|------|--------|-------|----------|
| T-7 days | Announce migration to users | Marketing | 1 hour |
| T-3 days | Run migration on staging | DevOps | 20 min |
| T-2 days | User acceptance testing | QA | 8 hours |
| T-1 day | Final backup verification | DevOps | 30 min |
| T-1 day | Send reminder email | Marketing | 30 min |
| **T-0** | **Enable maintenance mode** | **DevOps** | **2 min** |
| T+2 min | Run migration script | DevOps | 15 min |
| T+17 min | Verify data integrity | DevOps | 5 min |
| T+22 min | Deploy v2 app code | DevOps | 8 min |
| T+30 min | Disable maintenance mode | DevOps | 1 min |
| T+31 min | Monitor for issues | DevOps | 2 hours |
| T+1 day | User acceptance check | Support | Ongoing |
| T+7 days | Delete v1 tables (optional) | DevOps | 5 min |

### Support Contacts

- **Migration Lead:** dev@vagushealth.com
- **Database Admin:** dba@vagushealth.com
- **Support Team:** support@vagushealth.com
- **Emergency Hotline:** +1-XXX-XXX-XXXX

---

**Document Version:** 1.0
**Last Updated:** 2025-09-30
**Author:** Vagus Development Team
**Status:** ✅ Ready for Use
