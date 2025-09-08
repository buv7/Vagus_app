import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

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

      // Insert coach application into coach_applications table
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

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Coach application submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppTheme.mintAqua,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Apply to become a Coach',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2F33),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.mintAqua.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.school,
                          color: AppTheme.mintAqua,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Coach Application',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell us about your coaching experience and qualifications.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
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
                child: TextFormField(
                  controller: _bioController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tell us about your coaching philosophy, experience, and what makes you unique...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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
                      borderSide: BorderSide(color: AppTheme.mintAqua, width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1C1E),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator: _validateBio,
                ),
              ),
              
              // Specialization Field
              _buildModernFormField(
                label: 'Primary Specialization',
                icon: Icons.category,
                child: DropdownButtonFormField<String>(
                  value: _selectedSpecialization,
                  dropdownColor: const Color(0xFF2C2F33),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
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
                      borderSide: BorderSide(color: AppTheme.mintAqua, width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1C1E),
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
              ),
              
              // Years of Experience Field
              _buildModernFormField(
                label: 'Years of Experience',
                icon: Icons.schedule,
                child: TextFormField(
                  controller: _yearsExperienceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g., 5',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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
                      borderSide: BorderSide(color: AppTheme.mintAqua, width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1C1E),
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateYearsExperience,
                ),
              ),
              
              // Certifications Field
              _buildModernFormField(
                label: 'Certifications & Qualifications',
                icon: Icons.verified,
                child: TextFormField(
                  controller: _certificationsController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'List your relevant certifications, licenses, and qualifications...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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
                      borderSide: BorderSide(color: AppTheme.mintAqua, width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1C1E),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  validator: _validateCertifications,
                ),
              ),
              const SizedBox(height: 24),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mintAqua,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
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
                            Icon(Icons.send, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Submit Application',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Info Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your application will be reviewed by our admin team. You\'ll be notified once a decision is made.',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
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
}
