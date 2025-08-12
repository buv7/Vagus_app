# AI Usage Integration Guide

This guide explains how to integrate AI usage tracking into existing AI request flows in the VAGUS app.

## Overview

The AI usage tracking system consists of:
1. **`update-ai-usage` Edge Function** - Records usage in the database
2. **`AIUsageService`** - Flutter service for calling the Edge Function
3. **`AIUsageMeter`** - Widget to display usage statistics
4. **Updated database schema** - Supports monthly tracking with tokens

## Integration Steps

### 1. After Each AI Request

Add this code after your AI request completes:

```dart
import '../../services/ai/ai_usage_service.dart';

// After AI request completes
final tokensUsed = response.usage?.totalTokens ?? 0; // Get from your AI response
await AIUsageService.instance.recordUsage(tokensUsed: tokensUsed);
```

### 2. For More Detailed Tracking

If you want to track additional metadata:

```dart
await AIUsageService.instance.recordUsageWithMetadata(
  tokensUsed: tokensUsed,
  requestType: 'nutrition_plan_generation',
  requestId: requestId,
  additionalData: {
    'plan_type': 'weekly',
    'complexity': 'advanced',
  },
);
```

### 3. Check Usage Limits Before Requests

```dart
// Check if user can make more requests
if (await AIUsageService.instance.hasExceededMonthlyLimit()) {
  // Show limit exceeded message
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Monthly AI usage limit exceeded')),
  );
  return;
}

// Get remaining requests
final remaining = await AIUsageService.instance.getRemainingRequests();
print('Remaining requests this month: $remaining');
```

## Example Integration in Existing Code

### Nutrition Plan Generation

```dart
// In your nutrition plan generation method
Future<void> generateNutritionPlan() async {
  try {
    // Make AI request
    final aiResponse = await nutritionAI.generatePlan(prompt);
    
    // Record usage AFTER successful request
    final tokensUsed = aiResponse.usage?.totalTokens ?? 0;
    await AIUsageService.instance.recordUsage(
      tokensUsed: tokensUsed,
    );
    
    // Process response...
    
  } catch (e) {
    // Don't record usage for failed requests
    print('AI request failed: $e');
  }
}
```

### Workout Plan Generation

```dart
// In your workout plan generation method
Future<void> generateWorkoutPlan() async {
  try {
    // Make AI request
    final aiResponse = await workoutAI.generatePlan(prompt);
    
    // Record usage AFTER successful request
    final tokensUsed = aiResponse.usage?.totalTokens ?? 0;
    await AIUsageService.instance.recordUsage(
      tokensUsed: tokensUsed,
    );
    
    // Process response...
    
  } catch (e) {
    // Don't record usage for failed requests
    print('AI request failed: $e');
  }
}
```

### Chat/Messaging AI

```dart
// In your chat AI method
Future<void> sendAIMessage(String message) async {
  try {
    // Make AI request
    final aiResponse = await chatAI.sendMessage(message);
    
    // Record usage AFTER successful request
    final tokensUsed = aiResponse.usage?.totalTokens ?? 0;
    await AIUsageService.instance.recordUsage(
      tokensUsed: tokensUsed,
    );
    
    // Process response...
    
  } catch (e) {
    // Don't record usage for failed requests
    print('AI request failed: $e');
  }
}
```

## Important Notes

1. **Always record usage AFTER successful requests** - Don't record failed requests
2. **Get token count from AI response** - Most AI APIs return usage information
3. **Handle errors gracefully** - Usage tracking failures shouldn't break your app
4. **Use appropriate request types** - For detailed analytics and debugging

## Testing

### Test Usage Recording

```dart
// Test the service
final success = await AIUsageService.instance.recordUsage(tokensUsed: 150);
print('Usage recorded: $success');

// Check current usage
final usage = await AIUsageService.instance.getCurrentUsage();
print('Current usage: $usage');
```

### Test Edge Function

```bash
# Test the Edge Function directly
curl -X POST https://your-project.supabase.co/functions/v1/update-ai-usage \
  -H "Content-Type: application/json" \
  -d '{"user_id": "test-user-id", "tokens_used": 100}'
```

## Deployment

1. **Deploy the Edge Function:**
   ```bash
   supabase functions deploy update-ai-usage --no-verify-jwt
   ```

2. **Run the database migration:**
   ```sql
   -- Execute the create_ai_usage_table.sql migration
   ```

3. **Set environment variables:**
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`

## Monitoring

- Check Supabase logs for Edge Function execution
- Monitor the `ai_usage` table for usage data
- Use the `AIUsageMeter` widget to display real-time usage
- Set up alerts for usage limits if needed

## Troubleshooting

### Common Issues

1. **Edge Function not found**
   - Ensure function is deployed: `supabase functions list`
   - Check function name: `update-ai-usage`

2. **Database errors**
   - Verify migration was run
   - Check RLS policies
   - Ensure user is authenticated

3. **Usage not updating**
   - Check Edge Function logs
   - Verify request body format
   - Ensure user_id is valid UUID

### Debug Mode

Enable debug logging in your app:

```dart
// The service already includes debug prints
// Check console output for detailed logs
```
