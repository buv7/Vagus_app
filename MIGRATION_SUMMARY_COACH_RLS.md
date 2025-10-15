# Database Migration Summary - Coach Connections RLS & Notifications
**Date**: 2025-10-15
**Migration File**: `supabase_migration_fix_coach_connections_corrected.sql`
**Database**: Supabase PostgreSQL (EU Central 1, AWS)
**Connection**: Session Pooler (Port 5432)
**Status**: COMPLETED SUCCESSFULLY

## Executive Summary

This migration successfully implements comprehensive Row Level Security (RLS) policies, notification systems, and helper functions for the Vagus coach connection system. The migration correctly targets the `user_coach_links` base table (not the `coach_clients` view) and adds missing marketplace features to `coach_profiles`.

## Key Discovery

**IMPORTANT**: The `coach_clients` object is a VIEW, not a table. The underlying base table is `user_coach_links`.
```sql
CREATE VIEW coach_clients AS
SELECT client_id, coach_id, created_at, status
FROM user_coach_links;
```

## Changes Applied

### Part 1: Coach Profiles Enhancement
**Table**: `coach_profiles`

**New Columns Added**:
- `is_active` (BOOLEAN, default: true) - Controls whether the coach profile is active and can receive connections
- `marketplace_enabled` (BOOLEAN, default: true) - Controls whether the coach appears in marketplace listings
- `rating` (NUMERIC(3,2), default: 0.00) - Average rating from 0.00 to 5.00 with check constraint

**Indexes Created**:
- `idx_coach_profiles_marketplace` - Composite index on (is_active, marketplace_enabled, rating DESC) for optimized marketplace queries

**Data Migration**:
- All existing coach profiles automatically set to active and marketplace-enabled with 0.00 rating

### Part 2: User Coach Links Improvement
**Table**: `user_coach_links` (underlying table for `coach_clients` view)

**New Columns Added**:
- `updated_at` (TIMESTAMP WITH TIME ZONE, default: NOW()) - Tracks when connection status was last updated

**Indexes Created**:
- `idx_user_coach_links_coach_status` - Composite index on (coach_id, status)
- `idx_user_coach_links_client_status` - Composite index on (client_id, status)

**Triggers Created**:
- `update_user_coach_links_updated_at` - Automatically updates the `updated_at` column on any row update

### Part 3: Row Level Security (RLS) - user_coach_links
**Status**: ENABLED

**Policies Created**:
1. **"Coaches can view their connections"** (SELECT)
   - Allows coaches to see all connections where they are the coach
   - Policy: `auth.uid() = coach_id`

2. **"Clients can view their connections"** (SELECT)
   - Allows clients to see all connections where they are the client
   - Policy: `auth.uid() = client_id`

3. **"Clients can create connections"** (INSERT)
   - Allows authenticated users to create new connection requests
   - Enforces: `auth.uid() = client_id AND status = 'pending'`

4. **"Coaches can update connection status"** (UPDATE)
   - Allows coaches to update connection status (approve/reject)
   - Policy: `auth.uid() = coach_id AND status IN ('active', 'rejected', 'pending')`

5. **"Users can delete their own pending requests"** (DELETE)
   - Allows clients to cancel their own pending connection requests
   - Policy: `auth.uid() = client_id AND status = 'pending'`

### Part 4: Row Level Security (RLS) - coach_profiles
**Status**: ENABLED

**Policies Created**:
1. **"Public read access for active marketplace coaches"** (SELECT)
   - Allows anyone to view active coaches in the marketplace
   - Filter: `is_active = true AND marketplace_enabled = true`

2. **"Coaches can update their own profile"** (UPDATE)
   - Allows coaches to modify their own profile data
   - Policy: `auth.uid() = coach_id`

3. **"Coaches can insert their own profile"** (INSERT)
   - Allows users to create their coach profile
   - Policy: `auth.uid() = coach_id`

### Part 5: Helper Views
**Views Created**:

1. **`active_coach_connections`**
   - Shows all active coach-client connections
   - Joins with coach_profiles and profiles for complete information
   - Includes: coach details, client details, connection metadata
   - Security: Uses `security_invoker = true` for RLS enforcement

2. **`pending_coach_requests`**
   - Shows all pending connection requests
   - Sorted by creation date (newest first)
   - Includes: client information, request timestamp
   - Security: Uses `security_invoker = true` for RLS enforcement

### Part 6: Connection Management Functions
**Functions Created**:

1. **`approve_connection_request(p_client_id UUID)`**
   - Returns: BOOLEAN
   - Purpose: Allows coaches to approve pending connection requests
   - Security: SECURITY DEFINER with auth.uid() validation
   - Updates status from 'pending' to 'active'

2. **`reject_connection_request(p_client_id UUID)`**
   - Returns: BOOLEAN
   - Purpose: Allows coaches to reject pending connection requests
   - Security: SECURITY DEFINER with auth.uid() validation
   - Updates status from 'pending' to 'rejected'

3. **`is_actively_connected(p_coach_id UUID, p_client_id UUID)`**
   - Returns: BOOLEAN
   - Purpose: Checks if a coach-client connection is currently active
   - Security: SECURITY DEFINER for consistent access
   - Quick status check without full query

4. **`update_updated_at_column()`**
   - Returns: TRIGGER
   - Purpose: Automatically updates timestamp on row modifications
   - Used by trigger on user_coach_links

5. **`notify_connection_event()`**
   - Returns: TRIGGER
   - Purpose: Creates notifications when connection status changes
   - Triggers on: INSERT (pending), UPDATE (approved/rejected)

### Part 7: Notification System
**Table Created**: `connection_notifications`

**Columns**:
- `id` (UUID, primary key) - Unique notification identifier
- `user_id` (UUID, FK to auth.users) - User who receives the notification
- `coach_id` (UUID, FK to coach_profiles) - Related coach
- `client_id` (UUID, FK to profiles) - Related client
- `notification_type` (TEXT) - Type: 'request', 'approved', or 'rejected'
- `read` (BOOLEAN, default: false) - Whether notification has been read
- `created_at` (TIMESTAMP) - When notification was created

**Indexes**:
- `idx_connection_notifications_user` - Composite index on (user_id, read, created_at DESC)

**RLS Policies**:
1. Users can view their own notifications (SELECT)
2. Users can update their own notifications (UPDATE) - for marking as read

**Triggers**:
- `connection_notification_trigger` on `user_coach_links`
  - Creates notification when client requests connection (notifies coach)
  - Creates notification when coach approves request (notifies client)
  - Creates notification when coach rejects request (notifies client)

## Verification Results

All verification checks passed:

**1. Columns Verified**:
```
┌───────────────────────┬───────────┬────────────────┐
│ column_name           │ data_type │ column_default │
├───────────────────────┼───────────┼────────────────┤
│ is_active             │ boolean   │ true           │
│ marketplace_enabled   │ boolean   │ true           │
│ rating                │ numeric   │ 0.00           │
└───────────────────────┴───────────┴────────────────┘
```

**2. Indexes Verified**: 12 total indexes on affected tables
- coach_profiles: 3 indexes
- user_coach_links: 7 indexes
- connection_notifications: 2 indexes

**3. RLS Enabled**: All 3 tables have RLS enabled
- coach_profiles: rowsecurity = true
- user_coach_links: rowsecurity = true
- connection_notifications: rowsecurity = true

**4. Policies Verified**: 21 total policies created
- coach_profiles: 5 policies
- user_coach_links: 14 policies (including pre-existing)
- connection_notifications: 2 policies

**5. Views Verified**:
- active_coach_connections ✓
- pending_coach_requests ✓

**6. Functions Verified**: All 5 functions created successfully
- approve_connection_request ✓
- reject_connection_request ✓
- is_actively_connected ✓
- update_updated_at_column ✓
- notify_connection_event ✓

**7. Notification Table**: Successfully created ✓

## Database Objects Summary

### Tables Modified
- `coach_profiles` - 3 new columns, 1 new index
- `user_coach_links` - 1 new column, 2 new indexes, 2 new triggers

### Tables Created
- `connection_notifications` - Complete notification system

### Views Created/Modified
- `active_coach_connections` - New helper view
- `pending_coach_requests` - New helper view
- `coach_clients` - Existing view (unchanged, points to user_coach_links)

### Functions Created
- `approve_connection_request(UUID)` - Connection approval
- `reject_connection_request(UUID)` - Connection rejection
- `is_actively_connected(UUID, UUID)` - Connection status check
- `update_updated_at_column()` - Timestamp trigger function
- `notify_connection_event()` - Notification trigger function

### RLS Policies Created
- 3 policies on `coach_profiles`
- 5 policies on `user_coach_links`
- 2 policies on `connection_notifications`
- **Total: 10 new policies** (21 total including pre-existing)

### Indexes Created
- 1 on `coach_profiles`
- 2 on `user_coach_links`
- 1 on `connection_notifications`
- **Total: 4 new indexes**

## Next Steps

### 1. Update Application Code
The application code needs updates to work with the new RLS policies:

**File**: `c:\Users\alhas\StudioProjects\vagus_app\lib\services\supabase_service.dart`
- Update the `isConnected()` method to use the new RLS-protected query
- Current implementation may be hitting RLS restrictions
- Consider using the `is_actively_connected()` function instead:

```dart
final result = await supabase.rpc(
  'is_actively_connected',
  params: {
    'p_coach_id': coachId,
    'p_client_id': clientId,
  },
);
return result as bool;
```

### 2. Implement Connection Approval UI
Create coach-facing UI for managing connection requests:

**Display Pending Requests**:
```dart
final requests = await supabase
  .from('pending_coach_requests')
  .select()
  .eq('coach_id', currentUserId);
```

**Approve Connection**:
```dart
await supabase.rpc('approve_connection_request',
  params: {'p_client_id': clientId}
);
```

**Reject Connection**:
```dart
await supabase.rpc('reject_connection_request',
  params: {'p_client_id': clientId}
);
```

### 3. Implement Notification System
Create UI to display connection notifications:

**Query Notifications**:
```dart
final notifications = await supabase
  .from('connection_notifications')
  .select()
  .eq('user_id', currentUserId)
  .eq('read', false)
  .order('created_at', ascending: false);
```

**Mark as Read**:
```dart
await supabase
  .from('connection_notifications')
  .update({'read': true})
  .eq('id', notificationId);
```

**Real-time Subscriptions**:
```dart
supabase
  .from('connection_notifications')
  .stream(primaryKey: ['id'])
  .eq('user_id', currentUserId)
  .listen((data) {
    // Update UI with new notifications
  });
```

### 4. Test Connection Workflow
Test the complete flow:
1. Client searches marketplace (uses new RLS policy)
2. Client sends connection request (INSERT with RLS)
3. Coach receives notification
4. Coach approves/rejects request (uses stored functions)
5. Client receives notification
6. Both parties see active connection

### 5. Optional: Auto-Approve Existing Connections
If there are existing pending connections that should be automatically approved:
```sql
UPDATE user_coach_links
SET status = 'active', updated_at = NOW()
WHERE status = 'pending';
```

## Security Improvements

This migration significantly improves security:

1. **Row Level Security**: Ensures users can only access their own connection data
2. **Function-Based Updates**: Connection status changes go through controlled functions
3. **Audit Trail**: The `updated_at` column tracks when connections are modified
4. **Notification System**: Secure notification delivery with user-scoped access
5. **Marketplace Privacy**: Only active, marketplace-enabled coaches are publicly visible

## Performance Improvements

1. **Indexed Queries**: New composite indexes optimize common query patterns
   - Coach + status lookups
   - Client + status lookups
   - Marketplace filtering
2. **View-Based Access**: Helper views simplify application queries
3. **Function Efficiency**: Stored functions reduce round-trips to database
4. **Targeted RLS**: Policies use indexed columns for fast filtering

## Files Created

1. `c:\Users\alhas\StudioProjects\vagus_app\supabase_migration_fix_coach_connections.sql` - Original migration (had VIEW error)
2. `c:\Users\alhas\StudioProjects\vagus_app\supabase_migration_fix_coach_connections_corrected.sql` - Working migration
3. `c:\Users\alhas\StudioProjects\vagus_app\run_migration.js` - Migration execution script
4. `c:\Users\alhas\StudioProjects\vagus_app\check_schema.js` - Schema investigation script
5. `c:\Users\alhas\StudioProjects\vagus_app\MIGRATION_SUMMARY_COACH_RLS.md` - This summary document

## Connection Information

**Supabase Project**: kydrpnrmqbedjflklgue
**Region**: EU Central 1 (AWS)
**Connection Type**: Session Pooler (Port 5432)
**Endpoint**: aws-0-eu-central-1.pooler.supabase.com

**Connection String** (for reference):
```
postgresql://postgres.kydrpnrmqbedjflklgue:[PASSWORD]@aws-0-eu-central-1.pooler.supabase.com:5432/postgres
```

## Migration Complete

**Migration Completed**: 2025-10-15
**Executed By**: MCP Supabase Agent
**Status**: SUCCESS

All database changes have been successfully applied and verified. The coach connection system now has comprehensive security, notifications, and helper functions in place.
