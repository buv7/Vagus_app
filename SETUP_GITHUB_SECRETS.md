# 🔑 GitHub Secrets Setup - Quick Fix

## ❌ **Current Issue**
Your deployment is failing because GitHub Secrets are missing:
- `SUPABASE_PROJECT_REF` - Missing
- `SUPABASE_ACCESS_TOKEN` - Missing

## ✅ **Quick Fix (5 minutes)**

### **Step 1: Go to GitHub Secrets**
1. Visit: https://github.com/buv7/Vagus_app/settings/secrets/actions
2. Click **"New repository secret"**

### **Step 2: Add Required Secrets**

#### **Secret 1: SUPABASE_PROJECT_REF**
- **Name**: `SUPABASE_PROJECT_REF`
- **Value**: `kydrpnrmqbedjflklgue`
- **Description**: Your Supabase project reference

#### **Secret 2: SUPABASE_ACCESS_TOKEN**
- **Name**: `SUPABASE_ACCESS_TOKEN`
- **Value**: `[Get from Supabase Dashboard]`
- **Description**: Your Supabase access token

### **Step 3: Get Your Access Token**
1. Go to: https://supabase.com/dashboard/account/tokens
2. Click **"Generate new token"**
3. Copy the token and paste it as the value for `SUPABASE_ACCESS_TOKEN`

### **Step 4: Test the Deployment**
1. Go to: https://github.com/buv7/Vagus_app/actions
2. Click **"Supabase Auto Deploy (Fixed v2)"**
3. Click **"Re-run jobs"** → **"Re-run all jobs"**

## 🎯 **Expected Result**
- ✅ **deploy_prod** job should now succeed
- ✅ Database migrations will apply
- ✅ Your app will be deployed to production

## 🚨 **If Still Failing**
Check the GitHub Actions logs for specific error messages. The most common issues are:
- Wrong project reference
- Invalid access token
- Expired access token

---
**Need help?** The logs will show exactly what's wrong after you add the secrets.
