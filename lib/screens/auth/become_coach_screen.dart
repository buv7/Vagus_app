import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';

class BecomeCoachScreen extends StatefulWidget {
  const BecomeCoachScreen({super.key});

  @override
  State<BecomeCoachScreen> createState() => _BecomeCoachScreenState();
}

class _BecomeCoachScreenState extends State<BecomeCoachScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _certificationsController = TextEditingController();
  final _yearsExperienceController = TextEditingController();
  
  String _selectedSpecialization = 'Fitness';
  bool _loading = false;
  
  final List<String> _specializations = [
    'Fitness',
    'Nutrition',
    'Wellness',
    'Sports',
    'Rehabilitation',
    'Yoga',
    'CrossFit',
    'Strength Training',
    'Cardio',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _checkExistingApplication();
  }

  Future<void> _checkExistingApplication() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('coach_applications')
          .select('status, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final status = response['status'] as String;
        if (status == 'pending') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You already have a pending coach application.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop();
        } else if (status == 'approved') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your coach application has been approved!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (status == 'rejected') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your previous coach application was rejected. You can submit a new one.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking existing application: $e');
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _certificationsController.dispose();
    _yearsExperienceController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await Supabase.instance.client.from('coach_applications').insert({
        'user_id': user.id,
        'bio': _bioController.text.trim(),
        'specialization': _selectedSpecialization,
        'years_experience': int.tryParse(_yearsExperienceController.text.trim()) ?? 0,
        'certifications': _certificationsController.text.trim(),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Coach application submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to submit application: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String? _validateBio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please provide a bio';
    }
    if (value.trim().length < 50) {
      return 'Bio must be at least 50 characters long';
    }
    return null;
  }

  String? _validateYearsExperience(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter years of experience';
    }
    final years = int.tryParse(value.trim());
    if (years == null || years < 0) {
      return 'Please enter a valid number of years';
    }
    if (years > 50) {
      return 'Please enter a realistic number of years';
    }
    return null;
  }

  String? _validateCertifications(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please list your certifications';
    }
    if (value.trim().length < 10) {
      return 'Please provide more details about your certifications';
    }
    return null;
  }

  Widget _buildModernFormField({
    required String label,
    required IconData icon,
    required Widget child,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF1a1a2e);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: textColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1a1a2e);
    final subtitleColor = isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF4a4a5a);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0B1220),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              _buildGlassmorphicCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.school,
                          color: textColor.withValues(alpha: 0.9),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Coach Application',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell us about your coaching experience and qualifications.',
                      style: TextStyle(
                        fontSize: 14,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bio Field
              _buildModernFormField(
                label: 'Bio',
                icon: Icons.person,
                isDark: isDark,
                child: _buildGlassmorphicTextField(
                  controller: _bioController,
                  hintText: 'Tell us about your coaching philosophy, experience, and what makes you unique...',
                  maxLines: 4,
                  validator: _validateBio,
                  isDark: isDark,
                ),
              ),
              
              // Specialization Field
              _buildModernFormField(
                label: 'Primary Specialization',
                icon: Icons.category,
                isDark: isDark,
                child: _buildGlassmorphicDropdown(isDark: isDark),
              ),
              
              // Years of Experience Field
              _buildModernFormField(
                label: 'Years of Experience',
                icon: Icons.schedule,
                isDark: isDark,
                child: _buildGlassmorphicTextField(
                  controller: _yearsExperienceController,
                  hintText: 'e.g., 5',
                  keyboardType: TextInputType.number,
                  validator: _validateYearsExperience,
                  isDark: isDark,
                ),
              ),
              
              // Certifications Field
              _buildModernFormField(
                label: 'Certifications & Qualifications',
                icon: Icons.verified,
                isDark: isDark,
                child: _buildGlassmorphicTextField(
                  controller: _certificationsController,
                  hintText: 'List your relevant certifications, licenses, and qualifications...',
                  maxLines: 3,
                  validator: _validateCertifications,
                  isDark: isDark,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              _buildGlassmorphicButton(
                onPressed: _loading ? null : _submitApplication,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Submit Application',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Info Card
              _buildGlassmorphicCard(
                color: DesignTokens.accentBlue.withValues(alpha: 0.15),
                isDark: isDark,
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: textColor.withValues(alpha: 0.8)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your application will be reviewed by our admin team. You\'ll be notified once a decision is made.',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicCard({required Widget child, Color? color, required bool isDark}) {
    final baseColor = color ?? DesignTokens.accentBlue;
    final bgAlpha = isDark ? 0.25 : 0.12;
    final bgAlphaSecondary = isDark ? 0.1 : 0.05;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 2.0,
              colors: [
                baseColor.withValues(alpha: bgAlpha),
                baseColor.withValues(alpha: bgAlphaSecondary),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.35 : 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassmorphicTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF1a1a2e);
    final hintColor = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6a6a7a);
    
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: textColor, fontSize: 14),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: hintColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: DesignTokens.accentBlue.withValues(alpha: 0.6), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicDropdown({required bool isDark}) {
    final textColor = isDark ? Colors.white : const Color(0xFF1a1a2e);
    final iconColor = isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF4a4a5a);
    
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedSpecialization,
        dropdownColor: isDark 
            ? DesignTokens.accentBlue.withValues(alpha: 0.95) 
            : Colors.white,
        style: TextStyle(color: textColor, fontSize: 14),
        icon: Icon(Icons.keyboard_arrow_down, color: iconColor),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: DesignTokens.accentBlue.withValues(alpha: 0.6), width: 2),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: _specializations.map((String specialization) {
          return DropdownMenuItem<String>(
            value: specialization,
            child: Text(specialization),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedSpecialization = newValue!;
          });
        },
      ),
    );
  }

  Widget _buildGlassmorphicButton({required VoidCallback? onPressed, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 2.0,
              colors: [
                DesignTokens.accentBlue.withValues(alpha: 0.4),
                DesignTokens.accentBlue.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DesignTokens.accentBlue.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
