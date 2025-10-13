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
