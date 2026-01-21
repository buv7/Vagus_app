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
  final _usernameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _emailFocused = false;
  bool _passwordFocused = false;
  bool _confirmPasswordFocused = false;
  bool _nameFocused = false;
  bool _usernameFocused = false;
  bool _agreedToTerms = false;
  
  // Real-time validation states
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String _lastCheckedUsername = '';
  
  // Password strength
  int _passwordStrength = 0; // 0-5 scale

  // Reserved usernames that cannot be used
  static const List<String> _reservedUsernames = [
    'admin', 'administrator', 'vagus', 'support', 'help', 'info',
    'contact', 'official', 'moderator', 'mod', 'staff', 'team',
    'system', 'root', 'null', 'undefined', 'api', 'www', 'mail',
    'email', 'coach', 'client', 'user', 'test', 'demo', 'guest',
  ];

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
    _confirmPasswordFocusNode.addListener(_onConfirmPasswordFocusChange);
    _nameFocusNode.addListener(_onNameFocusChange);
    _usernameFocusNode.addListener(_onUsernameFocusChange);
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

  void _onUsernameFocusChange() {
    setState(() => _usernameFocused = _usernameFocusNode.hasFocus);
  }

  void _onConfirmPasswordFocusChange() {
    setState(() => _confirmPasswordFocused = _confirmPasswordFocusNode.hasFocus);
  }

  // Calculate password strength (0-5)
  void _updatePasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    
    // Cap at 5
    strength = strength > 5 ? 5 : strength;
    
    setState(() {
      _passwordStrength = strength;
    });
  }

  String _getPasswordStrengthText() {
    switch (_passwordStrength) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Fair';
      case 4:
        return 'Strong';
      case 5:
        return 'Very Strong';
      default:
        return '';
    }
  }

  Color _getPasswordStrengthColor() {
    switch (_passwordStrength) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Check username availability in real-time (debounced)
  Timer? _usernameCheckTimer;
  
  void _onUsernameChanged(String value) {
    setState(() {});
    
    // Cancel previous timer
    _usernameCheckTimer?.cancel();
    
    final username = value.trim().toLowerCase();
    
    // Reset if empty or same as last checked
    if (username.isEmpty || username.length < 3) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
      return;
    }
    
    // Validate format first
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(username)) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
      return;
    }
    
    // Check reserved
    if (_reservedUsernames.contains(username)) {
      setState(() {
        _isUsernameAvailable = false;
        _isCheckingUsername = false;
      });
      return;
    }
    
    // Debounce the API call
    setState(() {
      _isCheckingUsername = true;
    });
    
    _usernameCheckTimer = Timer(const Duration(milliseconds: 500), () async {
      if (username == _lastCheckedUsername) return;
      
      final isTaken = await _isUsernameTaken(username);
      
      if (mounted && _usernameController.text.trim().toLowerCase() == username) {
        setState(() {
          _isUsernameAvailable = !isTaken;
          _isCheckingUsername = false;
          _lastCheckedUsername = username;
        });
      }
    });
  }

  @override
  void dispose() {
    _usernameCheckTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _nameFocusNode.dispose();
    _usernameFocusNode.dispose();
    for (var controller in _dotControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Password strength validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  // Username validation
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please choose a username';
    }
    final username = value.trim().toLowerCase();
    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (username.length > 30) {
      return 'Username must be less than 30 characters';
    }
    if (!RegExp(r'^[a-zA-Z]').hasMatch(username)) {
      return 'Username must start with a letter';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Only letters, numbers, and underscores allowed';
    }
    if (_reservedUsernames.contains(username)) {
      return 'This username is reserved. Please choose another';
    }
    return null;
  }

  // Name validation
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    final name = value.trim();
    if (name.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (name.length > 50) {
      return 'Name must be less than 50 characters';
    }
    if (RegExp(r'[0-9]').hasMatch(name)) {
      return 'Name cannot contain numbers';
    }
    if (!RegExp(r'^[a-zA-Z\s\-\.]+$').hasMatch(name)) {
      return 'Name can only contain letters, spaces, hyphens, and dots';
    }
    return null;
  }

  // Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final email = value.trim().toLowerCase();
    // More strict email regex
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    // Block disposable email domains
    const blockedDomains = [
      'tempmail.com', 'guerrillamail.com', 'mailinator.com', 'throwaway.email',
      'temp-mail.org', 'fakeinbox.com', 'trashmail.com', '10minutemail.com',
      'yopmail.com', 'getairmail.com', 'mohmal.com', 'tempail.com',
    ];
    final domain = email.split('@').last;
    if (blockedDomains.contains(domain)) {
      return 'Please use a valid email address (temporary emails not allowed)';
    }
    return null;
  }

  Future<bool> _isUsernameTaken(String username) async {
    final result = await Supabase.instance.client
        .from('profiles')
        .select('username')
        .eq('username', username.toLowerCase())
        .maybeSingle();
    return result != null;
  }

  Future<bool> _isEmailRegistered(String email) async {
    final result = await Supabase.instance.client
        .from('profiles')
        .select('email')
        .eq('email', email.toLowerCase())
        .maybeSingle();
    return result != null;
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if user agreed to terms
    if (!_agreedToTerms) {
      _showSnackBar('Please agree to the Terms of Service and Privacy Policy');
      return;
    }

    setState(() => _loading = true);
    unawaited(HapticFeedback.mediumImpact());

    try {
      // Check if username is already taken
      final username = _usernameController.text.trim();
      if (username.isNotEmpty) {
        final isTaken = await _isUsernameTaken(username);
        if (isTaken) {
          setState(() => _loading = false);
          _showSnackBar('Username is already taken. Please choose another one.');
          return;
        }
      }

      // Check if email is already registered
      final email = _emailController.text.trim();
      final isEmailTaken = await _isEmailRegistered(email);
      if (isEmailTaken) {
        setState(() => _loading = false);
        _showSnackBar('This email is already registered. Please sign in or use a different email.');
        return;
      }

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
        'username': _usernameController.text.trim().isEmpty
            ? null
            : _usernameController.text.trim().toLowerCase(),
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
                fontWeight: FontWeight.w300,
                letterSpacing: 8,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Subtitle with shimmer
        FadeInAnimation(
          delay: const Duration(milliseconds: 400),
          child: Shimmer.fromColors(
            baseColor: Colors.white,
            highlightColor: const Color(0xFF00C8FF),
            period: const Duration(seconds: 3),
            child: const Text(
              'THE MOST ADVANCED IRAQI ONLINE FITNESS\nCOACHING PLATFORM',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.5,
                height: 1.4,
              ),
            ),
          ),
        ),

        const SizedBox(height: 48),

        // Description
        FadeInAnimation(
          delay: const Duration(milliseconds: 600),
          child: Text(
            'Join the revolution in fitness training. Create your account and unlock personalized coaching powered by VAGUS.',
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
                fontWeight: FontWeight.w300,
                letterSpacing: 8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FadeInAnimation(
          delay: const Duration(milliseconds: 400),
          child: Shimmer.fromColors(
            baseColor: Colors.white,
            highlightColor: const Color(0xFF00C8FF),
            period: const Duration(seconds: 3),
            child: const Text(
              'THE MOST ADVANCED IRAQI ONLINE FITNESS\nCOACHING PLATFORM',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.5,
                height: 1.4,
              ),
            ),
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

              const SizedBox(height: 12),

              // Inspirational quote
              Text(
                'YOUR JOURNEY TO GREATNESS STARTS HERE.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF00C8FF).withValues(alpha: 0.8),
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Name field
              _buildFloatingLabelInput(
                controller: _nameController,
                focusNode: _nameFocusNode,
                label: 'Full Name',
                hint: 'Enter your name',
                isFocused: _nameFocused,
                prefixEmoji: '👤',
                validator: _validateName,
              ),

              const SizedBox(height: 16),

              // Username field with availability indicator
              _buildFloatingLabelInput(
                controller: _usernameController,
                focusNode: _usernameFocusNode,
                label: 'Username',
                hint: 'Choose a unique username',
                isFocused: _usernameFocused,
                prefixEmoji: '@',
                validator: _validateUsername,
                onChanged: _onUsernameChanged,
                suffixIcon: _buildUsernameAvailabilityIndicator(),
              ),

              const SizedBox(height: 16),

              // Email field
              _buildFloatingLabelInput(
                controller: _emailController,
                focusNode: _emailFocusNode,
                label: 'Email',
                hint: 'your@email.com',
                keyboardType: TextInputType.emailAddress,
                isFocused: _emailFocused,
                prefixEmoji: '📧',
                validator: _validateEmail,
              ),

              const SizedBox(height: 16),

              // Password field with strength indicator
              _buildFloatingLabelInput(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                label: 'Password',
                hint: 'Min 8 chars, upper, lower, number, symbol',
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
                validator: _validatePassword,
                onChanged: _updatePasswordStrength,
              ),
              
              // Password strength indicator
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _passwordStrength / 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(_getPasswordStrengthColor()),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getPasswordStrengthText(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _getPasswordStrengthColor(),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Confirm Password field
              _buildFloatingLabelInput(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocusNode,
                label: 'Confirm Password',
                hint: 'Re-enter your password',
                obscureText: _obscureConfirmPassword,
                isFocused: _confirmPasswordFocused,
                prefixEmoji: '🔐',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                onSubmitted: (_) => _handleSignup(),
              ),

              const SizedBox(height: 20),

              // Terms and Privacy checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      onChanged: _loading ? null : (value) {
                        setState(() {
                          _agreedToTerms = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFF00C8FF),
                      checkColor: Colors.black,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _loading ? null : () {
                        setState(() {
                          _agreedToTerms = !_agreedToTerms;
                        });
                      },
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: const Color(0xFF00C8FF),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: const Color(0xFF00C8FF),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

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

  Widget? _buildUsernameAvailabilityIndicator() {
    final username = _usernameController.text.trim();
    
    if (username.isEmpty || username.length < 3) {
      return null;
    }
    
    if (_isCheckingUsername) {
      return const Padding(
        padding: EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C8FF)),
          ),
        ),
      );
    }
    
    if (_isUsernameAvailable == true) {
      return const Padding(
        padding: EdgeInsets.only(right: 12),
        child: Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 22,
        ),
      );
    }
    
    if (_isUsernameAvailable == false) {
      return const Padding(
        padding: EdgeInsets.only(right: 12),
        child: Icon(
          Icons.cancel,
          color: Colors.red,
          size: 22,
        ),
      );
    }
    
    return null;
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
    void Function(String)? onChanged,
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
          onChanged: (value) {
            setState(() {});
            onChanged?.call(value);
          },
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
    // Safety check - don't render if animations aren't ready
    if (_dotControllers.length < 5) {
      return const SizedBox.shrink();
    }
    
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
