# B1: Admin Button to Regenerate exercise_intensifier_links (RPC)

## Implementation Complete ✅

### Summary
This implementation adds an admin-only RPC function and UI button to regenerate exercise-intensifier links on demand, using the same heuristics as the migration.

---

## Changes Made

### 1. **RPC Function Migration** ✅
**File:** `supabase/migrations/20250122010000_rpc_regenerate_exercise_intensifier_links.sql`

**Function:** `public.regenerate_exercise_intensifier_links(p_limit int DEFAULT 500)`

**Features:**
- **Admin-only authorization:** Checks `profiles.role IN ('admin', 'superadmin')`
- **Security:** Uses `SECURITY DEFINER` with `SET search_path = public`
- **Same logic as migration:** Reuses all CTEs and heuristics from the original migration
- **Idempotent:** Uses `ON CONFLICT DO NOTHING`
- **No deletes/updates:** Only inserts new links
- **Returns JSON:** Statistics about the operation

**Return JSON:**
```json
{
  "requested_limit": 500,
  "inserted_links": 1234,
  "exercises_considered": 500,
  "exercises_with_new_links": 450
}
```

**Authorization Check:**
```sql
SELECT EXISTS (
  SELECT 1 
  FROM public.profiles 
  WHERE id = auth.uid() 
    AND role IN ('admin', 'superadmin')
) INTO v_is_admin;

IF NOT v_is_admin THEN
  RAISE EXCEPTION 'not authorized: admin access required';
END IF;
```

### 2. **Service Method** ✅
**File:** `lib/services/workout/workout_knowledge_service.dart`

**Method:** `regenerateExerciseIntensifierLinks({int limit = 500})`

**Features:**
- Calls RPC via `_supabase.rpc()`
- Error handling with readable messages
- Returns `Map<String, dynamic>` with statistics
- Handles authorization errors gracefully

**Error Messages:**
- "Admin access required to regenerate links" (for auth errors)
- "Invalid limit: must be between 1 and 1000" (for validation errors)
- "Failed to regenerate links: $e" (for other errors)

### 3. **Admin UI Button** ✅
**File:** `lib/screens/admin/workout_knowledge_admin_screen.dart`

**Features:**
- **Location:** Exercises tab, next to "Import Seed" button
- **Icon:** Refresh icon (`Icons.refresh`)
- **Tooltip:** "Regenerate Links (Top 500)"
- **Visibility:** Only shown when `_isAdmin == true`

**Flow:**
1. User taps button
2. Confirmation dialog appears:
   - Explains what will happen
   - Emphasizes no deletes/updates
   - Safe to run multiple times
3. If confirmed:
   - Shows loading dialog
   - Calls `_service.regenerateExerciseIntensifierLinks(limit: 500)`
   - Shows success dialog with results:
     - Inserted links count
     - Exercises considered count
     - Exercises affected count
4. If error:
   - Shows error snackbar

---

## How It Works

### RPC Function Flow

1. **Authorization Check:**
   - Gets `auth.uid()`
   - Checks `profiles.role IN ('admin', 'superadmin')`
   - Raises exception if not admin

2. **Validation:**
   - Validates `p_limit` (1-1000)

3. **Link Generation:**
   - Uses same CTEs as migration:
     - `intensifier_lookup`
     - `top_exercises` (limited by `p_limit`)
     - `generated_links`
     - `ranked_links`
     - `final_links`
   - `inserted_links` CTE performs INSERT with RETURNING

4. **Statistics:**
   - Counts inserted links
   - Counts exercises considered
   - Counts distinct exercises with new links

5. **Return:**
   - Builds JSON result
   - Returns to caller

### UI Flow

1. **Button Click:**
   - Checks admin status (already checked in `_isAdmin`)
   - Shows confirmation dialog

2. **Confirmation:**
   - User confirms or cancels
   - If confirmed, proceeds

3. **Execution:**
   - Shows loading dialog (non-dismissible)
   - Calls service method
   - Waits for result

4. **Result Display:**
   - Closes loading dialog
   - Shows success dialog with statistics
   - User dismisses dialog

---

## Security

### SQL-Level Enforcement ✅
- Function uses `SECURITY DEFINER` but checks admin status inside
- Authorization check happens before any data access
- Raises exception if not admin (prevents execution)

### Application-Level Enforcement ✅
- UI button only visible to admins
- Service method handles auth errors gracefully
- User sees clear error message if not authorized

---

## Testing Steps

### 1. Run Migration
```sql
-- Apply migration
-- File: supabase/migrations/20250122010000_rpc_regenerate_exercise_intensifier_links.sql
```

### 2. Test as Admin
1. Login as admin user
2. Navigate to Workout Knowledge Admin screen
3. Click refresh button (next to Import Seed)
4. Confirm dialog
5. Verify:
   - Loading dialog appears
   - Success dialog shows statistics
   - Links count increases (if new links were added)

### 3. Test as Non-Admin
1. Login as non-admin user (coach/client)
2. Navigate to Workout Knowledge Admin screen
3. Verify:
   - Refresh button is NOT visible
   - If somehow accessed, RPC call fails with "Admin access required"

### 4. Verify Links Count
```sql
-- Before regeneration
SELECT COUNT(*) FROM exercise_intensifier_links;

-- Run regeneration via UI

-- After regeneration
SELECT COUNT(*) FROM exercise_intensifier_links;
-- Should increase if new links were added
```

### 5. Verify Idempotency
1. Run regeneration once
2. Note the "inserted_links" count
3. Run regeneration again immediately
4. Verify:
   - "inserted_links" should be 0 (or very low)
   - No errors occur
   - No duplicates created

---

## Files Modified

1. **supabase/migrations/20250122010000_rpc_regenerate_exercise_intensifier_links.sql** (NEW)
   - RPC function with admin check
   - Same heuristics as migration
   - Returns JSON statistics

2. **lib/services/workout/workout_knowledge_service.dart**
   - Added `regenerateExerciseIntensifierLinks()` method

3. **lib/screens/admin/workout_knowledge_admin_screen.dart**
   - Added refresh button (admin-only)
   - Added `_regenerateLinks()` method
   - Added confirmation and result dialogs

---

## Notes

- **No app-side raw SQL** - All logic in RPC function
- **Admin-only enforced in SQL** - Cannot be bypassed from app
- **Idempotent** - Safe to run multiple times
- **No deletes/updates** - Only adds new links
- **Same heuristics** - Consistent with migration
- **User-friendly** - Clear dialogs and error messages

---

## Error Handling

### SQL Errors:
- **Not authenticated:** "not authorized: user not authenticated"
- **Not admin:** "not authorized: admin access required"
- **Invalid limit:** "invalid limit: must be between 1 and 1000"

### App Errors:
- **Auth errors:** "Admin access required to regenerate links"
- **Validation errors:** "Invalid limit: must be between 1 and 1000"
- **Other errors:** "Failed to regenerate links: $e"

All errors are caught and displayed to user via snackbar or dialog.

---

## Future Enhancements (Optional)

1. Add progress indicator for large batches
2. Add ability to specify custom limit in UI
3. Add "dry run" mode (preview without inserting)
4. Add link quality metrics
5. Add undo/rollback capability
