# Messaging System Migration Required

## Issue
The messaging system tables (`conversations`, `messages`, `message_attachments`) do not exist in the database yet.

## Error
```
PostgrestException(message: relation "public.conversations" does not exist, code: 42P01)
```

## Solution
The messaging system migration needs to be applied manually. Choose ONE of the following options:

### Option 1: Using Supabase Dashboard (Easiest)
1. Go to: https://supabase.com/dashboard/project/kydrpnrmqbedjflklgue/sql/new
2. Open the file: `supabase/migrations/20250115120031_messaging_system.sql`
3. Copy all the contents
4. Paste into the SQL Editor
5. Click "Run" or press `Ctrl+Enter`

### Option 2: Using psql (If installed)
```bash
psql "postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres" -f supabase/migrations/20250115120031_messaging_system.sql
```

### Option 3: Using Docker with psql
```bash
docker run --rm -i postgres:15 psql "postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres" < supabase/migrations/20250115120031_messaging_system.sql
```

## What the Migration Creates
- `conversations` table: Stores coach-client conversations
- `messages` table: Stores individual messages within conversations
- `message_attachments` table: Stores file attachments for messages
- Indexes for performance
- RLS (Row Level Security) policies for data access control
- Triggers for automatic timestamp updates

## Verification
After running the migration, verify the tables exist:
```bash
cd tooling
node apply_messaging_migration.js
```

You should see:
```
✅ conversations table already exists!
✅ messages table exists!
✅ All messaging tables are properly configured!
```

## Files Affected
- `lib/services/coach/coach_messaging_service.dart` - The service trying to access these tables
- `supabase/migrations/20250115120031_messaging_system.sql` - The migration file to apply
