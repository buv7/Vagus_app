import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/admin/admin_live_session_service.dart';
import '../../models/admin/live_session_models.dart';

class AdminLiveSessionScreen extends StatefulWidget {
  final String userId;
  const AdminLiveSessionScreen({super.key, required this.userId});

  @override
  State<AdminLiveSessionScreen> createState() => _AdminLiveSessionScreenState();
}

class _AdminLiveSessionScreenState extends State<AdminLiveSessionScreen> {
  final _svc = AdminLiveSessionService.instance;
  StreamSubscription<PresenceSnapshot>? _pSub;
  StreamSubscription<NetworkSnapshot>? _nSub;

  PresenceSnapshot? _presence;
  NetworkSnapshot? _net;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pSub = _svc.presence(widget.userId).listen((p) {
      setState(() => _presence = p);
    });
    _nSub = _svc.network(widget.userId).listen((n) {
      setState(() => _net = n);
    });
  }

  @override
  void dispose() {
    unawaited(_pSub?.cancel());
    unawaited(_nSub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _presence;
    final n = _net;
    return Scaffold(
      appBar: AppBar(title: const Text('Live Session')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _Section(title: 'Presence', child: _presenceCard(p)),
          const SizedBox(height: 10),
          _Section(title: 'Network', child: _networkRow(n)),
          const SizedBox(height: 10),
          _Section(title: 'Incident Tools', child: _tools()),
          const SizedBox(height: 10),
          _Section(title: 'Read-only Preview', child: _previewChooser()),
        ],
      ),
    );
  }

  Widget _presenceCard(PresenceSnapshot? p) {
    final status = p?.status ?? PresenceStatus.offline;
    final color = switch (status) {
      PresenceStatus.online => Colors.green,
      PresenceStatus.idle => Colors.orange,
      PresenceStatus.offline => Colors.red,
    };
    return Card(
      child: ListTile(
        leading: Icon(Icons.circle, color: color, size: 14),
        title: Text('Status: ${status.name.toUpperCase()}'),
        subtitle: Text('Last seen: ${p?.lastSeen.toLocal() ?? '-'}  ${p?.note ?? ''}'),
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _networkRow(NetworkSnapshot? n) {
    Widget stat(String label, String value) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: .06),
          border: Border.all(color: Colors.blue.withValues(alpha: .16)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(value),
          ],
        ),
      ),
    );
    return Row(
      children: [
        stat('Ping', '${n?.pingMs ?? 0} ms'),
        const SizedBox(width: 8),
        stat('Jitter', '${n?.jitterMs ?? 0} ms'),
        const SizedBox(width: 8),
        stat('Down', '${n?.downKbps ?? 0} kbps'),
        const SizedBox(width: 8),
        stat('Up', '${n?.upKbps ?? 0} kbps'),
      ],
    );
  }

  Widget _tools() {
    Future<void> run(Future<bool> Function() op, String okLabel) async {
      setState(() => _busy = true);
      final ok = await op();
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '$okLabel ✓' : '$okLabel failed')),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _btn('Push test', Icons.notifications_active, () async {
          setState(() => _busy = true);
          final res = await _svc.pushTest(
            widget.userId,
            title: 'Vagus Test',
            body: 'Hello from Admin',
          );
          if (!mounted) return;
          setState(() => _busy = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.sent ? 'Sent ${res.messageId}' : 'Failed')),
          );
        }),
        _btn('Send deep link', Icons.link,
            () => run(() => _svc.sendDeepLink(widget.userId, 'vagus://open/workout'), 'Deep link sent')),
        _btn('Banner 60s', Icons.campaign, () => run(
            () => _svc.broadcastBanner(widget.userId, 'We are assisting your session', seconds: 60),
            'Banner dispatched')),
        _btn('Refresh config', Icons.sync,
            () => run(() => _svc.refreshRemoteConfig(widget.userId), 'Config refreshed')),
      ],
    );
  }

  Widget _btn(String label, IconData icon, Future<void> Function() onTap) =>
      FilledButton.tonalIcon(
        onPressed: _busy ? null : () => unawaited(onTap()),
        icon: Icon(icon),
        label: Text(label),
      );

  // Read-only, safe previews of key UI surfaces for rapid reproduction.
  Widget _previewChooser() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Open a read-only preview of common surfaces. (No writes performed.)'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _openPreview('/nutrition'),
              icon: const Icon(Icons.local_dining),
              label: const Text('Nutrition'),
            ),
            OutlinedButton.icon(
              onPressed: () => _openPreview('/workout'),
              icon: const Icon(Icons.fitness_center),
              label: const Text('Workout'),
            ),
            OutlinedButton.icon(
              onPressed: () => _openPreview('/calendar'),
              icon: const Icon(Icons.event),
              label: const Text('Calendar'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openPreview(String route) async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: Text('Read-only preview: $route'),
                ),
                const Divider(height: 1),
                const Expanded(
                  child: Center(
                    child: Text('Preview stub — wire to real read-only builders later.'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          child,
        ],
      );
}
