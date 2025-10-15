# Database Migration Summary

**Date**: 2025-10-02
**Migration File**: `supabase/migrations/20251002140000_add_missing_tables_and_columns.sql`

## Status: ✓ SUCCESSFULLY APPLIED

---

## Changes Applied

### 1. calendar_events.event_type Column

**Added**:
- Column: `event_type` (TEXT, NOT NULL, default: 'session')
- Check constraint with allowed values: 'session', 'workout', 'consultation', 'check_in', 'appointment', 'other'
- 2 indexes:
  - `idx_calendar_events_event_type` - for filtering by event type
  - `idx_calendar_events_coach_event_type` - composite index for coach + event type queries

**SQL Statement**:
```sql
ALTER TABLE calendar_events
ADD COLUMN event_type TEXT DEFAULT 'session';

ALTER TABLE calendar_events
ALTER COLUMN event_type SET NOT NULL;

ALTER TABLE calendar_events
ADD CONSTRAINT calendar_events_event_type_check
CHECK (event_type IN ('session', 'workout', 'consultation', 'check_in', 'appointment', 'other'));
```

**Usage Example**:
```sql
-- Create a workout event
INSERT INTO calendar_events (
    title, event_type, coach_id, client_id, start_at, end_at
) VALUES (
    'Morning Workout',
    'workout',
    '<coach_uuid>',
    '<client_uuid>',
    '2025-10-03 08:00:00+00',
    '2025-10-03 09:00:00+00'
);

-- Query events by type
SELECT * FROM calendar_events
WHERE event_type = 'workout'
AND coach_id = '<coach_uuid>';
```

---

### 2. client_feedback Table

**Created**: Complete table with 8 columns

**Schema**:
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PRIMARY KEY, default: gen_random_uuid() |
| client_id | UUID | NOT NULL, FK → auth.users(id) ON DELETE CASCADE |
| coach_id | UUID | NOT NULL, FK → auth.users(id) ON DELETE CASCADE |
| feedback_text | TEXT | nullable |
| rating | INTEGER | NOT NULL, CHECK (rating >= 1 AND rating <= 5) |
| category | TEXT | NOT NULL, CHECK (values: workout, nutrition, support, communication, results, general) |
| created_at | TIMESTAMPTZ | NOT NULL, default: NOW() |
| updated_at | TIMESTAMPTZ | NOT NULL, default: NOW(), auto-updated via trigger |

**Indexes**: 8 total
- Primary key index on `id`
- Individual indexes on: `client_id`, `coach_id`, `rating`, `category`, `created_at`
- Composite indexes: `(coach_id, rating)`, `(coach_id, category)`

**RLS Policies**: 5 policies
1. Clients can create feedback for their coaches (INSERT)
2. Clients can view their own feedback (SELECT)
3. Coaches can view feedback about them (SELECT)
4. Clients can update their own feedback (UPDATE)
5. Clients can delete their own feedback (DELETE)

**Usage Example**:
```sql
-- Client submits feedback
INSERT INTO client_feedback (
    client_id, coach_id, feedback_text, rating, category
) VALUES (
    auth.uid(),
    '<coach_uuid>',
    'Great workout session! Very motivating and well-structured.',
    5,
    'workout'
);

-- Coach views their feedback
SELECT
    cf.rating,
    cf.category,
    cf.feedback_text,
    cf.created_at,
    u.email as client_email
FROM client_feedback cf
JOIN auth.users u ON u.id = cf.client_id
WHERE cf.coach_id = auth.uid()
ORDER BY cf.created_at DESC;

-- Get average rating for a coach
SELECT
    AVG(rating)::NUMERIC(3,2) as average_rating,
    COUNT(*) as total_feedback
FROM client_feedback
WHERE coach_id = '<coach_uuid>';
```

---

### 3. payments Table

**Created**: Complete table with 13 columns

**Schema**:
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PRIMARY KEY, default: gen_random_uuid() |
| client_id | UUID | NOT NULL, FK → auth.users(id) ON DELETE CASCADE |
| coach_id | UUID | NOT NULL, FK → auth.users(id) ON DELETE CASCADE |
| amount | NUMERIC(10,2) | NOT NULL, CHECK (amount >= 0) |
| currency | TEXT | NOT NULL, default: 'USD', CHECK (LENGTH = 3) |
| status | TEXT | NOT NULL, default: 'pending', CHECK (values: pending, completed, failed, refunded, cancelled) |
| payment_method | TEXT | nullable, CHECK (values: stripe, paypal, bank_transfer, cash, other) |
| stripe_payment_id | TEXT | nullable, indexed |
| stripe_payment_intent_id | TEXT | nullable, indexed |
| description | TEXT | nullable |
| metadata | JSONB | default: '{}' |
| created_at | TIMESTAMPTZ | NOT NULL, default: NOW() |
| updated_at | TIMESTAMPTZ | NOT NULL, default: NOW(), auto-updated via trigger |

**Indexes**: 10 total
- Primary key index on `id`
- Individual indexes on: `client_id`, `coach_id`, `status`, `stripe_payment_id`, `stripe_payment_intent_id`, `created_at`
- Composite indexes: `(coach_id, status)`, `(client_id, status)`, `(coach_id, created_at)`

**RLS Policies**: 4 policies (restricted to service_role for mutations)
1. Clients can view their own payments (SELECT, authenticated)
2. Coaches can view payments they receive (SELECT, authenticated)
3. Service role can create payments (INSERT, service_role only)
4. Service role can update payments (UPDATE, service_role only)

**Usage Example**:
```sql
-- View payments as a coach (through RLS)
SELECT
    p.amount,
    p.currency,
    p.status,
    p.description,
    p.created_at,
    u.email as client_email
FROM payments p
JOIN auth.users u ON u.id = p.client_id
WHERE p.coach_id = auth.uid()
ORDER BY p.created_at DESC;

-- Get revenue summary for a coach
SELECT
    COUNT(*) FILTER (WHERE status = 'completed') as completed_count,
    SUM(amount) FILTER (WHERE status = 'completed') as total_revenue,
    AVG(amount) FILTER (WHERE status = 'completed') as average_payment
FROM payments
WHERE coach_id = '<coach_uuid>';

-- Service role: Create payment (via Stripe webhook)
INSERT INTO payments (
    client_id, coach_id, amount, currency, status,
    payment_method, stripe_payment_id, stripe_payment_intent_id,
    description, metadata
) VALUES (
    '<client_uuid>',
    '<coach_uuid>',
    99.99,
    'USD',
    'completed',
    'stripe',
    'py_xxxxxxxxxxxxx',
    'pi_xxxxxxxxxxxxx',
    'Monthly coaching subscription',
    '{"subscription_id": "sub_xxxxx", "plan": "premium"}'::jsonb
);
```

---

### 4. Analytical Views

#### coach_feedback_summary
Aggregates feedback data per coach:
```sql
SELECT * FROM coach_feedback_summary
WHERE coach_id = '<coach_uuid>';
```

**Returns**:
- `total_feedback` - Total number of feedback entries
- `average_rating` - Average rating (NUMERIC(3,2))
- `five_star_count` through `one_star_count` - Count of each rating
- `latest_feedback_date` - Most recent feedback timestamp

#### coach_payment_summary
Aggregates payment data per coach:
```sql
SELECT * FROM coach_payment_summary
WHERE coach_id = '<coach_uuid>';
```

**Returns**:
- `total_payments` - Total payment count
- `completed_payments` - Count of completed payments
- `total_revenue` - Sum of completed payment amounts
- `average_payment` - Average completed payment amount
- `last_payment_date` - Most recent completed payment date

---

## Security Considerations

### RLS Policies Summary

**client_feedback**:
- ✓ Clients can manage their own feedback (full CRUD)
- ✓ Coaches can only view feedback about themselves
- ✓ No cross-client or cross-coach data leakage

**payments**:
- ✓ Clients can only view their own payments
- ✓ Coaches can only view payments they receive
- ✓ Payment creation/updates restricted to service_role (Stripe webhooks)
- ✓ No direct user manipulation of payment data

**calendar_events** (existing):
- ✓ Existing RLS policies maintained
- ✓ New event_type column does not affect security model

---

## Database Connection Details

**Connection Method**: Session Pooler (Supabase)
**Endpoint**: `aws-0-eu-central-1.pooler.supabase.com:5432`
**Database**: `postgres`
**Project ID**: `kydrpnrmqbedjflklgue`

**Connection String** (for reference):
```
postgresql://postgres.kydrpnrmqbedjflklgue:[PASSWORD]@aws-0-eu-central-1.pooler.supabase.com:5432/postgres
```

---

## Verification Results

All structures verified on 2025-10-02:

✓ calendar_events.event_type column created with constraints and indexes
✓ client_feedback table created with 8 columns, 8 indexes, 5 RLS policies
✓ payments table created with 13 columns, 10 indexes, 4 RLS policies
✓ coach_feedback_summary view created
✓ coach_payment_summary view created
✓ All triggers for updated_at timestamps working
✓ All RLS policies active and enforced

---

## Next Steps

### Application Integration

1. **Update Dart/Flutter Models**:
   - Add `eventType` field to `CalendarEvent` model
   - Create `ClientFeedback` model
   - Create `Payment` model

2. **Create Supabase Client Methods**:
   ```dart
   // Example: Fetch feedback for coach
   Future<List<ClientFeedback>> getCoachFeedback(String coachId) async {
     final response = await supabase
         .from('client_feedback')
         .select()
         .eq('coach_id', coachId)
         .order('created_at', ascending: false);
     return (response as List)
         .map((json) => ClientFeedback.fromJson(json))
         .toList();
   }
   ```

3. **UI Components**:
   - Add event type selector in calendar UI
   - Create feedback submission form
   - Create payment history view
   - Add analytics dashboard using summary views

4. **Stripe Integration** (for payments):
   - Set up Stripe webhook endpoint
   - Use service_role key for payment creation
   - Implement payment intent flow

---

## Files Created

1. `supabase/migrations/20251002140000_add_missing_tables_and_columns.sql` - Migration file
2. `apply_migration.js` - Node.js script to apply migrations
3. `check_schema.js` - Schema verification script
4. `verify_migration.js` - Comprehensive verification script
5. `MIGRATION_SUMMARY.md` - This document

---

## Support

For issues or questions:
- Check Supabase dashboard: https://app.supabase.com/project/kydrpnrmqbedjflklgue
- Review RLS policies in Table Editor
- Check logs in Supabase Logs section
- Use `verify_migration.js` to re-verify structure

---

**Migration Complete** ✓

---
---

# Database Migration Summary - Coach Schema Fix

**Date**: 2025-10-15
**Migration File**: `supabase/migrations/fix_coach_clients_schema.sql`
**Database**: Supabase PostgreSQL (EU Central 1)
**Connection**: Session Pooler (port 5432)

## Executive Summary

The migration was executed successfully with important discoveries about the database schema. The primary issue was that the original migration file targeted `coach_clients`, which is a **VIEW** rather than a base table. The actual base table is `user_coach_links`, which already had most of the required constraints in place.

## Key Findings

### 1. Schema Architecture Discovery

- **`coach_clients`** is a VIEW, not a table
- The view is defined as:
  ```sql
  SELECT client_id, coach_id, created_at, status
  FROM user_coach_links;
  ```
- **`user_coach_links`** is the actual base table where data is stored
- All constraints and indexes must be applied to `user_coach_links`, not `coach_clients`

### 2. Migration Results

#### A. user_coach_links (Base Table)

**Status**: ✓ Successfully configured

**Existing Structure** (already in place before migration):
- Primary Key: Composite key on (client_id, coach_id)
- NOT NULL constraints on: client_id, coach_id, created_at
- Foreign Keys:
  - `coach_id` → `auth.users(id)` ON DELETE CASCADE
  - `client_id` → `auth.users(id)` ON DELETE CASCADE
- Indexes:
  - `idx_user_coach_links_coach_id` on coach_id
  - `idx_user_coach_links_client_id` on client_id
- Check Constraint: Status must be one of: 'active', 'inactive', 'pending', 'suspended', 'completed'

**New Changes Applied**:
1. Added `id` UUID column with default gen_random_uuid()
2. Created unique index `idx_user_coach_links_id` on id column
3. Created index `idx_user_coach_links_status` on status column

**Final Column Structure**:
```
┌──────────────┬────────────────────────────┬─────────────┬─────────────────────┐
│ column_name  │ data_type                  │ is_nullable │ column_default      │
├──────────────┼────────────────────────────┼─────────────┼─────────────────────┤
│ client_id    │ uuid                       │ NO          │ null                │
│ coach_id     │ uuid                       │ NO          │ null                │
│ created_at   │ timestamp with time zone   │ NO          │ now()               │
│ status       │ text                       │ YES         │ 'active'::text      │
│ id           │ uuid                       │ YES         │ gen_random_uuid()   │
└──────────────┴────────────────────────────┴─────────────┴─────────────────────┘
```

**Constraints** (7 total):
1. `2200_75946_1_not_null` - CHECK constraint for client_id NOT NULL
2. `2200_75946_2_not_null` - CHECK constraint for coach_id NOT NULL
3. `2200_75946_3_not_null` - CHECK constraint for created_at NOT NULL
4. `user_coach_links_status_check` - CHECK constraint for valid status values
5. `user_coach_links_client_id_fkey` - FOREIGN KEY to auth.users(id)
6. `user_coach_links_coach_id_fkey` - FOREIGN KEY to auth.users(id)
7. `user_coach_links_pkey` - PRIMARY KEY on (client_id, coach_id)

**Indexes** (5 total):
1. `idx_user_coach_links_client_id` - B-tree index on client_id
2. `idx_user_coach_links_coach_id` - B-tree index on coach_id
3. `idx_user_coach_links_id` - Unique B-tree index on id (NEW)
4. `idx_user_coach_links_status` - B-tree index on status (NEW)
5. `user_coach_links_pkey` - Unique B-tree index on (client_id, coach_id)

#### B. coach_requests Table

**Status**: ✓ Successfully migrated

**Changes Applied**:
1. Set coach_id and client_id as NOT NULL
2. Added foreign key constraints:
   - `fk_coach_requests_coach`: coach_id → profiles(id) ON DELETE CASCADE
   - `fk_coach_requests_client`: client_id → profiles(id) ON DELETE CASCADE
3. Created indexes:
   - `idx_coach_requests_coach_id` on coach_id
   - `idx_coach_requests_client_id` on client_id
   - `idx_coach_requests_status` on status

**Final Column Structure**:
```
┌──────────────┬────────────────────────────┬─────────────┬─────────────────────┐
│ column_name  │ data_type                  │ is_nullable │ column_default      │
├──────────────┼────────────────────────────┼─────────────┼─────────────────────┤
│ id           │ uuid                       │ NO          │ gen_random_uuid()   │
│ coach_id     │ uuid                       │ NO          │ null                │
│ client_id    │ uuid                       │ NO          │ null                │
│ status       │ text                       │ YES         │ 'pending'::text     │
│ message      │ text                       │ YES         │ null                │
│ created_at   │ timestamp with time zone   │ YES         │ now()               │
│ updated_at   │ timestamp with time zone   │ YES         │ now()               │
└──────────────┴────────────────────────────┴─────────────┴─────────────────────┘
```

**Constraints** (10 total):
1. `2200_79746_1_not_null` - CHECK constraint
2. `2200_79746_2_not_null` - CHECK constraint
3. `2200_79746_3_not_null` - CHECK constraint
4. `coach_requests_status_check` - CHECK constraint for status validation
5. `coach_requests_client_id_fkey` - FOREIGN KEY (existing)
6. `coach_requests_coach_id_fkey` - FOREIGN KEY (existing)
7. `fk_coach_requests_client` - FOREIGN KEY (NEW) ON DELETE CASCADE
8. `fk_coach_requests_coach` - FOREIGN KEY (NEW) ON DELETE CASCADE
9. `coach_requests_pkey` - PRIMARY KEY on id
10. `coach_requests_coach_id_client_id_key` - UNIQUE constraint on (coach_id, client_id)

**Indexes** (7 total):
1. `coach_requests_coach_id_client_id_key` - Unique index on (coach_id, client_id)
2. `coach_requests_pkey` - Unique index on id
3. `idx_coach_requests_client` - B-tree index on client_id
4. `idx_coach_requests_client_id` - B-tree index on client_id (NEW)
5. `idx_coach_requests_coach` - B-tree index on coach_id
6. `idx_coach_requests_coach_id` - B-tree index on coach_id (NEW)
7. `idx_coach_requests_status` - B-tree index on status (NEW)

## Data Integrity Verification

### user_coach_links
- **Total rows**: 2
- **NULL values**: None in key columns (client_id, coach_id, created_at, status)
- **Duplicate coach-client pairs**: None
- **Orphaned records**: None (all foreign key references are valid)

### Data Sample
```
┌────────────────────────────────────────┬────────────────────────────────────────┬──────────────────────────┬───────────┐
│ client_id                              │ coach_id                               │ created_at               │ status    │
├────────────────────────────────────────┼────────────────────────────────────────┼──────────────────────────┼───────────┤
│ 7e12816a-f50a-458a-a504-6528319bbd3d   │ 7639dd28-4627-4926-a6b0-a948e6915aa2   │ 2025-10-11T20:08:59.466Z │ pending   │
│ 7e12816a-f50a-458a-a504-6528319bbd3d   │ 8e1753c8-996f-44ce-a171-fb16e9160948   │ 2025-10-11T20:09:06.023Z │ pending   │
└────────────────────────────────────────┴────────────────────────────────────────┴──────────────────────────┴───────────┘
```

## Issues Encountered

### Original Migration Errors

When attempting to apply the original migration to `coach_clients`:

```
Error Code: 42809
Error: ALTER action ADD CONSTRAINT cannot be performed on relation "coach_clients"
Detail: This operation is not supported for views.
```

This occurred because:
1. The migration SQL referenced `coach_clients`
2. `coach_clients` is a VIEW, not a table
3. Views cannot have constraints or indexes added directly

### Resolution

The issue was resolved by:
1. Identifying that `user_coach_links` is the base table
2. Verifying that most constraints already existed on `user_coach_links`
3. Adding only the missing elements (id column, status index)
4. Successfully applying all changes to `coach_requests`

## Recommendations

### 1. Update Application Code
If your application code references `coach_clients`, consider:
- Continue using the view for SELECT queries (no changes needed)
- Use `user_coach_links` for INSERT, UPDATE, DELETE operations
- Or keep using `coach_clients` if you have INSTEAD OF triggers configured

### 2. Migration File Update
Create a corrected migration file that:
```sql
-- Targets user_coach_links instead of coach_clients
ALTER TABLE user_coach_links
ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid();

CREATE INDEX IF NOT EXISTS idx_user_coach_links_status
ON user_coach_links(status);

-- Keep the coach_requests changes as-is (they worked correctly)
```

### 3. Foreign Key References
Note that `user_coach_links` references `auth.users` while `coach_requests` references `profiles`:
- **user_coach_links**: coach_id/client_id → `auth.users(id)`
- **coach_requests**: coach_id/client_id → `profiles(id)`

Verify this is intentional or consider standardizing to one table.

### 4. View Documentation
Document that `coach_clients` is a view of `user_coach_links` to prevent future confusion.

## Performance Considerations

With the new indexes added:
- ✓ Queries filtering by coach_id: Optimized
- ✓ Queries filtering by client_id: Optimized
- ✓ Queries filtering by status: Optimized (NEW)
- ✓ Queries by id: Optimized (NEW)
- ✓ Uniqueness enforced at database level
- ✓ Referential integrity enforced via foreign keys
- ✓ Cascade deletes configured for data cleanup

## Security & Data Integrity

**Enforced Constraints**:
1. ✓ No NULL values in coach_id or client_id
2. ✓ No duplicate coach-client relationships
3. ✓ Status values validated against allowed list
4. ✓ Foreign key constraints prevent orphaned records
5. ✓ Cascade deletes ensure cleanup when users are deleted

## Files Generated

Scripts created during this migration:
- `c:\Users\alhas\StudioProjects\vagus_app\execute_migration.js` - Initial migration attempt
- `c:\Users\alhas\StudioProjects\vagus_app\investigate_schema.js` - Schema investigation
- `c:\Users\alhas\StudioProjects\vagus_app\check_user_coach_links.js` - Base table analysis
- `c:\Users\alhas\StudioProjects\vagus_app\corrected_migration.js` - Final successful migration
- `c:\Users\alhas\StudioProjects\vagus_app\get_full_details.js` - FK details query
- `c:\Users\alhas\StudioProjects\vagus_app\check_fk_direct.js` - Direct FK catalog query

---

**Migration completed successfully** ✓

All data integrity constraints are in place, indexes are optimized, and the database schema is now properly configured for the Vagus application.
