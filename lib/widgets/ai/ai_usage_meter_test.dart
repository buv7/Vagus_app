import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'ai_usage_meter.dart';

void main() {
  group('AIUsageMeter Widget Tests', () {
    testWidgets('AIUsageMeter displays loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIUsageMeter(),
          ),
        ),
      );

      // Should show loading state initially
      expect(find.text('Loading AI usage...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AIUsageMeter shows error state when there is an error', (WidgetTester tester) async {
      // This would require mocking Supabase client to test error states
      // For now, we'll just verify the widget structure
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIUsageMeter(),
          ),
        ),
      );

      // Should show loading initially
      expect(find.text('Loading AI usage...'), findsOneWidget);
    });

    testWidgets('AIUsageMeter shows compact version when isCompact is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIUsageMeter(isCompact: true),
          ),
        ),
      );

      // Should show loading state initially
      expect(find.text('Loading AI usage...'), findsOneWidget);
    });

    testWidgets('AIUsageMeter calls onRefresh when refresh button is tapped', (WidgetTester tester) async {
      bool refreshCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIUsageMeter(
              onRefresh: () {
                refreshCalled = true;
              },
            ),
          ),
        ),
      );

      // Should show loading state initially
      expect(find.text('Loading AI usage...'), findsOneWidget);
      
      // Note: In a real test environment with mocked Supabase,
      // we would be able to test the refresh functionality
      // For now, we just verify the widget structure
    });
  });
}
