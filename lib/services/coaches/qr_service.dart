import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ResolvedCoach {
  final String coachId;
  final String? username;

  const ResolvedCoach({
    required this.coachId,
    this.username,
  });

  factory ResolvedCoach.fromMap(Map<String, dynamic> map) {
    return ResolvedCoach(
      coachId: map['coach_id']?.toString() ?? '',
      username: map['username']?.toString(),
    );
  }
}

class CoachQrService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  /// Create a QR token for a coach
  Future<String?> createToken({
    required String coachId,
    Duration ttl = const Duration(hours: 24),
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.id != coachId) {
        throw Exception('Unauthorized: Can only create tokens for yourself');
      }

      // Generate a unique token
      final token = _uuid.v4();
      final expiresAt = DateTime.now().add(ttl);

      // Insert token into database
      await _supabase.from('coach_qr_tokens').insert({
        'coach_id': coachId,
        'token': token,
        'expires_at': expiresAt.toIso8601String(),
      });

      // Return the deep link URL
      return 'vagus://qr/$token';
    } catch (e) {
      debugPrint('Error creating QR token: $e');
      return null;
    }
  }

  /// Resolve a QR token to coach information
  Future<ResolvedCoach?> resolveToken(String token) async {
    try {
      final response = await _supabase
          .rpc('resolve_coach_qr_token', params: {'_token': token});

      if (response == null || (response as List).isEmpty) {
        return null;
      }

      final data = response.first;
      return ResolvedCoach.fromMap(data);
    } catch (e) {
      debugPrint('Error resolving QR token: $e');
      return null;
    }
  }

  /// Clean up expired tokens (utility method)
  Future<void> cleanupExpiredTokens() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('coach_qr_tokens')
          .delete()
          .eq('coach_id', user.id)
          .lt('expires_at', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error cleaning up expired tokens: $e');
    }
  }

  /// Get active tokens for current user (for management)
  Future<List<Map<String, dynamic>>> getActiveTokens() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('coach_qr_tokens')
          .select('id, token, expires_at, created_at')
          .eq('coach_id', user.id)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting active tokens: $e');
      return [];
    }
  }

  /// Revoke a specific token
  Future<bool> revokeToken(String tokenId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('coach_qr_tokens')
          .delete()
          .eq('id', tokenId)
          .eq('coach_id', user.id);

      return true;
    } catch (e) {
      debugPrint('Error revoking token: $e');
      return false;
    }
  }
}