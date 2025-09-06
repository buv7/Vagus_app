import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/admin/session_models.dart';
import '../../services/admin/admin_session_service.dart';

class AdminSessionCopilotScreen extends StatefulWidget {
  final String userId;
  const AdminSessionCopilotScreen({super.key, required this.userId});

  @override
  State<AdminSessionCopilotScreen> createState() => _AdminSessionCopilotScreenState();
}

class _AdminSessionCopilotScreenState extends State<AdminSessionCopilotScreen> {
  final _svc = AdminSessionService.instance;
  UserDiagnostics? _dx;
  bool _loading = false;
  final _logs = ValueNotifier<String>(''); // display recent logs

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await _svc.loadDiagnostics(widget.userId);
    if (!mounted) return;
    setState(() {
      _dx = r;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dx = _dx;
    return Scaffold(
      appBar: AppBar(title: const Text('Session Co-Pilot')),
      body: dx == null
          ? (_loading
              ? const LinearProgressIndicator()
              : const Center(child: Text('No data')))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _Section(title: 'User', child: _userHeader(dx)),
                const SizedBox(height: 10),
                _Section(title: 'Devices', child: _devices(dx)),
                const SizedBox(height: 10),
                _Section(title: 'Quick Tools', child: _tools(dx)),
                const SizedBox(height: 10),
                _Section(title: 'Flags', child: _flags(dx)),
                const SizedBox(height: 10),
                _Section(title: 'Recent Logs', child: _logsViewer()),
              ],
            ),
    );
  }

  Widget _userHeader(UserDiagnostics dx) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text('${dx.email} • ${dx.role.toUpperCase()}'),
      subtitle: Text('Plan: ${dx.plan} • TZ: ${dx.timezone} • Locale: ${dx.locale}'),
      trailing: IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => unawaited(_load()),
      ),
    );
  }

  Widget _devices(UserDiagnostics dx) {
    if (dx.devices.isEmpty) return const Text('No devices');
    return Column(
      children: dx.devices.map((d) => Card(
        child: ListTile(
          leading: const Icon(Icons.devices),
          title: Text('${d.model} • ${d.platform.name.toUpperCase()}'),
          subtitle: Text(
            'OS ${d.osVersion} • App ${d.appVersion} (${d.buildNumber}) • Last seen ${d.lastSeen}',
          ),
          trailing: FilledButton.tonal(
            onPressed: () async {
              final ok = await _svc.pingDevice(dx.userId, d.deviceId);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? 'Ping sent' : 'Ping failed')),
              );
            },
            child: const Text('Ping'),
          ),
        ),
      )).toList(),
    );
  }

  Widget _tools(UserDiagnostics dx) {
    Future<void> run(Future<bool> Function() op, String label) async {
      final ok = await op();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '$label ✓' : '$label failed')),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip('Force refresh', Icons.sync,
            () => run(() => _svc.forceRefreshConfig(dx.userId), 'Refreshed')),
        _chip('Flush cache', Icons.cleaning_services,
            () => run(() => _svc.flushCache(dx.userId), 'Cache flushed')),
        _chip('Reset streaks', Icons.local_fire_department,
            () => run(() => _svc.resetStreaks(dx.userId), 'Streaks reset')),
        _chip('Reindex', Icons.manage_search,
            () => run(() => _svc.reindexSearch(dx.userId), 'Reindexed')),
        _chip('Pwd reset', Icons.lock_reset,
            () => run(() => _svc.sendPasswordReset(dx.userId), 'Email sent')),
        _chip('Invalidate sessions', Icons.no_accounts,
            () => run(() => _svc.invalidateSessions(dx.userId), 'Sessions invalidated')),
        _chip('Pull logs', Icons.article, () async {
          final txt = await _svc.pullRecentLogs(dx.userId);
          _logs.value = txt;
        }),
      ],
    );
  }

  Widget _chip(String label, IconData icon, Future<void> Function() onTap) =>
      ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: () => unawaited(onTap()),
      );

  Widget _flags(UserDiagnostics dx) {
    var f = dx.flags;
    Future<void> save() async {
      await _svc.setFlag(dx.userId, f);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flags updated')),
      );
      unawaited(_load());
    }

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Verbose logging'),
          value: f.verboseLogging,
          onChanged: (v) => setState(() => f = f.copyWith(verboseLogging: v)),
        ),
        SwitchListTile(
          title: const Text('Beta Nutrition'),
          value: f.betaNutrition,
          onChanged: (v) => setState(() => f = f.copyWith(betaNutrition: v)),
        ),
        SwitchListTile(
          title: const Text('Beta Music'),
          value: f.betaMusic,
          onChanged: (v) => setState(() => f = f.copyWith(betaMusic: v)),
        ),
        SwitchListTile(
          title: const Text('Force lite animations'),
          value: f.forceLiteAnimations,
          onChanged: (v) => setState(() => f = f.copyWith(forceLiteAnimations: v)),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => unawaited(save()),
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }

  Widget _logsViewer() {
    return ValueListenableBuilder<String>(
      valueListenable: _logs,
      builder: (_, v, __) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withValues(alpha: .16)),
        ),
        child: Text(v.isEmpty ? 'No logs pulled yet.' : v),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
