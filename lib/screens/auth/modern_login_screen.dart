import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../theme/design_tokens.dart';
import 'signup_screen.dart';
import 'password_reset_screen.dart';
import '../nav/main_nav.dart';

class ModernLoginScreen extends StatefulWidget {
  const ModernLoginScreen({super.key});

  @override
  State<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends State<ModernLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _localAuth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();
  
  bool _isLoading = false;
  bool _showPassword = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String? _storedUserEmail;
  String? _errorMessage;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late AnimationController _neonController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _neonAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkBiometricAvailability();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _neonController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.linear,
    ));
    
    _neonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _neonController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
    _slideController.forward();
    _backgroundController.repeat();
    _neonController.repeat(reverse: true);
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isEnabled = await _secureStorage.read(key: 'biometric_enabled') == 'true';
      final String? storedEmail = await _secureStorage.read(key: 'stored_user_email');
      
      setState(() {
        _biometricAvailable = isAvailable;
        _biometricEnabled = isEnabled;
        _storedUserEmail = storedEmail;
      });
    } catch (e) {
      debugPrint('Failed to check biometric availability: $e');
    }
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        // Store credentials for biometric authentication
        await _secureStorage.write(key: 'stored_user_email', value: _emailController.text.trim());
        await _secureStorage.write(key: 'biometric_enabled', value: 'true');
        
        // Navigate to main app
        if (mounted) {
          unawaited(Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNav()),
          ));
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Please enter valid credentials';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleBiometricAuth() async {
    if (!_biometricAvailable || _storedUserEmail == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your VAGUS account',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        // Get stored password (in real app, you'd use a more secure method)
        final String? storedPassword = await _secureStorage.read(key: 'stored_password');
        
        if (storedPassword != null) {
          final response = await Supabase.instance.client.auth.signInWithPassword(
            email: _storedUserEmail!,
            password: storedPassword,
          );

          if (response.user != null && mounted) {
            unawaited(Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainNav()),
            ));
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Biometric authentication failed';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _showPassword = !_showPassword;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    _neonController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: AnimatedBackgroundPainter(
            animation: _backgroundAnimation.value,
            neonAnimation: _neonAnimation.value,
          ),
        );
      },
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo Section
                          Container(
                            width: 80,
                            height: 80,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: DesignTokens.accentGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: DesignTokens.accentGreen.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                'assets/branding/vagus_logo_white.png',
                                width: 48,
                                height: 48,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          
                          // Title
                          Text(
                            'Welcome to VAGUS',
                            style: DesignTokens.titleLarge.copyWith(
                              color: DesignTokens.neutralWhite,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Subtitle
                          const Text(
                            'Sign in to your client portal',
                            style: TextStyle(
                              fontSize: 16,
                              color: DesignTokens.textSecondary, // Ash gray
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Email Field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Email',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFF5F7FA),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: DesignTokens.neutralWhite),
                                decoration: InputDecoration(
                                  hintText: 'Enter your email',
                                  hintStyle: TextStyle(
                                    color: DesignTokens.textSecondary.withValues(alpha: 0.7),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF1A1C1E).withValues(alpha: 0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: DesignTokens.accentGreen,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Password Field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFF5F7FA),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_showPassword,
                                style: const TextStyle(color: DesignTokens.neutralWhite),
                                decoration: InputDecoration(
                                  hintText: 'Enter your password',
                                  hintStyle: TextStyle(
                                    color: DesignTokens.textSecondary.withValues(alpha: 0.7),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF1A1C1E).withValues(alpha: 0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: DesignTokens.accentGreen,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: _togglePasswordVisibility,
                                    icon: Icon(
                                      _showPassword ? Icons.visibility_off : Icons.visibility,
                                      color: DesignTokens.textSecondary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Error Message
                          if (_errorMessage != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5A5A).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFF5A5A).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFFF5A5A),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          
                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DesignTokens.accentGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white.withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Signing In...'),
                                      ],
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Biometric Authentication Button
                          if (_biometricAvailable && _biometricEnabled)
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _handleBiometricAuth,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFF5F7FA),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.fingerprint, size: 20),
                                label: const Text('Biometric Authentication'),
                              ),
                            ),
                          
                          const SizedBox(height: 24),
                          
                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  thickness: 1,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR CONTINUE WITH',
                                  style: TextStyle(
                                    color: DesignTokens.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Forgot Password Link
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PasswordResetScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: DesignTokens.accentGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Don\'t have an account? ',
                                style: TextStyle(
                                  color: DesignTokens.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SignupScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: DesignTokens.accentGreen,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? DesignTokens.darkGradient : LinearGradient(
            colors: [theme.scaffoldBackgroundColor, theme.scaffoldBackgroundColor],
          ),
        ),
        child: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),
          
          // Main Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 448),
                      child: _buildLoginCard(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class AnimatedBackgroundPainter extends CustomPainter {
  final double animation;
  final double neonAnimation;

  AnimatedBackgroundPainter({
    required this.animation,
    required this.neonAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Create gradient background
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF1A1C1E),
        const Color(0xFF2C2F33).withValues(alpha: 0.3),
        const Color(0xFF1A1C1E),
      ],
      stops: [0.0, 0.5, 1.0],
    );
    
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final shader = gradient.createShader(rect);
    paint.shader = shader;
    canvas.drawRect(rect, paint);
    
    // Animated floating circles
    _drawFloatingCircles(canvas, size);
    
    // Neon wave lines
    _drawNeonWaves(canvas, size);
    
    // Animated particles
    _drawParticles(canvas, size);
  }

  void _drawFloatingCircles(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DesignTokens.accentGreen.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = DesignTokens.accentGreen.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Circle 1 - Top left
    final circle1X = size.width * 0.2 + math.sin(animation * 2 * math.pi) * 20;
    final circle1Y = size.height * 0.3 + math.cos(animation * 2 * math.pi) * 15;
    canvas.drawCircle(
      Offset(circle1X, circle1Y),
      60 + math.sin(animation * 3 * math.pi) * 10,
      paint,
    );
    canvas.drawCircle(
      Offset(circle1X, circle1Y),
      60 + math.sin(animation * 3 * math.pi) * 10,
      strokePaint,
    );
    
    // Circle 2 - Bottom right
    final circle2X = size.width * 0.8 + math.cos(animation * 2.5 * math.pi) * 25;
    final circle2Y = size.height * 0.7 + math.sin(animation * 2.5 * math.pi) * 20;
    canvas.drawCircle(
      Offset(circle2X, circle2Y),
      80 + math.cos(animation * 2 * math.pi) * 15,
      paint,
    );
    canvas.drawCircle(
      Offset(circle2X, circle2Y),
      80 + math.cos(animation * 2 * math.pi) * 15,
      strokePaint,
    );
    
    // Circle 3 - Center
    final circle3X = size.width * 0.5 + math.sin(animation * 1.5 * math.pi) * 30;
    final circle3Y = size.height * 0.5 + math.cos(animation * 1.5 * math.pi) * 25;
    canvas.drawCircle(
      Offset(circle3X, circle3Y),
      40 + math.sin(animation * 4 * math.pi) * 8,
      paint,
    );
    canvas.drawCircle(
      Offset(circle3X, circle3Y),
      40 + math.sin(animation * 4 * math.pi) * 8,
      strokePaint,
    );
  }

  void _drawNeonWaves(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DesignTokens.accentGreen.withValues(alpha: 0.1 + neonAnimation * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Create multiple wave layers
    for (int waveLayer = 0; waveLayer < 4; waveLayer++) {
      final path = Path();
      final waveHeight = 30 + waveLayer * 15;
      final waveFrequency = 0.02 + waveLayer * 0.005;
      final waveSpeed = animation * (1 + waveLayer * 0.3);
      final baseY = size.height * 0.2 + waveLayer * size.height * 0.2;
      
      // Start the wave path
      path.moveTo(0, baseY);
      
      // Draw the wave
      for (double x = 0; x <= size.width; x += 2) {
        final y = baseY + 
            math.sin(x * waveFrequency + waveSpeed * 2 * math.pi) * waveHeight +
            math.sin(x * waveFrequency * 0.5 + waveSpeed * 3 * math.pi) * (waveHeight * 0.3);
        path.lineTo(x, y);
      }
      
      // Set wave opacity and color
      final opacity = 0.1 + math.sin(animation * 2 * math.pi + waveLayer * 0.5) * 0.05;
      paint.color = DesignTokens.accentGreen.withValues(alpha: opacity);
      
      // Draw the wave
      canvas.drawPath(path, paint);
      
      // Add a second wave with different phase for depth
      final path2 = Path();
      path2.moveTo(0, baseY + 20);
      
      for (double x = 0; x <= size.width; x += 2) {
        final y = baseY + 20 + 
            math.cos(x * waveFrequency * 1.3 + waveSpeed * 2.5 * math.pi) * (waveHeight * 0.7) +
            math.sin(x * waveFrequency * 0.8 + waveSpeed * 4 * math.pi) * (waveHeight * 0.2);
        path2.lineTo(x, y);
      }
      
      final opacity2 = 0.05 + math.cos(animation * 2 * math.pi + waveLayer * 0.7) * 0.03;
      paint.color = DesignTokens.accentGreen.withValues(alpha: opacity2);
      canvas.drawPath(path2, paint);
    }
    
    // Add some flowing diagonal waves
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final startX = -100.0 + i * 200.0;
      final startY = size.height * 0.1 + i * size.height * 0.3;
      // final waveLength = 150.0 + i * 50.0;
      
      path.moveTo(startX, startY);
      
      for (double t = 0; t <= 2; t += 0.02) {
        final x = startX + t * size.width * 0.8;
        final y = startY + 
            math.sin(t * 4 * math.pi + animation * 3 * math.pi + i * 0.5) * 40 +
            t * size.height * 0.3;
        path.lineTo(x, y);
      }
      
      final opacity = 0.08 + math.sin(animation * 2 * math.pi + i * 1.2) * 0.04;
      paint.color = DesignTokens.accentGreen.withValues(alpha: opacity);
      canvas.drawPath(path, paint);
    }
  }

  void _drawParticles(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = DesignTokens.accentGreen.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 20; i++) {
      final x = (canvasSize.width * i / 20 + animation * 50) % canvasSize.width;
      final y = canvasSize.height * 0.2 + math.sin(animation * 2 * math.pi + i * 0.5) * 100;
      final particleSize = 2 + math.sin(animation * 3 * math.pi + i * 0.3) * 1;
      
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(AnimatedBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.neonAnimation != neonAnimation;
  }
}