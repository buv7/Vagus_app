import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/error/shield_store.dart';
import '../theme/design_tokens.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  PackageInfo? _packageInfo;
  List<ConnectivityResult> _connectivity = [ConnectivityResult.none];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    final conn = await Connectivity().checkConnectivity();
    if (!mounted) return;
    setState(() {
      _packageInfo = info;
      _connectivity = conn;
    });

    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (mounted) setState(() => _connectivity = result);
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  String get _networkLabel {
    if (_connectivity.contains(ConnectivityResult.wifi)) return 'Wi-Fi';
    if (_connectivity.contains(ConnectivityResult.mobile)) return 'Mobile';
    if (_connectivity.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    if (_connectivity.contains(ConnectivityResult.none)) return 'Offline';
    return 'Unknown';
  }

  Color get _networkColor {
    if (_connectivity.contains(ConnectivityResult.none)) {
      return Colors.redAccent;
    }
    return const Color(0xFF00C8FF);
  }

  @override
  Widget build(BuildContext context) {
    final store = ShieldStore.instance;
    final lastError = store.lastError;
    final lastSync = store.lastSyncTime;

    return Scaffold(
      backgroundColor: DesignTokens.darkBackground,
      appBar: AppBar(
        backgroundColor: DesignTokens.darkBackground,
        title: const Text(
          'Diagnostics',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0080FF)),
            onPressed: _load,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Network', Icons.wifi, [
            _row('Status', _networkLabel, valueColor: _networkColor),
          ]),
          const SizedBox(height: 12),
          _section('Sync', Icons.sync, [
            _row(
              'Pending items',
              store.pendingSyncItems.toString(),
              valueColor: store.pendingSyncItems > 0
                  ? Colors.orangeAccent
                  : const Color(0xFF00C8FF),
            ),
            _row(
              'Last sync',
              lastSync != null ? _formatTime(lastSync) : 'Never',
            ),
          ]),
          const SizedBox(height: 12),
          _section('Last Error', Icons.error_outline, [
            if (lastError == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('No errors recorded',
                    style: TextStyle(color: Color(0x99FFFFFF))),
              )
            else ...[
              _row('Time', _formatTime(lastError.timestamp)),
              if (lastError.context != null)
                _row('Context', lastError.context!),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  lastError.message,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ]),
          const SizedBox(height: 12),
          _section('Build', Icons.info_outline, [
            _row('Version', _packageInfo != null
                ? '${_packageInfo!.version}+${_packageInfo!.buildNumber}'
                : '…'),
            _row('Package', _packageInfo?.packageName ?? '…'),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A14),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: DesignTokens.accentBlue.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: DesignTokens.accentBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
