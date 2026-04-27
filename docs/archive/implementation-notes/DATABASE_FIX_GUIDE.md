# VAGUS App Database Fix Guide

## 🎯 **Direct Database Access Using Pooler Connection**

Since MCP Supabase tools aren't available, I've created direct database access tools using your pooler connection.

## 📋 **Files Created:**

1. **`setup_database_tools.js`** - Sets up required dependencies
2. **`direct_db_diagnosis.js`** - Diagnoses your database issues
3. **`direct_db_fix.js`** - Fixes authentication problems
4. **`DATABASE_FIX_GUIDE.md`** - This guide

## 🚀 **Step-by-Step Instructions:**

### **Step 1: Setup**
```bash
# Install Node.js if you don't have it
# Download from: https://nodejs.org/

# Run the setup script
node setup_database_tools.js
```

### **Step 2: Diagnose Issues**
```bash
# Run the diagnosis script
node direct_db_diagnosis.js
```

This will show you:
- Total users vs profiles
- Users without profiles
- Orphaned profiles
- RLS policies
- Missing triggers
- Auth configuration

### **Step 3: Apply Fixes**
```bash
# Run the fix script
node direct_db_fix.js
```

This will:
- ✅ Recreate profiles table with proper structure
- ✅ Create RLS policies
- ✅ Create profile creation trigger
- ✅ Create missing tables (ai_usage, user_devices)
- ✅ Create profiles for existing users
- ✅ Clean up orphaned profiles
- ✅ Create helper functions

### **Step 4: Test Your App**
```bash
# Restart your Flutter app
flutter clean
flutter run
```

## 🔍 **What the Scripts Do:**

### **Diagnosis Script (`direct_db_diagnosis.js`):**
- Connects to your database using pooler connection
- Checks auth.users table
- Checks profiles table
- Identifies users without profiles
- Checks RLS policies
- Verifies triggers
- Shows auth configuration

### **Fix Script (`direct_db_fix.js`):**
- Recreates profiles table with proper structure
- Creates RLS policies for security
- Creates trigger to auto-create profiles for new users
- Creates missing tables
- Creates profiles for existing users
- Cleans up orphaned data
- Creates helper functions

## 🎯 **Expected Results After Fix:**

```
✅ Total users: X
✅ Total profiles: X
✅ Users without profiles: 0
✅ Orphaned profiles: 0
✅ Database is now healthy!
```

## 🚨 **Common Issues and Solutions:**

### **Issue: "Users without profiles"**
- **Cause**: Users exist in auth.users but not in profiles table
- **Fix**: The fix script creates profiles for all existing users

### **Issue: "No profile creation trigger"**
- **Cause**: New users don't automatically get profiles
- **Fix**: The fix script creates a trigger that auto-creates profiles

### **Issue: "RLS policies missing"**
- **Cause**: Row Level Security policies are blocking access
- **Fix**: The fix script creates proper RLS policies

### **Issue: "Missing tables"**
- **Cause**: Required tables don't exist
- **Fix**: The fix script creates all missing tables

## 📱 **After Running Fixes:**

1. **Restart your Flutter app**
2. **Try creating a new account** (should work automatically)
3. **Try logging in** with existing account
4. **Watch debug console** for any remaining errors

## 🔧 **Manual Database Access:**

If you prefer to run SQL directly in Supabase Dashboard:

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Go to SQL Editor
3. Copy and paste the contents of `diagnose_auth_issues.sql`
4. Run it to see issues
5. Copy and paste the contents of `fix_auth_issues.sql`
6. Run it to apply fixes

## 🆘 **If Scripts Fail:**

1. **Check your connection string** is correct
2. **Verify your database is accessible**
3. **Check if you have the right permissions**
4. **Try running the SQL scripts directly in Supabase Dashboard**

## 📊 **Monitoring:**

After applying fixes, you can run the diagnosis script again to verify everything is working:

```bash
node direct_db_diagnosis.js
```

You should see:
- ✅ All users have profiles
- ✅ No orphaned profiles
- ✅ Proper RLS policies
- ✅ Profile creation trigger exists

## 🎉 **Success Indicators:**

When everything is working:
- ✅ Flutter app starts without errors
- ✅ You can create new accounts
- ✅ You can log in with existing accounts
- ✅ No "invalid credentials" errors
- ✅ Debug console shows successful authentication

**Run the diagnosis script first to see what issues exist, then apply the fixes!**