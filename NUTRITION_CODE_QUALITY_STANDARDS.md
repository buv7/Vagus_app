# Nutrition Platform 2.0 - Code Quality Standards

**Last Updated:** September 30, 2025
**Status:** Active

This document defines the code quality standards for the Nutrition Platform 2.0 rebuild.

---

## 📋 Table of Contents

1. [File Structure](#file-structure)
2. [Naming Conventions](#naming-conventions)
3. [Documentation](#documentation)
4. [Error Handling](#error-handling)
5. [State Management](#state-management)
6. [UI/UX Requirements](#uiux-requirements)
7. [Performance Standards](#performance-standards)
8. [Testing Requirements](#testing-requirements)
9. [Accessibility](#accessibility)
10. [Final Checklist](#final-checklist)

---

## 1. File Structure

Every Dart file MUST follow this structure:

```dart
// 1. Imports (sorted: dart, flutter, packages, app)
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/nutrition/nutrition_plan.dart';
import '../../services/nutrition/nutrition_service.dart';
import '../../theme/app_theme.dart';

// 2. Class definition with doc comment
/// A beautiful card that displays a meal in a timeline format.
///
/// Supports both coach and client modes with different interactions.
/// In coach mode, swipe actions enable duplicate/delete.
/// In client mode, shows checkbox for meal completion tracking.
class MealTimelineCard extends StatelessWidget {
  // 3. Fields (required first, then optional)
  final Meal meal;
  final bool isCoachMode;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  // 4. Constructor
  const MealTimelineCard({
    Key? key,
    required this.meal,
    required this.isCoachMode,
    required this.onTap,
    this.onEdit,
  }) : super(key: key);

  // 5. Build method
  @override
  Widget build(BuildContext context) {
    // ...
  }

  // 6. Private helper methods
  Widget _buildMealImage() {
    // ...
  }
}
```

---

## 2. Naming Conventions

### Classes
- **Format:** `PascalCase`
- **Examples:** `NutritionHubScreen`, `MacroRingChart`, `GlassCardBuilder`

### Files
- **Format:** `snake_case`
- **Examples:** `nutrition_hub_screen.dart`, `macro_ring_chart.dart`

### Variables
- **Format:** `camelCase`
- **Examples:** `totalCalories`, `isCoachMode`, `mealList`

### Constants
- **Format:** `camelCase` with const keyword
- **Examples:** `const maxMeals = 10`, `const defaultPadding = 16.0`

### Private Members
- **Format:** Prefix with `_`
- **Examples:** `_calculateMacros()`, `_supabase`, `_controller`

### Booleans
- **Format:** Prefix with `is`, `has`, `should`, `can`
- **Examples:** `isCoachMode`, `hasPermission`, `shouldShowBanner`, `canEdit`

---

## 3. Documentation

### Class Documentation

Every public class MUST have a doc comment:

```dart
/// A service for managing nutrition plans and meals.
///
/// Provides CRUD operations for nutrition plans with real-time sync,
/// offline support, and automatic conflict resolution.
///
/// Example:
/// ```dart
/// final service = NutritionService();
/// final plans = await service.fetchPlansForUser(userId);
/// ```
class NutritionService {
  // ...
}
```

### Method Documentation

All public methods MUST have doc comments:

```dart
/// Calculates the total macros for a list of food items.
///
/// Returns a [MacroSummary] with totals for:
/// - Calories (kcal)
/// - Protein (g)
/// - Carbohydrates (g)
/// - Fat (g)
///
/// Example:
/// ```dart
/// final items = [food1, food2, food3];
/// final summary = calculateMacros(items);
/// print('Total calories: ${summary.calories}');
/// ```
MacroSummary calculateMacros(List<FoodItem> items) {
  // Implementation
}
```

### Inline Comments

Use inline comments for complex logic:

```dart
// Calculate user bucket for percentage-based rollout
// Same user always gets same bucket (deterministic)
final hash = userId.hashCode.abs();
return hash % 100;
```

---

## 4. Error Handling

### Standard Pattern

All database operations MUST follow this pattern:

```dart
Future<NutritionPlan?> fetchPlan(String planId) async {
  try {
    final response = await _supabase
      .from('nutrition_plans')
      .select('*, meals(*)')
      .eq('id', planId)
      .maybeSingle();

    if (response == null) {
      debugPrint('Plan not found: $planId');
      return null;
    }

    return NutritionPlan.fromJson(response);
  } on PostgrestException catch (e) {
    debugPrint('Database error fetching plan: ${e.message}');
    rethrow;
  } catch (e) {
    debugPrint('Unexpected error fetching plan: $e');
    rethrow;
  }
}
```

### Error Messages

- **User-facing:** Clear, actionable messages
- **Debug logs:** Detailed context for troubleshooting
- **No silent failures:** Always log errors

### User Error Display

```dart
void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: NutritionColors.error,
      action: SnackBarAction(
        label: 'Retry',
        textColor: Colors.white,
        onPressed: _loadData,
      ),
    ),
  );
}
```

---

## 5. State Management

### Standard Pattern

```dart
class NutritionHubScreen extends StatefulWidget {
  const NutritionHubScreen({Key? key}) : super(key: key);

  @override
  State<NutritionHubScreen> createState() => _NutritionHubScreenState();
}

class _NutritionHubScreenState extends State<NutritionHubScreen> {
  // Services (initialized in initState or constructor)
  late final NutritionService _nutritionService;

  // State variables (use late if initialized in initState)
  bool _isLoading = true;
  String? _error;
  NutritionPlan? _plan;

  @override
  void initState() {
    super.initState();
    _nutritionService = NutritionService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final plan = await _nutritionService.fetchPlan(widget.planId);

      if (!mounted) return; // Critical check

      setState(() {
        _plan = plan;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load nutrition plan';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState(_error!);
    if (_plan == null) return _buildEmptyState();

    return _buildContent(_plan!);
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(message),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text('No nutrition plan found'),
    );
  }

  Widget _buildContent(NutritionPlan plan) {
    // Main content
    return Container();
  }
}
```

---

## 6. UI/UX Requirements

### Spacing System

Use consistent spacing from `NutritionSpacing`:

```dart
Padding(
  padding: EdgeInsets.all(NutritionSpacing.md),
  child: Column(
    children: [
      Text('Meal Name'),
      SizedBox(height: NutritionSpacing.sm),
      Text('Macros'),
    ],
  ),
)
```

### Typography

Use `NutritionTextStyles` for all text:

```dart
Text(
  'Meal Name',
  style: NutritionTextStyles.h4(context),
)

Text(
  '150g',
  style: NutritionTextStyles.macroValue(context),
)
```

### Colors

Use `NutritionColors` for all colors:

```dart
Container(
  color: NutritionColors.protein,
  child: Text('Protein'),
)

// Status colors
Container(
  color: NutritionColors.success, // or warning, error, info
)
```

### Animations

Use `NutritionAnimations` for consistent timing:

```dart
AnimatedContainer(
  duration: NutritionAnimations.normal,
  curve: NutritionAnimations.easeOut,
  color: isActive ? Colors.green : Colors.grey,
)
```

### Glassmorphism

Use `GlassCardBuilder` for cards:

```dart
GlassCardBuilder.build(
  child: MyContent(),
  onTap: () => handleTap(),
)

// Or presets
GlassCardBuilder.compact(child: MyContent())
GlassCardBuilder.prominent(child: MyContent())
GlassCardBuilder.success(child: MyContent())
```

---

## 7. Performance Standards

### Benchmarks

- App launch to nutrition hub: **<2 seconds**
- Meal list render (20 meals): **<500ms**
- Food search results: **<300ms**
- Image loading with cache: **<200ms**
- Save operation feedback: **<1 second**
- 60 FPS during all animations
- Memory usage: **<150MB** for entire nutrition section
- APK size increase: **<5MB**

### Best Practices

**Images:**
```dart
CachedNetworkImage(
  imageUrl: meal.photoUrl,
  placeholder: (context, url) => ShimmerLoading(),
  errorWidget: (context, url, error) => DefaultIcon(),
  cacheKey: meal.id,
)
```

**Lists:**
```dart
ListView.builder(
  itemCount: meals.length,
  itemBuilder: (context, index) => MealCard(meal: meals[index]),
  // Use ListView.builder, NOT ListView() with map
)
```

**Avoid Rebuilds:**
```dart
// BAD
setState(() {
  // Rebuilds entire widget tree
});

// GOOD
setState(() {
  _specificValue = newValue; // Only rebuild what changed
});
```

---

## 8. Testing Requirements

### Unit Tests

**Coverage:** >80% for services and utilities

```dart
test('calculateMacros returns correct totals', () {
  final items = [
    FoodItem(protein: 10, carbs: 20, fat: 5),
    FoodItem(protein: 15, carbs: 30, fat: 10),
  ];

  final result = calculateMacros(items);

  expect(result.protein, 25);
  expect(result.carbs, 50);
  expect(result.fat, 15);
});
```

### Widget Tests

All custom widgets MUST be tested:

```dart
testWidgets('MacroRingChart displays correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MacroRingChart(
        protein: 100,
        proteinTarget: 150,
        carbs: 200,
        carbsTarget: 250,
        fat: 50,
        fatTarget: 70,
      ),
    ),
  );

  expect(find.byType(CustomPaint), findsOneWidget);
});
```

### Integration Tests

Test critical user journeys:

```dart
testWidgets('User can create and save a meal', (tester) async {
  await tester.pumpWidget(MyApp());

  // Navigate to meal creation
  await tester.tap(find.text('Add Meal'));
  await tester.pumpAndSettle();

  // Fill form
  await tester.enterText(find.byType(TextField).first, 'Breakfast');

  // Save
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  // Verify
  expect(find.text('Meal saved'), findsOneWidget);
});
```

---

## 9. Accessibility

### Screen Reader Support

```dart
Semantics(
  label: 'Meal card for Breakfast',
  child: MealCard(meal: breakfast),
)
```

### Semantic Labels

```dart
IconButton(
  icon: Icon(Icons.delete),
  onPressed: _deleteMeal,
  tooltip: 'Delete meal',
)
```

### Font Scaling

Support up to 200% scaling:

```dart
Text(
  'Meal Name',
  style: Theme.of(context).textTheme.titleLarge,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)
```

### Color Blind Friendly

Never rely solely on color. Use icons/text:

```dart
// BAD
Container(color: Colors.red) // Only color indicates error

// GOOD
Row(
  children: [
    Icon(Icons.error, color: Colors.red),
    Text('Error: Failed to save'),
  ],
)
```

---

## 10. Final Checklist

Before marking any feature complete, verify:

### Code Quality
- [ ] No TODO or FIXME comments
- [ ] No debug print statements (use debugPrint or remove)
- [ ] No hardcoded strings (use LocaleHelper.t() or constants)
- [ ] No magic numbers (define constants)
- [ ] All public APIs documented
- [ ] No unused imports
- [ ] No warnings in IDE
- [ ] Formatted with `dart format`
- [ ] Linted with `dart analyze` (0 issues)

### Functionality
- [ ] All features from requirements implemented
- [ ] Coach mode works perfectly
- [ ] Client mode works perfectly
- [ ] Role detection accurate
- [ ] Data saves correctly
- [ ] Data loads correctly
- [ ] Offline mode graceful
- [ ] Error states helpful
- [ ] Loading states smooth
- [ ] Empty states delightful

### Visual Design
- [ ] Matches AppTheme precisely
- [ ] All animations smooth (60 FPS)
- [ ] No layout overflow errors
- [ ] Images load with placeholders
- [ ] Icons consistent style
- [ ] Colors match spec
- [ ] Typography consistent
- [ ] Spacing consistent
- [ ] Dark mode perfect
- [ ] Looks great on screenshots

### Performance
- [ ] No jank (performance overlay checked)
- [ ] Images cached properly
- [ ] Lazy loading implemented
- [ ] No memory leaks (devtools checked)
- [ ] Fast cold start (<3s)
- [ ] Fast hot reload (<1s)
- [ ] Efficient rebuilds (no unnecessary setState)
- [ ] Database queries optimized

### Testing
- [ ] Unit tests written and passing
- [ ] Widget tests written and passing
- [ ] Integration tests written and passing
- [ ] Manual testing completed
- [ ] Tested on iOS
- [ ] Tested on Android
- [ ] Tested on tablet
- [ ] Tested with slow network
- [ ] Tested with no network

### Accessibility
- [ ] Screen reader works
- [ ] Semantic labels added
- [ ] Contrast ratios checked
- [ ] Font scaling works
- [ ] Keyboard navigation works
- [ ] Color blind friendly

### Documentation
- [ ] README updated
- [ ] Architecture documented
- [ ] Service methods documented
- [ ] Complex logic commented

---

## Success Criteria

**Definition of Done:**

A feature is complete when:
- ✅ Zero broken functionality
- ✅ Performance benchmarks met
- ✅ Visual design matches specs exactly
- ✅ All tests passing
- ✅ Accessible to all users
- ✅ Fully documented

**Quality Gates:**

- Code review by 2+ developers
- QA testing pass
- Performance profiling pass
- Accessibility audit pass
- Security review pass (for data-sensitive features)

---

**Remember:** Code quality is not optional. It's a requirement for production deployment.

---

**Last Updated:** September 30, 2025
**Maintained By:** Nutrition Platform Team
**Status:** Active - Enforce on all PRs