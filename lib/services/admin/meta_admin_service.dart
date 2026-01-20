import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/admin/admin_models.dart';

class MetaAdminService {
  MetaAdminService._();
  static final MetaAdminService I = MetaAdminService._();

  final _db = Supabase.instance.client;

  /// Get admin hierarchy for a user
  Future<AdminHierarchy?> getAdminHierarchy(String adminId) async {
    try {
      final res = await _db
          .from('admin_hierarchy')
          .select()
          .eq('admin_id', adminId)
          .maybeSingle();

      if (res == null) return null;
      return AdminHierarchy.fromJson(res);
    } catch (e) {
      debugPrint('Failed to get admin hierarchy: $e');
      return null;
    }
  }

  /// Assign or update admin level
  Future<String> assignAdminLevel({
    required String adminId,
    required int level,
    String? parentAdminId,
    Map<String, dynamic>? permissions,
  }) async {
    try {
      final currentUser = _db.auth.currentUser;
      if (currentUser == null) throw Exception('Not authenticated');

      final hierarchy = AdminHierarchy(
        id: 'temp',
        adminId: adminId,
        level: level,
        parentAdminId: parentAdminId,
        permissions: permissions ?? {},
        assignedBy: currentUser.id,
        assignedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final res = await _db
          .from('admin_hierarchy')
          .upsert(hierarchy.toInsertJson(), onConflict: 'admin_id')
          .select()
          .single();

      return res['id'] as String;
    } catch (e) {
      debugPrint('Failed to assign admin level: $e');
      rethrow;
    }
  }

  /// List all admin hierarchy entries
  Future<List<AdminHierarchy>> listAdminHierarchy() async {
    try {
      final res = await _db
          .from('admin_hierarchy')
          .select()
          .order('level', ascending: true)
          .order('created_at', ascending: false);

      return (res as List)
          .map((e) => AdminHierarchy.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to list admin hierarchy: $e');
      return [];
    }
  }

  /// Remove admin from hierarchy
  Future<void> removeAdminFromHierarchy(String adminId) async {
    try {
      await _db.from('admin_hierarchy').delete().eq('admin_id', adminId);
    } catch (e) {
      debugPrint('Failed to remove admin from hierarchy: $e');
      rethrow;
    }
  }
}
