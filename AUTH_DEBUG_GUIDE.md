# Authentication Debug Guide

## Summary of Changes

Enhanced authentication debugging with comprehensive logging throughout the auth flow.

### Files Modified

1. **lib/main.dart**
   - Added session state check on app initialization
   - Logs initial session status on startup

2. **lib/screens/auth/login_screen.dart**
   - Added input validation before API call
   - Enhanced error logging with error types and details
   - Better error messages for common scenarios
   - Debug logs for successful login flow

3. **lib/screens/auth/auth_gate.dart**
   - Enhanced auth state listener with detailed event logging
   - Added signedIn/signedOut event handlers
   - Token refresh logging

## Debug Logs to Monitor

### 1. App Startup
```
🧪 Initial session check: [user-id or "null"]
🧪 Has access token: [true/false]
```

### 2. Login Attempt
```
🔐 Attempting login with: [email]
✅ Login response received
   User ID: [user-id]
   Session: [Yes/No]
   Email confirmed: [true/false]
✅ Login successful, proceeding with session setup
```

### 3. Auth State Changes
```
🔔 Auth state change: [event-type]
   User: [user-id or "null"]
✅ User signed in, reinitializing app state
```

### 4. Profile Loading
```
🔧 AuthGate: Starting session management...
🔧 AuthGate: Device upserted successfully
🔧 AuthGate: Revocation check completed
🔧 AuthGate: Loading user settings...
🔧 AuthGate: User settings loaded
🔧 AuthGate: Fetching user profile...
🔧 AuthGate: Profile fetched successfully, role: [coach/client/admin]
```

### 5. Error Scenarios
```
❌ Login error: [error]
   Error type: [error-type]
   Status code: [code]
   Message: [message]
```

## Testing Checklist

### Create Test Account
1. Go to Supabase Dashboard → Authentication → Users
2. Click "Add User"
3. Email: `test@vagusapp.com`
4. Password: `Test123!@#`
5. Check "Confirm email" (skip email verification for testing)

### Test Login Flow
1. Run app: `flutter run`
2. Enter test credentials
3. Watch console for debug logs
4. Expected flow:
   - ✅ Login attempt logged
   - ✅ Response received with user ID
   - ✅ Auth state change: signedIn
   - ✅ AuthGate reinitializes
   - ✅ Profile fetched
   - ✅ Navigate to dashboard

### Test Session Persistence
1. Log in successfully
2. Hot restart app (press 'r' in console)
3. Expected: Auto-logged in (session persisted)
4. Check logs for: "Initial session check: [user-id]"

### Test Logout
1. Navigate to settings/profile
2. Click logout
3. Check logs for: "User signed out"
4. Expected: Return to login screen

## Common Issues & Solutions

### Issue 1: "No user in response"
**Symptoms**: Login API succeeds but response.user is null

**Check**:
- Is email confirmed? (Check Supabase Dashboard)
- Are there RLS policies blocking the response?

**Fix**:
```dart
// In Supabase Dashboard → Authentication → Settings
// Temporarily disable "Confirm email" for testing
```

### Issue 2: Session not persisting
**Symptoms**: User logged in but lost on app restart

**Check**:
- Is secure storage working?
- Are there storage permissions issues?

**Fix**:
```dart
// Force session refresh after login
await Supabase.instance.client.auth.refreshSession();
```

### Issue 3: Auth state change not firing
**Symptoms**: Login succeeds but navigation doesn't happen

**Check**:
- Is auth listener subscribed correctly?
- Check logs for "Auth state change" messages

**Fix**: Already implemented in auth_gate.dart - listener handles all events

### Issue 4: Wrong credentials
**Symptoms**: "Invalid login credentials" error

**Check**:
- Verify email/password in Supabase Dashboard
- Ensure user is confirmed
- Check for typos

### Issue 5: Email not confirmed
**Symptoms**: "Email not confirmed" error

**Fix**:
- Go to Supabase Dashboard → Authentication → Users
- Find user → Click "..." → "Confirm email"

## Verification Steps

Run through these steps to verify auth is working:

- [ ] App starts and checks initial session
- [ ] Can enter email and password
- [ ] Login button triggers API call
- [ ] Success response logged with user ID
- [ ] Auth state change event fires (signedIn)
- [ ] Profile data fetched successfully
- [ ] Navigate to appropriate dashboard (client/coach/admin)
- [ ] Refresh app - still logged in
- [ ] Logout - returns to login screen
- [ ] Log back in - works again

## Next Steps if Issues Persist

1. **Check Supabase Connection**:
   ```dart
   // Add to login screen temporarily
   Future<void> _testConnection() async {
     try {
       final response = await Supabase.instance.client
           .from('profiles')
           .select('id')
           .limit(1);
       debugPrint('✅ Supabase connection works: $response');
     } catch (e) {
       debugPrint('❌ Supabase connection failed: $e');
     }
   }
   ```

2. **Verify Environment Variables**:
   ```bash
   # Check .env file
   cat .env | grep SUPABASE
   ```

3. **Check RLS Policies**:
   - Go to Supabase Dashboard → Database → Tables
   - Check `profiles` table has proper RLS policies
   - Users should be able to read their own profile

4. **Enable Detailed Supabase Logs**:
   ```dart
   // In main.dart
   await Supabase.initialize(
     url: EnvConfig.supabaseUrl,
     anonKey: EnvConfig.supabaseAnonKey,
     debug: true, // Add this for verbose Supabase logs
   );
   ```

## Contact
If none of these steps resolve the issue, capture the full console output from app start through login attempt and review the error messages.
