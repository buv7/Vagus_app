import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../models/ads/ad_banner.dart';
import '../../services/admin/ad_banner_service.dart';

class AdminAdsScreen extends StatefulWidget {
  const AdminAdsScreen({super.key});

  @override
  State<AdminAdsScreen> createState() => _AdminAdsScreenState();
}

class _AdminAdsScreenState extends State<AdminAdsScreen> {
  final AdBannerService _adService = AdBannerService();
  List<AdBanner> _ads = [];
  bool _loading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadAds();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adService.isCurrentUserAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  Future<void> _loadAds() async {
    try {
      final ads = await _adService.getAllAdBanners();
      setState(() {
        _ads = ads;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showCreateAdSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateAdSheet(),
    ).then((_) => _loadAds());
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text(
            'Ad Management',
            style: TextStyle(color: AppTheme.neutralWhite),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.neutralWhite),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text(
            'Access denied. Admin privileges required.',
            style: TextStyle(color: AppTheme.lightGrey),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text(
          'Ad Management',
          style: TextStyle(color: AppTheme.neutralWhite),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.neutralWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
              ),
            )
          : _ads.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.campaign,
                        color: AppTheme.lightGrey,
                        size: 64,
                      ),
                      SizedBox(height: DesignTokens.space16),
                      Text(
                        'No ads created yet',
                        style: TextStyle(
                          color: AppTheme.lightGrey,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: DesignTokens.space8),
                      Text(
                        'Create your first ad to get started',
                        style: TextStyle(
                          color: AppTheme.lightGrey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(DesignTokens.space16),
                  itemCount: _ads.length,
                  itemBuilder: (context, index) {
                    final ad = _ads[index];
                    return _buildAdCard(ad);
                  },
                ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: _showCreateAdSheet,
              backgroundColor: AppTheme.accentGreen,
              child: const Icon(
                Icons.add,
                color: AppTheme.primaryDark,
              ),
            )
          : null,
    );
  }

  Widget _buildAdCard(AdBanner ad) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: AppTheme.mediumGrey,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ad Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(DesignTokens.radius16),
              topRight: Radius.circular(DesignTokens.radius16),
            ),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: Image.network(
                ad.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.mediumGrey,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: AppTheme.lightGrey,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Ad Details
          Padding(
            padding: const EdgeInsets.all(DesignTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ad.title,
                        style: const TextStyle(
                          color: AppTheme.neutralWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space8,
                        vertical: DesignTokens.space4,
                      ),
                      decoration: BoxDecoration(
                        color: ad.isCurrentlyActive 
                            ? DesignTokens.success 
                            : AppTheme.mediumGrey,
                        borderRadius: BorderRadius.circular(DesignTokens.radius8),
                      ),
                      child: Text(
                        ad.isCurrentlyActive ? 'Active' : 'Inactive',
                        style: const TextStyle(
                          color: AppTheme.neutralWhite,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: DesignTokens.space8),
                
                Row(
                  children: [
                    const Icon(
                      Icons.people,
                      color: AppTheme.lightGrey,
                      size: 16,
                    ),
                    const SizedBox(width: DesignTokens.space4),
                    Text(
                      'Audience: ${ad.audience}',
                      style: const TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                
                if (ad.linkUrl != null && ad.linkUrl!.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.space4),
                  Row(
                    children: [
                      const Icon(
                        Icons.link,
                        color: AppTheme.lightGrey,
                        size: 16,
                      ),
                      const SizedBox(width: DesignTokens.space4),
                      Expanded(
                        child: Text(
                          ad.linkUrl!,
                          style: const TextStyle(
                            color: AppTheme.accentGreen,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: DesignTokens.space12),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editAd(ad),
                        icon: const Icon(
                          Icons.edit,
                          color: AppTheme.accentGreen,
                          size: 16,
                        ),
                        label: const Text(
                          'Edit',
                          style: TextStyle(color: AppTheme.accentGreen),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.accentGreen),
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteAd(ad),
                        icon: const Icon(
                          Icons.delete,
                          color: DesignTokens.danger,
                          size: 16,
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: DesignTokens.danger),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: DesignTokens.danger),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editAd(AdBanner ad) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateAdSheet(editingAd: ad),
    ).then((_) => _loadAds());
  }

  void _deleteAd(AdBanner ad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'Delete Ad',
          style: TextStyle(color: AppTheme.neutralWhite),
        ),
        content: Text(
          'Are you sure you want to delete "${ad.title}"?',
          style: const TextStyle(color: AppTheme.lightGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.lightGrey),
            ),
          ),
          TextButton(
            onPressed: () async {
              final currentContext = context;
              Navigator.of(currentContext).pop();
              final scaffoldMessenger = ScaffoldMessenger.of(currentContext);
              try {
                await _adService.deleteAdBanner(ad.id);
                unawaited(_loadAds());
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Ad deleted successfully'),
                      backgroundColor: DesignTokens.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error deleting ad: $e'),
                      backgroundColor: DesignTokens.danger,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: DesignTokens.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class CreateAdSheet extends StatefulWidget {
  final AdBanner? editingAd;

  const CreateAdSheet({super.key, this.editingAd});

  @override
  State<CreateAdSheet> createState() => _CreateAdSheetState();
}

class _CreateAdSheetState extends State<CreateAdSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  final AdBannerService _adService = AdBannerService();
  
  String _selectedAudience = 'both';
  bool _isActive = true;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _imageUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editingAd != null) {
      final ad = widget.editingAd!;
      _titleController.text = ad.title;
      _linkController.text = ad.linkUrl ?? '';
      _selectedAudience = ad.audience;
      _isActive = ad.isActive;
      _startDate = ad.startsAt;
      _endDate = ad.endsAt;
      _imageUrl = ad.imageUrl;
    } else {
      _startDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _uploading = true;
      });

      // Upload to Supabase Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final fileBytes = await image.readAsBytes();
      
      final supabase = Supabase.instance.client;
      await supabase.storage.from('ads').uploadBinary(fileName, fileBytes);
      
      final publicUrl = supabase.storage.from('ads').getPublicUrl(fileName);
      
      setState(() {
        _imageUrl = publicUrl;
        _uploading = false;
      });
    } catch (e) {
      setState(() {
        _uploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    }
  }

  Future<void> _saveAd() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          backgroundColor: DesignTokens.danger,
        ),
      );
      return;
    }

    try {
      if (widget.editingAd != null) {
        // Update existing ad
        await _adService.updateAdBanner(
          id: widget.editingAd!.id,
          title: _titleController.text,
          imageUrl: _imageUrl!,
          linkUrl: _linkController.text.isEmpty ? null : _linkController.text,
          audience: _selectedAudience,
          startsAt: _startDate,
          endsAt: _endDate,
          isActive: _isActive,
        );
      } else {
        // Create new ad
        await _adService.createAdBanner(
          title: _titleController.text,
          imageUrl: _imageUrl!,
          linkUrl: _linkController.text.isEmpty ? null : _linkController.text,
          audience: _selectedAudience,
          startsAt: _startDate,
          endsAt: _endDate,
          isActive: _isActive,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editingAd != null 
                ? 'Ad updated successfully' 
                : 'Ad created successfully'),
            backgroundColor: DesignTokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving ad: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(DesignTokens.radius20),
          topRight: Radius.circular(DesignTokens.radius20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: DesignTokens.space12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(DesignTokens.space16),
            child: Row(
              children: [
                Text(
                  widget.editingAd != null ? 'Edit Ad' : 'Create Ad',
                  style: const TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: AppTheme.lightGrey,
                  ),
                ),
              ],
            ),
          ),
          
          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Ad Title',
                        labelStyle: TextStyle(color: AppTheme.lightGrey),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.mediumGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.accentGreen),
                        ),
                      ),
                      style: const TextStyle(color: AppTheme.neutralWhite),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: DesignTokens.space16),
                    
                    // Image Upload
                    const Text(
                      'Ad Image',
                      style: TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space8),
                    
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.mediumGrey,
                          borderRadius: BorderRadius.circular(DesignTokens.radius12),
                          border: Border.all(
                            color: AppTheme.lightGrey,
                            style: BorderStyle.solid,
                            width: 2,
                          ),
                        ),
                        child: _imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                                child: Image.network(
                                  _imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _uploading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                                    ),
                                  )
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          color: AppTheme.lightGrey,
                                          size: 32,
                                        ),
                                        SizedBox(height: DesignTokens.space8),
                                        Text(
                                          'Tap to select image',
                                          style: TextStyle(color: AppTheme.lightGrey),
                                        ),
                                      ],
                                    ),
                                  ),
                      ),
                    ),
                    
                    const SizedBox(height: DesignTokens.space16),
                    
                    // Link URL
                    TextFormField(
                      controller: _linkController,
                      decoration: const InputDecoration(
                        labelText: 'Link URL (optional)',
                        labelStyle: TextStyle(color: AppTheme.lightGrey),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.mediumGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.accentGreen),
                        ),
                      ),
                      style: const TextStyle(color: AppTheme.neutralWhite),
                    ),
                    
                    const SizedBox(height: DesignTokens.space16),
                    
                    // Audience
                    const Text(
                      'Audience',
                      style: TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space8),
                    DropdownButtonFormField<String>(
                      value: _selectedAudience,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.mediumGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.accentGreen),
                        ),
                      ),
                      dropdownColor: AppTheme.cardBackground,
                      style: const TextStyle(color: AppTheme.neutralWhite),
                      items: const [
                        DropdownMenuItem(
                          value: 'client',
                          child: Text('Client', style: TextStyle(color: AppTheme.neutralWhite)),
                        ),
                        DropdownMenuItem(
                          value: 'coach',
                          child: Text('Coach', style: TextStyle(color: AppTheme.neutralWhite)),
                        ),
                        DropdownMenuItem(
                          value: 'both',
                          child: Text('Both', style: TextStyle(color: AppTheme.neutralWhite)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedAudience = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: DesignTokens.space16),
                    
                    // Active toggle
                    Row(
                      children: [
                        const Text(
                          'Active',
                          style: TextStyle(
                            color: AppTheme.neutralWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _isActive,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                          activeColor: AppTheme.accentGreen,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: DesignTokens.space32),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveAd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen,
                          padding: const EdgeInsets.symmetric(vertical: DesignTokens.space16),
                        ),
                        child: Text(
                          widget.editingAd != null ? 'Update Ad' : 'Create Ad',
                          style: const TextStyle(
                            color: AppTheme.primaryDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: DesignTokens.space32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
