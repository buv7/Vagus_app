import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  final _supabase = Supabase.instance.client;

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _exportData;

  Future<void> _requestExport() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _error = 'Please sign in to export your data.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _exportData = null;
    });

    try {
      final response = await _supabase.functions.invoke(
        'export-user-data',
        body: {'user_id': user.id},
      );

      if (response.status != 200) {
        throw Exception('Export failed (status ${response.status})');
      }

      final data = response.data;
      if (!mounted) return;
      setState(() {
        _exportData = data is Map<String, dynamic>
            ? data
            : (data is Map ? Map<String, dynamic>.from(data) : {'raw': data});
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

  Future<void> _copyToClipboard() async {
    if (_exportData == null) return;
    final pretty = const JsonEncoder.withIndent('  ').convert(_exportData);
    await Clipboard.setData(ClipboardData(text: pretty));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Export my data')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: DesignTokens.danger, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _requestExport,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_exportData == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.cloud_download, size: 72, color: DesignTokens.accentBlue),
          const SizedBox(height: 16),
          Text(
            'Export your VAGUS data',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We will collect your profile, plans, and activity. The download may take a few seconds to generate.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _requestExport,
            icon: const Icon(Icons.download),
            label: const Text('Request export'),
          ),
        ],
      );
    }

    final pretty = const JsonEncoder.withIndent('  ').convert(_exportData);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: DesignTokens.success),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Export ready',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy'),
            ),
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _requestExport,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DesignTokens.accentBlue.withValues(alpha: 0.3),
              ),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                pretty,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
