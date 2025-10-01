import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../services/haptics.dart';
import '../../../../services/nutrition/food_catalog_service.dart';
import '../../../../models/nutrition/food_item.dart';
import '../../../../widgets/anim/vagus_loader.dart';
import '../../../../widgets/anim/empty_state.dart';
import 'enhanced_food_card.dart';

/// Custom foods tab with food creation and management
/// Features: Create custom foods, photo upload, nutrition estimation, sharing with coach
class CustomFoodsTab extends StatefulWidget {
  final bool multiSelectMode;
  final List<FoodItem> selectedFoods;
  final Function(FoodItem) onFoodSelected;
  final Function(FoodItem) onFoodToggled;
  final Function(FoodItem) onFoodCreated;

  const CustomFoodsTab({
    super.key,
    required this.multiSelectMode,
    required this.selectedFoods,
    required this.onFoodSelected,
    required this.onFoodToggled,
    required this.onFoodCreated,
  });

  @override
  State<CustomFoodsTab> createState() => _CustomFoodsTabState();
}

class _CustomFoodsTabState extends State<CustomFoodsTab>
    with AutomaticKeepAliveClientMixin {
  List<FoodItem> _customFoods = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCustomFoods();
  }

  Future<void> _loadCustomFoods() async {
    setState(() => _isLoading = true);

    try {
      // Load custom foods from Supabase user_custom_foods table
      await Future.delayed(const Duration(milliseconds: 500));

      final customFoods = await FoodCatalogService.getUserCustomFoods();

      if (mounted) {
        setState(() {
          _customFoods = customFoods.cast<FoodItem>();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _customFoods = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      child: Column(
        children: [
          // Title
          Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: AppTheme.accentGreen,
                size: 24,
              ),
              const SizedBox(width: DesignTokens.space8),
              const Expanded(
                child: Text(
                  'Custom Foods',
                  style: TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.space16),

          // Create food button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCreateFoodSheet,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Create Custom Food'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: DesignTokens.space14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VagusLoader(size: 40),
            SizedBox(height: DesignTokens.space16),
            Text(
              'Loading custom foods...',
              style: TextStyle(
                color: AppTheme.lightGrey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_customFoods.isEmpty) {
      return EmptyState(
        icon: Icons.restaurant_menu,
        title: 'No custom foods yet',
        subtitle: 'Create custom foods for items not in our database',
        actionLabel: 'Create Your First Food',
        onAction: _showCreateFoodSheet,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCustomFoods,
      backgroundColor: AppTheme.cardDark,
      color: AppTheme.accentGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(DesignTokens.space20),
        itemCount: _customFoods.length,
        itemBuilder: (context, index) {
          final food = _customFoods[index];
          final isSelected = widget.selectedFoods.contains(food);

          return _buildCustomFoodCard(food, isSelected);
        },
      ),
    );
  }

  Widget _buildCustomFoodCard(FoodItem food, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space16),
      child: Stack(
        children: [
          EnhancedFoodCard(
            food: food,
            multiSelectMode: widget.multiSelectMode,
            isSelected: isSelected,
            onTap: () => widget.onFoodSelected(food),
            onToggle: () => widget.onFoodToggled(food),
            showNutritionalInfo: true,
            showServingSelector: false,
            showFavoriteButton: true,
          ),

          // Custom food badge
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.lightBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightBlue.withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person,
                    color: AppTheme.lightBlue,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Custom',
                    style: TextStyle(
                      color: AppTheme.lightBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Edit/Delete actions
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit button
                GestureDetector(
                  onTap: () => _editCustomFood(food),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.lightOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: AppTheme.lightOrange,
                      size: 16,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Delete button
                GestureDetector(
                  onTap: () => _deleteCustomFood(food),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateFoodSheet() {
    Haptics.tap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomFoodCreatorSheet(
        onFoodCreated: (food) {
          widget.onFoodCreated(food);
          setState(() => _customFoods.insert(0, food));
        },
      ),
    );
  }

  void _editCustomFood(FoodItem food) {
    Haptics.tap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomFoodCreatorSheet(
        existingFood: food,
        onFoodCreated: (updatedFood) {
          setState(() {
            final index = _customFoods.indexWhere((f) => f.id == food.id);
            if (index != -1) {
              _customFoods[index] = updatedFood;
            }
          });
        },
      ),
    );
  }

  void _deleteCustomFood(FoodItem food) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text(
          'Delete Custom Food?',
          style: TextStyle(color: AppTheme.neutralWhite),
        ),
        content: Text(
          'Are you sure you want to delete "${food.name}"? This action cannot be undone.',
          style: const TextStyle(color: AppTheme.lightGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDeleteFood(food);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _performDeleteFood(FoodItem food) async {
    try {
      // Delete from backend
      await FoodCatalogService.deleteCustomFood(food.id!);

      setState(() => _customFoods.removeWhere((f) => f.id == food.id));

      Haptics.success();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${food.name}"'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    } catch (e) {
      Haptics.error();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete food'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Custom food creator sheet with full form
class CustomFoodCreatorSheet extends StatefulWidget {
  final FoodItem? existingFood;
  final Function(FoodItem) onFoodCreated;

  const CustomFoodCreatorSheet({
    super.key,
    this.existingFood,
    required this.onFoodCreated,
  });

  @override
  State<CustomFoodCreatorSheet> createState() => _CustomFoodCreatorSheetState();
}

class _CustomFoodCreatorSheetState extends State<CustomFoodCreatorSheet>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();
  final _sodiumController = TextEditingController();
  final _potassiumController = TextEditingController();

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  File? _selectedImage;
  String _selectedServingSize = '100g';
  bool _shareWithCoach = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();

    // Pre-fill form if editing
    if (widget.existingFood != null) {
      final food = widget.existingFood!;
      _nameController.text = food.name;
      _brandController.text = food.brand ?? '';
      _caloriesController.text = food.kcal.toString();
      _proteinController.text = food.protein.toString();
      _carbsController.text = food.carbs.toString();
      _fatController.text = food.fat.toString();
      _sodiumController.text = food.sodium.toString();
      _potassiumController.text = food.potassium.toString();
      // Add other micronutrients if available
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sodiumController.dispose();
    _potassiumController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: AppTheme.backgroundDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildForm()),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.mediumGrey.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.restaurant_menu,
            color: AppTheme.accentGreen,
            size: 24,
          ),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: Text(
              widget.existingFood != null ? 'Edit Custom Food' : 'Create Custom Food',
              style: const TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Haptics.tap();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.mediumGrey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                color: AppTheme.lightGrey,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo upload section
            _buildPhotoUploadSection(),

            const SizedBox(height: DesignTokens.space24),

            // Basic info section
            _buildBasicInfoSection(),

            const SizedBox(height: DesignTokens.space24),

            // Nutrition section
            _buildNutritionSection(),

            const SizedBox(height: DesignTokens.space24),

            // Optional micronutrients
            _buildMicronutrientsSection(),

            const SizedBox(height: DesignTokens.space24),

            // Settings section
            _buildSettingsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photo (Optional)',
          style: TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: DesignTokens.space12),

        GestureDetector(
          onTap: _selectImage,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.mediumGrey.withOpacity(0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: _selectedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      color: AppTheme.lightGrey,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap to add photo',
                      style: TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: DesignTokens.space16),

        // Food name
        _buildTextField(
          controller: _nameController,
          label: 'Food Name',
          hint: 'e.g., Grandma\'s Apple Pie',
          required: true,
        ),

        const SizedBox(height: DesignTokens.space16),

        // Brand (optional)
        _buildTextField(
          controller: _brandController,
          label: 'Brand (Optional)',
          hint: 'e.g., Homemade',
        ),

        const SizedBox(height: DesignTokens.space16),

        // Serving size
        _buildServingSizeSelector(),
      ],
    );
  }

  Widget _buildNutritionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nutrition Facts',
          style: TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: DesignTokens.space16),

        // Calories
        _buildNumberField(
          controller: _caloriesController,
          label: 'Calories',
          hint: 'kcal',
          required: true,
        ),

        const SizedBox(height: DesignTokens.space16),

        // Macros row
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                controller: _proteinController,
                label: 'Protein',
                hint: 'g',
                required: true,
              ),
            ),
            const SizedBox(width: DesignTokens.space12),
            Expanded(
              child: _buildNumberField(
                controller: _carbsController,
                label: 'Carbs',
                hint: 'g',
                required: true,
              ),
            ),
            const SizedBox(width: DesignTokens.space12),
            Expanded(
              child: _buildNumberField(
                controller: _fatController,
                label: 'Fat',
                hint: 'g',
                required: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMicronutrientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Nutrients (Optional)',
          style: TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: DesignTokens.space16),

        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                controller: _fiberController,
                label: 'Fiber',
                hint: 'g',
              ),
            ),
            const SizedBox(width: DesignTokens.space12),
            Expanded(
              child: _buildNumberField(
                controller: _sodiumController,
                label: 'Sodium',
                hint: 'mg',
              ),
            ),
            const SizedBox(width: DesignTokens.space12),
            Expanded(
              child: _buildNumberField(
                controller: _potassiumController,
                label: 'Potassium',
                hint: 'mg',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: DesignTokens.space16),

        // Share with coach toggle
        Container(
          padding: const EdgeInsets.all(DesignTokens.space16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.mediumGrey.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.share,
                color: AppTheme.accentGreen,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.space12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share with Coach',
                      style: TextStyle(
                        color: AppTheme.neutralWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Allow your coach to see this custom food',
                      style: TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _shareWithCoach,
                onChanged: (value) {
                  setState(() => _shareWithCoach = value);
                  Haptics.tap();
                },
                activeColor: AppTheme.accentGreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppTheme.lightGrey.withOpacity(0.6),
            ),
            filled: true,
            fillColor: AppTheme.cardDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.mediumGrey.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.accentGreen,
              ),
            ),
          ),
          validator: required ? (value) {
            if (value == null || value.isEmpty) {
              return '$label is required';
            }
            return null;
          } : null,
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppTheme.lightGrey.withOpacity(0.6),
            ),
            filled: true,
            fillColor: AppTheme.cardDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.mediumGrey.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.accentGreen,
              ),
            ),
          ),
          validator: required ? (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            if (double.tryParse(value) == null) {
              return 'Invalid number';
            }
            return null;
          } : (value) {
            if (value != null && value.isNotEmpty) {
              if (double.tryParse(value) == null) {
                return 'Invalid number';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildServingSizeSelector() {
    final servingSizes = ['100g', '1 serving', '1 cup', '1 piece', '1 slice'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Serving Size',
          style: TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.mediumGrey.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedServingSize,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedServingSize = value);
                }
              },
              dropdownColor: AppTheme.cardDark,
              style: const TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 16,
              ),
              isExpanded: true,
              items: servingSizes.map((size) {
                return DropdownMenuItem(
                  value: size,
                  child: Text(size),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.mediumGrey.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.lightGrey,
                side: BorderSide(color: AppTheme.mediumGrey.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.space14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),

          const SizedBox(width: DesignTokens.space16),

          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.space14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(widget.existingFood != null ? 'Update Food' : 'Create Food'),
            ),
          ),
        ],
      ),
    );
  }

  void _selectImage() async {
    Haptics.tap();
    // TODO: Implement image picker (camera or gallery)
    // For now, just show a placeholder dialog
    if (!mounted) return;
    unawaited(showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text(
          'Add Photo',
          style: TextStyle(color: AppTheme.neutralWhite),
        ),
        content: const Text(
          'Photo upload feature coming soon!',
          style: TextStyle(color: AppTheme.lightGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    ));
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Create food item
      final food = FoodItem(
        id: widget.existingFood?.id,
        name: _nameController.text,
        brand: _brandController.text.isEmpty ? null : _brandController.text,
        kcal: double.tryParse(_caloriesController.text) ?? 0.0,
        protein: double.tryParse(_proteinController.text) ?? 0.0,
        carbs: double.tryParse(_carbsController.text) ?? 0.0,
        fat: double.tryParse(_fatController.text) ?? 0.0,
        sodium: double.tryParse(_sodiumController.text) ?? 0.0,
        potassium: double.tryParse(_potassiumController.text) ?? 0.0,
        amount: 100.0,
        unit: _selectedServingSize,
        source: 'custom',
      );

      // Save to backend
      final savedFood = widget.existingFood != null
        ? await FoodCatalogService.updateCustomFood(food)
        : await FoodCatalogService.createCustomFood(food);

      if (mounted) {
        Haptics.success();
        widget.onFoodCreated(savedFood);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Haptics.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${widget.existingFood != null ? 'update' : 'create'} food: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}