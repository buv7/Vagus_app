# Database Audit - Quick Reference

## Files Created ✅

| File | Purpose |
|------|---------|
| 📊 **DATABASE_SCHEMA_AUDIT.md** | Full migration analysis (744 lines) |
| 📊 **DATABASE_AUDIT_SUMMARY.md** | Overview & next steps |
| 📝 **MANUAL_DATABASE_AUDIT.md** | Step-by-step manual instructions |
| 🔧 **database_audit.sql** | SQL queries for live audit |
| 🤖 **run_database_audit.ps1** | PowerShell automation |
| 🤖 **run_database_audit.sh** | Bash automation |
| 📋 **code_tables.txt** | 179 tables from Dart code |

## Quick Start (2 Minutes)

### Option 1: Supabase Dashboard (Recommended - No Tools Needed)

1. Open: https://kydrpnrmqbedjflklgue.supabase.co
2. Go to: **SQL Editor**
3. Copy & paste from `database_audit.sql`
4. Run queries
5. Document findings

### Option 2: Automated (If You Have Tools)

```powershell
# Install PostgreSQL (if needed)
choco install postgresql

# Or start Docker Desktop

# Then run:
powershell -ExecutionPolicy Bypass -File run_database_audit.ps1
```

## Key Findings from Static Analysis

✅ **89 migrations analyzed**
✅ **127 tables defined**
✅ **45 views created**
✅ **75 functions implemented**
✅ **348 RLS policies configured**
✅ **94.5% RLS coverage**

⚠️ **~7 tables without RLS** (security review needed)
⚠️ **nutrition_grocery_items_with_info view** (had issues, needs verification)

## What to Verify

### Critical Tables (Must Exist)
- [ ] profiles
- [ ] nutrition_plans
- [ ] workout_plans
- [ ] ai_usage
- [ ] user_files
- [ ] client_metrics
- [ ] messages
- [ ] coach_notes

### Critical Views
- [ ] nutrition_grocery_items_with_info (⚠️ known issues)
- [ ] health_daily_v
- [ ] nutrition_cost_summary

### Critical Functions
- [ ] handle_new_user()
- [ ] update_ai_usage_tokens()
- [ ] increment_ai_usage()

## Expected Results

| Metric | Expected |
|--------|----------|
| Total Tables | ~127 |
| Total Views | ~45 |
| Total Functions | ~75 |
| Total RLS Policies | ~348 |
| Tables with RLS | 120/127 (94.5%) |

## If You Find Issues

### Missing Tables
```sql
-- Check migration files for CREATE TABLE statement
-- Apply the migration or create table manually
```

### Broken Views
```sql
-- Find view definition in migrations
-- Recreate view using CREATE OR REPLACE VIEW
```

### Missing RLS
```sql
ALTER TABLE [table_name] ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_own_data ON [table_name]
  FOR ALL
  USING (auth.uid() = user_id);
```

## Migration Health Score: 87% (B+)

**Strengths:**
- ✅ Comprehensive RLS coverage
- ✅ No SQL syntax errors
- ✅ Good use of IF EXISTS for drops
- ✅ Well-structured v2 systems

**Improvements Needed:**
- ⚠️ Add RLS to 7 tables
- ⚠️ Standardize migration naming
- ⚠️ Improve idempotency (IF NOT EXISTS)

## Next Steps

1. **Choose audit method** (Dashboard or Automated)
2. **Run audit queries**
3. **Compare results** with expected values
4. **Document findings**
5. **Create fix scripts** (if needed)

## Time Estimate

- **Manual Audit**: 15-20 minutes
- **Automated Audit**: 2-5 minutes
- **Review & Documentation**: 10-15 minutes
- **Total**: 25-40 minutes

## Support

- Full details: `DATABASE_SCHEMA_AUDIT.md`
- Manual steps: `MANUAL_DATABASE_AUDIT.md`
- Overview: `DATABASE_AUDIT_SUMMARY.md`
