import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/account_switcher.dart';
import 'auth/premium_login_screen.dart';
import '../theme/design_tokens.dart';

class AccountSwitchScreen extends StatefulWidget {
  const AccountSwitchScreen({super.key});

  @override
  State<AccountSwitchScreen> createState() => _AccountSwitchScreenState();
}

class _AccountSwitchScreenState extends State<AccountSwitchScreen> {
  List<SavedAccount> _accounts = [];
  String? _activeId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accounts = await AccountSwitcher.instance.loadAccounts();
    final active = await AccountSwitcher.instance.getActiveUserId();
    setState(() {
      _accounts = accounts;
      _activeId = active;
      _loading = false;
    });
  }

  Future<void> _switch(SavedAccount a) async {
    try {
      await AccountSwitcher.instance.switchTo(a);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to ${a.email}')),
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't switch — please sign in again")),
      );
    }
  }

  Future<void> _remove(SavedAccount a) async {
    await AccountSwitcher.instance.removeAccount(a.userId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0B1220),
        elevation: 0,
        title: Text(
          'Switch Accounts',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0B1220),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: DesignTokens.accentBlue))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_accounts.isEmpty)
                  _buildEmptyState()
                else
                  ..._accounts.map((a) => _buildAccountTile(a)),
                const SizedBox(height: 8),
                _buildAddAccountTile(),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return _buildGlassmorphicCard(
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No saved accounts',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add an account to switch between them',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(SavedAccount a) {
    final active = a.userId == _activeId;
    return _buildGlassmorphicCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DesignTokens.accentBlue.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: DesignTokens.accentBlue.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                a.email.isNotEmpty ? a.email[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.email,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  a.role.isEmpty ? 'client' : a.role,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (active)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00D4AA).withValues(alpha: 0.5),
                ),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  color: Color(0xFF00D4AA),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            _buildSmallButton(
              label: 'Switch',
              onPressed: () => _switch(a),
            ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.7)),
            color: DesignTokens.accentBlue.withValues(alpha: 0.9),
            onSelected: (v) {
              if (v == 'remove') _remove(a);
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red.withValues(alpha: 0.8), size: 20),
                    const SizedBox(width: 8),
                    const Text('Remove', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddAccountTile() {
    return _buildGlassmorphicCard(
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumLoginScreen()));
          await _load();
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.person_add_alt,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Add account',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallButton({required String label, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.accentBlue.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: DesignTokens.accentBlue.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 2.0,
                colors: [
                  DesignTokens.accentBlue.withValues(alpha: 0.25),
                  DesignTokens.accentBlue.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DesignTokens.accentBlue.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.accentBlue.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
