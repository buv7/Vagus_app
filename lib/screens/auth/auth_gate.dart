import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/account_switcher.dart';
import '../../services/session/session_service.dart';

import 'login_screen.dart';
import 'signup_screen.dart';
import 'set_new_password_screen.dart';
import 'verify_email_pending_screen.dart';
import '../dashboard/home_screen.dart'; // Can be reused for client
import '../admin/admin_screen.dart';
import '../dashboard/coach_home_screen.dart';
import '../dashboard/client_home_screen.dart';

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
      if (event == AuthChangeEvent.passwordRecovery) {
        // Navigate to SetNewPasswordScreen
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SetNewPasswordScreen()),
          );
        }
      } else if (event == AuthChangeEvent.userUpdated) {
        // Handle email verification updates
        final user = supabase.auth.currentUser;
        _handleUserUpdate(user);
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

    print('🧪 Supabase user: ${user?.id}');

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
      await SessionService.instance.upsertCurrentDevice();
      await SessionService.instance.checkRevocation();
      
      // Schedule heartbeat
      _scheduleHeartbeat();

      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      setState(() {
        _role = profile['role'];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _role = 'unauthenticated';
        _loading = false;
      });
    }

    // append-only: background refresh of active account, non-blocking
    AccountSwitcher.instance.init().then((_) => AccountSwitcher.instance.refreshActiveIfPossible());
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
      return const LoginScreen();
    }

    if (_role == 'email_verification_pending') {
      final user = supabase.auth.currentUser;
      if (user != null) {
        return VerifyEmailPendingScreen(email: user.email ?? '');
      }
      return const LoginScreen();
    }

    if (_role == 'admin') {
      return const AdminScreen();
    }

    if (_role == 'coach') {
      return const CoachHomeScreen();
    }

    // Default to client
    return const ClientHomeScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub.cancel();
    super.dispose();
  }
}
