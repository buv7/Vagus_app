/// EXAMPLE USAGE AND MIGRATION GUIDE
///
/// This file demonstrates how to use the new UnifiedCoachProfileScreen
/// and provides migration guidance from the old fragmented screens.
///
library;

import 'package:flutter/material.dart';
import '../../services/navigation/app_navigator.dart';

/// Example usage of the UnifiedCoachProfileScreen
class UnifiedCoachProfileExamples {

  /// Example 1: Navigate to coach profile in view mode
  static void viewCoachProfile(BuildContext context, String coachId) {
    // New way - unified screen
    AppNavigator.coachProfile(context, coachId);

    // This replaces:
    // AppNavigator.legacyCoachProfile(context, coachId); // Old CoachProfilePublicScreen
  }

  /// Example 2: Navigate to coach profile in edit mode
  static void editCoachProfile(BuildContext context, String coachId) {
    // New way - direct edit mode
    AppNavigator.editCoachProfile(context, coachId);

    // This replaces navigating to separate PortfolioEditScreen
  }

  /// Example 3: Navigate by username (deep linking support)
  static void viewCoachByUsername(BuildContext context, String username) {
    // New way - supports @username links
    AppNavigator.coachProfileByUsername(context, username);

    // This enables deep linking like: /coach/@johndoe
  }

  /// Example 4: QR code sharing integration
  static void shareCoachProfile(BuildContext context, String coachId, String username) {
    // The unified screen has built-in QR sharing
    // Just navigate to the profile and the share button will be available
    AppNavigator.coachProfile(context, coachId, username: username);
  }

  /// Example 5: Integration with existing coach search
  static void onCoachSearchResult(BuildContext context, Map<String, dynamic> coachData) {
    final coachId = coachData['id'] as String;
    final username = coachData['username'] as String?;

    // Navigate to unified profile
    AppNavigator.coachProfile(context, coachId, username: username);
  }

  /// Example 6: Profile completeness onboarding
  static void onboardNewCoach(BuildContext context, String coachId) {
    // New coaches see completeness indicator and can edit inline
    AppNavigator.coachProfile(context, coachId, editMode: true);
  }
}

/// MIGRATION GUIDE - What to update after implementing UnifiedCoachProfileScreen
///
/// 1. UPDATE NAVIGATION CALLS:
///
/// OLD:
/// - AppNavigator.legacyCoachProfile(context, coachId)
/// - Navigator.push(context, MaterialPageRoute(builder: (_) => CoachProfilePublicScreen(coachId: coachId)))
/// - Navigator.push(context, MaterialPageRoute(builder: (_) => PortfolioEditScreen(coachId: coachId)))
///
/// NEW:
/// - AppNavigator.coachProfile(context, coachId) // View mode
/// - AppNavigator.editCoachProfile(context, coachId) // Edit mode
///
/// 2. UPDATE DEEP LINKING:
///
/// OLD deep link handling:
/// /coach/{id} -> CoachProfilePublicScreen
///
/// NEW deep link handling:
/// /coach/{id} -> UnifiedCoachProfileScreen(coachId: id)
/// /coach/@{username} -> UnifiedCoachProfileScreen(username: username)
/// /coach/{id}/edit -> UnifiedCoachProfileScreen(coachId: id, initialEditMode: true)
///
/// 3. REMOVE OLD SCREENS (after thorough testing):
///
/// Files to potentially remove:
/// - lib/screens/coach/coach_profile_public_screen.dart
/// - lib/screens/coach/portfolio_edit_screen.dart
/// - lib/screens/dashboard/edit_profile_screen.dart (coach-specific parts)
///
/// 4. UPDATE REFERENCES:
///
/// Search codebase for:
/// - CoachProfilePublicScreen
/// - PortfolioEditScreen
/// - References to old navigation methods
///
/// 5. UPDATE TESTS:
///
/// Update any existing tests to use the new UnifiedCoachProfileScreen:
/// - Widget tests
/// - Integration tests
/// - Navigation tests
///
/// 6. FEATURE MAPPING:
///
/// OLD SCREENS -> NEW UNIFIED SCREEN FEATURES:
///
/// CoachProfilePublicScreen:
/// ✅ Profile header with avatar, name, username
/// ✅ Bio and headline display
/// ✅ Specialties chips
/// ✅ Media portfolio gallery
/// ✅ Stats and ratings
/// ✅ CTA buttons (Connect, Book, Message)
/// ✅ QR code sharing
///
/// PortfolioEditScreen:
/// ✅ Inline edit mode toggle
/// ✅ Profile completeness indicator
/// ✅ Form validation and auto-save
/// ✅ Media upload and management
/// ✅ Specialty selection
/// ✅ Username availability checking
///
/// EditProfileScreen (coach parts):
/// ✅ Avatar upload
/// ✅ Display name editing
/// ✅ Bio rich text editing
/// ✅ Headline editing
///
/// CoachSearchScreen (integration):
/// ✅ Supports navigation from search results
/// ✅ Username-based navigation
/// ✅ Deep linking support
///
/// 7. NEW FEATURES NOT IN OLD SCREENS:
///
/// ✅ Dual-mode functionality (view/edit in same screen)
/// ✅ Comprehensive profile completeness tracking
/// ✅ Real-time username validation
/// ✅ Unsaved changes warning
/// ✅ Animated transitions between modes
/// ✅ Consolidated media gallery with filters
/// ✅ Progressive profile completion UI
/// ✅ Enhanced QR sharing with temp/permanent options
/// ✅ Responsive design for mobile/tablet/web
/// ✅ Pull-to-refresh functionality
/// ✅ Better error handling and loading states
///
/// 8. TESTING CHECKLIST:
///
/// Before removing old screens, verify:
/// □ All navigation paths work correctly
/// □ Edit mode functions properly
/// □ Profile completeness calculation is accurate
/// □ Media upload/management works
/// □ QR code generation and sharing functions
/// □ Deep linking works for both ID and username
/// □ Form validation prevents invalid submissions
/// □ Unsaved changes dialog appears when appropriate
/// □ Loading and error states display correctly
/// □ Animations perform smoothly
/// □ Accessibility features work
/// □ Dark mode styling is correct
/// □ Responsive layout adapts to different screen sizes
///
/// 9. PERFORMANCE CONSIDERATIONS:
///
/// The unified screen loads multiple data sources concurrently:
/// - Profile data
/// - Stats data
/// - Media data
/// - Completeness data
///
/// Monitor performance and consider:
/// - Implementing data caching
/// - Adding pagination for media galleries
/// - Lazy loading for less critical sections
/// - Optimizing image loading and caching
///
/// 10. ACCESSIBILITY IMPROVEMENTS:
///
/// The unified screen includes better accessibility:
/// - Semantic labels for screen readers
/// - Proper heading hierarchy
/// - Keyboard navigation support
/// - High contrast mode compatibility
/// - Voice control integration
///
/// Ensure all interactive elements have proper accessibility labels.

/// Sample integration with existing coach management workflow
class CoachManagementIntegration {

  /// Example: Coach onboarding flow
  static void startCoachOnboarding(BuildContext context, String newCoachId) {
    // Direct to edit mode with completeness guidance
    AppNavigator.editCoachProfile(context, newCoachId);
  }

  /// Example: Coach dashboard integration
  static void navigateToMyProfile(BuildContext context, String myCoachId) {
    // Show in edit mode for own profile
    AppNavigator.coachProfile(context, myCoachId, editMode: true);
  }

  /// Example: Client viewing coach profiles
  static void viewCoachFromSearch(BuildContext context, String coachId, String? username) {
    // Show in view mode for clients
    AppNavigator.coachProfile(context, coachId, username: username);
  }

  /// Example: Admin reviewing coach profiles
  static void adminReviewCoach(BuildContext context, String coachId) {
    // Admin can view profiles but not edit (handled by permissions)
    AppNavigator.coachProfile(context, coachId);
  }
}

/// Deep linking integration example
class DeepLinkingIntegration {

  /// Handle incoming deep links
  static void handleDeepLink(BuildContext context, String url) {
    final uri = Uri.parse(url);

    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'coach') {
      final identifier = uri.pathSegments[1];

      if (identifier.startsWith('@')) {
        // Username-based link: /coach/@username
        final username = identifier.substring(1);
        AppNavigator.coachProfileByUsername(context, username);
      } else {
        // ID-based link: /coach/{id} or /coach/{id}/edit
        final coachId = identifier;
        final isEdit = uri.pathSegments.length > 2 && uri.pathSegments[2] == 'edit';

        AppNavigator.coachProfile(context, coachId, editMode: isEdit);
      }
    }
  }

  /// Generate shareable links
  static String generateShareableLink(String coachId, String? username) {
    if (username != null && username.isNotEmpty) {
      return 'https://vagus.app/coach/@$username';
    }
    return 'https://vagus.app/coach/$coachId';
  }
}