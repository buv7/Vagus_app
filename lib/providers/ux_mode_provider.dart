import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import '../services/ux/ux_mode_service.dart';

/// App-wide provider for the adaptive UX mode.
///
/// Wire up in main.dart via MultiProvider, then read in widgets:
///   `context.watch<UxModeProvider>().mode`
///   `context.read<UxModeProvider>().setOverride(UxMode.insane)`
///
/// This provider also observes the app lifecycle to accumulate foreground
/// usage hours, and detects threshold crossings so the UI can prompt the
/// user to promote or demote their experience level.
class UxModeProvider extends ChangeNotifier with WidgetsBindingObserver {
  UxMode _mode = UxMode.simple;
  UxMode _autoMode = UxMode.simple;
  UxMode? _overrideMode;
  bool _isLoaded = false;

  // Pending prompts: set when a threshold crossing is detected.
  // The UI picks these up and shows the appropriate dialog.
  UxMode? _pendingPromotion; // auto mode crossed upward into this
  bool _pendingDemotion = false;

  UxMode get mode => _mode;
  UxMode get autoMode => _autoMode;
  UxMode? get overrideMode => _overrideMode;
  bool get isLoaded => _isLoaded;
  bool get isOverridden => _overrideMode != null;
  UxMode? get pendingPromotion => _pendingPromotion;
  bool get pendingDemotion => _pendingDemotion;

  UxModeProvider() {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    await UxModeService.instance.onSessionStart();
    final result = await UxModeService.instance.loadMode();
    _autoMode = result.auto;
    _overrideMode = result.override;
    _mode = result.effective;
    _isLoaded = true;
    notifyListeners();

    // Check demotion eligibility on startup (non-blocking).
    unawaited(_checkDemotion());
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        UxModeService.instance.onSessionStart();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _onBackground();
        break;
      default:
        break;
    }
  }

  Future<void> _onBackground() async {
    final newHours = await UxModeService.instance.onSessionEnd();
    final newAuto = UxModeService.instance.computeAutoMode(newHours);

    // Detect upward threshold crossing (only if user hasn't set an override).
    if (_overrideMode == null && newAuto > _autoMode) {
      final alreadySeen = await UxModeService.instance.hasSeenPromotion(
        _autoMode,
        newAuto,
      );
      if (!alreadySeen) {
        _pendingPromotion = newAuto;
        notifyListeners();
      }
    }

    _autoMode = newAuto;
    if (_overrideMode == null) {
      _mode = _autoMode;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Set an explicit user override. Pass null to revert to auto.
  Future<void> setOverride(UxMode? mode) async {
    _overrideMode = mode;
    _mode = mode ?? _autoMode;
    notifyListeners();
    await UxModeService.instance.saveOverride(mode);
  }

  /// Called by the UI after showing a promotion prompt.
  Future<void> dismissPromotion({required bool accepted}) async {
    final from = _autoMode;
    final to = _pendingPromotion;
    if (to == null) return;

    await UxModeService.instance.markPromotionSeen(from, to);

    if (accepted) {
      await setOverride(to);
    }
    _pendingPromotion = null;
    notifyListeners();
  }

  /// Called by the UI after showing a demotion suggestion.
  Future<void> dismissDemotion({required bool accepted}) async {
    _pendingDemotion = false;
    if (accepted) {
      await setOverride(UxMode.default_);
    }
    notifyListeners();
  }

  /// Record that the user touched an advanced feature (resets demotion clock).
  void recordAdvancedFeatureUse() {
    UxModeService.instance.recordAdvancedFeatureUse();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _checkDemotion() async {
    final should = await UxModeService.instance.shouldSuggestDemotion(_mode);
    if (should) {
      _pendingDemotion = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
