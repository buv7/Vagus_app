# VAGUS App - Comprehensive Project Documentation

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Tech Stack & Dependencies](#tech-stack--dependencies)
3. [Architecture Overview](#architecture-overview)
4. [Features Documentation](#features-documentation)
5. [Service Layer Architecture](#service-layer-architecture)
6. [Data Models & Structures](#data-models--structures)
7. [UI Components & Widgets](#ui-components--widgets)
8. [Testing Strategy](#testing-strategy)
9. [File Structure](#file-structure)
10. [Setup & Development](#setup--development)

---

## 🏗️ Project Overview

### Project Name & Purpose
**VAGUS** - AI-Powered Fitness & Nutrition App

VAGUS is a comprehensive Flutter mobile application that provides AI-powered fitness and nutrition coaching, built with Supabase backend and OneSignal push notifications. The platform serves both coaches and clients with role-based access and features.

### Current Version
- **Version**: 0.9.0+90
- **Flutter SDK**: ^3.8.1
- **Platform**: Cross-platform (iOS/Android)

### Key Design Patterns
- **Singleton Pattern**: All services use singleton pattern for global access
- **Repository Pattern**: Services abstract data access from business logic
- **Service-Oriented Architecture**: Clean separation of concerns across domains
- **Reactive Programming**: ValueNotifier and Stream-based state management
- **Feature-Driven Development**: Code organized by business domains

---

## 🛠️ Tech Stack & Dependencies

### Core Framework
- **Flutter SDK**: ^3.8.1 (Cross-platform mobile development)
- **Dart**: Latest stable version

### Backend & Database
- **Supabase Flutter**: ^2.9.1 (Backend integration, auth, real-time)
- **PostgreSQL**: Database with Row Level Security (RLS)
- **Edge Functions**: Serverless backend logic
- **Storage Buckets**: File upload and management

### Key Dependencies

#### UI & Visualization
- **FL Chart**: ^0.66.0 (Data visualization and charts)
- **Lottie**: ^2.7.0 (Complex animations)
- **Rive**: ^0.13.13 (Interactive animations)
- **Photo View**: ^0.15.0 (Image viewing)

#### Media & Files
- **Image Picker**: ^1.1.0 (Camera/gallery access)
- **Video Player**: ^2.8.3 (Video playback)
- **Just Audio**: ^0.9.36 (Audio playback)
- **File Picker**: ^6.1.1 (File selection)
- **PDF**: ^3.10.6 (PDF generation)
- **Printing**: ^5.12.0 (PDF printing)

#### Scanning & Recognition
- **Mobile Scanner**: ^3.5.5 (Barcode/QR scanning)

#### Storage & Persistence
- **Flutter Secure Storage**: ^9.2.2 (Secure data storage)
- **Shared Preferences**: ^2.2.3 (User preferences)
- **Path Provider**: ^2.1.2 (File system paths)

#### Authentication & Security
- **Local Auth**: ^2.3.0 (Biometric authentication)
- **Device Info Plus**: ^10.1.0 (Device information)
- **Package Info Plus**: ^8.0.2 (App information)
- **Crypto**: ^3.0.3 (Cryptographic functions)

#### Notifications
- **Flutter Local Notifications**: ^18.0.0 (Local notifications)
- **Timezone**: ^0.9.2 (Timezone handling)

#### Networking & Communication
- **HTTP**: ^1.2.0 (HTTP requests)
- **URL Launcher**: ^6.2.5 (External URL handling)
- **Share Plus**: ^10.0.2 (Sharing functionality)

#### State Management & Utilities
- **Provider**: ^6.0.5 (State management)
- **Equatable**: ^2.0.5 (Value equality)
- **Collection**: ^1.18.0 (Collection utilities)
- **UUID**: ^4.3.3 (Unique ID generation)
- **CSV**: ^5.0.2 (CSV file handling)
- **Intl**: ^0.20.2 (Internationalization)

#### Development Tools
- **Flutter Test**: SDK (Testing framework)
- **Flutter Lints**: ^5.0.0 (Code quality)
- **Flutter Native Splash**: ^2.4.2 (Splash screen)

---

## 🏛️ Architecture Overview

### Overall Architecture
VAGUS follows a **clean, service-oriented architecture** with clear separation of concerns:

```
lib/
├── screens/          # UI Screens (Feature-driven)
├── services/         # Business Logic Layer
├── models/           # Data Models & Entities
├── widgets/          # Reusable UI Components
├── components/       # Feature-specific Components
├── theme/            # Design System & Theming
├── utils/            # Utility Functions
└── main.dart         # Application Entry Point
```

### Key Architectural Decisions
- **Single Source of Truth**: Supabase as primary data store
- **Reactive Updates**: Real-time subscriptions for live data
- **Caching Strategy**: Multi-layer caching (memory, preferences, secure storage)
- **Error Handling**: Graceful degradation with fallback mechanisms
- **Security**: Row Level Security (RLS) and secure token management

---

## ✨ Features Documentation

### 1. Admin Features & Support Systems

#### Core Admin Panel
- **User Role Management**: Change user roles (client/coach/admin)
- **User Account Control**: Enable/disable user accounts
- **Support Request Monitoring**: Real-time urgent/attention/recent request tracking
- **Live Support Chat**: Direct messaging with users needing assistance
- **CSV Export**: Export user data for analytics
- **Search & Filtering**: Find users by name, email, or role

#### Advanced Admin Tools
- **Admin Hub Screen**: Central command center
- **Agent Workload Management**: Monitor support agent capacity
- **Ticket Queue System**: Support ticket management and routing
- **Escalation Matrix**: Automated support escalation rules
- **Knowledge Base Management**: Help articles and documentation
- **Incident Console**: System incident tracking and resolution
- **Playbooks**: Standardized response procedures
- **Session Co-Pilot**: Real-time session assistance
- **Live Session Monitoring**: Observe ongoing sessions
- **Auto-Triage Rules**: Automated support categorization

### 2. User Management & Authentication

#### Authentication System
- **Modern Login Screen**: Email/password authentication
- **Sign-up Process**: New user registration
- **Email Verification**: Account activation workflow
- **Password Reset**: Secure password recovery
- **Biometric Authentication**: Fingerprint/Face ID support
- **Session Management**: Device-based session tracking
- **Account Switching**: Multi-account support

### 3. Nutrition Features & AI Capabilities

#### Nutrition Planning
- **Modern Nutrition Plan Builder**: Interactive plan creation
- **Recipe Management**: Custom recipe database
- **Meal Planning**: Daily/weekly meal scheduling
- **Macro Tracking**: Protein, carbs, fat, calorie monitoring
- **Food Database**: Extensive food item catalog
- **Nutrition AI**: AI-powered food recognition and estimation

#### Advanced Nutrition Tools
- **Barcode Scanner**: Quick food item addition
- **Food Photography**: AI-powered nutritional analysis
- **Recipe Editor**: Custom recipe creation with steps
- **Grocery Lists**: Automated shopping list generation
- **Pantry Management**: Food inventory tracking
- **Meal Photo Integration**: Visual meal logging
- **Cost Analysis**: Meal cost calculations
- **Hydration Tracking**: Water intake monitoring

### 4. Workout & Fitness Features

#### Workout Planning
- **Modern Plan Builder**: Interactive workout creation
- **Exercise Catalog**: Comprehensive exercise database
- **Workout Plan Viewer**: Client workout display
- **Cardio Logging**: Cardiovascular exercise tracking
- **Exercise History**: Performance tracking over time

#### Exercise Management
- **Exercise Database**: Muscle group categorization
- **Media Integration**: Exercise demonstration videos/GIFs
- **Set & Rep Tracking**: Detailed workout logging
- **Weight Progression**: Strength gain monitoring
- **Tempo Tracking**: Exercise timing controls
- **Rest Period Management**: Workout pacing

### 5. Messaging & Communication

#### Modern Messaging System
- **Real-time Chat**: Instant messaging between users
- **Thread Management**: Organized conversation handling
- **Coach-Client Messaging**: Direct communication channels
- **Group Messaging**: Multi-participant conversations
- **Message Search**: Find specific conversations
- **Smart Replies**: AI-suggested responses

#### Advanced Communication Features
- **Voice Recording**: Audio message capabilities
- **File Sharing**: Document and image sharing
- **Message Threading**: Organized conversation structure
- **Read Receipts**: Message delivery confirmation
- **Typing Indicators**: Real-time activity status
- **Message Pinning**: Important message highlighting

### 6. Calling & Live Sessions

#### Simple Calling System
- **Live Session Creation**: Video/audio call setup
- **Session Management**: Call control and moderation
- **Participant Management**: Multi-user call handling
- **Screen Sharing**: Desktop/mobile screen broadcast
- **Call Recording**: Session documentation
- **Chat During Calls**: In-call messaging

### 7. Coach Features & Client Management

#### Coach Dashboard
- **Performance Analytics**: Comprehensive coaching metrics
- **Client Overview**: Connected client management
- **Inbox Management**: Prioritized client communications
- **Session Scheduling**: Calendar integration
- **Quick Actions**: Rapid access to common tasks

#### Client Management Tools
- **Client Profile Management**: Individual client tracking
- **Weekly Reviews**: Regular progress assessments
- **Check-in Monitoring**: Daily client status updates
- **Progress Tracking**: Long-term client development
- **Photo Comparisons**: Visual progress documentation

### 8. Analytics & Reporting

#### Comprehensive Analytics
- **Client Metrics**: Retention, engagement, satisfaction
- **Performance Tracking**: Response times, completion rates
- **Business Intelligence**: Revenue and growth analytics
- **Compliance Monitoring**: Plan adherence tracking

#### Visual Analytics
- **Interactive Charts**: FL Chart integration for data visualization
- **Trend Analysis**: Historical performance tracking
- **Sparkline Indicators**: Quick trend visualization
- **Progress Reports**: Exportable analytics summaries

---

## 🔧 Service Layer Architecture

### Service Organization

#### Authentication & Security Services
- **AccountSwitcher**: Multi-account session management with secure token storage
- **BiometricAuthService**: Local biometric authentication
- **UserPrefsService**: Comprehensive user preference management

#### AI & ML Services
- **AIClient**: Centralized AI provider abstraction (OpenRouter)
- **ModelRegistry**: Task-to-model mapping with environment overrides
- **AIUsageService**: Usage tracking with monthly quotas

#### Messaging & Communication
- **MessagesService**: Real-time messaging with rich attachments
- **CoachMessagingService**: Coach-specific messaging workflows

#### Business Logic Services
- **NutritionService**: Complete nutrition plan CRUD operations
- **CoachAnalyticsService**: Comprehensive analytics aggregation
- **ExerciseHistoryService**: Exercise performance tracking

#### Administrative Services
- **AdminService**: User management with role-based access control
- **BillingService**: Subscription lifecycle management
- **FeatureFlagsService**: User-specific feature flag management

### Architecture Patterns

#### Singleton Pattern
- All services use singleton pattern for global access
- Consistent implementation: `static final instance = ServiceName._();`
- Lazy initialization with private constructors

#### Repository Pattern
- Services act as repositories abstracting data access
- Clear separation between data layer (Supabase) and business logic
- Centralized error handling and data transformation

#### Caching Strategy
- Multiple caching layers: Memory cache, SharedPreferences, Secure Storage
- Cache expiry mechanisms (typically 5-30 minutes)
- Cache invalidation on data mutations

---

## 📊 Data Models & Structures

### Model Architecture Patterns

#### Immutability and Value Objects
- **Equatable Usage**: Extensive use for value objects
- **Immutable Design**: const constructors and copyWith methods
- **Value Equality**: Equatable's props list for equality comparisons

#### Serialization Patterns
- **Consistent JSON Handling**: toJson()/fromJson() or toMap()/fromMap()
- **Snake Case Mapping**: Database fields use snake_case convention
- **Safe Parsing**: Robust null-safe parsing with fallback values
- **Date Handling**: Consistent ISO8601 string format

### Core Domain Models

#### User and Authentication Models
- **CoachProfile**: Coach-specific profile information
- **CoachMedia**: Media content associated with coaches
- **CoachClientPeriod**: Coaching periods with progress tracking

#### Communication Models
- **LiveSession**: Real-time session management
- **CallParticipant**: Participant state in calls
- **CallMessage**: Chat messages within calls

#### Nutrition Domain Models
- **Recipe**: Complex model with nutritional data and ingredients
- **RecipeStep**: Individual cooking instructions
- **RecipeIngredient**: Ingredients with nutritional information
- **FoodItem**: General food items with nutritional data
- **Money**: Sophisticated money class with currency support

#### Supplement Management
- **Supplement**: Supplement definitions with categories
- **SupplementSchedule**: Scheduling system for supplement intake
- **SupplementLog**: Actual intake tracking

---

## 🎨 UI Components & Widgets

### Design System

#### Theme Architecture
- **Monochrome Design System**: Black/white/grey base with teal and yellow accents
- **Design Tokens**: Centralized in design_tokens.dart with 8pt grid system
- **Dual Theme Support**: Light and dark themes
- **Consistent Typography**: Font weights from 400-800

#### Color System
```dart
// Primary Colors
primaryBlack: #000000
neutralWhite: #FFFFFF
steelGrey: #555555
lightGrey: #E0E0E0

// Accent Colors
mintAqua: #00D4AA (primary accent)
softYellow: #FFD700 (secondary accent)
```

### Component Categories

#### Core Branding Components
- **VagusLogo**: Adaptive logo with fallback text
- **VagusAppbar**: Brand-consistent app bar

#### Navigation Components
- **VagusSideMenu**: Feature-rich drawer with search and role-based content
- **AppNavigator**: Centralized navigation service integration

#### Form & Input Components
- **MessageInputBar**: Multi-functional input with attachments and voice
- **SectionHeaderBar**: Responsive header with action buttons
- **ThemeToggle**: System/light/dark theme switcher

#### Animation & Visual Effects
- **GlassmorphismFAB**: Advanced floating action button with backdrop blur
- **VagusLoader**: Lottie-based loading animations
- **MicRipple**: Rive-based interactive animations

### Feature-Specific Widgets

#### Nutrition Domain
- **HydrationRing**: Custom painted progress ring
- **MacroDonut**: Chart-based macro visualization
- **RecipeCard**: Recipe presentation with nutrition data

#### Coach Domain
- **ComplianceDonut**: FL Chart-based compliance visualization
- **WeeklyPhotosGrid**: Progress photo comparison
- **PerformanceAnalyticsCard**: Analytics dashboard components

#### Workout Domain
- **SetRowControls**: Exercise set management interface
- **TempoCuePill**: Exercise tempo indicators
- **ExerciseHistoryCard**: Historical workout data

#### Calling & Communication
- **CallControls**: Comprehensive call control interface
- **CallParticipantGrid**: Video call participant layout
- **VoiceRecorder**: Audio recording with waveform visualization

---

## 🧪 Testing Strategy

### Current Testing Setup

#### Test Categories
```
test/
├── calendar_peek_service_dst_test.dart      # Service testing
├── exercise_sheet_prefs_plumbing_test.dart  # Preferences testing
├── local_set_log_backcompat_test.dart       # Backward compatibility
├── progression_rules_advanced_test.dart     # Business logic testing
├── quickbook_reschedule_parser_test.dart    # Parser testing
├── set_type_format_test.dart                # Formatting testing
├── severity_colors_test.dart                # UI utility testing
├── user_prefs_service_test.dart             # Service testing
└── widget_test.dart                         # Placeholder widget test
```

#### Testing Patterns
- **Service Testing**: Comprehensive service layer testing
- **Parser Testing**: Multi-language input parsing (English/Arabic/Kurdish)
- **Preferences Testing**: User preference validation and persistence
- **Business Logic Testing**: Core domain logic validation

### Test Coverage Areas

#### ✅ Currently Tested
- **QuickBook Reschedule Parser**: Multi-language option parsing
- **User Preferences Service**: Preference persistence and validation
- **Calendar Services**: DST handling and date calculations
- **Exercise Preferences**: Advanced set type preferences
- **Data Formatting**: Set type and severity color formatting
- **Backward Compatibility**: Local data migration testing

### Testing Checklist

#### Unit Tests Needed
- [ ] All service classes unit tests
- [ ] All model serialization/deserialization tests
- [ ] All utility function tests
- [ ] All business logic validation tests
- [ ] All custom widget tests

#### Integration Tests Required
- [ ] Supabase integration tests
- [ ] Authentication flow tests
- [ ] File upload/download tests
- [ ] Real-time messaging tests
- [ ] Payment processing tests
- [ ] AI service integration tests

#### Edge Cases to Test
- [ ] Network connectivity issues
- [ ] Large file uploads
- [ ] Concurrent user operations
- [ ] Invalid data handling
- [ ] Memory constraints
- [ ] Background app behavior

#### Manual Testing Checklist
- [ ] Cross-platform functionality (iOS/Android)
- [ ] Biometric authentication flows
- [ ] Camera and file permissions
- [ ] Push notification delivery
- [ ] Offline functionality
- [ ] App state restoration
- [ ] Accessibility features
- [ ] Theme switching
- [ ] Multi-language support

#### Performance Tests
- [ ] Large dataset handling
- [ ] Image processing performance
- [ ] Real-time messaging scalability
- [ ] Battery usage optimization
- [ ] Memory leak detection
- [ ] Startup time optimization

#### Security Considerations
- [ ] Token storage security
- [ ] Data encryption validation
- [ ] API endpoint security
- [ ] File upload validation
- [ ] User input sanitization
- [ ] Permission handling

---

## 📁 File Structure

### Main Directories

```
vagus_app/
├── lib/
│   ├── screens/          # UI Screens (Feature-driven organization)
│   │   ├── admin/        # Admin panel screens
│   │   ├── auth/         # Authentication screens
│   │   ├── billing/      # Payment and subscription screens
│   │   ├── calendar/     # Calendar and scheduling screens
│   │   ├── calling/      # Video/audio calling screens
│   │   ├── coach/        # Coach-specific screens
│   │   ├── dashboard/    # Main dashboard screens
│   │   ├── learn/        # Educational content screens
│   │   ├── messaging/    # Chat and communication screens
│   │   ├── nutrition/    # Nutrition planning screens
│   │   ├── progress/     # Progress tracking screens
│   │   ├── settings/     # App settings screens
│   │   ├── supplements/  # Supplement management screens
│   │   ├── support/      # Help and support screens
│   │   └── workout/      # Workout planning screens
│   │
│   ├── services/         # Business Logic Layer
│   │   ├── admin/        # Admin-specific services
│   │   ├── ai/           # AI and ML services
│   │   ├── coach/        # Coach-specific services
│   │   ├── messaging/    # Communication services
│   │   ├── nutrition/    # Nutrition-related services
│   │   ├── notifications/ # Notification services
│   │   ├── settings/     # User preferences services
│   │   └── workout/      # Workout-related services
│   │
│   ├── models/           # Data Models & Entities
│   │   ├── admin/        # Admin domain models
│   │   ├── ads/          # Advertisement models
│   │   ├── announcements/ # Announcement models
│   │   ├── nutrition/    # Nutrition domain models
│   │   └── ...           # Other domain models
│   │
│   ├── widgets/          # Reusable UI Components
│   │   ├── admin/        # Admin-specific widgets
│   │   ├── ai/           # AI-related widgets
│   │   ├── anim/         # Animation widgets
│   │   ├── branding/     # Brand components
│   │   ├── calling/      # Calling interface widgets
│   │   ├── coach/        # Coach-specific widgets
│   │   ├── fab/          # Floating action buttons
│   │   ├── messaging/    # Chat interface widgets
│   │   ├── navigation/   # Navigation components
│   │   ├── nutrition/    # Nutrition widgets
│   │   ├── progress/     # Progress tracking widgets
│   │   ├── settings/     # Settings widgets
│   │   └── workout/      # Workout widgets
│   │
│   ├── components/       # Feature-specific Components
│   │   ├── announcements/ # Announcement components
│   │   ├── checkins/     # Check-in components
│   │   ├── feedback/     # Feedback components
│   │   ├── nutrition/    # Nutrition components
│   │   ├── periods/      # Period tracking components
│   │   └── supplements/  # Supplement components
│   │
│   ├── theme/            # Design System & Theming
│   │   └── app_theme.dart # Theme configuration
│   │
│   ├── utils/            # Utility Functions
│   │   ├── capture_widget_bitmap.dart
│   │   ├── load_math.dart
│   │   ├── message_helpers.dart
│   │   ├── natural_time_parser.dart
│   │   └── tempo_parser.dart
│   │
│   └── main.dart         # Application Entry Point
│
├── test/                 # Test Files
│   ├── *_test.dart       # Unit tests
│   └── widget_test.dart  # Widget tests
│
├── assets/               # Static Assets
│   ├── anim/             # Animation files (.json, .riv)
│   ├── branding/         # Logo and brand assets
│   └── foods/            # Food-related assets
│
├── android/              # Android-specific configuration
├── ios/                  # iOS-specific configuration
├── pubspec.yaml          # Dependencies and project configuration
├── README.md             # Project documentation
└── analysis_options.yaml # Code analysis configuration
```

### Key Files & Their Roles

#### Configuration Files
- **pubspec.yaml**: Dependencies, assets, and project metadata
- **analysis_options.yaml**: Code quality and linting rules
- **README.md**: Project documentation and setup instructions

#### Entry Points
- **main.dart**: Application entry point and initialization
- **app_theme.dart**: Design system and theme configuration

#### Core Services
- **account_switcher.dart**: Multi-account session management
- **ai_usage_service.dart**: AI usage tracking and quotas
- **messages_service.dart**: Real-time messaging infrastructure
- **nutrition_service.dart**: Nutrition plan management
- **billing_service.dart**: Subscription and payment handling

#### Key Models
- **recipe.dart**: Recipe data structure with nutrition information
- **money.dart**: Currency handling and calculations
- **live_session.dart**: Video/audio session management
- **support_models.dart**: Support ticket and escalation models

---

## 🚀 Setup & Development

### Prerequisites
- **Flutter SDK**: Latest stable version (3.8.1+)
- **Supabase Account**: For backend services
- **Android Studio** or **Xcode**: For platform-specific builds
- **Git**: Version control

### Installation Steps

#### 1. Clone the Repository
```bash
git clone <repository-url>
cd vagus_app
```

#### 2. Install Dependencies
```bash
flutter pub get
```

#### 3. Configure Supabase
- Create a new Supabase project
- Run database migrations from `supabase/migrations/`
- Set environment variables:
  - `SUPABASE_URL`: Your Supabase project URL
  - `SUPABASE_ANON_KEY`: Public anon key
  - `SUPABASE_SERVICE_ROLE_KEY`: Service role key

#### 4. Deploy Edge Functions
```bash
supabase functions deploy send-notification --no-verify-jwt
supabase functions deploy update-ai-usage --no-verify-jwt
```

### Environment Variables Needed

#### Supabase Configuration
- **SUPABASE_URL**: Your Supabase project URL
- **SUPABASE_ANON_KEY**: Public anon key for client access
- **SUPABASE_SERVICE_ROLE_KEY**: Service role key for Edge Functions

#### AI Services
- **OPENROUTER_API_KEY**: API key for AI services
- **AI_MODEL_***: Environment-specific model configurations

### How to Run Locally

#### Development Mode
```bash
flutter run
```

#### Debug Mode with Hot Reload
```bash
flutter run --debug
```

#### Release Mode Testing
```bash
flutter run --release
```

### Build/Deployment Process

#### Android Build
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle for Play Store
flutter build appbundle --release
```

#### iOS Build
```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release
```

#### Database Deployment
```bash
# Apply migrations
supabase db push

# Deploy functions
supabase functions deploy
```

### Development Workflow

#### Branch Strategy
- **main**: Production-ready code
- **develop**: Development branch
- **feature/***: Feature development branches

#### Code Quality
- Run linter: `flutter analyze`
- Format code: `flutter format .`
- Run tests: `flutter test`

#### Database Management
- Migrations live in `supabase/migrations/`
- Auto-deploy on push to develop/main branches
- Manual approval required for production deployments

---

## 📚 Additional Resources

### Documentation Links
- [Flutter Documentation](https://docs.flutter.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [AI Usage Integration Guide](AI_USAGE_METER_IMPLEMENTATION.md)

### Development Tools
- **VS Code Extensions**: Flutter, Dart
- **Debugging**: Flutter Inspector, Dart DevTools
- **Testing**: Flutter Test Framework
- **Profiling**: Flutter Performance Tools

### Deployment
- **CI/CD**: GitHub Actions for automated deployment
- **Environment Management**: Development and Production environments
- **Monitoring**: Error tracking and performance monitoring

---

*Last Updated: [Current Date]*
*Documentation Version: 1.0*