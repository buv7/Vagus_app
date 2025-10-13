# Apply Missing Column Migration

## Issue
The app is failing with: `Could not find the 'duration_weeks' column of 'workout_plans' in the schema cache`

## Solution
The migration file has been created at:
`supabase/migrations/20251002160000_add_duration_weeks_to_workout_plans.sql`

## How to Apply

### Option 1: Supabase Dashboard (EASIEST)
1. Go to: https://kydrpnrmqbedjflklgue.supabase.co/project/kydrpnrmqbedjflklgue/sql
2. Click "New Query"
3. Paste this SQL:
```sql
ALTER TABLE workout_plans
ADD COLUMN IF NOT EXISTS duration_weeks INTEGER;

COMMENT ON COLUMN workout_plans.duration_weeks IS 'Total duration of the workout plan in weeks';
```
4. Click "Run"

### Option 2: Fix .env BOM and use Supabase CLI
1. Fix the .env file (remove BOM character at start)
2. Run: `supabase db push`

### Option 3: Direct Database Connection
If you have PostgreSQL client installed:
```bash
psql "postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-us-east-1.pooler.supabase.com:6543/postgres" -f supabase/migrations/20251002160000_add_duration_weeks_to_workout_plans.sql
```

## Verify
After running the migration, restart your Flutter app and try creating a workout plan again.
