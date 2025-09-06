import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/utils/severity_colors.dart';

void main() {
  group('Severity Colors Tests', () {
    test('should return consistent colors for severity levels', () {
      // Test critical severity (4+)
      final criticalColor = getSeverityColor(4);
      expect(criticalColor, Colors.redAccent.shade400);
      
      // Test high severity (2-3)
      final highColor = getSeverityColor(3);
      expect(highColor, Colors.amberAccent.shade400);
      
      // Test medium severity (2)
      final mediumColor = getSeverityColor(2);
      expect(mediumColor, Colors.amberAccent.shade400);
      
      // Test low severity (1)
      final lowColor = getSeverityColor(1);
      expect(lowColor, Colors.orangeAccent.shade400);
    });

    test('should return correct severity levels for issue types', () {
      // Critical issues
      expect(getIssueSeverity('check-in overdue'), 4);
      expect(getIssueSeverity('session missed'), 4);
      
      // High severity issues
      expect(getIssueSeverity('low compliance'), 3);
      
      // Medium severity issues
      expect(getIssueSeverity('no progress photos'), 2);
      expect(getIssueSeverity('form incomplete'), 2);
      
      // Low severity issues
      expect(getIssueSeverity('message not replied'), 1);
      expect(getIssueSeverity('unknown issue'), 1); // default case
    });

    test('should handle case-insensitive issue names', () {
      expect(getIssueSeverity('CHECK-IN OVERDUE'), 4);
      expect(getIssueSeverity('Check-In Overdue'), 4);
      expect(getIssueSeverity('check-in overdue'), 4);
    });

    test('should maintain color consistency across different severity values', () {
      // Test edge cases
      expect(getSeverityColor(5), Colors.redAccent.shade400); // Above critical
      expect(getSeverityColor(0), Colors.orangeAccent.shade400); // Below low
      expect(getSeverityColor(-1), Colors.orangeAccent.shade400); // Negative
    });
  });
}
