import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized accessor for the currently authenticated user.
///
/// All user-scoped reads/writes must source the user ID from here, never from
/// a hardcoded placeholder. Use [currentUserId] when the call site requires
/// auth (a missing user is a bug); use [currentUserIdOrNull] / [currentUserOrNull]
/// for optional paths (UI gating, anonymous flows).
///
/// Wraps [Supabase.instance.client.auth] so tests and refactors can swap the
/// backing client in one place if needed.
class AuthContext {
  AuthContext._();

  static GoTrueClient get _auth => Supabase.instance.client.auth;

  /// The currently authenticated user's ID.
  ///
  /// Throws [AuthException] when no user is signed in. Callers in user-scoped
  /// code paths (RLS-bound queries, writes) should use this getter — a thrown
  /// exception surfaces the missing-auth bug instead of silently returning an
  /// empty string or a literal placeholder.
  static String get currentUserId {
    final id = _auth.currentUser?.id;
    if (id == null) {
      throw const AuthException('not signed in');
    }
    return id;
  }

  /// The currently authenticated user, or null if no session.
  static User? get currentUserOrNull => _auth.currentUser;

  /// The currently authenticated user's ID, or null if no session.
  static String? get currentUserIdOrNull => _auth.currentUser?.id;

  /// True when a user session exists.
  static bool get isSignedIn => _auth.currentUser != null;

  /// Auth state stream — emits on sign-in, sign-out, token refresh, etc.
  /// Use this to rebuild widgets that depend on the active user.
  static Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;
}
