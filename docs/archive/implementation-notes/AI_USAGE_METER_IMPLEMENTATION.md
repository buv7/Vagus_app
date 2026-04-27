# AI Usage Meter Implementation for VAGUS App

## Overview

This implementation adds an AI Usage Meter component that is visible to all signed-in users (not just admins) in the VAGUS mobile app. The meter displays AI usage statistics including monthly usage, limits, and remaining quota.

## Changes Made

### 1. Created AI Usage Meter Widget
- **File**: `lib/widgets/ai/ai_usage_meter.dart`
- **Features**:
  - Shows monthly usage progress bar
  - Displays total requests and remaining quota
  - Color-coded usage indicators (green → yellow → orange → red)
  - Compact mode for smaller displays
  - Refresh functionality
  - Error handling and loading states

### 2. Created File Manager Screen
- **File**: `lib/screens/files/file_manager_screen.dart`
- **Features**:
  - File upload functionality
  - File categorization (images, documents, videos, audio, other)
  - Search and filter capabilities
  - File management (view, delete)
  - **AI Usage Meter prominently displayed at the top**

### 3. Added AI Usage Meter to Nutrition Screens
- **NutritionPlanBuilder**: Added at the top of the form
- **NutritionPlanViewer**: Added at the top of the plan display
- Both use compact mode to save space

### 4. Database Schema
- **File**: `supabase/migrations/create_ai_usage_table.sql`
  - `ai_usage` table with user-specific usage tracking
  - Row Level Security (RLS) policies
  - Helper functions for usage management
  - Monthly reset functionality

- **File**: `supabase/migrations/create_user_files_table.sql`
  - `user_files` table for file management
  - RLS policies for user data isolation
  - File categorization and metadata storage

### 5. Navigation Integration
- **Coach Home Screen**: Added File Manager button
- **Client Home Screen**: Added File Manager button
- Both lead to the same File Manager screen with AI Usage Meter

## Key Features

### ✅ **No Role Restrictions**
- AI Usage Meter is visible to **all signed-in users**
- No admin-only checks or role restrictions
- Accessible to clients, coaches, and admins

### ✅ **User-Specific Data**
- Each user sees only their own AI usage
- Database queries filter by `user_id`
- RLS policies ensure data isolation

### ✅ **Cross-Platform Support**
- Works on both iOS and Android
- Responsive design with compact mode
- Consistent with VAGUS app design language

### ✅ **Real-time Updates**
- Refresh button to update usage data
- Automatic loading states
- Error handling with retry options

## Database Tables

### `ai_usage` Table
```sql
- user_id (UUID, references auth.users)
- total_requests (INTEGER)
- requests_this_month (INTEGER)
- monthly_limit (INTEGER, default 100)
- last_used (TIMESTAMP)
- created_at, updated_at (TIMESTAMP)
```

### `user_files` Table
```sql
- user_id (UUID, references auth.users)
- file_name, file_path, file_url (TEXT)
- file_size (BIGINT)
- file_type, category (TEXT)
- created_at, updated_at (TIMESTAMP)
```

## Usage Examples

### Basic Usage
```dart
// Simple usage meter
AIUsageMeter()

// Compact version for smaller spaces
AIUsageMeter(isCompact: true)

// With refresh callback
AIUsageMeter(
  onRefresh: () {
    // Handle refresh
  },
)
```

### Integration in Screens
```dart
// Add to any screen
Padding(
  padding: const EdgeInsets.all(16),
  child: AIUsageMeter(
    isCompact: true,
    onRefresh: _loadData,
  ),
),
```

## Testing

### Unit Tests
- **File**: `lib/widgets/ai/ai_usage_meter_test.dart`
- Tests basic widget functionality
- Verifies loading states and error handling

### Manual Testing
1. **Client Account**: Verify AI Usage Meter appears in File Manager and Nutrition screens
2. **Coach Account**: Verify AI Usage Meter appears in File Manager and Nutrition screens
3. **Admin Account**: Verify AI Usage Meter appears in File Manager and Nutrition screens
4. **Usage Updates**: Test that usage data updates correctly after AI operations

## Deployment Steps

### 1. Database Migration
```sql
-- Run in Supabase SQL editor
-- Execute both migration files:
-- - create_ai_usage_table.sql
-- - create_user_files_table.sql
```

### 2. Storage Bucket
```bash
# Ensure vagus-media bucket exists in Supabase
# Set appropriate RLS policies for file uploads
```

### 3. App Deployment
```bash
# Build and deploy the Flutter app
flutter build apk --release
flutter build ios --release
```

## Security Considerations

### ✅ **Row Level Security (RLS)**
- Users can only access their own data
- No cross-user data leakage
- Secure file uploads and downloads

### ✅ **Authentication Required**
- AI Usage Meter only visible to signed-in users
- No anonymous access to usage data
- Proper user session validation

### ✅ **Input Validation**
- File type restrictions
- File size limits (configurable)
- Secure file path handling

## Future Enhancements

### 🔮 **Planned Features**
- Usage analytics and charts
- Custom monthly limits per user
- Usage notifications and alerts
- Integration with billing system
- Advanced file preview capabilities

### 🔮 **Performance Optimizations**
- Usage data caching
- Batch file operations
- Lazy loading for large file lists
- Background usage tracking

## Troubleshooting

### Common Issues

1. **AI Usage Meter not appearing**
   - Check user authentication status
   - Verify database tables exist
   - Check RLS policies are enabled

2. **File uploads failing**
   - Verify storage bucket permissions
   - Check file size limits
   - Ensure proper file type validation

3. **Usage data not updating**
   - Check database connection
   - Verify user ID filtering
   - Check for RLS policy conflicts

### Debug Mode
```dart
// Enable verbose logging in AI Usage Meter
// Check console for detailed error messages
// Verify Supabase client initialization
```

## Support

For issues or questions:
1. Check the database logs in Supabase dashboard
2. Verify RLS policies are correctly configured
3. Test with different user roles
4. Check file permissions and storage settings

---

**Note**: This implementation ensures that the AI Usage Meter is accessible to all authenticated users while maintaining proper data security and user isolation.
