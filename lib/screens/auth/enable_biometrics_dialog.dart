import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth/biometric_auth_service.dart';

class EnableBiometricsDialog extends StatefulWidget {
  final String userEmail;
  
  const EnableBiometricsDialog({
    super.key,
    required this.userEmail,
  });

  @override
  State<EnableBiometricsDialog> createState() => _EnableBiometricsDialogState();
}

class _EnableBiometricsDialogState extends State<EnableBiometricsDialog> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  bool _loading = false;
  String _biometricDescription = '';

  @override
  void initState() {
    super.initState();
    _loadBiometricDescription();
  }

  Future<void> _loadBiometricDescription() async {
    try {
      final description = await _biometricService.getBiometricDescription();
      setState(() {
        _biometricDescription = description;
      });
    } catch (e) {
      setState(() {
        _biometricDescription = 'fingerprint or Face ID';
      });
    }
  }

  Future<void> _enableBiometrics() async {
    setState(() => _loading = true);
    
    try {
      // First check if biometrics are available
      final bool isAvailable = await _biometricService.isBiometricAvailable();
      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication is not available on this device'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        Navigator.of(context).pop(false);
        return;
      }

      // Test biometric authentication
      final bool authenticated = await _biometricService.authenticateWithBiometrics(
        reason: 'Enable biometric login for VAGUS',
      );

      if (authenticated) {
        // Save the preference
        await _biometricService.setBiometricEnabled(true, userEmail: widget.userEmail);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Biometric login enabled!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication was cancelled or failed'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop(false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enabling biometrics: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(false);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _skipBiometrics() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.fingerprint,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Enable Biometric Login'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Use $_biometricDescription for faster login?',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔐 Secure & Convenient',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  '• Quick login with your fingerprint or Face ID',
                  style: TextStyle(fontSize: 13),
                ),
                Text(
                  '• No need to remember passwords',
                  style: TextStyle(fontSize: 13),
                ),
                Text(
                  '• You can disable this anytime in settings',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : _skipBiometrics,
          child: const Text('Later'),
        ),
        ElevatedButton.icon(
          onPressed: _loading ? null : _enableBiometrics,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.fingerprint, size: 16),
          label: Text(_loading ? 'Setting up...' : 'Enable'),
        ),
      ],
    );
  }
}
