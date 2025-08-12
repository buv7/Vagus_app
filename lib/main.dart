import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/workout/ClientWorkoutDashboardScreen.dart'; // ✅ import workout screen
// NEW: Import OneSignal service
import 'services/notifications/onesignal_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kydrpnrmqbedjflklgue.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5ZHJwbnJtcWJlZGpmbGtsZ3VlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMjUxODAsImV4cCI6MjA2OTgwMTE4MH0.qlpGUiy17IbDsfgOf3-F2XBjOajjwxfy2NLMlUZWaqo',
  );

  // NEW: Initialize OneSignal notifications
  await OneSignalService.instance.init();

  runApp(const VagusMainApp());
}

class VagusMainApp extends StatelessWidget {
  const VagusMainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VAGUS',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const AuthGate(),
      routes: {
        // ✅ Add this route for client workout plan viewer
        '/client-workout': (context) => const ClientWorkoutDashboardScreen(),
      },
    );
  }
}
