@echo off
REM Apply migration to Supabase database
echo Applying migration to Supabase database...

supabase db push --db-url "postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres" --no-load-env

echo Migration completed!
pause
