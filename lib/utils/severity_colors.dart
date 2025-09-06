import 'package:flutter/material.dart';

/// Returns a consistent color for severity levels across the app
/// Used for chips, borders, and count badges in CoachInboxCard
Color getSeverityColor(int severity) {
  if (severity >= 4) return Colors.redAccent.shade400;
  if (severity >= 2) return Colors.amberAccent.shade400;
  return Colors.orangeAccent.shade400;
}

/// Returns the severity level for a given issue type
int getIssueSeverity(String issue) {
  switch (issue.toLowerCase()) {
    case 'check-in overdue':
      return 4; // Critical
    case 'session missed':
      return 4; // Critical
    case 'low compliance':
      return 3; // High
    case 'no progress photos':
      return 2; // Medium
    case 'form incomplete':
      return 2; // Medium
    case 'message not replied':
      return 1; // Low
    default:
      return 1; // Low
  }
}
