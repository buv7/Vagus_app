import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../widgets/auth/animated_gradient_background.dart';
import '../../widgets/auth/floating_particles.dart';
import '../../widgets/auth/premium_glass_card.dart';
import '../../widgets/auth/stats_display.dart';
import '../../widgets/auth/premium_gradient_button.dart';
import '../../widgets/auth/fade_in_animation.dart';
import 'verify_email_pending_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _emailFocused = false;
  bool _passwordFocused = false;
  bool _nameFocused = false;

  // Neural activity indicator animations
  final List<AnimationController> _dotControllers = [];
  final List<Animation<double>> _dotScaleAnimations = [];
  final List<Animation<double>> _dotOpacityAnimations = [];

  @override
  void initState() {
    super.initState();
    _initializeDotAnimations();
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
    _nameFocusNode.addListener(_onNameFocusChange);
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

  void _onEmailFocusChange() {
    setState(() => _emailFocused = _emailFocusNode.hasFocus);
  }

  void _onPasswordFocusChange() {
    setState(() => _passwordFocused = _passwordFocusNode.hasFocus);
  }

  void _onNameFocusChange() {
    setState(() => _nameFocused = _nameFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _nameFocusNode.dispose();
    for (var controller in _dotControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    unawaited(HapticFeedback.mediumImpact());

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Signup failed: No user returned');
      }

      // Auto-insert profile after signup
      await Supabase.instance.client.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'name': _nameController.text.trim().isEmpty
            ? 'New User'
            : _nameController.text.trim(),
        'role': 'client',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Check if email is already verified
      if (user.emailConfirmedAt != null) {
        if (mounted) {
          unawaited(HapticFeedback.heavyImpact());
          _showSnackBar('Account created successfully!', isError: false);
        }
      } else {
        // Navigate to email verification screen
        if (mounted) {
          unawaited(Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => VerifyEmailPendingScreen(
                email: _emailController.text.trim(),
              ),
            ),
          ));
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnackBar(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
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
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loading,
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

          // Right section - Signup form
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(64.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildSignupForm(),
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
              child: _buildSignupForm(),
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
          _buildSignupForm(),
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
            'ONLINE IRAQI FITNESS COACHING PLATFORM',
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
            'Join the revolution in neural fitness training. Create your account and unlock personalized coaching powered by advanced FEATURES.',
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
            'ONLINE IRAQI FITNESS COACHING PLATFORM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
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
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Begin your fitness journey',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),

              const SizedBox(height: 48),

              // Name field
              _buildFloatingLabelInput(
                controller: _nameController,
                focusNode: _nameFocusNode,
                label: 'Full Name',
                hint: 'Enter your name',
                isFocused: _nameFocused,
                prefixEmoji: '👤',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Email field
              _buildFloatingLabelInput(
                controller: _emailController,
                focusNode: _emailFocusNode,
                label: 'Email',
                hint: 'your@email.com',
                keyboardType: TextInputType.emailAddress,
                isFocused: _emailFocused,
                prefixEmoji: '📧',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Password field
              _buildFloatingLabelInput(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                label: 'Password',
                hint: 'Create a strong password',
                obscureText: _obscurePassword,
                isFocused: _passwordFocused,
                prefixEmoji: '🔑',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                onSubmitted: (_) => _handleSignup(),
              ),

              const SizedBox(height: 32),

              // Signup button
              PremiumGradientButton(
                text: 'Create Account',
                onPressed: _handleSignup,
                isLoading: _loading,
                enabled: !_loading,
              ),

              const SizedBox(height: 24),

              // Sign in link
              Center(
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: Text(
                    'Already have an account? Sign in',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: _loading ? 0.3 : 0.7),
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

  Widget _buildFloatingLabelInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required bool isFocused,
    String? prefixEmoji,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    final hasText = controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedOpacity(
          opacity: isFocused || hasText ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isFocused
                    ? const Color(0xFF00C8FF)
                    : Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enabled: !_loading,
          onChanged: (_) => setState(() {}),
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 16,
            ),
            prefixIcon: prefixEmoji != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Text(
                      prefixEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  )
                : null,
            prefixIconConstraints: prefixEmoji != null
                ? const BoxConstraints(minWidth: 0, minHeight: 0)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: EdgeInsets.symmetric(
              horizontal: prefixEmoji != null ? 8 : 20,
              vertical: 16,
            ),
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
          ),
          validator: validator,
        ),
      ],
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
                    color: const Color(0xFF00C8FF).withValues(
                      alpha: _dotOpacityAnimations[index].value,
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
