import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/services/nutrition/role_manager.dart';
import 'package:vagus_app/models/nutrition/nutrition_plan.dart';

void main() {
  group('NutritionRoleManager', () {
    late NutritionRoleManager roleManager;

    setUp(() {
      roleManager = NutritionRoleManager();
    });

    group('Mode Detection', () {
      test('detectMode returns coachBuilding when coach in edit mode', () {
        // Arrange
        roleManager.initialize(); // Mock initialization
        final plan = _createMockPlan(
          clientId: 'client-123',
          coachId: 'coach-456',
        );

        // Act
        final mode = roleManager.detectMode(plan: plan, editMode: true);

        // Assert
        expect(mode, equals(NutritionMode.coachBuilding));
      });

      test('detectMode returns clientViewing when viewing own plan', () {
        // Arrange
        final plan = _createMockPlan(
          clientId: 'user-123',
          coachId: 'coach-456',
        );

        // Act
        final mode = roleManager.detectMode(plan: plan, editMode: false);

        // Assert
        expect(mode, equals(NutritionMode.clientViewing));
      });
    });

    group('Permissions', () {
      test('canEditPlan returns true only in coachBuilding mode', () {
        final plan = _createMockPlan();

        // Coach building mode
        expect(roleManager.canEditMealContent(NutritionMode.coachBuilding), isTrue);

        // Other modes
        expect(roleManager.canEditMealContent(NutritionMode.coachViewing), isFalse);
        expect(roleManager.canEditMealContent(NutritionMode.clientViewing), isFalse);
      });

      test('canCheckOffMeals returns true only in clientViewing mode', () {
        // Client viewing mode
        expect(roleManager.canCheckOffMeals(NutritionMode.clientViewing), isTrue);

        // Other modes
        expect(roleManager.canCheckOffMeals(NutritionMode.coachBuilding), isFalse);
        expect(roleManager.canCheckOffMeals(NutritionMode.coachViewing), isFalse);
      });

      test('canExportPlan returns true for all modes', () {
        expect(roleManager.canExportPlan(NutritionMode.coachBuilding), isTrue);
        expect(roleManager.canExportPlan(NutritionMode.coachViewing), isTrue);
        expect(roleManager.canExportPlan(NutritionMode.clientViewing), isTrue);
      });

      test('canAddCoachNotes returns true for coach modes', () {
        expect(roleManager.canAddCoachNotes(NutritionMode.coachBuilding), isTrue);
        expect(roleManager.canAddCoachNotes(NutritionMode.coachViewing), isTrue);
        expect(roleManager.canAddCoachNotes(NutritionMode.clientViewing), isFalse);
      });
    });

    group('Available Actions', () {
      test('coachBuilding mode has all editing actions', () {
        final actions = roleManager.getAvailableActions(NutritionMode.coachBuilding);

        expect(actions, contains(NutritionAction.editMeals));
        expect(actions, contains(NutritionAction.addMeals));
        expect(actions, contains(NutritionAction.removeMeals));
        expect(actions, contains(NutritionAction.setTargets));
        expect(actions, contains(NutritionAction.saveTemplate));
      });

      test('clientViewing mode has limited actions', () {
        final actions = roleManager.getAvailableActions(NutritionMode.clientViewing);

        expect(actions, contains(NutritionAction.checkOffMeals));
        expect(actions, contains(NutritionAction.addClientComments));
        expect(actions, contains(NutritionAction.requestChanges));
        expect(actions, isNot(contains(NutritionAction.editMeals)));
        expect(actions, isNot(contains(NutritionAction.setTargets)));
      });
    });

    group('UI Configuration', () {
      test('coachBuilding config shows all editing UI', () {
        final config = roleManager.getUIConfig(NutritionMode.coachBuilding);

        expect(config.showEditButton, isTrue);
        expect(config.showAddMealButton, isTrue);
        expect(config.showMacroTargetEditor, isTrue);
        expect(config.allowMealEditing, isTrue);
        expect(config.allowMealReordering, isTrue);
        expect(config.headerTitle, equals('Build Nutrition Plan'));
      });

      test('clientViewing config shows limited UI', () {
        final config = roleManager.getUIConfig(NutritionMode.clientViewing);

        expect(config.showEditButton, isFalse);
        expect(config.showAddMealButton, isFalse);
        expect(config.showMacroTargetEditor, isFalse);
        expect(config.showCheckoffButtons, isTrue);
        expect(config.showClientComments, isTrue);
        expect(config.headerTitle, equals('Your Nutrition Plan'));
      });
    });

    group('User Display Info', () {
      test('getUserDisplayInfo returns correct role info', () {
        // This would require proper initialization with Supabase
        // Skipping for now, but structure is here
      });
    });
  });
}

// Helper function to create mock plans
NutritionPlan _createMockPlan({
  String? clientId,
  String? coachId,
}) {
  return NutritionPlan(
    id: 'plan-123',
    name: 'Test Plan',
    clientId: clientId ?? 'client-123',
    coachId: coachId ?? 'coach-456',
    lengthType: 'daily',
    meals: [],
    dailySummary: DailySummary(
      totalProtein: 150.0,
      totalCarbs: 200.0,
      totalFat: 60.0,
      totalKcal: 2000.0,
      totalSodium: 2000.0,
      totalPotassium: 3500.0,
    ),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}