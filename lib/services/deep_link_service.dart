import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import '../screens/coach_profile/coach_profile_screen.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// Initialize deep link listening
  void initialize(BuildContext context) {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        if (context.mounted) {
          handleDeepLink(uri.toString(), context);
        }
      },
      onError: (err) => debugPrint('Deep link error: $err'),
    );

    // Handle initial link when app is opened from a deep link
    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null && context.mounted) {
        handleDeepLink(uri.toString(), context);
      }
    });
  }

  /// Handle deep link navigation
  Future<void> handleDeepLink(String link, BuildContext context) async {
    try {
      final uri = Uri.parse(link);
      
      if (uri.scheme != 'vagus') {
        // Try to extract vagus:// from web URLs
        if (link.contains('vagus://')) {
          final vagusIndex = link.indexOf('vagus://');
          final vagusLink = link.substring(vagusIndex);
          return handleDeepLink(vagusLink, context);
        }
        return;
      }

      switch (uri.host) {
        case 'coach':
          await _handleCoachLink(uri, context);
          break;
        case 'qr':
          await _handleQRLink(uri, context);
          break;
        default:
          debugPrint('Unknown deep link host: ${uri.host}');
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
      if (context.mounted) {
        _showError(context, 'Invalid link format');
      }
    }
  }

  /// Handle coach profile deep links: vagus://coach/[username]
  Future<void> _handleCoachLink(Uri uri, BuildContext context) async {
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) {
      _showError(context, 'Invalid coach link');
      return;
    }

    final username = pathSegments.first;
    
    try {
      // Find coach by username
      final response = await _supabase
          .from('profiles')
          .select('''
            id, name, email, username,
            coach_profiles!inner(
              display_name, headline, bio, specialties, intro_video_url
            )
          ''')
          .eq('role', 'coach')
          .eq('username', username)
          .maybeSingle();

      if (response == null) {
        if (context.mounted) {
          _showError(context, 'Coach @$username not found');
        }
        return;
      }

      // Navigate to coach profile
      if (context.mounted) {
        unawaited(Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CoachProfileScreen(
              coachId: response['id'],
              isPublicView: true,
            ),
          ),
        ));
      }
    } catch (e) {
      debugPrint('Error loading coach profile: $e');
      if (context.mounted) {
        _showError(context, 'Failed to load coach profile');
      }
    }
  }

  /// Handle QR token deep links: vagus://qr/[token]
  Future<void> _handleQRLink(Uri uri, BuildContext context) async {
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) {
      _showError(context, 'Invalid QR link');
      return;
    }

    final token = pathSegments.first;
    
    try {
      // Resolve QR token
      final response = await _supabase.rpc('resolve_qr_token', params: {
        'p_token': token,
      });

      if (response == null || response.isEmpty) {
        if (context.mounted) {
          _showError(context, 'QR code expired or invalid');
        }
        return;
      }

      final coachData = response.first;
      
      // Navigate to coach profile
      if (context.mounted) {
        unawaited(Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CoachProfileScreen(
              coachId: coachData['coach_id'],
              isPublicView: true,
            ),
          ),
        ));
      }
    } catch (e) {
      debugPrint('Error resolving QR token: $e');
      if (context.mounted) {
        _showError(context, 'Failed to resolve QR code');
      }
    }
  }

  /// Generate a deep link for a coach username
  String generateCoachLink(String username) {
    return 'vagus://coach/$username';
  }

  /// Generate a QR token deep link
  String generateQRLink(String token) {
    return 'vagus://qr/$token';
  }

  /// Generate a shareable web URL that redirects to deep link
  String generateShareableLink(String deepLink) {
    // This would typically be your web domain that redirects to the deep link
    // For now, just return the deep link
    return deepLink;
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
  }
}
