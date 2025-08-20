# VAGUS - AI-Powered Fitness & Nutrition App

VAGUS is a comprehensive Flutter mobile application that provides AI-powered fitness and nutrition coaching, built with Supabase backend and OneSignal push notifications.

## 🚀 Features

### Core Functionality
- **AI-Powered Nutrition Plans** - Generate personalized meal plans using AI
- **Workout Management** - Create and track fitness routines
- **File Management** - Upload, organize, and manage personal files
- **Push Notifications** - Cross-platform notifications using OneSignal
- **AI Usage Tracking** - Monitor and limit AI request usage per user
- **User Authentication** - Secure login with Supabase Auth
- **Role-Based Access** - Separate interfaces for coaches and clients

### AI Usage Meter
- **Real-time Usage Display** - Shows current month usage and limits
- **Token Tracking** - Monitors AI request tokens consumed
- **Monthly Limits** - Configurable usage limits per user
- **Usage Analytics** - Historical usage data and trends

## 🏗️ Architecture

### Frontend
- **Flutter** - Cross-platform mobile development
- **Supabase Flutter** - Backend integration
- **OneSignal Flutter** - Push notification handling

### Backend
- **Supabase** - Database, authentication, and storage
- **Edge Functions** - Serverless backend logic
- **PostgreSQL** - Relational database with RLS
- **Storage Buckets** - File upload and management

### Notifications
- **OneSignal** - Cross-platform push notifications
- **Supabase Edge Functions** - Notification routing and delivery
- **Device Registration** - User device management for targeting

## 📱 Screens

### Coach Interface
- Dashboard with client overview
- Nutrition plan builder
- File manager
- Messaging system

### Client Interface
- Home dashboard
- Nutrition plan viewer
- File manager
- Progress tracking

## 🗄️ Database Schema

### Core Tables
- `profiles` - User profile information
- `ai_usage` - AI request tracking with monthly limits
- `user_files` - File metadata and organization
- `user_devices` - OneSignal device registration
- `nutrition_plans` - AI-generated meal plans
- `workout_plans` - Fitness routine data

### Security
- **Row Level Security (RLS)** - Data isolation per user
- **JWT Authentication** - Secure API access
- **Service Role Keys** - Admin operations via Edge Functions

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Supabase account and project
- OneSignal account and app
- Android Studio / Xcode for native builds

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd vagus_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a new Supabase project
   - Run database migrations from `supabase/migrations/`
   - Set environment variables

4. **Configure OneSignal**
   - Create OneSignal app
   - Update `ONESIGNAL_APP_ID` in `lib/services/notifications/onesignal_service.dart`
   - Add native configuration files

5. **Deploy Edge Functions**
   ```bash
   supabase functions deploy send-notification --no-verify-jwt
   supabase functions deploy update-ai-usage --no-verify-jwt
   ```

### Environment Variables

#### Supabase
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Public anon key
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key for Edge Functions

#### OneSignal
- `ONESIGNAL_APP_ID` - Your OneSignal app ID
- `ONESIGNAL_REST_API_KEY` - REST API key for sending notifications

## 🔧 Development

### Project Structure
```
lib/
├── screens/          # App screens and UI
├── services/         # Business logic and API calls
├── widgets/          # Reusable UI components
├── components/       # Feature-specific components
└── main.dart         # App entry point

supabase/
├── functions/        # Edge Functions
├── migrations/       # Database migrations
└── config.toml      # Supabase configuration
```

### Key Services
- `AIUsageService` - AI usage tracking and limits
- `OneSignalService` - Push notification management
- `NotificationHelper` - Notification sending utilities

### Adding New Features
1. Create database migrations in `supabase/migrations/`
2. Add Edge Functions in `supabase/functions/`
3. Create Flutter services in `lib/services/`
4. Build UI components in `lib/widgets/` or `lib/screens/`
5. Update navigation and routing

## 📊 AI Usage Tracking

### How It Works
1. **Request Made** - User initiates AI request (nutrition, workout, etc.)
2. **Usage Recorded** - After successful response, call `AIUsageService.recordUsage()`
3. **Database Update** - Edge Function upserts usage data with month/year grouping
4. **Real-time Display** - `AIUsageMeter` shows current usage and limits

### Integration Example
```dart
// After AI request completes
final tokensUsed = response.usage?.totalTokens ?? 0;
await AIUsageService.instance.recordUsage(tokensUsed: tokensUsed);
```

### Usage Limits
- **Monthly Request Limit** - Configurable per user
- **Token Tracking** - Monitor AI consumption
- **Automatic Reset** - Monthly usage resets automatically

## 🔔 Push Notifications

### Features
- **Cross-platform** - iOS and Android support
- **Targeted Delivery** - Send to specific users, roles, or topics
- **Rich Content** - Support for custom data and routing
- **Background Handling** - Notifications when app is closed

### Sending Notifications
```dart
// Send to specific user
await NotificationHelper.instance.sendToUser(
  userId: 'user-id',
  title: 'New Message',
  message: 'You have a new message from your coach',
  route: '/messages',
);
```

## 📁 File Management

### Features
- **Multi-format Support** - Images, documents, videos, audio
- **Category Organization** - Automatic file type detection
- **Secure Storage** - Supabase storage with RLS
- **Search & Filter** - Find files quickly

### Storage Structure
```
vagus-media/
└── user_files/
    └── {user_id}/
        └── {timestamp}_{filename}
```

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test test/widgets/
```

### Integration Tests
```bash
flutter test integration_test/
```

## 🚀 Deployment

### Android
1. Update `android/app/build.gradle.kts`
2. Configure signing keys
3. Build APK: `flutter build apk --release`

### iOS
1. Update `ios/Runner/Info.plist`
2. Configure signing and capabilities
3. Build: `flutter build ios --release`

### Supabase
1. Deploy migrations: `supabase db push`
2. Deploy functions: `supabase functions deploy`
3. Update environment variables

## Supabase Auto Deploy

- DB migrations live in `supabase/migrations/` (timestamped *.sql).  
- On push to `develop`: CI applies to DEV project.  
- On push to `main`: CI applies to PROD project (requires manual approval in GitHub Environments).

### GitHub Secrets (Settings → Secrets and variables → Actions)
**Dev**
- SUPABASE_PROJECT_REF_DEV = abcdefghijk (from Supabase settings)
- SUPABASE_ACCESS_TOKEN_DEV = <personal access token>

**Prod**
- SUPABASE_PROJECT_REF = lmnopqrstuv
- SUPABASE_ACCESS_TOKEN = <personal access token>

> Optional (Edge Functions): add any function secrets in Supabase Dashboard directly, or manage with `supabase secrets set` manually.

## 📚 Documentation

- [OneSignal Setup Guide](docs/onesignal_setup.md)
- [AI Usage Integration Guide](docs/ai_usage_integration.md)
- [Database Schema](supabase/migrations/)
- [Edge Functions](supabase/functions/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Check the documentation
- Review existing issues
- Create a new issue with detailed information

## 🔄 Changelog

### Latest Updates
- ✅ AI Usage Meter implementation
- ✅ File Manager screen
- ✅ OneSignal push notifications
- ✅ Supabase Edge Functions
- ✅ Monthly usage tracking with tokens
- ✅ Role-based access control
- ✅ Secure file storage with RLS

---

**VAGUS** - Empowering fitness and nutrition with AI technology.
