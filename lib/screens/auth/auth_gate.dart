import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/account_switcher.dart';

import 'login_screen.dart';
import 'signup_screen.dart';
import '../dashboard/home_screen.dart'; // Can be reused for client
import '../admin/admin_screen.dart';
import '../dashboard/coach_home_screen.dart';
import '../dashboard/client_home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final supabase = Supabase.instance.client;
  bool _loading = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _checkUser();
    // append-only: background refresh of active account, non-blocking
    AccountSwitcher.instance.init().then((_) => AccountSwitcher.instance.refreshActiveIfPossible());
  }

  Future<void> _checkUser() async {
    final user = supabase.auth.currentUser;

    print('🧪 Supabase user: ${user?.id}');

    if (user == null) {
      setState(() {
        _role = 'unauthenticated';
        _loading = false;
      });
      return;
    }

    try {
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
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_role == 'unauthenticated') {
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
}
