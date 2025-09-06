# GitHub-Supabase Integration Guide

This document explains the different options for connecting GitHub with Supabase for automatic deployment and continuous integration.

## Current Setup ✅

You already have a **GitHub Actions-based auto-deployment** system configured:

### What's Currently Working:
- **Automatic deployment** on push to `develop` and `main` branches
- **Database migrations** are automatically applied
- **Edge Functions** are automatically deployed
- **Production protection** with manual approval for `main` branch
- **Environment separation** between dev and prod

### Files:
- `.github/workflows/supabase-deploy.yml` - Main deployment workflow
- `.github/workflows/test-supabase.yml` - Connection testing workflow

## Integration Options

### 1. GitHub Actions (Current - Recommended) ⭐

**Status**: ✅ Already implemented and working

**How it works**:
```yaml
# Triggers on push to develop/main
on:
  push:
    branches: [ develop, main ]

# Deploys database migrations
- name: Push DB migrations
  run: supabase db push

# Deploys edge functions
- name: Deploy Edge Functions
  run: supabase functions deploy function-name
```

**Pros**:
- ✅ Full control over deployment logic
- ✅ Branch-based environments (dev/prod)
- ✅ Manual approval for production
- ✅ Can run tests before deployment
- ✅ Free for public repos, generous limits for private
- ✅ Already configured and working

**Cons**:
- Requires GitHub Secrets setup
- Need to manage Supabase CLI in workflows

### 2. Supabase GitHub Integration (Direct)

**Status**: 🔄 Alternative option

**How it works**:
- Connect your GitHub repo directly in Supabase Dashboard
- Automatic PR previews
- Built-in database diffing
- One-click deployment

**Setup**:
1. Go to Supabase Dashboard → Settings → Integrations
2. Connect GitHub repository
3. Configure deployment settings

**Pros**:
- Simpler setup
- Automatic PR previews
- Built-in database diffing
- Visual interface

**Cons**:
- Less control over deployment process
- Limited to Supabase-specific features
- May conflict with existing GitHub Actions

### 3. Supabase CLI + Custom Scripts

**Status**: 🔄 For advanced users

**How it works**:
- Use Supabase CLI directly
- Integrate with any CI/CD system
- Custom deployment scripts

**Example**:
```bash
# Manual deployment
supabase link --project-ref your-project-ref
supabase db push
supabase functions deploy function-name
```

**Pros**:
- Maximum control
- Can integrate with any CI/CD system
- Custom deployment logic

**Cons**:
- More setup required
- Manual process unless automated
- Need to handle authentication

## Enhanced Setup (Just Added)

I've enhanced your current GitHub Actions setup with:

### 1. Enhanced Main Workflow
- **Better logging** with deployment status
- **Verification steps** to confirm successful deployment
- **Deployment notifications** with URLs and status

### 2. PR Preview Workflow (New)
- **Automatic preview deployments** for pull requests
- **PR comments** with preview URLs
- **Isolated testing environment**

### 3. Health Check Workflow (New)
- **Scheduled health checks** every 6 hours
- **API connectivity testing**
- **Edge function testing**

## Required GitHub Secrets

To make the enhanced workflows work, you need these secrets in your GitHub repository:

### Current Secrets (Already Set):
- `SUPABASE_ACCESS_TOKEN` - Your Supabase access token
- `SUPABASE_PROJECT_REF` - Your Supabase project reference

### New Secrets (Optional):
- `SUPABASE_PREVIEW_PROJECT_REF` - For PR preview deployments

## Setup Instructions

### 1. Get Supabase Access Token
```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Get your access token from the dashboard
# Go to: https://supabase.com/dashboard/account/tokens
```

### 2. Get Project Reference
```bash
# Your project reference is in the URL:
# https://supabase.com/dashboard/project/YOUR_PROJECT_REF
```

### 3. Add GitHub Secrets
1. Go to your GitHub repository
2. Settings → Secrets and variables → Actions
3. Add the secrets listed above

### 4. Test the Setup
```bash
# Test the connection
gh workflow run test-supabase.yml

# Test deployment (will trigger on push to develop/main)
git push origin develop
```

## Deployment Flow

### Development Flow:
1. Push to `develop` branch
2. GitHub Actions automatically deploys to dev environment
3. Database migrations applied
4. Edge functions deployed
5. Deployment status reported

### Production Flow:
1. Push to `main` branch
2. GitHub Actions triggers production deployment
3. **Manual approval required** (GitHub Environments)
4. Database migrations applied
5. Edge functions deployed
6. Success notification sent

### PR Preview Flow:
1. Create PR with Supabase changes
2. Preview deployment automatically triggered
3. Preview URL posted as PR comment
4. Test changes in isolated environment

## Monitoring and Troubleshooting

### Check Deployment Status:
- GitHub Actions tab in your repository
- Supabase Dashboard → Logs
- Edge Function logs in Supabase Dashboard

### Common Issues:
1. **Authentication errors**: Check `SUPABASE_ACCESS_TOKEN`
2. **Project not found**: Check `SUPABASE_PROJECT_REF`
3. **Migration conflicts**: Check database schema changes
4. **Function deployment fails**: Check function code and dependencies

### Health Monitoring:
- The new `supabase-status.yml` workflow runs every 6 hours
- Tests API connectivity and edge functions
- Sends notifications on failures

## Recommendations

### For Your Current Setup:
1. **Keep the GitHub Actions approach** - it's working well
2. **Use the enhanced workflows** I just added
3. **Set up the optional PR preview** if you want isolated testing
4. **Monitor with the health check workflow**

### Future Enhancements:
1. **Add Slack/Discord notifications** for deployment status
2. **Implement rollback procedures** for failed deployments
3. **Add database backup before migrations**
4. **Set up staging environment** for testing

## Alternative: Supabase Dashboard Integration

If you want to try the direct Supabase integration:

1. **Disable current GitHub Actions** (rename the workflow files)
2. **Connect repository** in Supabase Dashboard
3. **Configure deployment settings**
4. **Test with a small change**

**Note**: This might conflict with your current setup, so test carefully.

## Conclusion

Your current GitHub Actions setup is **excellent** and provides:
- ✅ Full control and customization
- ✅ Production safety with manual approval
- ✅ Environment separation
- ✅ Comprehensive logging and monitoring

The enhanced workflows I added will make it even better with:
- ✅ Better visibility into deployments
- ✅ PR preview capabilities
- ✅ Automated health monitoring

**Recommendation**: Stick with GitHub Actions and use the enhanced workflows for the best developer experience and deployment control.
