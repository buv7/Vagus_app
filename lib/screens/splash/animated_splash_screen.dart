import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedSplashScreen extends StatefulWidget {
  final WidgetBuilder nextBuilder; // REQUIRED explicit target
  const AnimatedSplashScreen({super.key, required this.nextBuilder});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..forward();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900), lowerBound: 0.92, upperBound: 1.0)..forward();
    _boot();
  }

  Future<void> _boot() async {
    // Keep a minimum display time; in parallel you can init services if needed.
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1200)),
    ]);
    if (!mounted) return;
    unawaited(Navigator.of(context).pushReplacement(MaterialPageRoute(builder: widget.nextBuilder)));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: Center(
          child: ScaleTransition(
            scale: _scaleCtrl,
            child: const _Logo(),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) {
    // White logo on black background
    const path = 'assets/branding/vagus_logo_white.png';
    return Image.asset(
      path,
      width: 160,
      height: 160,
      errorBuilder: (_, __, ___) {
        // If asset missing, show branded fallback (prevents "freeze")
        // Also logs a debug hint.
        // ignore: avoid_print
        print('VAGUS splash: missing $path. Add PNG to assets and run flutter pub get.');
        return const Text(
          'VAGUS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        );
      },
      filterQuality: FilterQuality.high,
    );
  }
}
