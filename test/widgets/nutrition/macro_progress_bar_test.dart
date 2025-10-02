import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/services/accessibility/accessibility_service.dart';

/// Widget tests for macro progress bar component
void main() {
  group('MacroProgressBar Widget', () {
    testWidgets('displays macro name and percentage', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestMacroProgressBar(
              label: 'Protein',
              current: 150,
              target: 180,
              percentage: 83,
            ),
          ),
        ),
      );

      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('83%'), findsOneWidget);
      expect(find.text('150/180'), findsOneWidget);
    });

    testWidgets('progress bar fills correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestMacroProgressBar(
              label: 'Protein',
              current: 90,
              target: 180,
              percentage: 50,
            ),
          ),
        ),
      );

      // Find the progress indicator
      final progressFinder = find.byType(FractionallySizedBox);
      expect(progressFinder, findsOneWidget);

      // Verify width factor
      final progressWidget = tester.widget<FractionallySizedBox>(progressFinder);
      expect(progressWidget.widthFactor, equals(0.5));
    });

    testWidgets('includes semantic label for accessibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestMacroProgressBar(
              label: 'Protein',
              current: 150,
              target: 180,
              percentage: 83,
            ),
          ),
        ),
      );

      // Find semantics node
      final semanticsFinder = find.byType(Semantics);
      expect(semanticsFinder, findsWidgets);

      // Verify semantic label exists
      final semantics = tester.widget<Semantics>(semanticsFinder.first);
      expect(semantics.properties.label, isNotNull);
      expect(semantics.properties.label, contains('Protein'));
    });

    testWidgets('updates when values change', (WidgetTester tester) async {
      int current = 100;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    _TestMacroProgressBar(
                      label: 'Protein',
                      current: current,
                      target: 180,
                      percentage: (current / 180 * 100).round(),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => current = 150),
                      child: const Text('Update'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('100/180'), findsOneWidget);

      await tester.tap(find.text('Update'));
      await tester.pump();

      expect(find.text('150/180'), findsOneWidget);
    });

    testWidgets('handles zero target gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestMacroProgressBar(
              label: 'Protein',
              current: 100,
              target: 0,
              percentage: 0,
            ),
          ),
        ),
      );

      // Should not crash
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });
  });
}

/// Test widget that mimics the macro progress bar structure
class _TestMacroProgressBar extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final int percentage;

  const _TestMacroProgressBar({
    required this.label,
    required this.current,
    required this.target,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final a11y = AccessibilityService();
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Semantics(
      label: a11y.getMacroRingSemantics(
        macroName: label,
        current: current.toDouble(),
        target: target.toDouble(),
        unit: 'grams',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('$percentage%'),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('$current/$target'),
        ],
      ),
    );
  }
}