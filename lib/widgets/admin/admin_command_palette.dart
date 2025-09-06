import 'package:flutter/material.dart';

class AdminCommandPalette extends StatefulWidget {
  const AdminCommandPalette({super.key});
  @override State<AdminCommandPalette> createState() => _AdminCommandPaletteState();
}

class _AdminCommandPaletteState extends State<AdminCommandPalette> {
  final _q = TextEditingController();
  final _items = <_Cmd>[
    _Cmd('Go: Users', Icons.people_alt, 'users'),
    _Cmd('Go: Support', Icons.mail_outline, 'support'),
    _Cmd('Go: Approvals', Icons.verified_user, 'approvals'),
    _Cmd('Action: Export Users CSV', Icons.download, 'export_users'),
    _Cmd('Action: Create Ticket', Icons.support_agent, 'new_ticket'),
  ];
  @override void dispose() { _q.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((c) => c.title.toLowerCase().contains(_q.text.toLowerCase())).toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _q, autofocus: true, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search commands…')),
          const SizedBox(height: 12),
          ...filtered.map((c) => ListTile(
            leading: Icon(c.icon),
            title: Text(c.title),
            onTap: () { Navigator.pop(context, c.key); /* Handle in AdminHub if needed */ },
          )),
        ]),
      ),
    );
  }
}
class _Cmd { final String title; final IconData icon; final String key; _Cmd(this.title, this.icon, this.key); }
