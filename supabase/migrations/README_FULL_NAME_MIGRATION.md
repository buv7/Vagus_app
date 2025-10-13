# Full Name Column Migration Guide

## Overview
This guide explains how to execute the migration `20251002150000_add_full_name_to_profiles.sql` which adds a `full_name` column to the profiles table.

## What This Migration Does

1. **Adds `full_name` column** to the `profiles` table
   - Type: `TEXT`
   - Nullable: `true` (to support existing records)
   - Includes documentation comment

2. **Migrates existing data** from `name` column to `full_name`
   - Copies all existing name data to preserve it
   - Only updates records where `full_name` is NULL and `name` is NOT NULL

3. **Creates search indexes**
   - If `pg_trgm` extension is available: GIN trigram index for fuzzy search
   - Otherwise: B-tree index + lowercase index for case-insensitive search

4. **Provides verification**
   - Reports migration statistics
   - Shows column structure
   - Displays sample data

## Execution Options

### Option 1: Using Supabase CLI (Local/Remote)

#### For Remote Production Database:

```bash
# Make sure you're linked to your Supabase project
supabase link --project-ref kydrpnrmqbedjflklgue

# Push the migration to production
supabase db push

# Or apply migrations individually
supabase migration up
```

#### For Local Development:

```bash
# Start local Supabase
supabase start

# Apply migration to local database
supabase db reset  # This will apply all migrations
# OR
supabase migration up
```

### Option 2: Using Supabase Dashboard

1. Go to https://supabase.com/dashboard/project/kydrpnrmqbedjflklgue
2. Navigate to **SQL Editor**
3. Copy the contents of `20251002150000_add_full_name_to_profiles.sql`
4. Paste into the SQL editor
5. Click **Run**
6. Check the output for migration report

### Option 3: Using psql (PostgreSQL CLI)

```bash
# Connect to your Supabase database
psql "postgresql://postgres.kydrpnrmqbedjflklgue:[PASSWORD]@aws-0-eu-central-1.pooler.supabase.com:5432/postgres"

# Run the migration file
\i supabase/migrations/20251002150000_add_full_name_to_profiles.sql

# Or copy-paste the SQL directly
```

### Option 4: Using DBeaver, pgAdmin, or other GUI tools

1. Connect using the connection string:
   - Host: `aws-0-eu-central-1.pooler.supabase.com`
   - Port: `5432`
   - Database: `postgres`
   - User: `postgres.kydrpnrmqbedjflklgue`
   - Password: `[YOUR_PASSWORD]`

2. Open SQL editor
3. Copy-paste the migration SQL
4. Execute

## Verification

After running the migration, you should see output similar to:

```
=================================================
PROFILES TABLE - FULL_NAME MIGRATION REPORT
=================================================
Total profiles: [NUMBER]
Profiles with name column: [NUMBER]
Profiles with full_name column: [NUMBER]
Profiles migrated (name -> full_name): [NUMBER]
=================================================
```

## Expected Results

1. **Column Added**: `full_name` column exists in `profiles` table
2. **Data Migrated**: All existing `name` values copied to `full_name`
3. **Index Created**: Search index on `full_name` column
4. **No Data Loss**: Original `name` column unchanged

## Rollback (If Needed)

If you need to rollback this migration:

```sql
-- Remove the full_name column
ALTER TABLE profiles DROP COLUMN IF EXISTS full_name;

-- Remove indexes
DROP INDEX IF EXISTS idx_profiles_full_name_trgm;
DROP INDEX IF EXISTS idx_profiles_full_name;
DROP INDEX IF EXISTS idx_profiles_full_name_lower;
```

## Security Notes

- The migration uses the session pooler (port 5432) for connection
- All operations are wrapped in a transaction (BEGIN/COMMIT)
- Row Level Security (RLS) policies are not affected
- No sensitive data is exposed in the migration

## Troubleshooting

### Error: "relation 'profiles' does not exist"
- Ensure you're connected to the correct database
- Check if profiles table was created in earlier migrations

### Error: "column 'full_name' already exists"
- The migration is idempotent and uses `IF NOT EXISTS`
- This is safe and can be ignored

### Error: "permission denied"
- Ensure you're using credentials with ALTER TABLE permissions
- Use the service role key or database password (not anon/authenticated key)

## Next Steps

After migration, update your application code to:
1. Use `full_name` instead of `name` where appropriate
2. Update user profile forms to populate `full_name`
3. Update search/filter logic to use the new indexes
