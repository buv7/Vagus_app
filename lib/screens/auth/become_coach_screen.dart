import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply to Become a Coach'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Coach Application',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tell us about your coaching experience and qualifications.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              
              // Bio Field
              const Text(
                'Bio',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  hintText: 'Tell us about your coaching philosophy, experience, and what makes you unique...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: _validateBio,
              ),
              const SizedBox(height: 24),
              
              // Specialization Field
              const Text(
                'Primary Specialization',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSpecialization,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
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
              const SizedBox(height: 24),
              
              // Years of Experience Field
              const Text(
                'Years of Experience',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _yearsExperienceController,
                decoration: const InputDecoration(
                  hintText: 'e.g., 5',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: _validateYearsExperience,
              ),
              const SizedBox(height: 24),
              
              // Certifications Field
              const Text(
                'Certifications & Qualifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _certificationsController,
                decoration: const InputDecoration(
                  hintText: 'List your relevant certifications, licenses, and qualifications...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: _validateCertifications,
              ),
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Application',
                          style: TextStyle(fontSize: 16),
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
