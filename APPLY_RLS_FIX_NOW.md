# 🔴 CRITICAL: Apply RLS Fix to support_tickets

**IMMEDIATE ACTION REQUIRED**

## What's Wrong

The `support_tickets` table has **NO ROW LEVEL SECURITY**, meaning:
- Any authenticated user can view ALL support tickets
- User privacy is compromised
- Potential data breach risk

## Fix Takes 5 Minutes

### Step 1: Open Supabase Dashboard

1. Go to: **https://supabase.com/dashboard**
2. Select your **VAGUS** project
3. Click **SQL Editor** in left sidebar

### Step 2: Copy & Run This SQL

```sql
-- ============================================================
-- CRITICAL FIX: Add RLS to support_tickets
-- ============================================================

-- Enable Row Level Security
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

-- Create policy: Users can only access their own tickets
CREATE POLICY support_tickets_user_access ON support_tickets
  FOR ALL
  USING (
    -- Users can access their own tickets
    auth.uid() = user_id
    OR
    -- Admins can access all tickets
    (auth.jwt() ->> 'role' = 'admin')
    OR
    -- Support staff can access all tickets
    (auth.jwt() ->> 'role' = 'support')
  );

-- Add helpful comment
COMMENT ON POLICY support_tickets_user_access ON support_tickets IS
  'Users can view/edit their own tickets. Admins and support staff can access all tickets.';
```

### Step 3: Click "RUN" Button

The queries should execute successfully. You should see:
```
Success. No rows returned
```

### Step 4: Verify Fix Applied

Run this verification query in the same SQL Editor:

```sql
-- Verify RLS is enabled
SELECT
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'support_tickets';
```

**Expected result:** `rls_enabled = true`

### Step 5: Verify Policy Created

```sql
-- Verify policy exists
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'support_tickets';
```

**Expected result:** You should see one row with `policyname = support_tickets_user_access`

### Step 6: Test the Policy

As a regular user (not admin), try:

```sql
-- This should only return YOUR tickets
SELECT * FROM support_tickets LIMIT 5;
```

If you're not admin, you should ONLY see tickets where `user_id` matches your user ID.

### Step 7: Document Completion

After applying successfully, copy this template and save as `RLS_FIX_APPLIED.md`:

```markdown
# RLS Fix Applied to support_tickets

**Applied:** [Current Date/Time]
**Applied By:** [Your Name]
**Status:** ✅ SUCCESS

## Verification Results

### RLS Enabled Check
- Query: `SELECT rowsecurity FROM pg_tables WHERE tablename = 'support_tickets'`
- Result: `rowsecurity = true` ✅

### Policy Created Check
- Query: `SELECT policyname FROM pg_policies WHERE tablename = 'support_tickets'`
- Result: `support_tickets_user_access` policy found ✅

### Security Test
- Tested as regular user
- Can only see own tickets ✅
- Cannot see other users' tickets ✅

## RLS Coverage After Fix
- Tables with RLS: 156/160 (97.5%)
- Tables without RLS: 4
- Improvement: +0.6% coverage

## Next Steps
- [x] RLS fix applied
- [ ] Update code table references
- [ ] Pull database schema
- [ ] Rerun audit
```

---

## What If Something Goes Wrong?

### Error: "policy already exists"
**Meaning:** The policy was already created (safe to ignore)
**Action:** Just verify the policy exists with Step 5

### Error: "permission denied"
**Meaning:** You need admin access
**Action:** Contact database administrator

### Error: "column user_id does not exist"
**Meaning:** The table structure is different than expected
**Action:** First check the actual column name:
```sql
SELECT column_name FROM information_schema.columns
WHERE table_name = 'support_tickets';
```
Then adjust the policy to use the correct column name.

---

## Security Impact

**Before Fix:**
- 🔴 Any user could `SELECT * FROM support_tickets` and see ALL tickets
- 🔴 Privacy breach
- 🔴 96.9% RLS coverage

**After Fix:**
- ✅ Users can only see their own tickets
- ✅ Admins/support can see all tickets (appropriate)
- ✅ 97.5% RLS coverage

---

## APPLY THIS FIX NOW

This is a **CRITICAL SECURITY VULNERABILITY**. The fix takes 5 minutes.

1. Open Supabase Dashboard
2. Go to SQL Editor
3. Copy the SQL from Step 2
4. Click RUN
5. Verify with queries from Steps 4-5
6. Create `RLS_FIX_APPLIED.md` to document completion

**DO NOT SKIP THIS FIX**
