import 'package:vagus_app/models/nutrition/nutrition_plan.dart';

extension NutritionPlanCompat on NutritionPlan {
  List<dynamic> get days {
    try {
      final d = (this as dynamic).days;
      if (d != null) return d as List;
      final w = (this as dynamic).weeks;
      if (w != null) {
        return (w as List)
            .expand((week) => ((week as dynamic).days as List? ?? const []))
            .toList();
      }
    } catch (_) {}
    return const [];
  }
}
