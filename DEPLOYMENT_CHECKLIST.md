# 🚀 AI Usage Tracking Deployment Checklist

## ✅ Pre-Deployment
- [ ] Supabase CLI installed and authenticated
- [ ] Database migration `create_ai_usage_table.sql` ready
- [ ] Edge Function `update-ai-usage/index.ts` created
- [ ] Flutter app updated with test widget

## 🚀 Step 1: Deploy Edge Function
```bash
supabase functions deploy update-ai-usage --no-verify-jwt
```
- [ ] Function deployed successfully
- [ ] No error messages in terminal

## ⚙️ Step 2: Set Environment Variables
In Supabase Dashboard → Project Settings → Functions → Environment Variables:

- [ ] **SUPABASE_URL** = `https://kydrpnrmqbedjflklgue.supabase.co`
- [ ] **SUPABASE_SERVICE_ROLE_KEY** = [your service role key]

## 🗄️ Step 3: Run Database Migration
```bash
# Option 1: Using Supabase CLI
supabase db push

# Option 2: Manual execution in Supabase Dashboard
# Go to SQL Editor and run create_ai_usage_table.sql
```
- [ ] Migration executed successfully
- [ ] `ai_usage` table exists
- [ ] RLS policies are active

## 🧪 Step 4: Test Edge Function
```bash
curl -X POST https://kydrpnrmqbedjflklgue.supabase.co/functions/v1/update-ai-usage \
  -H "Content-Type: application/json" \
  -d '{"user_id": "test-user-id", "tokens_used": 100}'
```
- [ ] Function responds with `{"success": true}`
- [ ] No error messages

## 📱 Step 5: Test Flutter App
1. **Navigate to File Manager**
   - [ ] AI Usage Meter displays
   - [ ] AI Usage Test Panel shows

2. **Test Basic Usage**
   - [ ] "Test 50 Tokens" button works
   - [ ] Success message appears
   - [ ] Usage meter updates

3. **Test Detailed Usage**
   - [ ] "Test Detailed (75)" button works
   - [ ] Metadata is recorded
   - [ ] Usage meter updates

4. **Test Refresh**
   - [ ] "Refresh Data" button works
   - [ ] Current usage displays correctly

## 🔍 Step 6: Verify Database
In Supabase Dashboard → Table Editor → `ai_usage`:
- [ ] Records created with correct user_id
- [ ] Month/year is current
- [ ] tokens_used matches test values
- [ ] updated_at is recent

## 📊 Step 7: Check Logs
In Supabase Dashboard → Functions → `update-ai-usage` → Logs:
- [ ] Successful executions logged
- [ ] No error messages
- [ ] Request/response data visible

## 🎯 Step 8: Integration Testing
- [ ] Multiple test calls work
- [ ] Usage accumulates correctly
- [ ] Real-time updates function
- [ ] No Firebase dependencies required

## 🚨 Troubleshooting Common Issues

### Edge Function Not Found
```bash
supabase functions list
# If not listed, redeploy:
supabase functions deploy update-ai-usage --no-verify-jwt
```

### Environment Variables Missing
- Check Supabase Dashboard → Project Settings → Functions → Environment Variables
- Ensure both variables are set correctly
- Wait a few minutes for changes to propagate

### Database Errors
- Verify migration was run: `supabase db push`
- Check RLS policies are correct
- Ensure user is authenticated

### Usage Not Updating
- Check Edge Function logs for errors
- Verify request body format
- Ensure user_id is valid UUID

## ✅ Final Verification

The AI Usage Tracking system is fully deployed when:

1. **Edge Function** responds successfully to test calls
2. **Database** contains test records
3. **Flutter App** displays and updates usage data
4. **Test Widget** successfully records usage
5. **Real-time Updates** work without page refresh
6. **No Errors** in logs or console

## 🎉 Success!

Once all checkboxes are marked, your AI Usage Tracking system is fully operational and ready for production use!

## 🔄 Next Steps

After successful deployment:
1. Remove test widget from production code
2. Integrate with real AI requests
3. Set up usage monitoring and alerts
4. Configure usage limits per user
