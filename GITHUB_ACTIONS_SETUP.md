# 🚀 GitHub Actions Setup Guide for VAGUS App

## ❌ Current Issue
The **Supabase Auto Deploy** workflow is failing because:
1. Database schema issues (missing tables, RLS policies)
2. Migration conflicts
3. Missing GitHub Secrets

## ✅ Solution Steps

### Step 1: Set Up GitHub Secrets

Go to your GitHub repository: https://github.com/buv7/Vagus_app

1. **Click**: Settings → Secrets and variables → Actions
2. **Add these secrets**:

#### Required Secrets:
- **`SUPABASE_ACCESS_TOKEN`**: Your Supabase access token
  - Get it from: https://supabase.com/dashboard/account/tokens
  - Click "Generate new token"
  - Copy the token

- **`SUPABASE_PROJECT_REF`**: Your project reference
  - Value: `kydrpnrmqbedjflklgue`
  - (This is from your Supabase URL: https://kydrpnrmqbedjflklgue.supabase.co)

### Step 2: Apply Database Fixes

**Option A: Manual Fix (Recommended)**
1. Go to: https://supabase.com/dashboard/project/kydrpnrmqbedjflklgue
2. Click "SQL Editor"
3. Copy the contents of `complete_production_fix.sql`
4. Paste and run it

**Option B: Use Fixed Workflow**
1. Replace `.github/workflows/supabase-deploy.yml` with `supabase-deploy-fixed.yml`
2. The fixed workflow includes retry logic and better error handling

### Step 3: Test the Workflow

1. **Commit the changes**:
   ```bash
   git add .
   git commit -m "fix: Update GitHub Actions workflow for Supabase deployment"
   git push origin develop
   ```

2. **Check the workflow**:
   - Go to: https://github.com/buv7/Vagus_app/actions
   - Look for "Supabase Auto Deploy" workflow
   - It should now succeed!

## 🔧 Troubleshooting

### If workflow still fails:

1. **Check the logs** in GitHub Actions
2. **Verify secrets** are set correctly
3. **Apply database fixes** manually first
4. **Check Supabase project** is accessible

### Common Issues:

- **"Project not found"**: Check SUPABASE_PROJECT_REF secret
- **"Access denied"**: Check SUPABASE_ACCESS_TOKEN secret
- **"Migration failed"**: Apply database fixes manually first

## 📊 Expected Results

After fixing:
- ✅ **deploy_dev** job should succeed
- ✅ **deploy_prod** job should be skipped (only runs on main branch)
- ✅ Database migrations should apply successfully
- ✅ Edge Functions should deploy (if any exist)

## 🎯 Next Steps

1. Set up the GitHub secrets
2. Apply the database fixes
3. Test the workflow
4. Your app will auto-deploy on every push to develop/main!

---

**Need help?** Check the GitHub Actions logs for detailed error messages.
