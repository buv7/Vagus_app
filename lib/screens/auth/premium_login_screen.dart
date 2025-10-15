import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/auth/biometric_auth_service.dart';
import '../../widgets/auth/animated_gradient_background.dart';
import '../../widgets/auth/floating_particles.dart';
import '../../widgets/auth/premium_glass_card.dart';
import '../../widgets/auth/stats_display.dart';
import '../../widgets/auth/premium_gradient_button.dart';
import '../../widgets/auth/fade_in_animation.dart';
import 'signup_screen.dart';

class PremiumLoginScreen extends StatefulWidget {
  const PremiumLoginScreen({super.key});

  @override
  State<PremiumLoginScreen> createState() => _PremiumLoginScreenState();
}

class _PremiumLoginScreenState extends State<PremiumLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _biometricService = BiometricAuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  String? _storedEmail;

  // Neural activity indicator animations
  final List<AnimationController> _dotControllers = [];
  final List<Animation<double>> _dotScaleAnimations = [];
  final List<Animation<double>> _dotOpacityAnimations = [];

  @override
  void initState() {
    super.initState();
    _initializeDotAnimations();
    _checkBiometricAvailability();
  }

  void _initializeDotAnimations() {
    for (int i = 0; i < 5; i++) {
      final controller = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      );

      final scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );

      final opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );

      _dotControllers.add(controller);
      _dotScaleAnimations.add(scaleAnimation);
      _dotOpacityAnimations.add(opacityAnimation);

      // Stagger the animations
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          controller.repeat(reverse: true);
        }
      });
    }
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final isEnabled = await _biometricService.getBiometricEnabled();
    final storedEmail = await _biometricService.getStoredUserEmail();

    if (mounted) {
      setState(() {
        _biometricAvailable = isAvailable && isEnabled;
        _storedEmail = storedEmail;
        if (_storedEmail != null) {
          _emailController.text = _storedEmail!;
        }
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (!_biometricAvailable || _storedEmail == null) return;

    setState(() => _isLoading = true);

    try {
      final authenticated = await _biometricService.authenticateWithBiometrics(
        reason: 'Authenticate to access your Vagus account',
      );

      if (!authenticated) {
        setState(() => _isLoading = false);
        return;
      }

      // After successful biometric auth, user should already be logged in
      // or we can navigate them to enter password
      if (mounted) {
        _showSnackBar('Biometric authentication successful', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Biometric authentication failed: ${e.toString()}');
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    unawaited(HapticFeedback.mediumImpact());

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user == null) {
        throw Exception('Login failed: No user returned');
      }

      // Login successful - AuthGate will handle navigation
      if (mounted) {
        unawaited(HapticFeedback.heavyImpact());
        _showSnackBar('Welcome back!', isError: false);
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('An error occurred: ${e.toString()}');
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade900 : Colors.green.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    for (var controller in _dotControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Animated gradient background
            const AnimatedGradientBackground(),

            // Floating particles
            const FloatingParticles(),

            // Main content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 900;
                  final isTablet = constraints.maxWidth > 600;

                  if (isDesktop) {
                    return _buildDesktopLayout();
                  } else if (isTablet) {
                    return _buildTabletLayout();
                  } else {
                    return _buildMobileLayout();
                  }
                },
              ),
            ),

            // Neural activity indicator
            _buildNeuralActivityIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: Row(
        children: [
          // Left section - Info
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(64.0),
              child: _buildInfoSection(),
            ),
          ),

          // Right section - Login form
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(64.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildLoginForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: _buildInfoSection(),
            ),
            const SizedBox(width: 48),
            Expanded(
              flex: 1,
              child: _buildLoginForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 32),
          _buildMobileHeader(),
          const SizedBox(height: 48),
          _buildLoginForm(),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // VAGUS title with shimmer
        FadeInAnimation(
          delay: const Duration(milliseconds: 200),
          child: Shimmer.fromColors(
            baseColor: Colors.white,
            highlightColor: const Color(0xFF00C8FF),
            period: const Duration(seconds: 3),
            child: const Text(
              'VAGUS',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w100,
                letterSpacing: 4,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Subtitle
        FadeInAnimation(
          delay: const Duration(milliseconds: 400),
          child: Text(
            'THE MOST ADVANCED ONLINE FITNESS PLATFORM',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 2,
            ),
          ),
        ),

        const SizedBox(height: 48),

        // Description
        FadeInAnimation(
          delay: const Duration(milliseconds: 600),
          child: Text(
            'Experience the advanced features withoptimization and personalized fitness coaching. Transform your potential into measurable results.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),
        ),

        const SizedBox(height: 64),

        // Stats display
        const FadeInAnimation(
          delay: Duration(milliseconds: 800),
          child: StatsDisplay(),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        FadeInAnimation(
          delay: const Duration(milliseconds: 200),
          child: Shimmer.fromColors(
            baseColor: Colors.white,
            highlightColor: const Color(0xFF00C8FF),
            period: const Duration(seconds: 3),
            child: const Text(
              'VAGUS',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w100,
                letterSpacing: 4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FadeInAnimation(
          delay: const Duration(milliseconds: 400),
          child: Text(
            'The most advanced IRAQI ONLINE FITNESS COACHING PLATFORM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 400),
      child: PremiumGlassCard(
        padding: const EdgeInsets.all(48),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Header
            const Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'BE YOUR BEST TODAY WITH OUR ELITE COACHES AND THE MOST ADVANCED FITNESS PLATFORM ON EARTH !',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),

            const SizedBox(height: 48),

            // Email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                hintText: 'your@email.com',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00C8FF), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade400),
                ),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              enabled: !_isLoading,
            ),

            const SizedBox(height: 24),

            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                hintText: '••••••••',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00C8FF), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade400),
                ),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              enabled: !_isLoading,
              onFieldSubmitted: (_) => _handleLogin(),
            ),

            const SizedBox(height: 32),

            // Login button
            PremiumGradientButton(
              text: 'Un lock your dream physique',
              onPressed: _handleLogin,
              isLoading: _isLoading,
              enabled: !_isLoading,
            ),

            // Biometric button (if available)
            if (_biometricAvailable) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _isLoading ? null : _handleBiometricLogin,
                icon: Icon(
                  Icons.fingerprint,
                  color: const Color(0xFF00C8FF).withValues(alpha: _isLoading ? 0.3 : 1.0),
                ),
                label: Text(
                  'Use biometric authentication',
                  style: TextStyle(
                    color: const Color(0xFF00C8FF).withValues(alpha: _isLoading ? 0.3 : 1.0),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Sign up link
            Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SignupScreen(),
                          ),
                        );
                      },
                child: Text(
                  'Create new account →',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: _isLoading ? 0.3 : 0.7),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeuralActivityIndicator() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return AnimatedBuilder(
              animation: _dotControllers[index],
              builder: (context, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00C8FF).withValues(alpha: 
                      _dotOpacityAnimations[index].value,
                    ),
                  ),
                  transform: Matrix4.identity()
                    ..scale(_dotScaleAnimations[index].value),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
