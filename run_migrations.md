# Quick Migration Guide - Run These in Supabase Dashboard

## ⚠️ IMPORTANT: Backup First!
Before running, go to Supabase Dashboard → Database → Backups and verify automatic backups are enabled.

---

## 🚀 How to Run (5 minutes)

### Step 1: Open Supabase Dashboard
1. Go to https://supabase.com/dashboard
2. Select project: **vagus_app** (kydrpnrmqbedjflklgue)
3. Click **SQL Editor** in left sidebar

---

### Step 2: Run Migration 1 (Foundation)

1. Click **New query** button
2. Copy the ENTIRE contents of this file:
   ```
   supabase/migrations/20251001000001_nutrition_v2_foundation.sql
   ```
3. Paste into SQL Editor
4. Click **Run** (bottom right, or Ctrl+Enter)
5. **Wait 30-60 seconds** for completion
6. ✅ Look for "Success. No rows returned" message

**Expected output:**
- "Success. No rows returned"
- No error messages
- Takes 30-60 seconds

**If you see an error:**
- Check if tables already exist (they shouldn't on first run)
- Verify you're using the correct project
- Check database permissions

---

### Step 3: Run Migration 2 (Archive & Migrate Data)

1. Click **New query** again
2. Copy the ENTIRE contents of this file:
   ```
   supabase/migrations/20251001000002_archive_and_migrate.sql
   ```
3. Paste into SQL Editor
4. Click **Run**
5. **Wait for completion** (may take 1-2 minutes if you have lots of data)
6. ✅ Look for migration statistics in output

**Expected output:**
```
NOTICE:  Migration Statistics:
NOTICE:  - Plans migrated to v2.0: [number]
NOTICE:  - Meals updated: [number]
NOTICE:  - Foods with sustainability data: [number]
```

---

## ✅ Verification (2 minutes)

After both migrations complete, run this verification query:

```sql
-- Check all new tables were created
SELECT
  COUNT(*) FILTER (WHERE table_name LIKE '%nutrition%') as nutrition_tables,
  COUNT(*) FILTER (WHERE table_name = 'households') as households,
  COUNT(*) FILTER (WHERE table_name = 'achievements') as achievements,
  COUNT(*) FILTER (WHERE table_name = 'allergy_profiles') as allergy_profiles,
  COUNT(*) FILTER (WHERE table_name = 'active_macro_cycles') as macro_cycles,
  COUNT(*) as total_new_tables
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'households',
    'active_macro_cycles',
    'diet_phase_programs',
    'refeed_schedules',
    'allergy_profiles',
    'restaurant_meal_estimations',
    'dining_tips',
    'social_events',
    'geofence_reminders',
    'achievements',
    'challenges',
    'challenge_participants',
    'user_streaks',
    'meal_prep_plans',
    'food_waste_logs',
    'integration_configs',
    'sync_results',
    'voice_commands',
    'chat_messages',
    'voice_reminders',
    'collaboration_sessions',
    'version_history',
    'comment_threads',
    'cohorts',
    'shared_resources',
    'daily_sustainability_summaries',
    'ethical_food_items'
  );
```

**Expected result:** Should show counts for all table types, total_new_tables = 28

---

## 📊 Check Data Migration

```sql
-- Verify nutrition plans were migrated to v2.0
SELECT
  COUNT(*) as total_plans,
  COUNT(*) FILTER (WHERE format_version = '2.0') as v2_plans,
  COUNT(*) FILTER (WHERE migrated_at IS NOT NULL) as migrated_plans,
  COUNT(*) FILTER (WHERE format_version IS NULL) as null_version
FROM nutrition_plans;
```

**Expected:** All plans should have format_version = '2.0' and migrated_at filled

---

## 🎉 Success Indicators

You'll know migrations succeeded when:

- ✅ Both queries run without errors
- ✅ 28 new tables created
- ✅ All nutrition_plans have format_version = '2.0'
- ✅ Archive tables contain backup data
- ✅ Sustainability data populated for common foods
- ✅ User streaks initialized
- ✅ Allergy profiles created for all users

---

## 🐛 Troubleshooting

### Error: "relation already exists"
**Meaning:** Tables already created (migration 1 already ran)
**Solution:** Skip to migration 2

### Error: "permission denied"
**Meaning:** User doesn't have CREATE TABLE permission
**Solution:** Make sure you're logged in as project owner

### Error: "out of memory"
**Meaning:** Database doesn't have enough resources
**Solution:** Upgrade database tier temporarily or run migrations in smaller batches

### Query takes >5 minutes
**Meaning:** Lots of data to migrate
**Solution:** This is normal! Just wait. Check query status in dashboard.

---

## 🔄 Rollback (If Needed)

If something goes wrong, you can rollback:

```sql
BEGIN;

-- Restore nutrition plans
TRUNCATE nutrition_plans;
INSERT INTO nutrition_plans SELECT * FROM nutrition_plans_archive;

-- Restore meals
TRUNCATE meals;
INSERT INTO meals SELECT * FROM meals_archive;

-- Drop new tables
DROP TABLE IF EXISTS households CASCADE;
DROP TABLE IF EXISTS achievements CASCADE;
-- ... (see MIGRATION_INSTRUCTIONS.md for full rollback)

COMMIT;
```

---

## 📞 Need Help?

**Can't access SQL Editor?**
- Make sure you're project owner
- Check browser console for errors
- Try incognito/private mode

**Migration failed partway?**
- Check error message
- Take screenshot
- Contact support with details

**Not sure if it worked?**
- Run verification queries above
- Check Tables tab in dashboard
- Look for new tables listed

---

## ✨ What You Just Enabled

After successful migration, your app now supports:

✅ **10 Revolutionary Features:**
1. Meal Prep Planning with batch cooking
2. Gamification with achievements & streaks
3. Restaurant mode with AI estimation
4. Macro cycling & periodization
5. Allergy & medical condition tracking
6. Advanced analytics & predictions
7. Wearable & app integrations
8. Voice interface capabilities
9. Real-time collaboration
10. Sustainability tracking

✅ **28 New Tables** ready for advanced features
✅ **Backward Compatible** - old app still works
✅ **Data Preserved** - all existing data safe in archives
✅ **Performance Improved** - new indexes added

---

**Ready to deploy the new app features!** 🎉

---

**Last Updated:** 2025-09-30
**Migration Files:** 20251001000001 & 20251001000002
**Estimated Time:** 5-10 minutes total