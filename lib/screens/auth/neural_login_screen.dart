import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_screen.dart';
import 'password_reset_screen.dart';
import 'enable_biometrics_dialog.dart';
import '../../services/account_switcher.dart';
import '../../services/auth/biometric_auth_service.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../widgets/anim/vagus_loader.dart';
import '../../widgets/anim/vagus_success.dart';
import '../../theme/design_tokens.dart';

class NeuralLoginScreen extends StatefulWidget {
  const NeuralLoginScreen({super.key});

  @override
  State<NeuralLoginScreen> createState() => _NeuralLoginScreenState();
}

class _NeuralLoginScreenState extends State<NeuralLoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final BiometricAuthService _biometricService = BiometricAuthService();

  bool _loading = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String? _storedUserEmail;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  late AnimationController _particleController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);

    // Initialize animations
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Moderate speed
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6), // Moderate wave flow
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _particleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _onEmailFocusChange() {
    setState(() => _emailFocused = _emailFocusNode.hasFocus);
  }

  void _onPasswordFocusChange() {
    setState(() => _passwordFocused = _passwordFocusNode.hasFocus);
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
        reason: 'Log in to VAGUS Neural Platform',
      );

      if (authenticated && _storedUserEmail != null) {
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
          backgroundColor: DesignTokens.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius24),
            side: const BorderSide(color: DesignTokens.glassBorder),
          ),
          title: Text(
            'Enter Password',
            style: DesignTokens.titleSmall.copyWith(color: DesignTokens.neutralWhite),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome back! Please enter your password to complete login.',
                style: DesignTokens.bodySmall.copyWith(color: DesignTokens.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                style: DesignTokens.bodyMedium.copyWith(color: DesignTokens.neutralWhite),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: DesignTokens.textSecondary),
                  filled: true,
                  fillColor: DesignTokens.primaryDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    borderSide: const BorderSide(color: DesignTokens.glassBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    borderSide: const BorderSide(color: DesignTokens.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    borderSide: const BorderSide(color: DesignTokens.accentBlue, width: 2),
                  ),
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: DesignTokens.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.accentBlue,
                foregroundColor: DesignTokens.neutralWhite,
              ),
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

    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: VagusLoader(size: 72)),
    ));

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _storedUserEmail!,
        password: password,
      );

      if (!mounted) return;

      if (response.user == null) {
        Navigator.pop(context);
        _showMessage('Login failed. Check your password.');
        return;
      } else {
        await _handleSuccessfulLogin(response.user!.email ?? '');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showMessage('Error: ${e.toString()}');
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter both email and password');
      setState(() => _loading = false);
      return;
    }

    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: VagusLoader(size: 72)),
    ));

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.user == null) {
        Navigator.pop(context);
        _showMessage('Login failed. Check your credentials.');
        return;
      }

      await _handleSuccessfulLogin(email);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);

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

  Future<void> _handleSuccessfulLogin(String userEmail) async {
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

      if (mounted && _biometricAvailable && !_biometricEnabled) {
        await _showBiometricSetupDialog(userEmail);
      }
    }

    if (mounted) {
      Navigator.pop(context);
      unawaited(showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: VagusSuccess(size: 84)),
      ));

      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> _showBiometricSetupDialog(String userEmail) async {
    try {
      final bool? enable = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => EnableBiometricsDialog(userEmail: userEmail),
      );

      if (enable == true && mounted) {
        await _checkBiometricAvailability();
      }
    } catch (e) {
      debugPrint('Error showing biometric setup dialog: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = LocaleHelper.isRTL(Localizations.localeOf(context).languageCode);

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: DesignTokens.primaryDark,
        body: Stack(
          children: [
            // 3D Neural Network Background
            _build3DBackground(),

            // Glass-morphic Login UI
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildLoginCard(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, 0.0),
          radius: 1.5,
          colors: [
            DesignTokens.secondaryDark, // Black soft
            DesignTokens.primaryDark, // Pure black
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated wave lines
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                painter: WavesPainter(_waveController.value),
                size: Size.infinite,
              );
            },
          ),

          // Animated blue gradient orb (left)
          Positioned(
            left: -100,
            top: 100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DesignTokens.accentBlue.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Animated cyan gradient orb (right)
          Positioned(
            right: -100,
            top: 200,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DesignTokens.accentGreen.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Animated floating particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlesPainter(_particleController.value),
                size: Size.infinite,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius24),
        border: Border.all(color: DesignTokens.glassBorder, width: 1),
        boxShadow: DesignTokens.glowMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Logo
          _buildAnimatedLogo(),

          const SizedBox(height: 24),

          // Status indicators with emojis
          _buildStatusIndicators(),

          const SizedBox(height: 32),

          // Email Input
          _buildFloatingLabelInput(
            controller: _emailController,
            focusNode: _emailFocusNode,
            label: 'Neural ID',
            hint: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            isFocused: _emailFocused,
            prefixEmoji: '👤',
          ),

          const SizedBox(height: 24),

          // Password Input
          _buildFloatingLabelInput(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            label: 'Access Key',
            hint: 'Enter your password',
            obscureText: true,
            isFocused: _passwordFocused,
            onSubmitted: (_) => _loading ? null : _signIn(),
            prefixEmoji: '🔑',
          ),

          const SizedBox(height: 16),

          // Biometric/Forgot Password Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_biometricAvailable && _biometricEnabled)
                TextButton.icon(
                  onPressed: _authenticateWithBiometrics,
                  icon: const Icon(Icons.fingerprint, color: DesignTokens.accentBlue, size: 20),
                  label: Text(
                    'Biometric',
                    style: DesignTokens.bodySmall.copyWith(color: DesignTokens.accentBlue),
                  ),
                )
              else
                const SizedBox.shrink(),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PasswordResetScreen()),
                  );
                },
                child: Text(
                  'Forgot Password?',
                  style: DesignTokens.bodySmall.copyWith(color: DesignTokens.textSecondary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Initialize Connection Button
          _buildGradientButton(),

          const SizedBox(height: 24),

          // Create Account Link
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignupScreen()),
              );
            },
            child: RichText(
              text: TextSpan(
                style: DesignTokens.bodySmall.copyWith(color: DesignTokens.textSecondary),
                children: [
                  const TextSpan(text: "Don't have an account? "),
                  const TextSpan(
                    text: 'Create Account',
                    style: TextStyle(
                      color: DesignTokens.accentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [DesignTokens.neutralWhite, DesignTokens.accentBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: const Text(
            'VAGUS',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w100,
              letterSpacing: -2,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Neural Fitness Platform',
          style: DesignTokens.bodySmall.copyWith(
            color: DesignTokens.textSecondary,
            letterSpacing: 3,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatusBox('🔐', 'Secure', DesignTokens.accentGreen),
        _buildStatusBox('⚡', 'Fast', DesignTokens.accentBlue),
        _buildStatusBox('🧠', 'Smart', DesignTokens.accentPurple),
      ],
    );
  }

  Widget _buildStatusBox(String emoji, String label, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: DesignTokens.labelSmall.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
    bool obscureText = false,
    TextInputType? keyboardType,
    void Function(String)? onSubmitted,
  }) {
    final hasText = controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedOpacity(
          opacity: isFocused || hasText ? 1.0 : 0.0,
          duration: DesignTokens.durationFast,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: DesignTokens.labelSmall.copyWith(
                color: isFocused ? DesignTokens.accentBlue : DesignTokens.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enabled: !_loading,
          onSubmitted: onSubmitted,
          onChanged: (_) => setState(() {}),
          style: DesignTokens.bodyMedium.copyWith(
            color: DesignTokens.neutralWhite,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: DesignTokens.bodyMedium.copyWith(
              color: DesignTokens.textSecondary.withValues(alpha: 0.5),
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
            filled: true,
            fillColor: DesignTokens.primaryDark.withValues(alpha: 0.6),
            contentPadding: EdgeInsets.symmetric(
              horizontal: prefixEmoji != null ? 8 : 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              borderSide: const BorderSide(color: DesignTokens.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              borderSide: const BorderSide(color: DesignTokens.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              borderSide: const BorderSide(color: DesignTokens.accentBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00c8ff), Color(0xFF0080ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        boxShadow: _loading ? [] : DesignTokens.glowMd,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : _signIn,
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          child: Center(
            child: _loading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Initialize Connection',
                    style: DesignTokens.bodyMedium.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for animated wave lines
class WavesPainter extends CustomPainter {
  final double animationValue;

  WavesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00c8ff).withValues(alpha: 0.08)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paint2 = Paint()
      ..color = const Color(0xFF00ffa3).withValues(alpha: 0.06)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final paint3 = Paint()
      ..color = DesignTokens.accentBlue.withValues(alpha: 0.05)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final bridgePaint = Paint()
      ..color = const Color(0xFF00c8ff).withValues(alpha: 0.04)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw horizontal flowing wave lines (increased to 10)
    for (int i = 0; i < 10; i++) {
      final path = Path();
      final yOffset = size.height * (0.1 + i * 0.09);
      final amplitude = 30.0 + i * 6;
      final frequency = 0.01 + i * 0.003;
      final phase = animationValue * 2 * math.pi + i * 0.3;

      path.moveTo(0, yOffset);

      for (double x = 0; x <= size.width; x += 5) {
        final y = yOffset + amplitude * math.sin(x / size.width) * math.sin(frequency * x + phase);
        path.lineTo(x, y);
      }

      // Alternate between 3 different colors
      final paintToUse = i % 3 == 0 ? paint : (i % 3 == 1 ? paint2 : paint3);
      canvas.drawPath(path, paintToUse);
    }

    // Draw vertical bridge waves connecting pairs of horizontal waves
    for (int waveIndex = 0; waveIndex < 9; waveIndex++) {
      // For each pair of waves, draw vertical bridges
      for (int bridgeIndex = 0; bridgeIndex < 6; bridgeIndex++) {
        final path = Path();
        final xOffset = size.width * (0.12 + bridgeIndex * 0.15);
        final amplitude = 15.0;
        final frequency = 0.03;
        final phase = animationValue * 2 * math.pi + bridgeIndex * 0.4;

        // Calculate exact positions on the horizontal waves
        final waveAmplitude1 = 30.0 + waveIndex * 6;
        final waveFrequency1 = 0.01 + waveIndex * 0.003;
        final wavePhase1 = animationValue * 2 * math.pi + waveIndex * 0.3;
        final baseY1 = size.height * (0.1 + waveIndex * 0.09);
        final yStart = baseY1 + waveAmplitude1 * math.sin(xOffset / size.width) * math.sin(waveFrequency1 * xOffset + wavePhase1);

        final waveAmplitude2 = 30.0 + (waveIndex + 1) * 6;
        final waveFrequency2 = 0.01 + (waveIndex + 1) * 0.003;
        final wavePhase2 = animationValue * 2 * math.pi + (waveIndex + 1) * 0.3;
        final baseY2 = size.height * (0.1 + (waveIndex + 1) * 0.09);
        final yEnd = baseY2 + waveAmplitude2 * math.sin(xOffset / size.width) * math.sin(waveFrequency2 * xOffset + wavePhase2);

        path.moveTo(xOffset, yStart);

        // Draw wave segment between two horizontal waves
        for (double t = 0; t <= 1.0; t += 0.05) {
          final y = yStart + (yEnd - yStart) * t;
          final x = xOffset + amplitude * math.sin(t * math.pi) * math.sin(frequency * y + phase);
          path.lineTo(x, y);
        }

        canvas.drawPath(path, bridgePaint);
      }
    }
  }

  @override
  bool shouldRepaint(WavesPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}

// Custom painter for animated particles
class ParticlesPainter extends CustomPainter {
  final double animationValue;
  static final List<Particle> _particles = _generateParticles();

  ParticlesPainter(this.animationValue);

  static List<Particle> _generateParticles() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(40, (index) { // Fewer particles for better spacing
      return Particle(
        x: ((random + index * 123) % 1000) / 1000,
        y: ((random + index * 456) % 1000) / 1000,
        size: 2.0 + ((random + index * 789) % 100) / 150, // Larger particles
        speed: 0.15 + ((random + index * 234) % 100) / 800, // Slower, smooth movement
        opacity: 0.4 + ((random + index * 567) % 100) / 150, // More visible
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in _particles) {
      final paint = Paint()
        ..color = const Color(0xFF00c8ff).withValues(alpha: particle.opacity * 0.6)
        ..style = PaintingStyle.fill;

      // Calculate particle position with vertical movement
      final y = ((particle.y + animationValue * particle.speed) % 1.0) * size.height;
      final x = particle.x * size.width;

      // Draw particle
      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );

      // Draw subtle glow
      if (particle.size > 2) {
        final glowPaint = Paint()
          ..color = const Color(0xFF00c8ff).withValues(alpha: particle.opacity * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

        canvas.drawCircle(
          Offset(x, y),
          particle.size * 2,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}

// Particle data class
class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}
