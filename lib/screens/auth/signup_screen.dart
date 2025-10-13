import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'verify_email_pending_screen.dart';
import '../../theme/design_tokens.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _signUp() async {
    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = response.user;
      if (user == null) {
        _showMessage('Signup failed.');
      } else {
        // ✅ Auto-insert profile after signup
        await Supabase.instance.client.from('profiles').insert({
          'id': user.id,
          'email': user.email,
          'name': 'New User',
          'role': 'client',
          'created_at': DateTime.now().toIso8601String(),
        });

        // Check if email is already verified
        if (user.emailConfirmedAt != null) {
          _showMessage('Account created successfully.');
          // User is already verified, let auth gate handle routing
        } else {
          // Navigate to email verification screen
          if (mounted) {
            // ignore: unawaited_futures
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => VerifyEmailPendingScreen(
                  email: _emailController.text.trim(),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    }
    setState(() => _loading = false);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.primaryDark,
      appBar: AppBar(
        title: const Text('Sign Up', style: TextStyle(color: DesignTokens.textPrimary)),
        backgroundColor: DesignTokens.darkBackground,
        iconTheme: const IconThemeData(color: DesignTokens.textPrimary),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Create your VAGUS account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: DesignTokens.textPrimary),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: DesignTokens.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DesignTokens.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DesignTokens.accentGreen),
                ),
                filled: true,
                fillColor: DesignTokens.cardBackground,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: DesignTokens.textPrimary),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: DesignTokens.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DesignTokens.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DesignTokens.accentGreen),
                ),
                filled: true,
                fillColor: DesignTokens.cardBackground,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : () => unawaited(_signUp()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: DesignTokens.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                  elevation: 0,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: _loading
                        ? null
                        : const LinearGradient(
                            colors: [DesignTokens.accentGreen, DesignTokens.accentBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: _loading
                        ? const CircularProgressIndicator(color: DesignTokens.accentGreen)
                        : const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: DesignTokens.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Back to login
              },
              child: const Text(
                'Already have an account? Sign in',
                style: TextStyle(color: DesignTokens.accentGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
