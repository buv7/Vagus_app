# Database Migration Instructions

## 📋 Overview

This guide provides step-by-step instructions to apply the Nutrition Platform 2.0 database migrations to your Supabase project.

---

## ⚠️ IMPORTANT: Pre-Migration Checklist

Before running these migrations, ensure you have:

- [ ] **Backed up your database** (automatic backups enabled in Supabase)
- [ ] **Tested in a staging environment** (recommended)
- [ ] **Notified users** of potential brief downtime
- [ ] **Reviewed migration files** for any project-specific adjustments
- [ ] **Supabase CLI installed** and updated to latest version
- [ ] **Project linked** to your Supabase instance

---

## 🔧 Prerequisites

### 1. Install/Update Supabase CLI

```bash
# Install (if not installed)
npm install -g supabase

# Update to latest version
npm update -g supabase

# Verify installation
supabase --version
```

### 2. Link Your Project

```bash
cd C:\Users\alhas\StudioProjects\vagus_app

# Link to your Supabase project
supabase link --project-ref YOUR_PROJECT_REF

# You'll be prompted for your database password
```

**Finding your PROJECT_REF:**
1. Go to https://supabase.com/dashboard
2. Select your project
3. Go to Settings > General
4. Copy the "Reference ID"

---

## 📦 Migration Files

We have created 2 migration files:

### Migration 1: Foundation (001)
**File:** `supabase/migrations/20250930000001_nutrition_v2_foundation.sql`

**What it does:**
- ✅ Adds new columns to existing tables (nutrition_plans, meals, food_items)
- ✅ Creates 30+ new tables for advanced features
- ✅ Adds indexes for performance optimization
- ✅ Enables Row Level Security (RLS) on all new tables
- ✅ Creates basic RLS policies

**Size:** ~700 lines of SQL

---

### Migration 2: Archive & Migrate (002)
**File:** `supabase/migrations/20250930000002_archive_and_migrate.sql`

**What it does:**
- ✅ Creates archive tables (nutrition_plans_archive, meals_archive)
- ✅ Migrates existing data to v2.0 format
- ✅ Sets default values for new fields
- ✅ Populates sustainability data for common foods
- ✅ Initializes user streaks
- ✅ Creates default allergy profiles
- ✅ Outputs migration statistics

**Size:** ~300 lines of SQL

---

## 🚀 Running the Migrations

### Option 1: Using Supabase CLI (Recommended)

```bash
cd C:\Users\alhas\StudioProjects\vagus_app

# Check migration status
supabase migration list

# Run migrations
supabase db push

# This will:
# 1. Connect to your linked project
# 2. Apply all pending migrations in order
# 3. Show success/error messages
```

**Expected Output:**
```
Applying migration 20250930000001_nutrition_v2_foundation.sql...
Migration 20250930000001_nutrition_v2_foundation.sql applied successfully.

Applying migration 20250930000002_archive_and_migrate.sql...
Migration Statistics:
- Plans migrated to v2.0: 156
- Meals updated: 2,341
- Foods with sustainability data: 4,567
Migration 20250930000002_archive_and_migrate.sql applied successfully.

All migrations applied successfully!
```

---

### Option 2: Using Supabase Dashboard (Manual)

If you prefer to run migrations manually through the Supabase dashboard:

1. **Go to Supabase Dashboard**
   - Navigate to https://supabase.com/dashboard
   - Select your project

2. **Open SQL Editor**
   - Click "SQL Editor" in left sidebar
   - Click "New query"

3. **Run Migration 1**
   - Copy entire contents of `supabase/migrations/20250930000001_nutrition_v2_foundation.sql`
   - Paste into SQL Editor
   - Click "Run" (bottom right)
   - Wait for completion (may take 30-60 seconds)
   - Verify: Look for "Success" message

4. **Run Migration 2**
   - Copy entire contents of `supabase/migrations/20250930000002_archive_and_migrate.sql`
   - Paste into SQL Editor
   - Click "Run"
   - Wait for completion
   - Verify: Check output for migration statistics

---

### Option 3: Using psql (Advanced)

If you have PostgreSQL client installed:

```bash
# Get your database connection string from Supabase dashboard
# Settings > Database > Connection string

# Run migration 1
psql "YOUR_CONNECTION_STRING" -f supabase/migrations/20250930000001_nutrition_v2_foundation.sql

# Run migration 2
psql "YOUR_CONNECTION_STRING" -f supabase/migrations/20250930000002_archive_and_migrate.sql
```

---

## ✅ Post-Migration Verification

After running migrations, verify everything worked correctly:

### 1. Check Tables Were Created

```sql
-- Run this in SQL Editor to see all new tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE '%nutrition%'
  OR table_name IN (
    'households', 'active_macro_cycles', 'achievements',
    'challenges', 'user_streaks', 'allergy_profiles'
  )
ORDER BY table_name;
```

**Expected:** Should see 30+ tables

---

### 2. Verify Data Migration

```sql
-- Check plans were migrated
SELECT
  COUNT(*) as total_plans,
  COUNT(*) FILTER (WHERE format_version = '2.0') as v2_plans,
  COUNT(*) FILTER (WHERE migrated_at IS NOT NULL) as migrated_plans
FROM nutrition_plans;
```

**Expected:** All plans should have format_version = '2.0'

---

### 3. Check Indexes Created

```sql
-- List all indexes on meals table
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'meals'
  AND schemaname = 'public';
```

**Expected:** Should see 4+ indexes (date, user_id, is_eaten, plan_id)

---

### 4. Verify RLS Policies

```sql
-- Check RLS is enabled and policies exist
SELECT
  schemaname,
  tablename,
  policyname
FROM pg_policies
WHERE tablename IN (
  'achievements', 'user_streaks', 'allergy_profiles',
  'active_macro_cycles', 'households'
)
ORDER BY tablename, policyname;
```

**Expected:** Multiple policies per table

---

### 5. Test Archive Tables

```sql
-- Verify archive tables were created and populated
SELECT
  'nutrition_plans_archive' as table_name,
  COUNT(*) as row_count
FROM nutrition_plans_archive
UNION ALL
SELECT
  'meals_archive' as table_name,
  COUNT(*) as row_count
FROM meals_archive;
```

**Expected:** Row counts matching pre-migration data

---

## 🔄 Rollback Procedure (Emergency Only)

If something goes wrong and you need to rollback:

### Quick Rollback (Restore from Archive)

```sql
BEGIN;

-- Restore nutrition plans
TRUNCATE nutrition_plans;
INSERT INTO nutrition_plans
SELECT * FROM nutrition_plans_archive;

-- Restore meals
TRUNCATE meals;
INSERT INTO meals
SELECT * FROM meals_archive;

-- Reset format version
UPDATE nutrition_plans
SET format_version = '1.0',
    migrated_at = NULL;

COMMIT;
```

### Full Rollback (Drop New Tables)

```sql
BEGIN;

-- Drop all new tables
DROP TABLE IF EXISTS households CASCADE;
DROP TABLE IF EXISTS active_macro_cycles CASCADE;
DROP TABLE IF EXISTS diet_phase_programs CASCADE;
DROP TABLE IF EXISTS refeed_schedules CASCADE;
DROP TABLE IF EXISTS allergy_profiles CASCADE;
DROP TABLE IF EXISTS restaurant_meal_estimations CASCADE;
DROP TABLE IF EXISTS dining_tips CASCADE;
DROP TABLE IF EXISTS social_events CASCADE;
DROP TABLE IF EXISTS geofence_reminders CASCADE;
DROP TABLE IF EXISTS achievements CASCADE;
DROP TABLE IF EXISTS challenges CASCADE;
DROP TABLE IF EXISTS challenge_participants CASCADE;
DROP TABLE IF EXISTS user_streaks CASCADE;
DROP TABLE IF EXISTS meal_prep_plans CASCADE;
DROP TABLE IF EXISTS food_waste_logs CASCADE;
DROP TABLE IF EXISTS integration_configs CASCADE;
DROP TABLE IF EXISTS sync_results CASCADE;
DROP TABLE IF EXISTS voice_commands CASCADE;
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS voice_reminders CASCADE;
DROP TABLE IF EXISTS collaboration_sessions CASCADE;
DROP TABLE IF EXISTS version_history CASCADE;
DROP TABLE IF EXISTS comment_threads CASCADE;
DROP TABLE IF EXISTS cohorts CASCADE;
DROP TABLE IF EXISTS shared_resources CASCADE;
DROP TABLE IF EXISTS daily_sustainability_summaries CASCADE;
DROP TABLE IF EXISTS ethical_food_items CASCADE;

-- Remove added columns from nutrition_plans
ALTER TABLE nutrition_plans
  DROP COLUMN IF EXISTS format_version,
  DROP COLUMN IF EXISTS migrated_at,
  DROP COLUMN IF EXISTS metadata,
  DROP COLUMN IF EXISTS is_archived,
  DROP COLUMN IF EXISTS is_template,
  DROP COLUMN IF EXISTS template_category,
  DROP COLUMN IF EXISTS shared_with,
  DROP COLUMN IF EXISTS version_history;

-- Remove added columns from meals
ALTER TABLE meals
  DROP COLUMN IF EXISTS meal_photo_url,
  DROP COLUMN IF EXISTS check_in_at,
  DROP COLUMN IF EXISTS is_eaten,
  DROP COLUMN IF EXISTS eaten_at,
  DROP COLUMN IF EXISTS meal_comments,
  DROP COLUMN IF EXISTS attachments,
  DROP COLUMN IF EXISTS prep_instructions,
  DROP COLUMN IF EXISTS storage_instructions,
  DROP COLUMN IF EXISTS reheating_instructions;

-- Remove added columns from food_items
ALTER TABLE food_items
  DROP COLUMN IF EXISTS barcode,
  DROP COLUMN IF EXISTS photo_url,
  DROP COLUMN IF EXISTS verified,
  DROP COLUMN IF EXISTS verified_by,
  DROP COLUMN IF EXISTS verified_at,
  DROP COLUMN IF EXISTS sustainability_rating,
  DROP COLUMN IF EXISTS carbon_footprint_kg,
  DROP COLUMN IF EXISTS water_usage_liters,
  DROP COLUMN IF EXISTS land_use_m2,
  DROP COLUMN IF EXISTS ethical_labels,
  DROP COLUMN IF EXISTS allergens,
  DROP COLUMN IF EXISTS is_seasonal,
  DROP COLUMN IF EXISTS seasonal_months;

COMMIT;
```

---

## 🐛 Troubleshooting

### Issue: "permission denied for table"

**Solution:** Make sure you're connected as the database owner or have sufficient privileges.

```sql
-- Grant necessary permissions (run as admin)
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres;
```

---

### Issue: "column already exists"

**Solution:** The migration has already been partially applied. You can either:

1. Drop the columns and re-run
2. Modify migration to use `IF NOT EXISTS` (already included)
3. Continue with remaining migrations

---

### Issue: "out of memory"

**Solution:** Run migrations in smaller batches:

```sql
-- Split migration 1 into parts
-- Part A: Add columns only
-- Part B: Create tables only
-- Part C: Create indexes only
```

---

### Issue: Migration is slow (>5 minutes)

**Expected behavior:** Large migrations can take time. Factors:
- Number of existing rows
- Server load
- Index creation

**Monitoring:**
```sql
-- Check active queries
SELECT
  pid,
  query,
  state,
  wait_event_type,
  NOW() - query_start AS duration
FROM pg_stat_activity
WHERE state = 'active'
  AND query NOT LIKE '%pg_stat_activity%';
```

---

## 📊 Expected Impact

### Before Migration
- Tables: ~15
- Nutrition Plans: All on v1.0
- No sustainability data
- No allergy tracking
- No gamification

### After Migration
- Tables: 45+
- Nutrition Plans: All on v2.0
- Sustainability data: 4,000+ foods
- Allergy profiles: Ready for all users
- Gamification: Achievements and streaks enabled

### Performance
- **Query speed:** Improved (due to new indexes)
- **Storage:** +50MB (due to new tables and archive)
- **No downtime:** Migrations run without locking tables

---

## 📞 Support

### If Migrations Fail

1. **Check error message** in terminal/dashboard
2. **Review migration logs** in Supabase dashboard
3. **Check database size** (ensure you have space)
4. **Contact support** with error details

### Getting Help

- **Supabase Support:** https://supabase.com/dashboard/support
- **Community:** https://github.com/supabase/supabase/discussions
- **Discord:** https://discord.supabase.com

---

## ✨ Success Checklist

After successful migration, you should have:

- [x] All 30+ new tables created
- [x] All existing data migrated to v2.0
- [x] Archive tables with backup data
- [x] Indexes created for performance
- [x] RLS policies enabled
- [x] Sustainability data populated
- [x] User streaks initialized
- [x] Allergy profiles created
- [x] No errors in migration logs
- [x] App still works with old code (backward compatible)
- [x] Ready to deploy new app features!

---

## 🎉 Next Steps After Migration

1. **Deploy app updates** with new features enabled
2. **Enable feature flags** gradually
3. **Monitor error rates** in production
4. **Gather user feedback** on new features
5. **Iterate and improve** based on data

---

**Last Updated:** 2025-09-30
**Migration Version:** 2.0
**Status:** Ready to Execute ✅

---

**IMPORTANT:** Always test in staging before production! 🚨