import 'package:flutter/material.dart';
import '../services/account_switcher.dart';
import 'auth/login_screen.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Switch Accounts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 12),
                ..._accounts.map((a) {
                  final active = a.userId == _activeId;
                  return ListTile(
                    leading: CircleAvatar(child: Text(a.email.isNotEmpty ? a.email[0].toUpperCase() : '?')),
                    title: Text(a.email),
                    subtitle: Text(a.role.isEmpty ? 'client' : a.role),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (active)
                          const Chip(label: Text('Active'))
                        else
                          TextButton(
                            onPressed: () => _switch(a),
                            child: const Text('Switch'),
                          ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'remove') _remove(a);
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'remove', child: Text('Remove')),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_add_alt),
                  title: const Text('Add account'),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                    await _load();
                  },
                )
              ],
            ),
    );
  }
}


