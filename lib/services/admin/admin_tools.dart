import 'package:flutter/material.dart';

class AdminTools {
  static Future<void> openSupportForUser(BuildContext context, String userId) async {
    debugPrint('openSupportForUser $userId'); // TODO: prefill support ticket compose
  }
  static Future<void> sendPasswordReset(BuildContext context, String email) async {
    debugPrint('sendPasswordReset $email'); // TODO: call backend function; client cannot do admin auth ops
  }
  static Future<void> markEmailVerified(BuildContext context, String userId) async {
    debugPrint('markEmailVerified $userId'); // TODO
  }
  static Future<void> clearDevices(BuildContext context, String userId) async {
    debugPrint('clearDevices $userId'); // TODO: wipe push tokens row if exists
  }
  static Future<void> impersonate(BuildContext context, String userId, String email) async {
    debugPrint('impersonate as $email'); // TODO: local "actingAs" flag + prominent banner; revert action
  }
}
