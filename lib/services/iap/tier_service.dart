import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/subscription/tier.dart';

/// Single source of truth for the user's current subscription tier.
///
/// Reads from the `subscriptions` table (server is authority).
/// Notifies listeners within 5 seconds of a purchase completing.
class TierService extends ChangeNotifier {
  TierService._();
  static final TierService instance = TierService._();

  SubscriptionState _state = SubscriptionState.free;
  bool _initialized = false;
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSub;

  SubscriptionState get currentState => _state;
  SubscriptionTier get currentTier => _state.tier;

  bool get isPro => _state.tier == SubscriptionTier.pro ||
      _state.tier == SubscriptionTier.ultimate;
  bool get isUltimate => _state.tier == SubscriptionTier.ultimate;
  bool get isTrial => _state.isTrial && _state.isActive;

  /// Initialize once after Supabase is ready. Attaches a realtime listener
  /// so the UI updates within seconds of server-side validation completing.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
    _attachRealtime();
  }

  /// Pull the latest subscription row from the database.
  Future<void> refresh() async {
    try {
      final userId =
          Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _update(SubscriptionState.free);
        return;
      }

      final row = await Supabase.instance.client
          .from('subscriptions')
          .select(
            'plan_code, status, period_end, apple_expires_at, is_trial, platform',
          )
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row == null) {
        _update(SubscriptionState.free);
        return;
      }

      final state = SubscriptionState.fromMap(row);

      // Treat expired subscriptions as free regardless of DB row.
      if (state.expiresAt != null &&
          state.expiresAt!.isBefore(DateTime.now()) &&
          !state.isTrial) {
        _update(SubscriptionState.free);
      } else {
        _update(state);
      }
    } catch (e) {
      debugPrint('TierService.refresh error: $e');
      // Fail closed: keep whatever state we had rather than grant access.
    }
  }

  void _update(SubscriptionState newState) {
    if (_state.tier == newState.tier && _state.status == newState.status) {
      return;
    }
    _state = newState;
    notifyListeners();
  }

  void _attachRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // ignore: discarded_futures
    _realtimeSub = Supabase.instance.client
        .from('subscriptions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen(
          (rows) {
            if (rows.isEmpty) {
              _update(SubscriptionState.free);
              return;
            }
            final state = SubscriptionState.fromMap(rows.first);
            _update(state);
          },
          onError: (e) =>
              debugPrint('TierService realtime error: $e'),
        );
  }

  /// Re-init when the auth user changes (sign-out → sign-in).
  Future<void> onAuthStateChange() async {
    await _realtimeSub?.cancel();
    _realtimeSub = null;
    _initialized = false;
    _state = SubscriptionState.free;
    await init();
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }
}
