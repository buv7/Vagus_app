import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Simple in-memory cache for AI responses
/// Helps reduce redundant API calls and improve performance
class AICache {
  // In-memory cache with TTL
  final Map<String, _CacheEntry> _cache = {};

  // Default TTL: 1 hour
  static const Duration _defaultTtl = Duration(hours: 1);

  // Max cache size to prevent memory bloat
  static const int _maxCacheSize = 100;

  /// Generate a cache key from task, model, and input
  String cacheKeyFor({
    required String task,
    required String model,
    required String inputOrPrompt,
  }) {
    // Combine all parameters into a stable string
    final combined = '$task:$model:$inputOrPrompt';

    // Generate hash to keep key length manageable
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);

    return hash.toString();
  }

  /// Get cached value if it exists and hasn't expired
  Future<T?> get<T>(String key) async {
    final entry = _cache[key];

    if (entry == null) {
      return null;
    }

    // Check if expired
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return null;
    }

    return entry.value as T?;
  }

  /// Set a value in the cache with optional TTL
  void set(String key, dynamic value, {Duration? ttl}) {
    // Enforce cache size limit
    if (_cache.length >= _maxCacheSize) {
      _evictOldest();
    }

    final expiresAt = DateTime.now().add(ttl ?? _defaultTtl);
    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: expiresAt,
      createdAt: DateTime.now(),
    );
  }

  /// Clear all cached entries
  void clear() {
    _cache.clear();
  }

  /// Remove expired entries
  void cleanExpired() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => now.isAfter(entry.expiresAt));
  }

  /// Evict the oldest entry to make room
  void _evictOldest() {
    if (_cache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _cache.entries) {
      if (oldestTime == null || entry.value.createdAt.isBefore(oldestTime)) {
        oldestKey = entry.key;
        oldestTime = entry.value.createdAt;
      }
    }

    if (oldestKey != null) {
      _cache.remove(oldestKey);
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    cleanExpired();
    return {
      'size': _cache.length,
      'maxSize': _maxCacheSize,
      'entries': _cache.length,
    };
  }
}

/// Internal cache entry with metadata
class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;
  final DateTime createdAt;

  _CacheEntry({
    required this.value,
    required this.expiresAt,
    required this.createdAt,
  });
}
