import 'dart:convert';
import 'dart:collection';
import 'package:crypto/crypto.dart';

class AICache {
  static final AICache _instance = AICache._internal();
  factory AICache() => _instance;
  AICache._internal();

  static const int maxEntries = 200;
  static const Duration defaultTtl = Duration(minutes: 15);

  final Map<String, _CacheEntry> _cache = {};
  final Queue<String> _accessOrder = Queue<String>();

  Future<T?> get<T>(String key) async {
    final entry = _cache[key];
    if (entry == null) return null;

    // Check if expired
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _remove(key);
      return null;
    }

    // Update access order
    _accessOrder.remove(key);
    _accessOrder.addLast(key);

    return entry.value as T;
  }

  void set<T>(String key, T value, {Duration? ttl}) {
    final expiresAt = DateTime.now().add(ttl ?? defaultTtl);

    // Remove if already exists
    if (_cache.containsKey(key)) {
      _remove(key);
    }

    // Evict oldest if at capacity
    if (_cache.length >= maxEntries) {
      final oldestKey = _accessOrder.removeFirst();
      _cache.remove(oldestKey);
    }

    // Add new entry
    _cache[key] = _CacheEntry(value, expiresAt);
    _accessOrder.addLast(key);
  }

  void _remove(String key) {
    _cache.remove(key);
    _accessOrder.remove(key);
  }

  String cacheKeyFor({
    required String task,
    required String model,
    required String inputOrPrompt,
  }) {
    // Normalize input to avoid huge keys
    final normalizedInput = inputOrPrompt.trim().toLowerCase();
    
    // Create hash of the normalized input
    final hash = sha256.convert(utf8.encode(normalizedInput)).toString();
    
    return '$task|$model|$hash';
  }

  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  int get size => _cache.length;
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  _CacheEntry(this.value, this.expiresAt);
}
