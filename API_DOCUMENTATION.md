# Nutrition Platform API Documentation

## Table of Contents
1. [Services](#services)
2. [Models](#models)
3. [Widgets](#widgets)
4. [Utilities](#utilities)
5. [Usage Examples](#usage-examples)

---

## Services

### NutritionRoleManager

**Purpose:** Manages role-based access control and UI configuration for nutrition features.

**Location:** `lib/services/nutrition/role_manager.dart`

#### Methods

##### `initialize()`
Initializes the role manager by fetching current user role from Supabase.

```dart
Future<void> initialize()
```

**Example:**
```dart
final roleManager = NutritionRoleManager();
await roleManager.initialize();
```

---

##### `detectMode()`
Detects the appropriate nutrition mode based on user role and context.

```dart
NutritionMode detectMode({
  required NutritionPlan plan,
  bool editMode = false,
})
```

**Parameters:**
- `plan` (NutritionPlan): The nutrition plan to check
- `editMode` (bool): Whether user is in edit mode

**Returns:** `NutritionMode` enum (coachBuilding, coachViewing, clientViewing)

**Example:**
```dart
final mode = roleManager.detectMode(
  plan: currentPlan,
  editMode: false,
);

switch (mode) {
  case NutritionMode.coachBuilding:
    // Show full edit capabilities
    break;
  case NutritionMode.coachViewing:
    // Show read-only with coach notes
    break;
  case NutritionMode.clientViewing:
    // Show client features
    break;
}
```

---

##### `canEditPlan()`
Checks if user can edit a nutrition plan.

```dart
bool canEditPlan(NutritionPlan plan)
```

**Example:**
```dart
if (roleManager.canEditPlan(currentPlan)) {
  // Show edit button
}
```

---

##### `getUIConfig()`
Gets UI configuration for a specific mode.

```dart
ModeUIConfig getUIConfig(NutritionMode mode)
```

**Returns:** `ModeUIConfig` with all UI settings

**Example:**
```dart
final config = roleManager.getUIConfig(NutritionMode.coachBuilding);

if (config.showEditButton) {
  // Render edit button
}

if (config.showAddMealButton) {
  // Render add meal button
}
```

---

##### `getAvailableActions()`
Gets list of available actions for a mode.

```dart
List<NutritionAction> getAvailableActions(NutritionMode mode)
```

**Example:**
```dart
final actions = roleManager.getAvailableActions(mode);

if (actions.contains(NutritionAction.editMeals)) {
  // Enable meal editing
}
```

---

### AccessibilityService

**Purpose:** Provides WCAG AA compliant accessibility features.

**Location:** `lib/services/accessibility/accessibility_service.dart`

#### Methods

##### `initialize()`
Initializes accessibility service with context.

```dart
Future<void> initialize(BuildContext context)
```

**Example:**
```dart
final a11y = AccessibilityService();
await a11y.initialize(context);
```

---

##### `getMacroRingSemantics()`
Generates semantic label for macro progress rings.

```dart
String getMacroRingSemantics({
  required String macroName,
  required double current,
  required double target,
  required String unit,
})
```

**Example:**
```dart
final label = a11y.getMacroRingSemantics(
  macroName: 'Protein',
  current: 150.0,
  target: 180.0,
  unit: 'grams',
);

// Returns: "Protein: 150.0 grams of 180.0 grams target. 83% complete. Approaching target"

Semantics(
  label: label,
  child: MacroRingWidget(...),
)
```

---

##### `getMealSemantics()`
Generates semantic label for meal cards.

```dart
String getMealSemantics({
  required String mealName,
  required int foodCount,
  required double calories,
  required double protein,
  String? time,
})
```

**Example:**
```dart
final label = a11y.getMealSemantics(
  mealName: 'Breakfast',
  foodCount: 3,
  calories: 520.0,
  protein: 28.0,
  time: '8:00 AM',
);

// Returns: "Breakfast. Scheduled at 8:00 AM. 3 food items. 520 calories. 28.0 grams protein."
```

---

##### `meetsContrastStandards()`
Checks if color contrast meets WCAG AA standards.

```dart
bool meetsContrastStandards({
  required Color foreground,
  required Color background,
  bool isLargeText = false,
})
```

**Example:**
```dart
final hasGoodContrast = a11y.meetsContrastStandards(
  foreground: Colors.white,
  background: AppTheme.primaryDark,
  isLargeText: false,
);

if (!hasGoodContrast) {
  // Use different color combination
}
```

---

##### `makeKeyboardAccessible()`
Wraps widget with keyboard accessibility.

```dart
Widget makeKeyboardAccessible({
  required Widget child,
  required VoidCallback onPressed,
  required String semanticLabel,
  String? hint,
})
```

**Example:**
```dart
a11y.makeKeyboardAccessible(
  child: Container(
    child: Icon(Icons.add),
  ),
  onPressed: () => addFood(),
  semanticLabel: 'Add food to meal',
  hint: 'Opens food picker',
)
```

---

##### `announce()`
Announces message to screen reader.

```dart
void announce(
  BuildContext context,
  String message, {
  Assertiveness assertiveness = Assertiveness.polite,
})
```

**Example:**
```dart
// Polite announcement (waits for current speech)
a11y.announce(context, 'Food added to meal');

// Assertive announcement (interrupts current speech)
a11y.announce(
  context,
  'Error: Failed to save plan',
  assertiveness: Assertiveness.assertive,
);
```

---

### LocaleHelper

**Purpose:** Provides internationalization utilities.

**Location:** `lib/services/nutrition/locale_helper.dart`

#### Methods

##### `t()`
Translates a key to the specified locale.

```dart
static String t(String key, String lang)
```

**Example:**
```dart
final text = LocaleHelper.t('nutrition', 'en'); // "Nutrition"
final textAr = LocaleHelper.t('nutrition', 'ar'); // "التغذية"
final textKu = LocaleHelper.t('nutrition', 'ku'); // "خۆراک"
```

---

##### `isRTL()`
Checks if locale is right-to-left.

```dart
static bool isRTL(String lang)
```

**Example:**
```dart
if (LocaleHelper.isRTL('ar')) {
  // Apply RTL layout
  textDirection = TextDirection.rtl;
}
```

---

##### `normalizeNumber()`
Converts Arabic/Persian digits to Western digits.

```dart
static String normalizeNumber(String s)
```

**Example:**
```dart
final normalized = LocaleHelper.normalizeNumber('١٢٣'); // "123"
final number = double.parse(normalized); // 123.0
```

---

##### `formatNumber()`
Formats number with locale-specific formatting.

```dart
static String formatNumber(num value, {int decimalPlaces = 1})
```

**Example:**
```dart
final formatted = LocaleHelper.formatNumber(123.456); // "123.5"
final formatted2 = LocaleHelper.formatNumber(123.456, decimalPlaces: 2); // "123.46"
```

---

### SafeDatabaseService

**Purpose:** Provides safe database operations with error handling.

**Location:** `lib/services/nutrition/safe_database_service.dart`

#### Methods

##### `safeSingle()`
Safely fetches a single row with error handling.

```dart
Future<T?> safeSingle<T>(
  String table,
  T Function(Map<String, dynamic>) fromJson, {
  String? id,
  Map<String, dynamic>? filters,
  String? select,
  String? cacheKey,
})
```

**Example:**
```dart
final service = SafeDatabaseService();

final plan = await service.safeSingle<NutritionPlan>(
  'nutrition_plans',
  NutritionPlan.fromJson,
  id: planId,
  cacheKey: 'plan_$planId',
);

if (plan == null) {
  // Handle not found
}
```

---

##### `safeList()`
Safely fetches a list of rows with error handling.

```dart
Future<List<T>> safeList<T>(
  String table,
  T Function(Map<String, dynamic>) fromJson, {
  Map<String, dynamic>? filters,
  String? select,
  String? orderBy,
  int? limit,
  String? cacheKey,
})
```

**Example:**
```dart
final plans = await service.safeList<NutritionPlan>(
  'nutrition_plans',
  NutritionPlan.fromJson,
  filters: {'client_id': clientId},
  orderBy: 'created_at desc',
  limit: 10,
  cacheKey: 'plans_$clientId',
);
```

---

##### `safeInsert()`
Safely inserts data with error handling.

```dart
Future<T?> safeInsert<T>(
  String table,
  Map<String, dynamic> data,
  T Function(Map<String, dynamic>) fromJson, {
  bool optimistic = true,
  VoidCallback? rollback,
})
```

**Example:**
```dart
final newPlan = await service.safeInsert<NutritionPlan>(
  'nutrition_plans',
  plan.toJson(),
  NutritionPlan.fromJson,
  optimistic: true,
  rollback: () {
    // Undo UI changes
    setState(() => plans.remove(plan));
  },
);
```

---

##### `safeUpdate()`
Safely updates data with error handling.

```dart
Future<T?> safeUpdate<T>(
  String table,
  String id,
  Map<String, dynamic> data,
  T Function(Map<String, dynamic>) fromJson, {
  bool optimistic = true,
  VoidCallback? rollback,
})
```

**Example:**
```dart
final updated = await service.safeUpdate<NutritionPlan>(
  'nutrition_plans',
  planId,
  {'name': newName},
  NutritionPlan.fromJson,
  optimistic: true,
  rollback: () {
    // Revert to old name
    setState(() => plan.name = oldName);
  },
);
```

---

## Models

### NutritionMode

**Type:** Enum

**Values:**
- `coachBuilding` - Coach creating/editing plan for client
- `coachViewing` - Coach viewing own or client's plan
- `clientViewing` - Client viewing assigned plan

---

### NutritionAction

**Type:** Enum

**Values:**
- `editMeals`
- `addMeals`
- `removeMeals`
- `setTargets`
- `addCoachNotes`
- `checkOffMeals`
- `addClientComments`
- `exportPlan`
- `duplicatePlan`
- `saveTemplate`
- `generateGroceryList`
- `viewCompliance`
- `requestChanges`

---

### ModeUIConfig

**Type:** Class

**Properties:**
```dart
class ModeUIConfig {
  final bool showEditButton;
  final bool showAddMealButton;
  final bool showMacroTargetEditor;
  final bool showCoachNotesInput;
  final bool showClientComments;
  final bool showCheckoffButtons;
  final bool showRequestChangesButton;
  final bool allowMealEditing;
  final bool allowMealReordering;
  final bool showTemplateActions;
  final String headerTitle;
  final String emptyStateMessage;
}
```

---

## Widgets

### I18nNutritionWrapper

**Purpose:** Provides i18n context for nutrition screens.

**Location:** `lib/screens/nutrition/widgets/shared/i18n_nutrition_wrapper.dart`

**Usage:**
```dart
I18nNutritionWrapper(
  initialLocale: 'en',
  child: YourScreen(),
)

// Access translations
context.t('nutrition')
context.t('add_food')

// Check RTL
if (context.isRTL) {
  // Apply RTL layout
}

// Update locale
context.updateLocale('ar');
```

---

### LocalizedText

**Purpose:** Text widget that automatically translates.

**Usage:**
```dart
LocalizedText(
  'nutrition',
  style: TextStyle(fontSize: 18),
)
```

---

### LocalizedNumber

**Purpose:** Number widget with locale-specific formatting.

**Usage:**
```dart
LocalizedNumber(
  123.456,
  decimalPlaces: 2,
  style: TextStyle(fontSize: 14),
)
```

---

### LanguageSelectorDropdown

**Purpose:** Dropdown for language selection.

**Usage:**
```dart
LanguageSelectorDropdown(
  currentLocale: 'en',
  onLocaleChanged: (newLocale) {
    setState(() => locale = newLocale);
  },
)
```

---

## Usage Examples

### Complete Role-Based Flow

```dart
class NutritionScreen extends StatefulWidget {
  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final roleManager = NutritionRoleManager();
  final a11y = AccessibilityService();
  String locale = 'en';

  NutritionMode? mode;
  ModeUIConfig? uiConfig;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await roleManager.initialize();
    await a11y.initialize(context);

    // Detect mode
    mode = roleManager.detectMode(
      plan: currentPlan,
      editMode: false,
    );

    // Get UI config
    uiConfig = roleManager.getUIConfig(mode!);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (uiConfig == null) return CircularProgressIndicator();

    return I18nNutritionWrapper(
      initialLocale: locale,
      child: Scaffold(
        appBar: AppBar(
          title: Text(uiConfig!.headerTitle),
          actions: [
            if (uiConfig!.showEditButton)
              Semantics(
                label: a11y.t('edit_plan'),
                button: true,
                child: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: _editPlan,
                ),
              ),
          ],
        ),
        body: _buildBody(),
        floatingActionButton: uiConfig!.showAddMealButton
            ? FloatingActionButton(
                onPressed: _addMeal,
                child: Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    return ListView.builder(
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];

        return Semantics(
          label: a11y.getMealSemantics(
            mealName: meal.label,
            foodCount: meal.items.length,
            calories: meal.mealSummary.totalKcal,
            protein: meal.mealSummary.totalProtein,
          ),
          button: true,
          child: MealCard(
            meal: meal,
            canEdit: uiConfig!.allowMealEditing,
            canCheckOff: uiConfig!.showCheckoffButtons,
            onTap: () => _showMealDetail(meal),
          ),
        );
      },
    );
  }
}
```

---

### Offline Operation with Rollback

```dart
Future<void> _addFoodToMeal(FoodItem food) async {
  final originalMeal = meal.copyWith();

  // Optimistic update
  setState(() {
    meal.items.add(food);
    meal.mealSummary = calculateSummary(meal);
  });

  // Announce to screen reader
  a11y.announceSuccess(context, 'Food added to meal');

  // Attempt save
  try {
    await safeDatabase.safeUpdate(
      'nutrition_plans',
      planId,
      {'meals': meals.map((m) => m.toJson()).toList()},
      NutritionPlan.fromJson,
      optimistic: true,
      rollback: () {
        // Rollback on failure
        setState(() {
          meal = originalMeal;
        });
        a11y.announceError(context, 'Failed to add food');
      },
    );
  } catch (e) {
    // Error handled by rollback
  }
}
```

---

### Multi-Language Support

```dart
class MultiLanguageScreen extends StatefulWidget {
  @override
  State<MultiLanguageScreen> createState() => _MultiLanguageScreenState();
}

class _MultiLanguageScreenState extends State<MultiLanguageScreen> {
  String locale = 'en';

  @override
  Widget build(BuildContext context) {
    return I18nNutritionWrapper(
      initialLocale: locale,
      child: Scaffold(
        appBar: AppBar(
          title: LocalizedText('nutrition'),
          actions: [
            LanguageSelectorDropdown(
              currentLocale: locale,
              onLocaleChanged: (newLocale) {
                setState(() => locale = newLocale);
                context.updateLocale(newLocale);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            LocalizedText('protein'),
            LocalizedNumber(150.5, decimalPlaces: 1),
            ElevatedButton(
              onPressed: () {},
              child: LocalizedText('save'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Error Codes

### Database Errors
- `PGRST116` - No rows returned (use `.maybeSingle()`)
- `PGRST301` - Authentication required
- `PGRST302` - Permission denied

### Network Errors
- `SocketException` - No internet connection
- `TimeoutException` - Request timeout
- `HttpException` - HTTP error

### Validation Errors
- `VALIDATION_REQUIRED` - Required field missing
- `VALIDATION_FORMAT` - Invalid format
- `VALIDATION_RANGE` - Value out of range

---

## Best Practices

### 1. Always Initialize Services
```dart
// ❌ BAD
final roleManager = NutritionRoleManager();
roleManager.detectMode(plan: plan); // May fail

// ✅ GOOD
final roleManager = NutritionRoleManager();
await roleManager.initialize();
roleManager.detectMode(plan: plan);
```

### 2. Use Semantic Labels
```dart
// ❌ BAD
IconButton(
  icon: Icon(Icons.edit),
  onPressed: () {},
)

// ✅ GOOD
Semantics(
  label: 'Edit nutrition plan',
  button: true,
  child: IconButton(
    icon: Icon(Icons.edit),
    onPressed: () {},
    tooltip: 'Edit Plan',
  ),
)
```

### 3. Handle Errors Gracefully
```dart
// ❌ BAD
final plan = await database.from('plans').select().single();

// ✅ GOOD
final plan = await safeDatabase.safeSingle<NutritionPlan>(
  'plans',
  NutritionPlan.fromJson,
  id: planId,
);

if (plan == null) {
  // Show error message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Plan not found')),
  );
}
```

### 4. Use Optimistic Updates
```dart
// ✅ GOOD
Future<void> _savePlan() async {
  final originalPlan = plan.copyWith();

  // Update UI immediately
  setState(() => plan.status = 'saved');

  try {
    await database.update(plan);
  } catch (e) {
    // Rollback on error
    setState(() => plan = originalPlan);
    showError(e);
  }
}
```

---

## Version History

- **v2.0.0** - Complete rebuild with role-based access, i18n, and accessibility
- **v1.0.0** - Initial nutrition platform

---

For more information, see:
- [Migration Guide](MIGRATION_GUIDE.md)
- [Testing Documentation](test/README.md)
- [Component Examples](examples/)