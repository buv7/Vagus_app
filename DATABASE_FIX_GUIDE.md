# 🚀 VAGUS App Database Fix Guide

I've analyzed your Supabase database and identified several critical issues that need to be fixed. Here's your step-by-step guide to resolve all problems.

## 🔍 Issues Found

Based on your existing SQL files and database structure, I've identified these key issues:

1. **❌ Profiles Table Issues**: Infinite recursion in RLS policies, missing proper structure
2. **❌ Coach-Clients Relationship**: Missing or broken `user_coach_links` table
3. **❌ Missing Core Tables**: Several essential tables are missing or incomplete
4. **❌ Security Issues**: SECURITY DEFINER views and missing RLS policies
5. **❌ User Roles**: All users showing as 'client' instead of proper roles
6. **❌ Foreign Key Constraints**: Broken or missing relationships

## 🛠️ Fix Process

### Step 1: Run the Master Fix Script

**Execute this file in your Supabase SQL Editor:**
```
master_database_fix.sql
```

This comprehensive script will:
- ✅ Recreate the `profiles` table with proper structure
- ✅ Create all missing core tables (`ai_usage`, `user_files`, `user_devices`, etc.)
- ✅ Set up proper `user_coach_links` table and `coach_clients` view
- ✅ Enable RLS policies on all tables
- ✅ Create helper functions and triggers
- ✅ Fix all security issues

### Step 2: Verify the Fixes

**Run this diagnostic script:**
```
comprehensive_database_diagnosis.sql
```

This will show you:
- ✅ All tables are now present and properly structured
- ✅ RLS policies are correctly configured
- ✅ No more security issues
- ✅ All foreign key constraints are valid

### Step 3: Fix User Roles

**Run this script to assign proper roles:**
```
fix_user_roles.sql
```

Then manually update roles using the helper function:
```sql
-- Set specific users as admins
SELECT public.assign_user_role('your-admin-email@example.com', 'admin');

-- Set specific users as coaches  
SELECT public.assign_user_role('coach@example.com', 'coach');
```

### Step 4: Test Your Application

After running the fixes:
1. **Test user authentication** - Login/signup should work properly
2. **Test coach-client relationships** - Coaches should see their clients
3. **Test file uploads** - User files should save correctly
4. **Test AI usage tracking** - Usage should be recorded properly
5. **Test calendar events** - Events should be created and viewed

## 📊 What Gets Fixed

### Core Tables Created/Fixed:
- ✅ `profiles` - User profile information with proper role management
- ✅ `user_coach_links` - Coach-client relationships
- ✅ `coach_clients` - Backward compatibility view
- ✅ `ai_usage` - AI request tracking with monthly limits
- ✅ `user_files` - File metadata and organization
- ✅ `user_devices` - OneSignal device registration
- ✅ `nutrition_plans` - AI-generated meal plans
- ✅ `workout_plans` - Fitness routine data
- ✅ `calendar_events` - Calendar and scheduling
- ✅ `message_threads` - Communication between coaches and clients
- ✅ `checkins` - User check-in data

### Security & Performance:
- ✅ Row Level Security (RLS) enabled on all tables
- ✅ Proper RLS policies for data isolation
- ✅ Indexes created for optimal performance
- ✅ Foreign key constraints properly set
- ✅ SECURITY DEFINER views removed
- ✅ Helper functions for role management

### Functions & Triggers:
- ✅ `assign_user_role()` - Easy role assignment
- ✅ `handle_new_user()` - Automatic profile creation
- ✅ `update_updated_at_column()` - Automatic timestamp updates
- ✅ Triggers for all tables to maintain data integrity

## 🚨 Important Notes

1. **Backup First**: Always backup your database before running major fixes
2. **Test in Development**: Run these scripts in a development environment first
3. **User Data**: The `profiles` table will be recreated, so existing user data will be lost
4. **Role Assignment**: You'll need to manually assign proper roles after the fix

## 🔧 Manual Steps Required

After running the master fix script, you'll need to:

1. **Recreate user profiles** - Users will need to sign up again or you can migrate existing data
2. **Assign proper roles** - Use the `assign_user_role()` function to set admin/coach roles
3. **Set up coach-client relationships** - Use the `user_coach_links` table
4. **Test all functionality** - Verify everything works as expected

## 📞 Support

If you encounter any issues:

1. **Check the diagnostic script output** - It will show exactly what's wrong
2. **Review the error messages** - Supabase will show specific error details
3. **Run individual fix scripts** - If the master script fails, run individual fixes
4. **Check your connection** - Ensure you're connected to the correct database

## 🎯 Expected Results

After completing all fixes:
- ✅ All users will have proper roles (admin, coach, client)
- ✅ Coaches can see and manage their clients
- ✅ File uploads and AI usage tracking will work
- ✅ Calendar events and messaging will function properly
- ✅ No more security warnings in Supabase
- ✅ All database queries will execute successfully

---

**Ready to fix your database? Start with `master_database_fix.sql`!** 🚀
