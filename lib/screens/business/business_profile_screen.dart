import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessTypeController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _servicesController = TextEditingController();
  final TextEditingController _pricingController = TextEditingController();
  
  Map<String, dynamic>? _businessProfile;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessTypeController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _servicesController.dispose();
    _pricingController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      // Try to load from business_profiles table
      final response = await supabase
          .from('business_profiles')
          .select('*')
          .eq('coach_id', user.id)
          .single();

      setState(() {
        _businessProfile = response;
        _loading = false;
      });

      // Populate form fields
      _businessNameController.text = response['business_name'] ?? '';
      _businessTypeController.text = response['business_type'] ?? '';
      _websiteController.text = response['website'] ?? '';
      _addressController.text = response['address'] ?? '';
      _cityController.text = response['city'] ?? '';
      _stateController.text = response['state'] ?? '';
      _zipCodeController.text = response['zip_code'] ?? '';
      _countryController.text = response['country'] ?? '';
      _phoneController.text = response['phone'] ?? '';
      _descriptionController.text = response['description'] ?? '';
      _servicesController.text = response['services'] ?? '';
      _pricingController.text = response['pricing'] ?? '';
    } catch (e) {
      // If no business profile exists, create default
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveBusinessProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final businessData = {
        'coach_id': user.id,
        'business_name': _businessNameController.text.trim(),
        'business_type': _businessTypeController.text.trim(),
        'website': _websiteController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'zip_code': _zipCodeController.text.trim(),
        'country': _countryController.text.trim(),
        'phone': _phoneController.text.trim(),
        'description': _descriptionController.text.trim(),
        'services': _servicesController.text.trim(),
        'pricing': _pricingController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_businessProfile != null) {
        // Update existing profile
        await supabase
            .from('business_profiles')
            .update(businessData)
            .eq('coach_id', user.id);
      } else {
        // Create new profile
        businessData['created_at'] = DateTime.now().toIso8601String();
        await supabase.from('business_profiles').insert(businessData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business profile saved successfully'),
            backgroundColor: DesignTokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving business profile: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppTheme.neutralWhite),
        ),
        title: const Text(
          'Business Profile',
          style: TextStyle(color: AppTheme.neutralWhite),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.mintAqua),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveBusinessProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppTheme.mintAqua,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.mintAqua),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.space20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Business Information
                    _buildSectionTitle('Business Information'),
                    const SizedBox(height: DesignTokens.space16),

                    _buildTextField(
                      controller: _businessNameController,
                      label: 'Business Name',
                      hint: 'Enter your business name',
                      icon: Icons.business,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Business name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: DesignTokens.space16),

                    _buildTextField(
                      controller: _businessTypeController,
                      label: 'Business Type',
                      hint: 'e.g., Personal Training, Nutrition Coaching',
                      icon: Icons.category,
                    ),

                    const SizedBox(height: DesignTokens.space16),

                    _buildTextField(
                      controller: _websiteController,
                      label: 'Website',
                      hint: 'https://yourwebsite.com',
                      icon: Icons.language,
                      keyboardType: TextInputType.url,
                    ),

                    const SizedBox(height: DesignTokens.space16),

                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Business Description',
                      hint: 'Describe your business and what you offer',
                      icon: Icons.description,
                      maxLines: 3,
                    ),

                    const SizedBox(height: DesignTokens.space32),

                    // Contact Information
                    _buildSectionTitle('Contact Information'),
                    const SizedBox(height: DesignTokens.space16),

                    _buildTextField(
                      controller: _phoneController,
                      label: 'Business Phone',
                      hint: 'Enter your business phone number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: DesignTokens.space16),

                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter your business address',
                      icon: Icons.location_on,
                    ),

                    const SizedBox(height: DesignTokens.space16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _cityController,
                            label: 'City',
                            hint: 'Enter city',
                            icon: Icons.location_city,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.space16),
                        Expanded(
                          child: _buildTextField(
                            controller: _stateController,
                            label: 'State',
                            hint: 'Enter state',
                            icon: Icons.map,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: DesignTokens.space16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _zipCodeController,
                            label: 'ZIP Code',
                            hint: 'Enter ZIP code',
                            icon: Icons.pin_drop,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.space16),
                        Expanded(
                          child: _buildTextField(
                            controller: _countryController,
                            label: 'Country',
                            hint: 'Enter country',
                            icon: Icons.public,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: DesignTokens.space32),

                    // Services & Pricing
                    _buildSectionTitle('Services & Pricing'),
                    const SizedBox(height: DesignTokens.space16),

                    _buildTextField(
                      controller: _servicesController,
                      label: 'Services Offered',
                      hint: 'List your services (e.g., Personal Training, Nutrition Planning)',
                      icon: Icons.list,
                      maxLines: 3,
                    ),

                    const SizedBox(height: DesignTokens.space16),

                    _buildTextField(
                      controller: _pricingController,
                      label: 'Pricing Information',
                      hint: 'Describe your pricing structure',
                      icon: Icons.attach_money,
                      maxLines: 2,
                    ),

                    const SizedBox(height: DesignTokens.space32),

                    // Business Hours (Future feature)
                    _buildSectionTitle('Business Hours'),
                    const SizedBox(height: DesignTokens.space16),

                    Container(
                      padding: const EdgeInsets.all(DesignTokens.space16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(DesignTokens.radius12),
                        border: Border.all(
                          color: AppTheme.steelGrey,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: AppTheme.mintAqua,
                            size: 24,
                          ),
                          const SizedBox(width: DesignTokens.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Business Hours',
                                  style: TextStyle(
                                    color: AppTheme.neutralWhite,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Coming soon - Set your availability',
                                  style: TextStyle(
                                    color: AppTheme.lightGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: AppTheme.lightGrey,
                            size: 16,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: DesignTokens.space20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.lightGrey,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: DesignTokens.space8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            border: Border.all(
              color: AppTheme.steelGrey,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(color: AppTheme.neutralWhite),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppTheme.lightGrey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(DesignTokens.space16),
              prefixIcon: Icon(
                icon,
                color: AppTheme.mintAqua,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
