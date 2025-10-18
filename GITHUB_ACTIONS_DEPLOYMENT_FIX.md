# 🚀 GitHub Actions Deployment Fix

## ❌ **Issue Identified**
Your `deploy_prod` job is failing because:
1. **Missing Project Reference**: The `supabase link --project-ref` command is missing the required project reference argument
2. **Incorrect Secret Configuration**: The workflow is using the same secrets for both dev and production environments

## ✅ **Solution Implemented**

### **New Workflow File Created**
- **File**: `.github/workflows/supabase-deploy-fixed-v2.yml`
- **Features**: 
  - Separate secrets for dev and production environments
  - Better error handling and validation
  - Clear error messages when secrets are missing

### **Required GitHub Secrets**

Go to your GitHub repository: **Settings → Secrets and variables → Actions**

#### **For Development Environment:**
```
SUPABASE_PROJECT_REF_DEV = your-dev-project-reference
SUPABASE_ACCESS_TOKEN_DEV = your-dev-access-token
```

#### **For Production Environment:**
```
SUPABASE_PROJECT_REF = your-prod-project-reference  
SUPABASE_ACCESS_TOKEN = your-prod-access-token
```

## 🔧 **Setup Instructions**

### **Step 1: Get Your Supabase Project References**

1. **Go to Supabase Dashboard**: https://supabase.com/dashboard
2. **Find your project references**:
   - **Development**: Look for your dev project URL (e.g., `https://abc123def.supabase.co`)
   - **Production**: Look for your prod project URL (e.g., `https://xyz789ghi.supabase.co`)
   - The project reference is the part before `.supabase.co`

### **Step 2: Get Your Access Tokens**

1. **Go to**: https://supabase.com/dashboard/account/tokens
2. **Generate tokens** for both environments
3. **Copy the tokens** (you won't see them again!)

### **Step 3: Configure GitHub Secrets**

1. **Go to**: https://github.com/buv7/Vagus_app/settings/secrets/actions
2. **Add these secrets**:

#### **Development Secrets:**
- **Name**: `SUPABASE_PROJECT_REF_DEV`
- **Value**: Your dev project reference (e.g., `abc123def`)

- **Name**: `SUPABASE_ACCESS_TOKEN_DEV`  
- **Value**: Your dev access token

#### **Production Secrets:**
- **Name**: `SUPABASE_PROJECT_REF`
- **Value**: Your prod project reference (e.g., `xyz789ghi`)

- **Name**: `SUPABASE_ACCESS_TOKEN`
- **Value**: Your prod access token

### **Step 4: Replace the Workflow File**

```bash
# Remove the old workflow
rm .github/workflows/supabase-deploy-fixed.yml

# Rename the new workflow
mv .github/workflows/supabase-deploy-fixed-v2.yml .github/workflows/supabase-deploy-fixed.yml
```

### **Step 5: Test the Deployment**

1. **Commit and push**:
   ```bash
   git add .
   git commit -m "fix: Update GitHub Actions workflow with proper secret handling"
   git push origin develop
   ```

2. **Check the workflow**:
   - Go to: https://github.com/buv7/Vagus_app/actions
   - Look for "Supabase Auto Deploy (Fixed v2)"
   - It should now succeed! ✅

## 🔍 **Troubleshooting**

### **If the workflow still fails:**

1. **Check the logs** in GitHub Actions for specific error messages
2. **Verify all secrets are set** correctly in GitHub Settings
3. **Test the connection** using the test workflow:
   ```bash
   # Run the test workflow manually
   # Go to Actions → Test Supabase Connection → Run workflow
   ```

### **Common Issues:**

- **"Project not found"**: Check that your project references are correct
- **"Access denied"**: Check that your access tokens are valid and not expired
- **"Secret is missing"**: Make sure you've added all required secrets

## 📋 **Workflow Features**

### **Development Deployment** (`develop` branch):
- Uses `SUPABASE_PROJECT_REF_DEV` and `SUPABASE_ACCESS_TOKEN_DEV`
- Automatic deployment on push to `develop`
- Includes retry logic for database migrations

### **Production Deployment** (`main` branch):
- Uses `SUPABASE_PROJECT_REF` and `SUPABASE_ACCESS_TOKEN`
- Requires manual approval (GitHub Environments)
- Includes comprehensive error handling

### **Error Handling:**
- ✅ Validates secrets before attempting connection
- ✅ Clear error messages when secrets are missing
- ✅ Retry logic for database migrations (3 attempts)
- ✅ Proper environment separation

## 🎯 **Next Steps**

1. **Set up the secrets** as described above
2. **Replace the workflow file**
3. **Test the deployment** by pushing to `develop` branch
4. **Verify production deployment** by pushing to `main` branch

Your deployment pipeline should now work correctly! 🚀
