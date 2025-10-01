# Manual Database Audit Instructions

Since automated database connection tools (psql, Docker) are not available, follow these manual steps to complete the database audit.

## Step 1: Access Supabase Dashboard

1. Open your browser and navigate to:
   ```
   https://kydrpnrmqbedjflklgue.supabase.co
   ```

2. Log in to your Supabase account

3. Navigate to: **SQL Editor**

## Step 2: Run Audit Queries

Copy and paste the queries from `database_audit.sql` into the SQL Editor.

### Quick Start Queries

Run these queries first to get a quick assessment:

```sql
-- 1. Count total tables
SELECT COUNT(*) as total_tables
FROM information_schema.tables
WHERE table_schema = 'public';

-- 2. List all tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- 3. Check critical tables exist
SELECT
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles')
    THEN '✅' ELSE '❌' END as profiles,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'nutrition_plans')
    THEN '✅' ELSE '❌' END as nutrition_plans,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'workout_plans')
    THEN '✅' ELSE '❌' END as workout_plans,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'ai_usage')
    THEN '✅' ELSE '❌' END as ai_usage,
  CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_files')
    THEN '✅' ELSE '❌' END as user_files;

-- 4. RLS Coverage
SELECT
  COUNT(*) FILTER (WHERE rowsecurity = true) as tables_with_rls,
  COUNT(*) FILTER (WHERE rowsecurity = false) as tables_without_rls,
  COUNT(*) as total_tables
FROM pg_tables
WHERE schemaname = 'public';

-- 5. View count
SELECT COUNT(*) as total_views
FROM information_schema.views
WHERE table_schema = 'public';

-- 6. Function count
SELECT COUNT(*) as total_functions
FROM information_schema.routines
WHERE routine_schema = 'public';

-- 7. Policy count
SELECT COUNT(*) as total_policies
FROM pg_policies
WHERE schemaname = 'public';
```

## Step 3: Export Table List

Run this query and save the results:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

**Export Instructions:**
1. After running the query, click the "Download CSV" button
2. Save as `db_tables_export.csv`
3. Copy to the project directory

## Step 4: Compare with Code

We've already extracted tables from the Dart code. The file `code_tables.txt` contains 179 table references.

Run this PowerShell command to compare:

```powershell
# Load files
$codeTables = Get-Content code_tables.txt

# Manually create db_tables.txt from your CSV export
# Then run:
$dbTables = Get-Content db_tables.txt

# Find missing
$missingTables = Compare-Object $codeTables $dbTables |
    Where-Object { $_.SideIndicator -eq '<=' } |
    Select-Object -ExpandProperty InputObject

# Show results
Write-Host "Missing tables in database:"
$missingTables
```

## Step 5: Check Specific Schema Issues

### Check profiles table structure
```sql
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
ORDER BY ordinal_position;
```

### Check nutrition_grocery_items_with_info view
```sql
SELECT
  table_name,
  view_definition
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name = 'nutrition_grocery_items_with_info';
```

### Check workout v2 tables
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE '%workout%'
ORDER BY table_name;
```

### Check tables without RLS
```sql
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND rowsecurity = false
ORDER BY tablename;
```

## Step 6: Document Findings

Create a file `database_audit_findings.txt` with:

```
=== DATABASE AUDIT FINDINGS ===
Date: [Current Date]

Total Tables in DB: [from query 1]
Tables Referenced in Code: 179
Total Views: [from query 5]
Total Functions: [from query 6]
Total RLS Policies: [from query 7]

Tables WITH RLS: [from query 4]
Tables WITHOUT RLS: [from query 4]

=== CRITICAL TABLES STATUS ===
profiles: [✅ or ❌]
nutrition_plans: [✅ or ❌]
workout_plans: [✅ or ❌]
ai_usage: [✅ or ❌]
user_files: [✅ or ❌]

=== MISSING TABLES ===
[List from comparison]

=== TABLES WITHOUT RLS ===
[List from query]

=== ISSUES FOUND ===
1. [Issue description]
2. [Issue description]
...
```

## Alternative: Use Supabase CLI (if available)

If you have Supabase CLI configured:

```bash
# Pull schema from remote
supabase db pull

# This will create a migration file with the current schema
# Review it to see what's actually in the database
```

## Expected Results

Based on the migration audit, you should find:

- **~127 tables** in the database
- **~45 views**
- **~75 functions**
- **~348 RLS policies**
- **94-95% RLS coverage** (120/127 tables)

## Key Things to Verify

1. ✅ **Profiles table** - Core user table
2. ✅ **Nutrition v2 tables** - nutrition_plans, nutrition_recipes, nutrition_barcodes, etc.
3. ✅ **Workout v2 tables** - workout_plans, workout_plan_weeks, workout_plan_days, etc.
4. ✅ **AI usage table** - ai_usage
5. ✅ **User files table** - user_files
6. ✅ **Coach notes** - coach_notes, coach_note_versions
7. ⚠️ **nutrition_grocery_items_with_info view** - Known to have had issues

## If You Find Critical Issues

If you discover missing tables or broken views:

1. Check if migrations were applied:
   ```sql
   SELECT * FROM supabase_migrations
   ORDER BY version DESC
   LIMIT 20;
   ```

2. If migrations are pending, you may need to apply them:
   ```bash
   supabase db push
   ```

3. Document the issue in the findings file

## Next Steps

After completing the manual audit:

1. Update `DATABASE_SCHEMA_AUDIT.md` with live findings
2. Create `database_fixes.sql` if issues are found
3. Report back the key findings

## Files Generated

- `code_tables.txt` - 179 tables from Dart code ✅ (already created)
- `db_tables_export.csv` - Tables from database (manual export)
- `database_audit_findings.txt` - Your documented findings
- `database_fixes.sql` - SQL to fix any issues found
