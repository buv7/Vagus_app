# 🧪 AI Usage Tracking Test Guide

## Prerequisites
- ✅ Supabase Edge Function `update-ai-usage` deployed
- ✅ Environment variables set in Supabase dashboard
- ✅ Database migration `create_ai_usage_table.sql` executed
- ✅ Flutter app running with test widget

## 🚀 Deployment Verification

### 1. Check Edge Function Status
```bash
supabase functions list
```
Should show `update-ai-usage` as deployed.

### 2. Verify Environment Variables
In Supabase Dashboard → Project Settings → Functions → Environment Variables:
- `SUPABASE_URL` = `https://kydrpnrmqbedjflklgue.supabase.co`
- `SUPABASE_SERVICE_ROLE_KEY` = [your service role key]

### 3. Test Edge Function Directly
```bash
curl -X POST https://kydrpnrmqbedjflklgue.supabase.co/functions/v1/update-ai-usage \
  -H "Content-Type: application/json" \
  -d '{"user_id": "test-user-id", "tokens_used": 100}'
```

Expected response:
```json
{
  "success": true,
  "message": "AI usage updated successfully",
  "data": {...}
}
```

## 📱 Flutter App Testing

### 1. Navigate to File Manager
- Open VAGUS app
- Go to File Manager screen
- You should see:
  - AI Usage Meter at the top
  - AI Usage Test Panel below it

### 2. Test Basic Usage Recording
1. Tap **"Test 50 Tokens"** button
2. Watch for success message: "✅ Successfully recorded 50 tokens"
3. AI Usage Meter should update automatically
4. Check Supabase logs for Edge Function execution

### 3. Test Detailed Usage Recording
1. Tap **"Test Detailed (75)"** button
2. Watch for success message with metadata
3. Verify usage meter updates

### 4. Test Data Refresh
1. Tap **"Refresh Data"** button
2. Should show current usage summary
3. Verify numbers match the meter display

## 🔍 Verification Steps

### 1. Check Database
In Supabase Dashboard → Table Editor → `ai_usage`:
- Should see records with your user_id
- Month/year should be current month
- `tokens_used` should match test values
- `updated_at` should be recent

### 2. Check Edge Function Logs
In Supabase Dashboard → Functions → `update-ai-usage` → Logs:
- Should see successful executions
- Check for any error messages

### 3. Verify Real-time Updates
- Make multiple test calls
- AI Usage Meter should update immediately
- Token counts should accumulate correctly

## 🚨 Troubleshooting

### Edge Function Not Found
```bash
# Redeploy the function
supabase functions deploy update-ai-usage --no-verify-jwt
```

### Environment Variables Missing
- Check Supabase Dashboard → Project Settings → Functions → Environment Variables
- Ensure both variables are set correctly

### Database Errors
- Verify migration was run: `supabase db push`
- Check RLS policies are correct
- Ensure user is authenticated

### Usage Not Updating
- Check Edge Function logs for errors
- Verify request body format
- Ensure user_id is valid UUID

## ✅ Success Criteria

The AI Usage Tracking system is working correctly when:

1. **Edge Function responds** with `{ "success": true }`
2. **Database records** are created/updated in `ai_usage` table
3. **AI Usage Meter** displays current usage data
4. **Test buttons** successfully record usage
5. **Real-time updates** work without page refresh
6. **No Firebase dependencies** are required

## 🎯 Next Steps

After successful testing:

1. **Remove test widget** from production code
2. **Integrate with real AI requests** using `AIUsageService`
3. **Set up monitoring** for usage limits
4. **Configure alerts** for high usage users

## 📊 Expected Data Flow

```
User Action → Flutter App → AIUsageService → Edge Function → Database → UI Update
     ↓              ↓            ↓              ↓           ↓         ↓
Test Button → recordUsage() → update-ai-usage → ai_usage → Meter Refresh
```

## 🔐 Security Notes

- Edge Function uses service role key (admin access)
- RLS policies ensure users only see their own data
- All requests are validated and sanitized
- CORS is properly configured for cross-origin requests
