import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_screen.dart';
import 'password_reset_screen.dart';
import 'enable_biometrics_dialog.dart';
import '../../services/account_switcher.dart';
import '../../services/auth/biometric_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final BiometricAuthService _biometricService = BiometricAuthService();
  
  bool _loading = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String? _storedUserEmail;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final bool isAvailable = await _biometricService.isBiometricAvailable();
      final bool isEnabled = await _biometricService.getBiometricEnabled();
      final String? storedEmail = await _biometricService.getStoredUserEmail();
      
      setState(() {
        _biometricAvailable = isAvailable;
        _biometricEnabled = isEnabled;
        _storedUserEmail = storedEmail;
      });
    } catch (e) {
      debugPrint('Failed to check biometric availability: $e');
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (!_biometricAvailable || !_biometricEnabled) {
      _showMessage('Biometric login is not available or not enabled.');
      return;
    }

    try {
      final bool authenticated = await _biometricService.authenticateWithBiometrics(
        reason: 'Log in to VAGUS',
      );

      if (authenticated && _storedUserEmail != null) {
        // Pre-fill email and show password dialog
        setState(() {
          _emailController.text = _storedUserEmail!;
        });
        
        _showPasswordDialog();
      } else if (!authenticated) {
        _showMessage('Biometric authentication failed. Please use your password.');
      } else {
        _showMessage('No stored credentials found. Please log in manually.');
      }
    } catch (e) {
      _showMessage('Biometric authentication error: ${e.toString()}');
    }
  }

  void _showPasswordDialog() {
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Welcome back! Please enter your password to complete login.'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                autofocus: true,
                onSubmitted: (value) {
                  Navigator.of(context).pop();
                  _signInWithStoredEmail(passwordController.text);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _signInWithStoredEmail(passwordController.text);
              },
              child: const Text('Sign In'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signInWithStoredEmail(String password) async {
    if (_storedUserEmail == null) return;
    
    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _storedUserEmail!,
        password: password,
      );
      
      if (response.user == null) {
        _showMessage('Login failed. Check your password.');
        return;
      } else {
        // Capture account after successful sign-in
        final user = Supabase.instance.client.auth.currentUser;
        final session = Supabase.instance.client.auth.currentSession;
        if (user != null && session != null) {
          String role = 'client';
          String? avatar;
          try {
            final profile = await Supabase.instance.client
                .from('profiles')
                .select('role, avatar_url')
                .eq('id', user.id)
                .maybeSingle();
            if (profile != null) {
              role = (profile['role'] ?? 'client').toString();
              avatar = (profile['avatar_url'] ?? '').toString().isEmpty ? null : (profile['avatar_url'] as String);
            }
          } catch (_) {}
          await AccountSwitcher.instance.captureCurrentSession(role: role, avatarUrl: avatar);
          
          // Show biometric setup dialog if biometrics are available and not already enabled
          if (mounted && _biometricAvailable && !_biometricEnabled) {
            await _showBiometricSetupDialog(user.email ?? '');
          }
        }
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    }
    setState(() => _loading = false);
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (response.user == null) {
        _showMessage('Login failed. Check your credentials.');
        return;
      }
      
      // append-only: capture account after successful sign-in
      final user = Supabase.instance.client.auth.currentUser;
      final session = Supabase.instance.client.auth.currentSession;
      if (user != null && session != null) {
        String role = 'client';
        String? avatar;
        try {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('role, avatar_url')
              .eq('id', user.id)
              .maybeSingle();
          if (profile != null) {
            role = (profile['role'] ?? 'client').toString();
            avatar = (profile['avatar_url'] ?? '').toString().isEmpty ? null : (profile['avatar_url'] as String);
          }
        } catch (_) {}
        await AccountSwitcher.instance.captureCurrentSession(role: role, avatarUrl: avatar);
        
        // Show biometric setup dialog if biometrics are available and not already enabled
        if (mounted && _biometricAvailable && !_biometricEnabled) {
          await _showBiometricSetupDialog(user.email ?? '');
        }
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    }
    setState(() => _loading = false);
  }

  Future<void> _showBiometricSetupDialog(String userEmail) async {
    try {
      final bool? enable = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => EnableBiometricsDialog(userEmail: userEmail),
      );
      
      // If user enabled biometrics, refresh the biometric state
      if (enable == true && mounted) {
        await _checkBiometricAvailability();
      }
    } catch (e) {
      debugPrint('Error showing biometric setup dialog: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sign in to VAGUS',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Biometric login button
                if (_biometricAvailable && _biometricEnabled)
                  TextButton.icon(
                    onPressed: _authenticateWithBiometrics,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Use biometrics'),
                  )
                else
                  const SizedBox.shrink(),
                
                // Forgot password button
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PasswordResetScreen()),
                    );
                  },
                  child: const Text('Forgot Password?'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _signIn,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Sign In'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                );
              },
              child: const Text("Don't have an account? Sign up"),
            ),
          ],
        ),
      ),
    );
  }
}
