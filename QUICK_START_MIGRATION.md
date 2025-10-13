# 🚀 QUICK START: Add full_name Column to profiles

## ⚡ Fastest Method (2 minutes)

### Option 1: Supabase Dashboard (RECOMMENDED)

**Step 1:** Go to SQL Editor
```
https://supabase.com/dashboard/project/kydrpnrmqbedjflklgue/sql/new
```

**Step 2:** Copy this file:
```
C:\Users\alhas\StudioProjects\vagus_app\supabase\migrations\20251002150000_add_full_name_to_profiles.sql
```

**Step 3:** Paste entire contents into SQL Editor

**Step 4:** Click **"Run"** button

**Step 5:** Look for success message:
```
✓ Full_name column migration completed successfully!
```

✅ **Done!** That's it.

---

## 📝 What This Does

- Adds `full_name` column (TEXT, nullable) to `profiles` table
- Copies all data from existing `name` column to `full_name`
- Creates search index on `full_name`
- Safe: Transaction-wrapped, no data loss

---

## ✅ Quick Verification

After running, execute this to confirm:

```sql
SELECT id, name, full_name, email FROM profiles LIMIT 5;
```

You should see:
- ✅ `full_name` column exists
- ✅ `full_name` contains the same data as `name`
- ✅ All rows returned successfully

---

## 📚 Need More Details?

See: `FULL_NAME_MIGRATION_SUMMARY.md` for:
- Alternative execution methods
- Verification steps
- Troubleshooting
- Rollback instructions

---

## 🔧 Alternative: Using Supabase CLI

```bash
supabase link --project-ref kydrpnrmqbedjflklgue
supabase db push
```

---

## 🆘 Having Issues?

**Common Solutions:**

1. **"Permission denied"** → Use database password (service role), not anon key
2. **"Table doesn't exist"** → Check you're connected to correct database
3. **"Column exists"** → Safe to ignore, migration is idempotent

**Still stuck?** Check `README_FULL_NAME_MIGRATION.md` for detailed troubleshooting.

---

**Time to complete:** ~2 minutes
**Risk level:** Low (safe, transaction-wrapped, no breaking changes)
**Reversible:** Yes (rollback instructions in README)
