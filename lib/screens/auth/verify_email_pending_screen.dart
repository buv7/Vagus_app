import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerifyEmailPendingScreen extends StatefulWidget {
  final String email;
  
  const VerifyEmailPendingScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyEmailPendingScreen> createState() => _VerifyEmailPendingScreenState();
}

class _VerifyEmailPendingScreenState extends State<VerifyEmailPendingScreen> {
  final supabase = Supabase.instance.client;
  bool _loading = false;
  bool _resendLoading = false;
  Timer? _pollingTimer;
  int _pollingAttempts = 0;
  static const int _maxPollingAttempts = 24; // 2 minutes with 5-second intervals
  static const int _pollingInterval = 5; // seconds

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: _pollingInterval), (timer) {
      if (_pollingAttempts >= _maxPollingAttempts) {
        timer.cancel();
        return;
      }
      _pollingAttempts++;
      _checkVerificationStatus();
    });
  }

  Future<void> _checkVerificationStatus() async {
    try {
      // Refresh the session to get updated user data
      final response = await supabase.auth.getUser();
      final user = response.user;
      
      if (user != null && user.emailConfirmedAt != null) {
        _pollingTimer?.cancel();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Email verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back to auth gate which will handle routing
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Error checking verification status: $e');
    }
  }

  Future<void> _resendVerificationEmail() async {
    // Check cooldown
    final prefs = await SharedPreferences.getInstance();
    final lastResendTime = prefs.getInt('last_resend_time') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cooldownPeriod = 60 * 1000; // 60 seconds in milliseconds
    
    if (now - lastResendTime < cooldownPeriod) {
      final remainingSeconds = ((cooldownPeriod - (now - lastResendTime)) / 1000).ceil();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please wait $remainingSeconds seconds before resending'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _resendLoading = true);
    
    try {
      // Use Supabase auth resend method
      await supabase.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
      
      // Update last resend time
      await prefs.setInt('last_resend_time', now);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Verification email sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to resend: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _resendLoading = false);
      }
    }
  }

  Future<void> _refreshStatus() async {
    setState(() => _loading = true);
    await _checkVerificationStatus();
    setState(() => _loading = false);
  }

  void _goBackToSignup() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Email Icon
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'Check your inbox',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Description
            const Text(
              'We\'ve sent a verification link to your email address.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Email Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.email,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Column(
                children: [
                  Text(
                    '📧 Click the verification link in your email',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '🔄 This page will automatically check for verification',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '⏱️ You can also manually refresh or resend the email',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resendLoading ? null : _resendVerificationEmail,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: _resendLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_resendLoading ? 'Sending...' : 'Resend Email'),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _refreshStatus,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_loading ? 'Checking...' : 'Refresh Status'),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _goBackToSignup,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Change Email'),
              ),
            ),
            const SizedBox(height: 24),
            
            // Polling Status
            if (_pollingAttempts > 0)
              Text(
                'Checking verification status... ($_pollingAttempts/$_maxPollingAttempts)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
