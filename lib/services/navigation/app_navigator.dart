import 'package:flutter/material.dart';

// ✅ Import actual screens (use existing snake_case paths)
import 'package:vagus_app/screens/dashboard/edit_profile_screen.dart';
import 'package:vagus_app/screens/settings/user_settings_screen.dart';
import 'package:vagus_app/screens/billing/billing_settings.dart';
import 'package:vagus_app/screens/settings/health_connections_screen.dart';
import 'package:vagus_app/screens/auth/become_coach_screen.dart';
import 'package:vagus_app/screens/settings/ai_usage_screen.dart';
import 'package:vagus_app/screens/progress/export_progress_screen.dart';
import 'package:vagus_app/screens/messaging/admin_support_chat_screen.dart';
import 'package:vagus_app/screens/admin/admin_hub_screen.dart';
import 'package:vagus_app/screens/admin/support/support_inbox_screen.dart';
import 'package:vagus_app/screens/admin/admin_agent_workload_screen.dart';
import 'package:vagus_app/screens/admin/admin_macros_screen.dart';
import 'package:vagus_app/screens/admin/admin_root_cause_screen.dart';
import 'package:vagus_app/screens/admin/admin_ticket_queue_screen.dart';
import 'package:vagus_app/screens/admin/admin_escalation_matrix_screen.dart';
import 'package:vagus_app/screens/admin/admin_playbooks_screen.dart';
import 'package:vagus_app/screens/admin/admin_knowledge_screen.dart';
import 'package:vagus_app/screens/admin/admin_incidents_screen.dart';
import 'package:vagus_app/screens/admin/admin_session_copilot_screen.dart';
import 'package:vagus_app/screens/admin/admin_live_session_screen.dart';
import 'package:vagus_app/screens/admin/admin_triage_rules_screen.dart';
import 'package:vagus_app/screens/coach_profile/coach_profile_screen.dart';

class AppNavigator {
  // Always close Drawer first, then navigate on next frame to avoid wrong targets.
  static void _closeDrawerAndPush(BuildContext context, Widget page) {
    // Close Drawer if open
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    // Next frame: push
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page),
      );
    });
  }

  static void editProfile(BuildContext context) =>
      _closeDrawerAndPush(context, const EditProfileScreen());

  static void settings(BuildContext context) =>
      _closeDrawerAndPush(context, const UserSettingsScreen());

  // "Upgrade to Pro" → Billing settings (manages plan & invoices)
  static void billingUpgrade(BuildContext context) =>
      _closeDrawerAndPush(context, const BillingSettings());

  static void manageDevices(BuildContext context) =>
      _closeDrawerAndPush(context, const HealthConnectionsScreen());

  static void aiUsage(BuildContext context) =>
      _closeDrawerAndPush(context, const AiUsageScreen());

  static void exportProgress(BuildContext context) =>
      _closeDrawerAndPush(context, const ExportProgressScreen());

  static void applyCoach(BuildContext context) =>
      _closeDrawerAndPush(context, const BecomeCoachScreen());

  static void support(BuildContext context) =>
      _closeDrawerAndPush(context, const AdminSupportChatScreen());

  // Admin navigation methods
  static void adminHub(BuildContext context) =>
      _closeDrawerAndPush(context, const AdminHubScreen());

  static void supportInbox(BuildContext context) =>
      _closeDrawerAndPush(context, const SupportInboxScreen());

  static void adminAgentWorkload(BuildContext context) =>
      _closeDrawerAndPush(context, const AdminAgentWorkloadScreen());

  static void adminMacros(BuildContext context) =>
      _closeDrawerAndPush(context, const AdminMacrosScreen());

  static void adminRootCause(BuildContext context) =>
      _closeDrawerAndPush(context, const AdminRootCauseScreen());

  static void adminTicketQueue(BuildContext context) =>
      _closeDrawerAndPush(context, const AdminTicketQueueScreen());

  static void adminEscalationMatrix(BuildContext context) =>
      _closeDrawerAndPush(context, const AdminEscalationMatrixScreen());

  static void adminPlaybooks(BuildContext context) =>
      _closeDrawerAndPush(context, const AdminPlaybooksScreen());

  static void adminKnowledge(BuildContext context) =>
      _closeDrawerAndPush(context, const AdminKnowledgeScreen());

  static void adminIncidents(BuildContext context) =>
      _closeDrawerAndPush(context, const AdminIncidentsScreen());

  static Future<void> adminCopilotFor(BuildContext context, String userId) async =>
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AdminSessionCopilotScreen(userId: userId)));

  static Future<void> adminLiveFor(BuildContext context, String userId) async =>
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AdminLiveSessionScreen(userId: userId)));

  static Future<void> adminRules(BuildContext context) async =>
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const AdminTriageRulesScreen()));

  // Coach profile navigation - unified screen
  static void coachProfile(BuildContext context, String coachId, {bool isPublicView = true}) =>
      _closeDrawerAndPush(context, CoachProfileScreen(
        coachId: coachId,
        isPublicView: isPublicView,
      ));

  // View own coach profile (for coach users)
  static void myCoachProfile(BuildContext context) =>
      _closeDrawerAndPush(context, const CoachProfileScreen());

  // Edit coach profile navigation (legacy compatibility - now goes to profile with edit mode)
  static void editCoachProfile(BuildContext context, String coachId) =>
      _closeDrawerAndPush(context, CoachProfileScreen(
        coachId: coachId,
        isPublicView: false,
      ));
}
