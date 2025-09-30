import 'package:flutter/material.dart';
import '../../../../models/nutrition/nutrition_plan.dart';
import '../../nutrition_plan_builder.dart';

/// Plan builder view for creating and editing nutrition plans
/// Wraps the existing NutritionPlanBuilder with enhanced hub integration
class BuilderView extends StatelessWidget {
  final String? clientId;
  final NutritionPlan? planToEdit;
  final String userRole;
  final List<dynamic> availableClients;
  final Function(NutritionPlan) onPlanCreated;
  final Function(NutritionPlan) onPlanUpdated;
  final VoidCallback onCancel;

  const BuilderView({
    super.key,
    this.clientId,
    this.planToEdit,
    required this.userRole,
    required this.availableClients,
    required this.onPlanCreated,
    required this.onPlanUpdated,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Use the existing NutritionPlanBuilder which has all the functionality
    return NutritionPlanBuilder(
      clientId: clientId,
      planToEdit: planToEdit,
    );
  }
}