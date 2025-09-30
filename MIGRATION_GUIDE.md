# Migration Guide: Old Nutrition System → New Unified Platform

## Overview
This guide helps you migrate from the old nutrition system (with duplicate screens) to the new unified nutrition platform with role-based access, i18n, and accessibility features.

## Breaking Changes

### 1. Screen Structure Changes

#### Old Structure (Deprecated)
```
lib/screens/nutrition/
├── nutrition_plan_builder.dart          ❌ DEPRECATED
├── modern_nutrition_plan_builder.dart   ✅ KEEP (Enhanced)
├── nutrition_plan_viewer.dart           ❌ DEPRECATED
├── modern_nutrition_plan_viewer.dart    ✅ KEEP (Enhanced)
└── nutrition_hub_screen.dart            ✅ KEEP (Unified Entry)
```

#### New Structure
```
lib/screens/nutrition/
├── nutrition_hub_screen.dart            ← Main entry point
├── modern_nutrition_plan_builder.dart   ← Enhanced with role manager
├── modern_nutrition_plan_viewer.dart    ← Enhanced with role manager
└── widgets/shared/                      ← Reusable components
    ├── food_picker_2_0.dart
    ├── smart_food_search.dart
    ├── enhanced_food_card.dart
    ├── barcode_scanner_tab.dart
    ├── recent_foods_tab.dart
    ├── favorites_tab.dart
    ├── custom_foods_tab.dart
    └── i18n_nutrition_wrapper.dart
```

### 2. Import Path Changes

#### Before
```dart
import 'package:vagus_app/screens/nutrition/nutrition_plan_builder.dart';
import 'package:vagus_app/screens/nutrition/nutrition_plan_viewer.dart';
```

#### After
```dart
import 'package:vagus_app/screens/nutrition/nutrition_hub_screen.dart';
import 'package:vagus_app/screens/nutrition/modern_nutrition_plan_builder.dart';
import 'package:vagus_app/screens/nutrition/modern_nutrition_plan_viewer.dart';
```

### 3. Navigation Changes

#### Before
```dart
// Different navigation for coach vs client
if (userRole == 'coach') {
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => NutritionPlanBuilder(clientId: clientId),
  ));
} else {
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => NutritionPlanViewer(),
  ));
}
```

#### After
```dart
// Unified navigation - automatic role detection
Navigator.push(context, MaterialPageRoute(
  builder: (_) => NutritionHubScreen(
    planId: planId,  // Optional
    editMode: false, // Optional
  ),
));
```

### 4. Service Initialization

#### New Requirements
```dart
// Initialize role manager and accessibility service
final roleManager = NutritionRoleManager();
await roleManager.initialize();

final a11y = AccessibilityService();
await a11y.initialize(context);
```

## Step-by-Step Migration

### Step 1: Update Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  # Already present, ensure versions
  supabase_flutter: ^latest
  cached_network_image: ^latest

  # May need to update
  intl: ^latest

dev_dependencies:
  # For testing
  integration_test: ^latest
  mockito: ^latest
```

### Step 2: Remove Deprecated Screens

**⚠️ IMPORTANT:** Backup these files before deleting!

Delete or move to `deprecated/` folder:
- `lib/screens/nutrition/nutrition_plan_builder.dart`
- `lib/screens/nutrition/nutrition_plan_viewer.dart`

### Step 3: Update Navigation Routes

In your `app_navigator.dart` or routing file:

```dart
// OLD
static const String nutritionBuilder = '/nutrition/builder';
static const String nutritionViewer = '/nutrition/viewer';

// NEW
static const String nutritionHub = '/nutrition';

// Update route definitions
routes: {
  // Remove old routes
  // nutritionBuilder: (context) => NutritionPlanBuilder(),
  // nutritionViewer: (context) => NutritionPlanViewer(),

  // Add new unified route
  nutritionHub: (context) => NutritionHubScreen(),
}
```

### Step 4: Update All Navigation Calls

Find and replace all instances:

**Search for:**
```dart
NutritionPlanBuilder
NutritionPlanViewer
```

**Replace with:**
```dart
NutritionHubScreen
```

Use regex to find all navigation pushes:
```regex
Navigator\.push.*Nutrition(Plan)?(Builder|Viewer)
```

### Step 5: Wrap App with I18n Support

In your `main.dart` or root widget:

```dart
import 'package:vagus_app/screens/nutrition/widgets/shared/i18n_nutrition_wrapper.dart';

// Option 1: Wrap entire app
MaterialApp(
  home: I18nNutritionWrapper(
    initialLocale: 'en',
    child: YourHomePage(),
  ),
)

// Option 2: Wrap only nutrition screens
NutritionHubScreen(
  // Wrapper applied internally
)
```

### Step 6: Initialize Services in App Startup

In your app initialization:

```dart
class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeNutritionServices();
  }

  Future<void> _initializeNutritionServices() async {
    // Initialize role manager
    final roleManager = NutritionRoleManager();
    await roleManager.initialize();

    // Initialize accessibility (after first frame)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final a11y = AccessibilityService();
        await a11y.initialize(context);
      }
    });
  }
}
```

### Step 7: Update Database Schema (if needed)

Run migration scripts:

```bash
# Apply new database migrations
flutter run migration/add_nutrition_v2_fields.sql
```

See `migration/` folder for SQL scripts.

### Step 8: Update Permission Checks

#### Before
```dart
// Manual permission checks
if (userRole == 'coach') {
  // Show edit button
}
```

#### After
```dart
// Use role manager
final roleManager = NutritionRoleManager();
final mode = roleManager.detectMode(plan: plan, editMode: false);

if (roleManager.canEditPlan(plan)) {
  // Show edit button
}

// Or use UI config
final uiConfig = roleManager.getUIConfig(mode);
if (uiConfig.showEditButton) {
  // Show edit button
}
```

### Step 9: Update Translations

All hardcoded strings should use `LocaleHelper`:

#### Before
```dart
Text('Nutrition')
Text('Add Food')
```

#### After
```dart
// With context
Text(context.t('nutrition'))
Text(context.t('add_food'))

// Or without context
Text(LocaleHelper.t('nutrition', locale))
Text(LocaleHelper.t('add_food', locale))

// Or use LocalizedText widget
LocalizedText('nutrition')
LocalizedText('add_food')
```

### Step 10: Add Accessibility Labels

All interactive widgets should have semantic labels:

#### Before
```dart
IconButton(
  icon: Icon(Icons.edit),
  onPressed: () {},
)
```

#### After
```dart
Semantics(
  label: 'Edit nutrition plan',
  button: true,
  child: IconButton(
    icon: Icon(Icons.edit),
    onPressed: () {},
    tooltip: 'Edit Plan',
  ),
)

// Or use accessibility service helper
a11y.makeKeyboardAccessible(
  child: IconButton(...),
  onPressed: () {},
  semanticLabel: 'Edit nutrition plan',
  hint: 'Opens plan editor',
)
```

## Testing Migration

### 1. Verify Old Screens Removed
```bash
# Search for deprecated imports
grep -r "nutrition_plan_builder.dart" lib/
grep -r "nutrition_plan_viewer.dart" lib/

# Should return empty results
```

### 2. Run Unit Tests
```bash
flutter test test/services/nutrition/
flutter test test/services/accessibility/
```

### 3. Run Widget Tests
```bash
flutter test test/widgets/nutrition/
```

### 4. Run Integration Tests
```bash
flutter test integration_test/nutrition_flow_test.dart
```

### 5. Manual Testing Checklist
Use `test/manual_qa_checklist.md`:
- [ ] Coach can create plans
- [ ] Client can view plans
- [ ] Offline mode works
- [ ] Language switching works
- [ ] Screen reader works
- [ ] All buttons work

## Common Migration Issues

### Issue 1: Import Errors

**Error:**
```
Error: Not found: 'package:vagus_app/screens/nutrition/nutrition_plan_builder.dart'
```

**Solution:**
Update import to new path:
```dart
import 'package:vagus_app/screens/nutrition/nutrition_hub_screen.dart';
```

### Issue 2: Role Manager Not Initialized

**Error:**
```
Null check operator used on a null value
```

**Solution:**
Initialize role manager before use:
```dart
final roleManager = NutritionRoleManager();
await roleManager.initialize();
```

### Issue 3: Translation Keys Not Found

**Error:**
Shows translation key instead of text (e.g., "nutrition_plan" instead of "Nutrition Plan")

**Solution:**
Add missing keys to `LocaleHelper`:
```dart
// In lib/services/nutrition/locale_helper.dart
'nutrition_plan': 'Nutrition Plan',
```

### Issue 4: Accessibility Labels Missing

**Warning:**
Screen reader announces "Button" instead of descriptive label

**Solution:**
Add semantic labels:
```dart
Semantics(
  label: 'Create nutrition plan',
  button: true,
  child: YourButton(),
)
```

### Issue 5: RTL Layout Issues

**Problem:**
Arabic/Kurdish UI appears broken

**Solution:**
Wrap with `I18nNutritionWrapper`:
```dart
I18nNutritionWrapper(
  initialLocale: 'ar',
  child: YourScreen(),
)
```

## Rollback Plan

If migration causes critical issues:

### 1. Quick Rollback
```bash
# Restore deprecated files from backup
cp deprecated/nutrition_plan_builder.dart lib/screens/nutrition/
cp deprecated/nutrition_plan_viewer.dart lib/screens/nutrition/

# Revert navigation changes
git checkout HEAD -- lib/services/navigation/app_navigator.dart

# Rebuild
flutter clean
flutter pub get
flutter run
```

### 2. Database Rollback
```bash
# Revert database migrations
flutter run migration/rollback_nutrition_v2.sql
```

### 3. Gradual Migration

If full migration is too risky, migrate gradually:

**Phase 1: Keep Both Systems**
- Keep old screens alongside new ones
- Route new users to new system
- Route existing users to old system

**Phase 2: Migrate User Segments**
- Internal team → New system
- Beta users → New system
- All coaches → New system
- All clients → New system

**Phase 3: Full Cutover**
- Remove old screens
- Update all navigation
- Full QA pass

## Support & Resources

### Documentation
- [Feature Documentation](NUTRITION_REBUILD_SUMMARY.md)
- [API Documentation](docs/api/)
- [Component Examples](docs/components/)

### Testing
- [Unit Tests](test/services/)
- [Widget Tests](test/widgets/)
- [Integration Tests](test/integration/)
- [Manual QA Checklist](test/manual_qa_checklist.md)

### Help
- Create issue: [GitHub Issues](https://github.com/your-repo/issues)
- Team Slack: #nutrition-platform
- Email support: dev@yourcompany.com

## Migration Checklist

Use this checklist to track migration progress:

### Pre-Migration
- [ ] Backup all nutrition files
- [ ] Review breaking changes
- [ ] Update dependencies
- [ ] Run existing tests (baseline)

### Migration
- [ ] Remove deprecated screens
- [ ] Update navigation routes
- [ ] Update all navigation calls
- [ ] Wrap app with i18n
- [ ] Initialize services
- [ ] Run database migrations
- [ ] Update permission checks
- [ ] Update translations
- [ ] Add accessibility labels

### Testing
- [ ] No import errors
- [ ] All unit tests pass
- [ ] All widget tests pass
- [ ] Integration tests pass
- [ ] Manual QA complete
- [ ] No regressions

### Post-Migration
- [ ] Monitor error logs
- [ ] Check analytics
- [ ] Gather user feedback
- [ ] Document lessons learned
- [ ] Remove deprecated files permanently

---

**Migration Date:** __________
**Completed By:** __________
**Issues Encountered:** __________
**Resolution:** __________