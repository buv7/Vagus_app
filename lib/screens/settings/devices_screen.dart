import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _devices = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Please sign in to view your devices.';
      });
      return;
    }

    try {
      final rows = await _supabase
          .from('user_devices')
          .select()
          .eq('user_id', user.id)
          .order('updated_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _devices = List<Map<String, dynamic>>.from(
          (rows as List).map((r) => Map<String, dynamic>.from(r as Map)),
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _removeDevice(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove device?'),
        content: const Text(
          'You will stop receiving notifications on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _supabase.from('user_devices').delete().eq('id', id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device removed')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: DesignTokens.danger,
        ),
      );
    }
  }

  IconData _platformIcon(String? platform) {
    switch (platform) {
      case 'ios':
        return Icons.phone_iphone;
      case 'android':
        return Icons.phone_android;
      case 'web':
        return Icons.desktop_windows;
      default:
        return Icons.devices_other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: DesignTokens.danger, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final session = _supabase.auth.currentSession;
    final currentUser = _supabase.auth.currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: DesignTokens.success),
            title: const Text('This device'),
            subtitle: Text(
              currentUser?.email ?? 'Current session',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: session != null
                ? const Text('Active', style: TextStyle(color: DesignTokens.success))
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Registered devices',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        if (_devices.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.devices_other,
                      size: 48, color: DesignTokens.mediumGrey),
                  SizedBox(height: 12),
                  Text(
                    'No other devices registered',
                    style: TextStyle(
                      color: DesignTokens.mediumGrey,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._devices.map((d) {
            final model = (d['device_model'] ?? '').toString();
            final platform = (d['platform'] ?? '').toString();
            final version = (d['app_version'] ?? '').toString();
            final updated = d['updated_at']?.toString();
            final subtitleParts = <String>[];
            if (platform.isNotEmpty) subtitleParts.add(platform);
            if (version.isNotEmpty) subtitleParts.add('v$version');
            if (updated != null && updated.isNotEmpty) {
              subtitleParts.add('last seen ${_formatDate(updated)}');
            }
            return Card(
              child: ListTile(
                leading: Icon(_platformIcon(platform)),
                title: Text(model.isEmpty ? 'Unknown device' : model),
                subtitle: subtitleParts.isEmpty
                    ? null
                    : Text(subtitleParts.join(' • ')),
                trailing: IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeDevice(d['id'].toString()),
                ),
              ),
            );
          }),
      ],
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
