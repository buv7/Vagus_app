import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/account_switcher.dart';
import '../../services/session/session_service.dart';
import '../../services/settings/settings_service.dart';

import 'modern_login_screen.dart';
import 'set_new_password_screen.dart';
import 'verify_email_pending_screen.dart';
import '../admin/admin_screen.dart';
import '../nav/main_nav.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final supabase = Supabase.instance.client;
  bool _loading = true;
  String? _role;
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      debugPrint('🔔 Auth state change: $event');
      debugPrint('   User: ${data.session?.user.id ?? "null"}');

      if (event == AuthChangeEvent.signedIn) {
        debugPrint('✅ User signed in, reinitializing app state');
        _initializeApp();
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('👋 User signed out');
        if (mounted) {
          setState(() {
            _role = 'unauthenticated';
            _loading = false;
          });
        }
      } else if (event == AuthChangeEvent.passwordRecovery) {
        debugPrint('🔑 Password recovery triggered');
        // Navigate to SetNewPasswordScreen
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SetNewPasswordScreen()),
          );
        }
      } else if (event == AuthChangeEvent.userUpdated) {
        debugPrint('🔄 User updated');
        // Handle email verification updates
        final user = supabase.auth.currentUser;
        _handleUserUpdate(user);
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        debugPrint('🔄 Token refreshed');
      }
    });

    _initializeApp();
  }

  Future<void> _handleUserUpdate(User? user) async {
    if (user != null && user.emailConfirmedAt != null) {
      // User's email was verified, refresh the app state
      await _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    final user = supabase.auth.currentUser;

          debugPrint('🧪 Supabase user: ${user?.id}');

    if (user == null) {
      setState(() {
        _role = 'unauthenticated';
        _loading = false;
      });
      return;
    }

    // Check if user's email is verified
    if (user.emailConfirmedAt == null) {
      setState(() {
        _role = 'email_verification_pending';
        _loading = false;
      });
      return;
    }

    try {
      // Session management for authenticated users
      debugPrint('🔧 AuthGate: Starting session management...');
      await SessionService.instance.upsertCurrentDevice();
      debugPrint('🔧 AuthGate: Device upserted successfully');
      
      await SessionService.instance.checkRevocation();
      debugPrint('🔧 AuthGate: Revocation check completed');
      
      // Load user settings
      debugPrint('🔧 AuthGate: Loading user settings...');
      await SettingsService.instance.loadForCurrentUser();
      debugPrint('🔧 AuthGate: User settings loaded');
      
      // Schedule heartbeat
      _scheduleHeartbeat();

      debugPrint('🔧 AuthGate: Fetching user profile...');
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      String role = 'client'; // Default role for new users
      
      if (profile == null) {
        debugPrint('⚠️ AuthGate: No profile found for user, attempting to create default profile...');
        // Create a default profile for the user with retry logic
        bool profileCreated = false;
        int retryCount = 0;
        const maxRetries = 3;
        
        while (!profileCreated && retryCount < maxRetries) {
          try {
            // Wait a bit for the user to be fully committed to auth.users
            if (retryCount > 0) {
              await Future.delayed(Duration(milliseconds: 500 * retryCount));
            }
            
            await supabase.from('profiles').insert({
              'id': user.id,
              'email': user.email,
              'name': user.userMetadata?['name'] ?? 'New User',
              'role': 'client', // New users default to client
            });
            profileCreated = true;
            debugPrint('✅ AuthGate: Default profile created successfully');
          } catch (e) {
            retryCount++;
            debugPrint('❌ AuthGate: Failed to create profile (attempt $retryCount): $e');
            
            if (retryCount >= maxRetries) {
              debugPrint('❌ AuthGate: Max retries reached, continuing with default role');
              // Check if profile was created by trigger in the meantime
              try {
                final retryProfile = await supabase
                    .from('profiles')
                    .select('role')
                    .eq('id', user.id)
                    .maybeSingle();
                if (retryProfile != null) {
                  role = retryProfile['role'] ?? 'client';
                  profileCreated = true;
                  debugPrint('✅ AuthGate: Profile found after retry, role: $role');
                }
              } catch (retryError) {
                debugPrint('❌ AuthGate: Error checking profile after retry: $retryError');
              }
            }
          }
        }
        
        // If still no profile, continue with default role
        if (!profileCreated) {
          debugPrint('⚠️ AuthGate: Continuing with default client role');
        }
      } else {
        // Use the existing role from the database, don't default to client
        role = profile['role'] ?? 'client';
        debugPrint('🔧 AuthGate: Profile fetched successfully, role: $role');
      }

      setState(() {
        _role = role;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ AuthGate: Error during initialization: $e');
      debugPrint('❌ AuthGate: Stack trace: ${StackTrace.current}');
      setState(() {
        _role = 'unauthenticated';
        _loading = false;
      });
    }

    // append-only: background refresh of active account, non-blocking
    unawaited(AccountSwitcher.instance.init().then((_) => AccountSwitcher.instance.refreshActiveIfPossible()));
  }

  void _scheduleHeartbeat() {
    // Send heartbeat every 5 minutes when app is active
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted && supabase.auth.currentUser != null) {
        SessionService.instance.heartbeat();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - check revocation and send heartbeat
      if (supabase.auth.currentUser != null) {
        SessionService.instance.checkRevocation();
        SessionService.instance.heartbeat();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_role == 'unauthenticated') {
      return const ModernLoginScreen();
    }

    if (_role == 'email_verification_pending') {
      final user = supabase.auth.currentUser;
      if (user != null) {
        return VerifyEmailPendingScreen(email: user.email ?? '');
      }
      return const ModernLoginScreen();
    }

    if (_role == 'admin') {
      return const AdminScreen();
    }

    if (_role == 'coach') {
      return const MainNav(); // Route coach into MainNav same as client
    }

    // Default to client with navigation
    return const MainNav();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub.cancel();
    super.dispose();
  }
}
