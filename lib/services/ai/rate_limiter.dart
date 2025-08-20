import 'dart:async';
import 'ai_usage_service.dart';

class RateLimiter {
  static final RateLimiter _instance = RateLimiter._internal();
  factory RateLimiter() => _instance;
  RateLimiter._internal();

  final Map<String, _TokenBucket> _buckets = {};
  final AIUsageService _usageService = AIUsageService();

  // Default limits per minute (fallback if usage service unavailable)
  static const Map<String, int> _defaultLimits = {
    'chat': 30,
    'embedding': 100,
    'notes.summarize': 20,
    'notes.tags': 20,
    'notes.dupdetect': 10,
    'workout.suggest': 15,
    'workout.deload': 10,
    'workout.weakpoint': 10,
    'calendar.tagger': 20,
    'messaging.reply': 30,
  };

  Future<bool> tryConsume(String task, {int tokens = 1}) async {
    try {
      // Get limit from usage service or use default
      int limit;
      try {
        final plan = await _usageService.getCurrentPlan();
        limit = _getPlanLimit(task, plan);
      } catch (e) {
        limit = _defaultLimits[task] ?? 10;
      }

      // Get or create bucket for this task
      final bucket = _buckets.putIfAbsent(
        task,
        () => _TokenBucket(limit, Duration(minutes: 1)),
      );

      return bucket.tryConsume(tokens);
    } catch (e) {
      // On any error, allow the request (fail open)
      return true;
    }
  }

  int _getPlanLimit(String task, String plan) {
    // Plan-aware limits (multiply defaults based on plan)
    switch (plan.toLowerCase()) {
      case 'premium':
        return (_defaultLimits[task] ?? 10) * 3;
      case 'pro':
        return (_defaultLimits[task] ?? 10) * 2;
      case 'basic':
      default:
        return _defaultLimits[task] ?? 10;
    }
  }

  void reset(String task) {
    _buckets.remove(task);
  }

  void resetAll() {
    _buckets.clear();
  }
}

class _TokenBucket {
  final int capacity;
  final Duration refillTime;
  int _tokens;
  DateTime _lastRefill;

  _TokenBucket(this.capacity, this.refillTime)
      : _tokens = capacity,
        _lastRefill = DateTime.now();

  bool tryConsume(int tokens) {
    _refill();

    if (_tokens >= tokens) {
      _tokens -= tokens;
      return true;
    }

    return false;
  }

  void _refill() {
    final now = DateTime.now();
    final timePassed = now.difference(_lastRefill);
    final refillAmount = (timePassed.inMilliseconds / refillTime.inMilliseconds * capacity).floor();

    if (refillAmount > 0) {
      _tokens = (_tokens + refillAmount).clamp(0, capacity);
      _lastRefill = now;
    }
  }

  int get availableTokens => _tokens;
}
