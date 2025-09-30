import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Append-only AccountSwitcher – stores multiple Supabase sessions locally and switches fast

class SavedAccount {
  final String userId;
  final String email;
  final String? avatarUrl;
  final String refreshToken;
  final String accessToken;
  final String role;
  final DateTime savedAt;

  const SavedAccount({
    required this.userId,
    required this.email,
    required this.refreshToken,
    required this.accessToken,
    required this.role,
    required this.savedAt,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'avatarUrl': avatarUrl,
        // never log tokens
        'refreshToken': refreshToken,
        'accessToken': accessToken,
        'role': role,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedAccount.fromJson(Map<String, dynamic> json) => SavedAccount(
        userId: json['userId'] as String,
        email: json['email'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        refreshToken: json['refreshToken'] as String? ?? '',
        accessToken: json['accessToken'] as String? ?? '',
        role: json['role'] as String? ?? 'client',
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class AccountSwitcher {
  AccountSwitcher._();
  static final AccountSwitcher instance = AccountSwitcher._();

  // Secure storage is initialized lazily to avoid MissingPluginException on early calls
  FlutterSecureStorage? _storage; // initialized on demand (not on web)
  Future<FlutterSecureStorage?> _getStorage() async {
    if (kIsWeb) return null; // not supported on web – fallback to SharedPreferences
    _storage ??= const FlutterSecureStorage();
    return _storage;
  }
  final _accountsKey = 'secure:saved_accounts';
  final _activeKey = 'prefs:active_account_id';

  final ValueNotifier<String?> activeUserId = ValueNotifier<String?>(null);
  final ValueNotifier<bool> authChanged = ValueNotifier<bool>(false);

  Future<List<SavedAccount>> loadAccounts() async {
    try {
      final s = await _getStorage();
      if (s == null) {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_accountsKey);
        if (raw == null || raw.isEmpty) return [];
        final list = (jsonDecode(raw) as List)
            .map((e) => SavedAccount.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return list;
      }
      final raw = await s.read(key: _accountsKey);
      if (raw == null || raw.isEmpty) return [];
      final list = (jsonDecode(raw) as List)
          .map((e) => SavedAccount.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return list;
    } catch (e) {
      // Fallback if plugin not ready
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_accountsKey);
        if (raw == null || raw.isEmpty) return [];
        final list = (jsonDecode(raw) as List)
            .map((e) => SavedAccount.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return list;
      } catch (_) {
        return [];
      }
    }
  }

  Future<void> _saveAccounts(List<SavedAccount> accounts) async {
    final jsonList = accounts.map((a) => a.toJson()).toList();
    try {
      final s = await _getStorage();
      if (s == null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accountsKey, jsonEncode(jsonList));
      } else {
        await s.write(key: _accountsKey, value: jsonEncode(jsonList));
      }
    } catch (e) {
      // Fallback to prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accountsKey, jsonEncode(jsonList));
    }
  }

  Future<void> upsertAccount(SavedAccount acc) async {
    final accounts = await loadAccounts();
    final idx = accounts.indexWhere((a) => a.userId == acc.userId);
    if (idx >= 0) {
      accounts[idx] = acc;
    } else {
      accounts.add(acc);
    }
    await _saveAccounts(accounts);
  }

  Future<void> removeAccount(String userId) async {
    final accounts = await loadAccounts();
    accounts.removeWhere((a) => a.userId == userId);
    await _saveAccounts(accounts);
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_activeKey) == userId) {
      await prefs.remove(_activeKey);
      activeUserId.value = null;
    }
  }

  Future<void> setActive(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeKey, userId);
    activeUserId.value = userId;
  }

  Future<String?> getActiveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_activeKey);
    activeUserId.value = id;
    return id;
  }

  Future<void> switchTo(SavedAccount acc) async {
    final supabase = Supabase.instance.client;
    try {
      // Latest Supabase Flutter: setSession expects refresh token (positional)
      await supabase.auth.setSession(acc.refreshToken);
    } catch (_) {
      // try to refresh
      try {
        await supabase.auth.refreshSession();
      } catch (e) {
        if (kDebugMode) {
          // do not log tokens; message only
          // debugPrint('Switch failed: $e');
        }
        rethrow;
      }
    }

    await setActive(acc.userId);
    authChanged.value = !authChanged.value; // notify listeners
  }

  // Capture current session and save locally
  Future<void> captureCurrentSession({String role = 'client', String? avatarUrl}) async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    final user = supabase.auth.currentUser;
    if (session == null || user == null) return;

    final acc = SavedAccount(
      userId: user.id,
      email: user.email ?? '',
      avatarUrl: avatarUrl,
      refreshToken: session.refreshToken ?? '',
      accessToken: session.accessToken,
      role: role,
      savedAt: DateTime.now(),
    );
    await upsertAccount(acc);
    await setActive(user.id);
  }

  // Background refresh on app start
  Future<void> refreshActiveIfPossible() async {
    final supabase = Supabase.instance.client;
    final id = await getActiveUserId();
    if (id == null) return;
    final accounts = await loadAccounts();
    final acc = accounts.firstWhere((a) => a.userId == id, orElse: () =>
        SavedAccount(userId: '', email: '', refreshToken: '', accessToken: '', role: 'client', savedAt: DateTime(1970)));
    if (acc.userId.isEmpty) return;
    try {
      await supabase.auth.refreshSession();
    } catch (_) {
      // mark as needs sign-in by keeping tokens but not blocking
    }
  }

  // Safe init – call after Supabase.initialize()
  Future<void> init() async {
    await loadAccounts();
  }
}


