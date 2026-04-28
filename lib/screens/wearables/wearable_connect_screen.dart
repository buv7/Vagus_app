import 'package:flutter/material.dart';
import '../../services/wearables/wearable_service.dart';
import '../../theme/design_tokens.dart';

class WearableConnectScreen extends StatefulWidget {
  const WearableConnectScreen({super.key});

  @override
  State<WearableConnectScreen> createState() => _WearableConnectScreenState();
}

class _WearableConnectScreenState extends State<WearableConnectScreen> {
  final _service = WearableService.instance;
  Map<WearableProvider, bool> _connected = {};
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final statuses = <WearableProvider, bool>{};
    for (final p in WearableProvider.values) {
      statuses[p] = await _service.isConnected(p);
    }
    if (mounted) setState(() { _connected = statuses; _loading = false; });
  }

  Future<void> _toggle(WearableProvider provider, bool on) async {
    setState(() => _loading = true);
    if (on) {
      await _service.connect(provider);
    } else {
      await _service.disconnect(provider);
    }
    await _refresh();
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    await _service.syncAll();
    if (mounted) {
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync complete'),
          backgroundColor: DesignTokens.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wearable Connections'),
        backgroundColor: DesignTokens.ink50,
        foregroundColor: DesignTokens.ink900,
        actions: [
          if (_syncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.space16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sync now',
              onPressed: _syncNow,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: DesignTokens.accentGreen))
          : ListView(
              padding: const EdgeInsets.all(DesignTokens.space16),
              children: [
                const _SectionHeader(
                  title: 'Free — On-device',
                  subtitle: 'Reads health data directly from your phone. No account needed.',
                ),
                ..._deviceProviders(),
                const SizedBox(height: DesignTokens.space24),
                const _SectionHeader(
                  title: 'Pro+ — Cloud wearables',
                  subtitle: 'Requires a Pro subscription. OAuth approvals in progress.',
                ),
                ..._cloudProviders(),
                const SizedBox(height: DesignTokens.space24),
                _PrivacyNote(),
              ],
            ),
    );
  }

  List<Widget> _deviceProviders() {
    return [
      WearableProvider.appleHealth,
      WearableProvider.healthConnect,
    ].map((p) => _ProviderCard(
          provider: p,
          connected: _connected[p] ?? false,
          onToggle: (v) => _toggle(p, v),
        )).toList();
  }

  List<Widget> _cloudProviders() {
    return [
      WearableProvider.garmin,
      WearableProvider.whoop,
      WearableProvider.oura,
    ].map((p) => _ProviderCard(
          provider: p,
          connected: _connected[p] ?? false,
          onToggle: (v) => _toggle(p, v),
          comingSoon: true,
        )).toList();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle}); // ignore: unused_element

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: DesignTokens.titleMedium
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: DesignTokens.space4),
          Text(subtitle,
              style: DesignTokens.bodySmall
                  .copyWith(color: DesignTokens.ink500)),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final WearableProvider provider;
  final bool connected;
  final ValueChanged<bool> onToggle;
  final bool comingSoon;

  const _ProviderCard({
    required this.provider,
    required this.connected,
    required this.onToggle,
    this.comingSoon = false,
  });

  IconData get _icon {
    switch (provider) {
      case WearableProvider.appleHealth:
        return Icons.apple;
      case WearableProvider.healthConnect:
        return Icons.health_and_safety;
      case WearableProvider.garmin:
        return Icons.watch;
      case WearableProvider.whoop:
        return Icons.monitor_heart;
      case WearableProvider.oura:
        return Icons.circle_outlined;
    }
  }

  Color get _color {
    if (comingSoon) return DesignTokens.ink400;
    return connected ? DesignTokens.success : DesignTokens.ink600;
  }

  @override
  Widget build(BuildContext context) {
    final osSupported = provider.isOsSupported;

    return Card(
      margin: const EdgeInsets.only(bottom: DesignTokens.space8),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: Icon(_icon, color: _color, size: 22),
            ),
            const SizedBox(width: DesignTokens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.displayName,
                    style: DesignTokens.titleSmall
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    comingSoon
                        ? 'Coming soon — awaiting OAuth approval'
                        : !osSupported
                            ? 'Not available on this device'
                            : connected
                                ? 'Connected'
                                : 'Not connected',
                    style: DesignTokens.bodySmall.copyWith(
                      color: comingSoon
                          ? DesignTokens.ink400
                          : connected
                              ? DesignTokens.success
                              : DesignTokens.ink500,
                    ),
                  ),
                ],
              ),
            ),
            if (comingSoon)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space8,
                    vertical: DesignTokens.space4),
                decoration: BoxDecoration(
                  color: DesignTokens.ink100,
                  borderRadius: BorderRadius.circular(DesignTokens.radius4),
                ),
                child: Text('Pro+',
                    style: DesignTokens.labelSmall
                        .copyWith(color: DesignTokens.ink600)),
              )
            else if (osSupported)
              Switch(
                value: connected,
                onChanged: onToggle,
                activeColor: DesignTokens.success,
              ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: DesignTokens.ink50,
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        border: Border.all(color: DesignTokens.ink100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline,
                  size: 16, color: DesignTokens.ink500),
              const SizedBox(width: DesignTokens.space8),
              Text('Privacy & Data',
                  style: DesignTokens.labelMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            'Sleep, HRV, and VO₂ max are stored encrypted. '
            'Syncs automatically every 4 hours. '
            'Your coach sees daily summary data only — never raw streams. '
            'Disconnect any source at any time.',
            style: DesignTokens.bodySmall.copyWith(color: DesignTokens.ink600),
          ),
        ],
      ),
    );
  }
}
