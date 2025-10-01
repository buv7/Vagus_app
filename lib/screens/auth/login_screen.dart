import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_screen.dart';
import 'password_reset_screen.dart';
import 'enable_biometrics_dialog.dart';
import '../../services/account_switcher.dart';
import '../../services/auth/biometric_auth_service.dart';
import '../../widgets/anim/vagus_loader.dart';
import '../../widgets/anim/vagus_success.dart';


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
    
    // ignore: unawaited_futures
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

    debugPrint('🔐 Biometric login with stored email: $_storedUserEmail');

    // Show loading dialog
    // ignore: unawaited_futures
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: VagusLoader(size: 72)),
    );

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _storedUserEmail!,
        password: password,
      );

      debugPrint('✅ Biometric login response received');
      debugPrint('   User ID: ${response.user?.id ?? "null"}');

      if (!mounted) return;

      if (response.user == null) {
        Navigator.pop(context); // Remove loader
        _showMessage('Login failed. Check your password.');
        debugPrint('❌ Biometric login failed: No user in response');
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
        
        // Show success animation
        if (mounted) {
          Navigator.pop(context); // Remove loader
          // ignore: unawaited_futures
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: VagusSuccess(size: 84)),
          );
          
          // Wait for success animation, then navigate
          await Future.delayed(const Duration(milliseconds: 700));
          if (!mounted) return;
          Navigator.pop(context); // Remove success dialog
          
          // Navigate to home (the app will handle routing via AuthGate)
          // No need to navigate manually as Supabase auth state change will trigger navigation
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loader
        _showMessage('Error: ${e.toString()}');
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _signIn() async {
    debugPrint('🔘 SIGN IN BUTTON PRESSED');

    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    debugPrint('🔐 Email field: "$email"');
    debugPrint('🔐 Password length: ${password.length}');

    // Validation
    if (email.isEmpty || password.isEmpty) {
      debugPrint('❌ Validation failed: Empty fields');
      _showMessage('Please enter both email and password');
      setState(() => _loading = false);
      return;
    }

    debugPrint('🔐 Attempting login with: $email');

    // Show loading dialog
    // ignore: unawaited_futures
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: VagusLoader(size: 72)),
    );

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ Login response received');
      debugPrint('   User ID: ${response.user?.id ?? "null"}');
      debugPrint('   Session: ${response.session?.accessToken != null ? "Yes" : "No"}');
      debugPrint('   Email confirmed: ${response.user?.emailConfirmedAt != null}');

      if (!mounted) return;

      if (response.user == null) {
        Navigator.pop(context); // Remove loader
        _showMessage('Login failed. Check your credentials.');
        debugPrint('❌ Login failed: No user in response');
        return;
      }

      debugPrint('✅ Login successful, proceeding with session setup');
      
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
      
      // Show success animation
      if (mounted) {
        Navigator.pop(context); // Remove loader
        // ignore: unawaited_futures
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: VagusSuccess(size: 84)),
        );
        
        // Wait for success animation, then navigate
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        Navigator.pop(context); // Remove success dialog
        
        // Navigate to home (the app will handle routing via AuthGate)
        // No need to navigate manually as Supabase auth state change will trigger navigation
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      debugPrint('   Error type: ${e.runtimeType}');

      if (e is AuthException) {
        debugPrint('   Status code: ${e.statusCode}');
        debugPrint('   Message: ${e.message}');
      }

      if (mounted) {
        Navigator.pop(context); // Remove loader

        String errorMessage = 'Login failed';
        if (e is AuthException) {
          if (e.message.toLowerCase().contains('invalid')) {
            errorMessage = 'Invalid email or password';
          } else if (e.message.toLowerCase().contains('email not confirmed')) {
            errorMessage = 'Please verify your email before logging in';
          } else {
            errorMessage = e.message;
          }
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }

        _showMessage(errorMessage);
      }
    }

    if (mounted) setState(() => _loading = false);
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

  Future<void> _testSupabaseConnection() async {
    debugPrint('🧪 TEST CONNECTION BUTTON PRESSED');
    debugPrint('🧪 Testing Supabase connection...');

    setState(() => _loading = true);

    try {
      // Test: Simple query to profiles table
      debugPrint('🧪 Attempting to query profiles table...');
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 10));

      debugPrint('✅ Supabase connection SUCCESS!');
      debugPrint('✅ Response: $response');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('✅ Supabase connection works!')),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('❌ Supabase connection FAILED: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');

      if (e is PostgrestException) {
        debugPrint('❌ Postgrest error code: ${e.code}');
        debugPrint('❌ Postgrest error message: ${e.message}');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('❌ Connection failed: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_loading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              enabled: !_loading,
              onSubmitted: (_) => _loading ? null : _signIn(),
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
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _signIn,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Sign In'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loading ? null : _testSupabaseConnection,
              child: const Text('Test Connection'),
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
