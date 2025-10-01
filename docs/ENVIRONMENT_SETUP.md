# Environment Setup Guide

This guide explains how to configure environment variables for the VAGUS app.

## Overview

The VAGUS app uses environment variables to manage sensitive credentials and configuration. This ensures:
- ✅ Credentials are never committed to version control
- ✅ Different environments (dev/staging/prod) use different configs
- ✅ Easy credential rotation without code changes
- ✅ Secure deployment practices

## Initial Setup

### 1. Create Your `.env` File

```bash
# Copy the example file
cp .env.example .env
```

### 2. Fill in Your Credentials

Open `.env` in your text editor and replace placeholder values:

```env
# Supabase Configuration
SUPABASE_URL=https://your-actual-project.supabase.co
SUPABASE_ANON_KEY=your-actual-anon-key-here

# OneSignal Configuration (optional)
ONESIGNAL_APP_ID=your-onesignal-app-id

# Environment
ENVIRONMENT=development
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the App

```bash
flutter run
```

You should see:
```
✅ Environment variables loaded successfully
   Environment: development
   Supabase URL: ✓ Set
   Supabase Key: ✓ Set
   OneSignal ID: ✗ Missing
```

## Getting Credentials

### Supabase Credentials

1. Log in to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Go to **Settings** → **API**
4. Copy the following:
   - **Project URL** → `SUPABASE_URL`
   - **anon/public key** → `SUPABASE_ANON_KEY`

⚠️ **Important:** Use the **anon** key, NOT the service_role key!

### OneSignal Credentials (Optional)

1. Log in to [OneSignal Dashboard](https://app.onesignal.com)
2. Select your app
3. Go to **Settings** → **Keys & IDs**
4. Copy **OneSignal App ID** → `ONESIGNAL_APP_ID`

If you don't configure OneSignal, push notifications will be disabled but the app will still work.

## Environment Variables Reference

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SUPABASE_URL` | Your Supabase project URL | `https://abc123.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase anonymous/public key | `eyJhbGc...` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ONESIGNAL_APP_ID` | OneSignal App ID for push notifications | _(none)_ |
| `ENVIRONMENT` | Current environment | `development` |
| `API_BASE_URL` | Custom API endpoint | _(none)_ |
| `DEBUG_MODE` | Enable debug logging | `false` |
| `SENTRY_DSN` | Sentry error tracking DSN | _(none)_ |

## Multiple Environments

### Development Environment

```env
ENVIRONMENT=development
SUPABASE_URL=https://dev-project.supabase.co
SUPABASE_ANON_KEY=dev-anon-key
```

### Staging Environment

```env
ENVIRONMENT=staging
SUPABASE_URL=https://staging-project.supabase.co
SUPABASE_ANON_KEY=staging-anon-key
```

### Production Environment

```env
ENVIRONMENT=production
SUPABASE_URL=https://prod-project.supabase.co
SUPABASE_ANON_KEY=prod-anon-key
```

## Verification

### Check Configuration

```bash
# Run the app
flutter run

# Look for output in console:
✅ Environment variables loaded successfully
```

### Validate All Variables

The app automatically validates required variables on startup. If any are missing, you'll see:

```
⚠️  Missing required environment variables: SUPABASE_URL, SUPABASE_ANON_KEY
   App may not function correctly without these values
```

### Test Database Connection

If the app starts successfully and you can log in, your Supabase credentials are correct.

## Troubleshooting

### Error: "Failed to load .env file"

**Cause:** `.env` file doesn't exist

**Solution:**
```bash
cp .env.example .env
# Then edit .env with your credentials
```

### Error: "Missing required environment variables"

**Cause:** `.env` file exists but is empty or incomplete

**Solution:** Open `.env` and ensure `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set

### Error: "Supabase initialization failed"

**Cause:** Invalid credentials or wrong URL

**Solution:**
1. Double-check credentials in Supabase Dashboard
2. Ensure you're using the **anon** key, not service_role
3. Verify URL includes `https://` and `.supabase.co`

### Warning: "OneSignal App ID not configured"

**Cause:** `ONESIGNAL_APP_ID` is not set in `.env`

**Solution:** This is optional. Push notifications will be disabled, but the app will work. To enable:
1. Get your OneSignal App ID
2. Add to `.env`: `ONESIGNAL_APP_ID=your-app-id`
3. Restart the app

## Security Best Practices

### ✅ DO:
- Keep `.env` file on your local machine only
- Use different credentials for dev/staging/prod
- Rotate credentials if they're ever exposed
- Add `.env` to `.gitignore` (already configured)
- Use environment-specific `.env` files for CI/CD

### ❌ DON'T:
- Commit `.env` to version control
- Share `.env` files via email or Slack
- Use production credentials in development
- Hardcode credentials in source code
- Include credentials in error messages or logs

## CI/CD Configuration

### GitHub Actions

Create repository secrets:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `ONESIGNAL_APP_ID`

Then in your workflow:

```yaml
- name: Create .env file
  run: |
    echo "SUPABASE_URL=${{ secrets.SUPABASE_URL }}" >> .env
    echo "SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}" >> .env
    echo "ONESIGNAL_APP_ID=${{ secrets.ONESIGNAL_APP_ID }}" >> .env
    echo "ENVIRONMENT=production" >> .env
```

### Codemagic

Add environment variables in:
**App settings** → **Environment variables**

### Fastlane

Create `fastlane/.env.default`:

```env
SUPABASE_URL=https://...
SUPABASE_ANON_KEY=...
```

Then reference in `Fastfile`:

```ruby
ENV['SUPABASE_URL']
```

## Credential Rotation

If credentials are exposed:

### 1. Rotate Supabase Key

1. Go to Supabase Dashboard → Settings → API
2. Click **Reset API Keys** (this will generate new keys)
3. Update `.env` with new `SUPABASE_ANON_KEY`
4. Update all deployed environments
5. Test the app

### 2. Rotate OneSignal Key

1. OneSignal App IDs cannot be rotated
2. Create a new OneSignal app if necessary
3. Update `.env` with new `ONESIGNAL_APP_ID`

## Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [OneSignal Documentation](https://documentation.onesignal.com)
- [flutter_dotenv Package](https://pub.dev/packages/flutter_dotenv)
- [12-Factor App Config](https://12factor.net/config)

## Support

If you encounter issues:
1. Check this guide's Troubleshooting section
2. Verify credentials in respective dashboards
3. Check app logs for specific error messages
4. Consult `AUDIT_REPORT.md` for known issues

---

**Last Updated:** October 1, 2025
**Version:** 1.0
