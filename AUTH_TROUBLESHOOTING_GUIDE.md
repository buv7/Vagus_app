# VAGUS App Authentication Troubleshooting Guide

## 🚨 **Current Issue: Login Not Working**

Your app is running but login is still failing. Here's a comprehensive guide to identify and fix the authentication issues.

## 🔍 **Step 1: Run Database Diagnostics**

1. **Open your Supabase Dashboard**: Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. **Go to SQL Editor**: Click on "SQL Editor" in the left sidebar
3. **Run the diagnostic script**: Copy and paste the contents of `diagnose_auth_issues.sql` and run it
4. **Check the results**: Look for any errors or missing data

## 🔧 **Step 2: Apply Authentication Fixes**

1. **In the same SQL Editor**, run the contents of `fix_auth_issues.sql`
2. **This will**:
   - Fix the profiles table structure
   - Create missing RLS policies
   - Create profiles for existing users
   - Set up proper authentication triggers

## 🧪 **Step 3: Test Authentication Connection**

1. **Install Node.js** if you don't have it
2. **Install Supabase client**: `npm install @supabase/supabase-js`
3. **Run the test script**: `node test_auth_connection.js`
4. **Check the output** for any errors

## 🎯 **Common Issues and Solutions**

### **Issue 1: "Invalid credentials" error**
- **Cause**: Wrong email/password or user doesn't exist
- **Solution**: 
  - Check if the user exists in Supabase Dashboard → Authentication → Users
  - Try creating a new account first
  - Check if email is confirmed

### **Issue 2: "User not found" error**
- **Cause**: User exists in auth.users but not in profiles table
- **Solution**: Run the `fix_auth_issues.sql` script

### **Issue 3: "Permission denied" error**
- **Cause**: RLS policies are blocking access
- **Solution**: The fix script will recreate proper RLS policies

### **Issue 4: "Email not confirmed" error**
- **Cause**: User signed up but didn't confirm email
- **Solution**: 
  - Check email for confirmation link
  - Or manually confirm in Supabase Dashboard
  - Or disable email confirmation in Supabase settings

## 📱 **Step 4: Test in Your App**

After running the fixes:

1. **Restart your Flutter app**: `flutter run`
2. **Try to create a new account** first
3. **Then try logging in** with the new account
4. **Watch the debug console** for specific error messages

## 🔍 **Debug Information to Look For**

When testing login, watch for these debug messages:

```
🔐 Email field: "your-email@example.com"
🔐 Password length: 8
🔐 Attempting login with: your-email@example.com
✅ Login response received
   User ID: [user-id]
   Session: Yes
   Email confirmed: true
```

If you see errors like:
- `❌ Login failed: No user in response`
- `❌ Validation failed: Empty fields`
- `Error: [specific error message]`

## 🚀 **Quick Fix Commands**

If you want to quickly test the connection:

```bash
# 1. Check if your .env file has correct credentials
cat .env

# 2. Restart the app
flutter clean
flutter run

# 3. Try logging in and watch the console
```

## 📊 **Expected Database State After Fixes**

After running the fix script, you should have:

- ✅ `profiles` table with proper structure
- ✅ RLS policies for profiles table
- ✅ All existing users have profiles
- ✅ Trigger to auto-create profiles for new users
- ✅ Proper foreign key relationships

## 🆘 **If Still Not Working**

If login still fails after running all fixes:

1. **Check the specific error message** in the Flutter console
2. **Verify your Supabase project is active** (not paused)
3. **Check if email confirmation is required** in Supabase settings
4. **Try creating a completely new user account**
5. **Check if there are any network connectivity issues**

## 📞 **Next Steps**

1. **Run the diagnostic script** first
2. **Apply the fixes** 
3. **Test the connection**
4. **Try logging in** in your app
5. **Let me know the specific error messages** you see

The most common issue is missing profiles for existing users, which the fix script will resolve.
