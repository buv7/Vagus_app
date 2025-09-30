import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/coach/coach_profile.dart';
import '../../services/coach_portfolio_service.dart';
import '../../services/coaches/coach_repository.dart';
import '../../widgets/branding/vagus_appbar.dart';
import '../../theme/app_theme.dart';

class PortfolioEditScreen extends StatefulWidget {
  final CoachProfile? existingProfile;

  const PortfolioEditScreen({super.key, this.existingProfile});

  @override
  State<PortfolioEditScreen> createState() => _PortfolioEditScreenState();
}

class _PortfolioEditScreenState extends State<PortfolioEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _headlineController = TextEditingController();
  final _bioController = TextEditingController();
  final _introVideoUrlController = TextEditingController();
  
  final CoachPortfolioService _portfolioService = CoachPortfolioService();
  final CoachRepository _coachRepository = CoachRepository();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<String> _specialties = [];
  final List<String> _availableSpecialties = [
    'Weight Loss',
    'Muscle Building',
    'Strength Training',
    'Cardio Fitness',
    'Nutrition Coaching',
    'Bodybuilding',
    'Powerlifting',
    'CrossFit',
    'Yoga',
    'Pilates',
    'Functional Training',
    'Sports Performance',
    'Rehabilitation',
    'Senior Fitness',
    'Youth Training',
    'Prenatal/Postnatal',
    'Flexibility & Mobility',
    'Endurance Training',
    'HIIT',
    'Bodyweight Training',
  ];
  
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  void _loadExistingProfile() {
    if (widget.existingProfile != null) {
      _displayNameController.text = widget.existingProfile!.displayName ?? '';
      _usernameController.text = widget.existingProfile!.username ?? '';
      _headlineController.text = widget.existingProfile!.headline ?? '';
      _bioController.text = widget.existingProfile!.bio ?? '';
      _introVideoUrlController.text = widget.existingProfile!.introVideoUrl ?? '';
      _specialties = List.from(widget.existingProfile!.specialties);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _headlineController.dispose();
    _bioController.dispose();
    _introVideoUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final profile = CoachProfile(
        coachId: user.id,
        displayName: _displayNameController.text.trim(),
        username: _usernameController.text.trim().isEmpty
            ? null
            : _usernameController.text.trim(),
        headline: _headlineController.text.trim(),
        bio: _bioController.text.trim(),
        specialties: _specialties,
        introVideoUrl: _introVideoUrlController.text.trim().isEmpty
            ? null
            : _introVideoUrlController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await _portfolioService.createOrUpdateProfile(profile);

      // Update username in profiles table if provided
      if (_usernameController.text.trim().isNotEmpty) {
        await _coachRepository.updateUsername(_usernameController.text.trim());
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Portfolio updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VagusAppBar(title: Text('Edit Portfolio')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading portfolio',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _error = null;
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryDark,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COACH PORTFOLIO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create a compelling profile that attracts the right clients',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Display Name
                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name *',
                          hintText: 'How clients will see your name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Display name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Username
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username (optional)',
                          hintText: 'e.g., johndoe (3-24 characters, a-z, 0-9, ., _)',
                          border: OutlineInputBorder(),
                          prefixText: '@',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null; // Username is optional
                          }
                          final username = value.trim().toLowerCase();
                          if (username.length < 3 || username.length > 24) {
                            return 'Username must be 3-24 characters';
                          }
                          if (!RegExp(r'^[a-z0-9._]+$').hasMatch(username)) {
                            return 'Username can only contain letters, numbers, dots, and underscores';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          // Convert to lowercase automatically
                          final cursorPos = _usernameController.selection;
                          _usernameController.value = _usernameController.value.copyWith(
                            text: value.toLowerCase(),
                            selection: cursorPos,
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Headline
                      TextFormField(
                        controller: _headlineController,
                        decoration: const InputDecoration(
                          labelText: 'Professional Headline *',
                          hintText: 'e.g., "Certified Personal Trainer & Nutrition Coach"',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Professional headline is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Bio
                      TextFormField(
                        controller: _bioController,
                        decoration: const InputDecoration(
                          labelText: 'Bio *',
                          hintText: 'Tell clients about your experience, approach, and what makes you unique',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bio is required';
                          }
                          if (value.trim().length < 50) {
                            return 'Bio should be at least 50 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Specialties
                      _buildSpecialtiesSection(),

                      const SizedBox(height: 16),

                      // Intro Video URL
                      TextFormField(
                        controller: _introVideoUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Intro Video URL *',
                          hintText: '30-second "Why choose me?" video URL',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Intro video is required';
                          }
                          final uri = Uri.tryParse(value.trim());
                          if (uri == null || !uri.hasAbsolutePath) {
                            return 'Please enter a valid URL';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Save Portfolio',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSpecialtiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specialties',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select your areas of expertise (choose at least 3)',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        
        // Selected specialties
        if (_specialties.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _specialties.map((specialty) {
              return Chip(
                label: Text(specialty),
                onDeleted: () {
                  setState(() {
                    _specialties.remove(specialty);
                  });
                },
                deleteIcon: const Icon(Icons.close, size: 18),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        
        // Available specialties
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.lightGrey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _availableSpecialties.length,
            itemBuilder: (context, index) {
              final specialty = _availableSpecialties[index];
              final isSelected = _specialties.contains(specialty);
              
              return CheckboxListTile(
                title: Text(specialty),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _specialties.add(specialty);
                    } else {
                      _specialties.remove(specialty);
                    }
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            },
          ),
        ),
        
        if (_specialties.length < 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least 3 specialties',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
