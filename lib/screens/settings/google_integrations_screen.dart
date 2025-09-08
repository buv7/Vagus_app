import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/google/google_models.dart';
import '../../services/google/google_apps_service.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/pro_upgrade_chip.dart';

class GoogleIntegrationsScreen extends StatefulWidget {
  const GoogleIntegrationsScreen({super.key});

  @override
  State<GoogleIntegrationsScreen> createState() => _GoogleIntegrationsScreenState();
}

class _GoogleIntegrationsScreenState extends State<GoogleIntegrationsScreen> {
  final GoogleAppsService _googleService = GoogleAppsService();
  GoogleAccount? _connectedAccount;
  bool _isLoading = true;
  bool _isConnecting = false;
  bool _isDisconnecting = false;
  final TextEditingController _workspaceFolderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConnectedAccount();
  }

  @override
  void dispose() {
    _workspaceFolderController.dispose();
    super.dispose();
  }

  Future<void> _loadConnectedAccount() async {
    setState(() => _isLoading = true);
    try {
      final account = await _googleService.getConnectedAccount();
      setState(() {
        _connectedAccount = account;
        if (account?.workspaceFolder != null) {
          _workspaceFolderController.text = account!.workspaceFolder!;
        }
      });
    } catch (e) {
      debugPrint('Error loading connected account: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectAccount() async {
    setState(() => _isConnecting = true);
    try {
      final success = await _googleService.connectCoachAccount();
      if (success) {
        await _loadConnectedAccount();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google account connected successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to connect Google account')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnectAccount() async {
    setState(() => _isDisconnecting = true);
    try {
      final success = await _googleService.disconnect();
      if (success) {
        setState(() => _connectedAccount = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google account disconnected')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to disconnect Google account')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isDisconnecting = false);
    }
  }

  Future<void> _updateWorkspaceFolder() async {
    try {
      final success = await _googleService.updateWorkspaceFolder(
        _workspaceFolderController.text.trim(),
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workspace folder updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating workspace folder: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Google Integration',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.mintAqua,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConnectionCard(),
                  const SizedBox(height: 16),
                  _buildExportsPanel(),
                  const SizedBox(height: 16),
                  _buildScheduledExportsPanel(),
                ],
              ),
            ),
    );
  }

  Widget _buildConnectionCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_done,
                color: _connectedAccount != null ? Colors.green : AppTheme.mintAqua,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Google Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_connectedAccount != null) ...[
            _buildConnectedAccountInfo(),
            const SizedBox(height: 16),
            _buildWorkspaceFolderField(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isDisconnecting ? null : _disconnectAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isDisconnecting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Disconnect'),
              ),
            ),
          ] else ...[
            Text(
              'Connect your Google account to export data to Sheets and attach files from Drive.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConnecting ? null : _connectAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.mintAqua,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isConnecting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Connect Google Account'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectedAccountInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connected: ${_connectedAccount!.email}',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.green,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Connected on: ${_formatDate(_connectedAccount!.connectedAt)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceFolderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workspace Folder (optional)',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _workspaceFolderController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter Google Drive folder name',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.mintAqua),
            ),
            filled: true,
            fillColor: const Color(0xFF1A1C1E),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _updateWorkspaceFolder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.mintAqua,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Update Folder'),
          ),
        ),
      ],
    );
  }

  Widget _buildExportsPanel() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export to Google Sheets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (_connectedAccount != null) ...[
            _buildExportRow('Metrics', 'metrics'),
            _buildExportRow('Check-ins', 'checkins'),
            _buildExportRow('Workouts', 'workouts'),
            _buildExportRow('Nutrition', 'nutrition'),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connect your Google account to export data to Sheets',
                      style: const TextStyle(color: Colors.orange, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportRow(String title, String kind) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => unawaited(_exportToSheets(kind)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.mintAqua,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledExportsPanel() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: AppTheme.mintAqua,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Scheduled Exports',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const ProUpgradeChip(),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Upgrade to Pro to schedule automatic weekly exports',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToSheets(String kind) async {
    try {
      final sheetUrl = await _googleService.exportToSheets(kind);
      if (!mounted || !context.mounted) return;
      if (sheetUrl != null) {
        final opened = await _googleService.openUrl(sheetUrl);
        if (!mounted || !context.mounted) return;
        if (!opened) {
          // Copy URL to clipboard if can't open
          await Clipboard.setData(ClipboardData(text: sheetUrl));
          if (!mounted || !context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sheet URL copied to clipboard')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export data')),
        );
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
