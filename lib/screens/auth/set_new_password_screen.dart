import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    try {
      final newPwd = _passwordController.text.trim();
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPwd),
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated. Please log in.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back to login screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryDark,
              AppTheme.primaryDark.withValues(alpha: 0.8),
              AppTheme.accentGreen.withValues(alpha: 0.1),
            ],
          ) : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
              AppTheme.accentGreen.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom app bar with glassmorphic effect
              Container(
                margin: const EdgeInsets.all(DesignTokens.space16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.radius16),
                  color: AppTheme.cardBackground.withValues(alpha: 0.7),
                  border: Border.all(
                    color: AppTheme.accentGreen.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radius16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space16,
                        vertical: DesignTokens.space12,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: AppTheme.neutralWhite,
                              size: 20,
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'Set New Password',
                              style: TextStyle(
                                color: AppTheme.neutralWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48), // Balance the back button
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.space24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Main glassmorphic card
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(DesignTokens.radius24),
                            color: AppTheme.cardBackground.withValues(alpha: 0.7),
                            border: Border.all(
                              color: AppTheme.accentGreen.withValues(alpha: 0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(DesignTokens.radius24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Padding(
                                padding: const EdgeInsets.all(DesignTokens.space32),
                                child: Column(
                                  children: [
                                    // Header
                                    const Icon(
                                      Icons.lock_reset,
                                      size: 48,
                                      color: AppTheme.accentGreen,
                                    ),
                                    const SizedBox(height: DesignTokens.space16),
                                    const Text(
                                      'Set your new password',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.neutralWhite,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: DesignTokens.space8),
                                    const Text(
                                      'Enter your new password below.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: DesignTokens.textSecondary,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: DesignTokens.space32),
                                    
                                    // Password field
                                    _buildGlassmorphicTextField(
                                      controller: _passwordController,
                                      label: 'New Password',
                                      icon: Icons.lock_outline,
                                      obscureText: _obscurePassword,
                                      validator: _validatePassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                          color: DesignTokens.textSecondary,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: DesignTokens.space16),
                                    
                                    // Confirm password field
                                    _buildGlassmorphicTextField(
                                      controller: _confirmPasswordController,
                                      label: 'Confirm New Password',
                                      icon: Icons.lock_outline,
                                      obscureText: _obscureConfirmPassword,
                                      validator: _validateConfirmPassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                          color: DesignTokens.textSecondary,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirmPassword = !_obscureConfirmPassword;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: DesignTokens.space32),
                                    
                                    // Update button
                                    _buildGlassmorphicButton(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildGlassmorphicTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        color: AppTheme.cardBackground.withValues(alpha: 0.5),
        border: Border.all(
          color: AppTheme.accentGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            enabled: !_loading,
            style: const TextStyle(color: AppTheme.neutralWhite),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: DesignTokens.textSecondary),
              prefixIcon: Icon(icon, color: AppTheme.accentGreen),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space16,
                vertical: DesignTokens.space16,
              ),
              filled: false,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        gradient: LinearGradient(
          colors: [
            AppTheme.accentGreen,
            AppTheme.accentGreen.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGreen.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _loading ? null : _updatePassword,
              borderRadius: BorderRadius.circular(DesignTokens.radius16),
              child: Center(
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Update Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
