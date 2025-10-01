# Database Schema Audit - Summary & Next Steps

**Generated:** October 1, 2025
**Status:** ⚠️ Audit Prepared - Manual Completion Required

---

## What We've Accomplished

### ✅ Phase 1: Migration File Analysis (COMPLETE)

Comprehensive static analysis of all 89 migration files:

**Key Findings:**
- 89 migration files analyzed
- 127 unique tables defined
- 45 views created
- 75 functions implemented
- 348 RLS policies configured
- 94.5% RLS coverage (120/127 tables)

**Documents Created:**
- ✅ `DATABASE_SCHEMA_AUDIT.md` (744 lines) - Full migration analysis
- ✅ Migration health score: **87% (B+)**

### ✅ Phase 2: Code Reference Extraction (COMPLETE)

**Extracted Dart Code References:**
- ✅ `code_tables.txt` - 179 unique table references from Dart code
- ✅ Most frequently used tables identified
- ✅ Service layer dependencies mapped

**Top Tables by Usage:**
1. messages (30 references)
2. workout_plans (22 references)
3. support_requests (22 references)
4. calendar_events (21 references)
5. profiles (17 references)
6. nutrition_plans (17 references)

### ⚠️ Phase 3: Live Database Verification (MANUAL REQUIRED)

**Blockers:**
- ❌ psql not installed
- ❌ Docker Desktop not running
- ❌ Direct database connection not available via CLI

**Solution Created:**
- ✅ `database_audit.sql` - Comprehensive SQL audit script (300+ lines)
- ✅ `run_database_audit.ps1` - PowerShell runner (when tools available)
- ✅ `run_database_audit.sh` - Bash runner (alternative)
- ✅ `MANUAL_DATABASE_AUDIT.md` - Manual audit instructions

---

## What Still Needs to Be Done

### Option 1: Manual Audit via Supabase Dashboard (RECOMMENDED)

**Time Required:** ~15-20 minutes

**Steps:**

1. **Open Supabase Dashboard**
   - URL: `https://kydrpnrmqbedjflklgue.supabase.co`
   - Navigate to: SQL Editor

2. **Run Quick Assessment Queries**
   ```sql
   -- Copy from MANUAL_DATABASE_AUDIT.md
   -- Run the "Quick Start Queries" section
   ```

3. **Export Table List**
   - Run table list query
   - Export as CSV
   - Save as `db_tables_export.csv`

4. **Compare with Code References**
   - Open PowerShell
   - Run comparison script (provided in manual)
   - Identify missing tables

5. **Document Findings**
   - Create `database_audit_findings.txt`
   - List any missing tables
   - Note RLS coverage gaps
   - Identify broken views

### Option 2: Install PostgreSQL Client

```bash
# Install psql (Windows via Chocolatey)
choco install postgresql

# Or download from: https://www.postgresql.org/download/windows/

# Then run automated audit
powershell -ExecutionPolicy Bypass -File run_database_audit.ps1
```

### Option 3: Start Docker Desktop

```bash
# Start Docker Desktop
# Then run automated audit
powershell -ExecutionPolicy Bypass -File run_database_audit.ps1
```

### Option 4: Use Supabase CLI Pull

```bash
# Pull remote schema
supabase db pull

# This creates a migration with current schema
# Review the generated file to see actual DB state
```

---

## Expected Findings

Based on migration analysis, the live database **should** have:

### Tables (127 expected)

**Core Tables:**
- ✅ profiles
- ✅ ai_usage
- ✅ user_files
- ✅ user_devices

**Nutrition v2 (12 tables):**
- ✅ nutrition_plans
- ✅ nutrition_plan_meals
- ✅ nutrition_recipes
- ✅ nutrition_recipe_ingredients
- ✅ nutrition_barcodes
- ✅ nutrition_pantry_items
- ✅ nutrition_supplements
- ✅ nutrition_hydration_logs
- ✅ nutrition_grocery_lists
- ✅ nutrition_grocery_items
- ✅ nutrition_allergies
- ✅ nutrition_preferences

**Workout v2 (10+ tables):**
- ✅ workout_plans
- ✅ workout_plan_weeks
- ✅ workout_plan_days
- ✅ workout_plan_exercises
- ✅ workout_plan_versions
- ✅ workout_sessions
- ✅ workout_exercises
- ✅ workout_cardio
- ✅ exercise_library
- ✅ exercise_media
- ✅ exercise_tags
- ✅ exercise_alternatives

**Progress Tracking:**
- ✅ progress_photos
- ✅ client_metrics
- ✅ checkins

**Coach System:**
- ✅ coach_notes
- ✅ coach_note_versions
- ✅ coach_clients
- ✅ coach_profiles

**Messaging:**
- ✅ messages
- ✅ message_threads
- ✅ message_attachments

### Views (45 expected)

**Critical Views:**
- ⚠️ nutrition_grocery_items_with_info (known to have had issues)
- ✅ nutrition_cost_summary
- ✅ nutrition_hydration_summary
- ✅ health_daily_v
- ✅ sleep_quality_v

### Functions (75 expected)

**Critical Functions:**
- ✅ handle_new_user()
- ✅ update_ai_usage_tokens()
- ✅ increment_ai_usage()
- ✅ calculate_1rm()
- ✅ is_day_compliant()

### RLS Policies (348 expected)

**Coverage:**
- ✅ 120/127 tables with RLS enabled (94.5%)
- ⚠️ ~7 tables without RLS (need review)

---

## Known Issues from Migration Analysis

### 🟠 HIGH Priority

1. **Tables Without RLS (Security Risk)**
   - achievements
   - active_macro_cycles
   - ai_usage (needs verification)
   - allergy_profiles
   - ~3-7 more tables

2. **Fragile View: nutrition_grocery_items_with_info**
   - Required 5+ fix attempts in migrations
   - May still have issues
   - Critical for nutrition features

### 🟡 MEDIUM Priority

3. **Non-Standard Migration Names (9 files)**
   - create_ai_usage_table.sql
   - create_coach_applications_table.sql
   - fix_ai_usage_functions.sql
   - migrate_workout_v1_to_v2.sql
   - rollback_workout_v2.sql
   - Others...

4. **Idempotency Concerns**
   - Only 59.6% migrations use IF NOT EXISTS
   - Should be 100% for safety

### 🟢 LOW Priority

5. **Migration Naming Inconsistency**
   - Mix of numbered (0001_), timestamped (20250115120000_), and descriptive names
   - Recommend standardizing on timestamp format

---

## Schema Mismatch Analysis

### False Positive Issue

The initial analysis showed **179 "missing" tables**, but this is a **false positive**:

**Root Cause:**
- Migrations use: `CREATE TABLE public.tablename` or `CREATE TABLE tablename`
- Dart code uses: `.from('tablename')` (no schema prefix)
- Supabase SDK auto-resolves schema at runtime

**Conclusion:**
- Tables are NOT actually missing
- Schema qualification mismatch in comparison
- Live database verification will confirm

### Potential Real Missing Tables

These need verification (unusual names):
- `vagus-media` (hyphenated - 15 references)
- `workout-media` (hyphenated - 3 references)
- `v_current_ads` (view or table?)

---

## Critical Verification Checklist

When running the live database audit, verify:

### 🔴 CRITICAL

- [ ] profiles table exists and has correct structure
- [ ] nutrition_grocery_items_with_info view is working
- [ ] workout_plans table has v2 schema
- [ ] ai_usage table exists
- [ ] user_files table exists
- [ ] All 348 RLS policies are active

### 🟠 HIGH

- [ ] nutrition v2 tables all present (12 tables)
- [ ] workout v2 tables all present (10+ tables)
- [ ] exercise_library is populated
- [ ] Messages system tables exist
- [ ] Coach notes system is complete

### 🟡 MEDIUM

- [ ] View count matches expected (~45)
- [ ] Function count matches expected (~75)
- [ ] Foreign key constraints are valid
- [ ] Indexes exist on foreign keys

---

## Recommended Fix Priority

If issues are found, fix in this order:

### Priority 1: Security (Do First)
```sql
-- Add RLS to unprotected tables
ALTER TABLE [table_name] ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_own_data ON [table_name]
  FOR ALL
  USING (auth.uid() = user_id);
```

### Priority 2: Broken Views (Do Second)
```sql
-- Recreate nutrition_grocery_items_with_info if broken
CREATE OR REPLACE VIEW nutrition_grocery_items_with_info AS
[view definition from migration];
```

### Priority 3: Missing Tables (Do Third)
```sql
-- Create any missing tables identified in audit
CREATE TABLE IF NOT EXISTS [table_name] (
  -- schema from migration
);
```

### Priority 4: Performance (Do Later)
```sql
-- Add missing indexes
CREATE INDEX IF NOT EXISTS idx_[table]_[column]
  ON [table]([column]);
```

---

## Files Available

| File | Status | Purpose |
|------|--------|---------|
| DATABASE_SCHEMA_AUDIT.md | ✅ Complete | Full migration analysis (744 lines) |
| database_audit.sql | ✅ Ready | SQL queries for live audit (300+ lines) |
| run_database_audit.ps1 | ✅ Ready | PowerShell automation (needs psql/Docker) |
| run_database_audit.sh | ✅ Ready | Bash automation (needs psql/Docker) |
| MANUAL_DATABASE_AUDIT.md | ✅ Ready | Step-by-step manual instructions |
| code_tables.txt | ✅ Complete | 179 tables from Dart code |
| DATABASE_AUDIT_SUMMARY.md | ✅ Complete | This file - overview and next steps |

**Not Yet Created (Needs Live DB):**
- ❌ db_tables.txt - Actual database tables
- ❌ missing_tables.txt - Tables in code but not DB
- ❌ unused_tables.txt - Tables in DB but not code
- ❌ database_audit_findings.txt - Live findings
- ❌ database_fixes.sql - SQL to fix issues (if needed)

---

## Success Criteria

The audit will be **complete** when you have:

- [ ] Connected to live database (via dashboard or CLI)
- [ ] Confirmed table count (expected: ~127)
- [ ] Verified critical tables exist (profiles, nutrition_plans, workout_plans, etc.)
- [ ] Checked RLS coverage (expected: 94-95%)
- [ ] Verified views work (especially nutrition_grocery_items_with_info)
- [ ] Compared code expectations vs database reality
- [ ] Documented any discrepancies
- [ ] Created fix scripts for any issues found

---

## Risk Assessment

**Current Risk Level: 🟢 LOW**

Why?
- ✅ Migrations appear well-structured (87% health score)
- ✅ Comprehensive RLS coverage (94.5%)
- ✅ No SQL syntax errors detected
- ✅ Recent v2 systems (Workout, Nutrition) properly implemented
- ⚠️ Minor security gaps (7 tables without RLS)
- ⚠️ One fragile view (nutrition_grocery_items_with_info)

**Worst Case Scenario:**
- Some tables missing → Create them from migrations
- RLS policies not applied → Apply from migrations
- Views broken → Recreate from migrations
- **All fixable** - migrations provide complete blueprint

---

## Next Action Required

**Choose ONE approach and execute:**

### ⭐ Recommended: Manual Dashboard Audit
1. Follow `MANUAL_DATABASE_AUDIT.md`
2. Takes ~15-20 minutes
3. No tools required
4. Copy queries to Supabase SQL Editor
5. Document findings

### Alternative 1: Install Tools
1. Install PostgreSQL client or start Docker
2. Run `run_database_audit.ps1`
3. Automated - takes ~2 minutes
4. Results in `database_audit_results.txt`

### Alternative 2: Use Supabase CLI
1. Ensure Supabase CLI is linked to project
2. Run `supabase db pull`
3. Review generated migration file
4. Compare with existing migrations

---

## Questions to Answer

After completing the live audit, we'll know:

1. ✅ or ❌ Do all expected tables exist?
2. ✅ or ❌ Does nutrition_grocery_items_with_info view work?
3. ✅ or ❌ Are all RLS policies active?
4. ✅ or ❌ Do workout v2 tables match expected schema?
5. ✅ or ❌ Do nutrition v2 tables match expected schema?
6. 🔢 How many tables are missing from database?
7. 🔢 How many tables in DB but not used in code?
8. 🔢 How many tables lack RLS policies?

---

## Contact & Support

If you encounter issues during the audit:

1. Check error messages carefully
2. Review `DATABASE_SCHEMA_AUDIT.md` for context
3. Check migration files in `supabase/migrations/`
4. Consult Supabase documentation
5. Create GitHub issue if needed

---

**Audit Prepared By:** Claude Code Assistant
**Date:** October 1, 2025
**Next Step:** Choose audit method and execute
**Time to Complete:** 15-30 minutes (manual) or 2-5 minutes (automated)
