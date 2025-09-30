import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import '../../theme/app_theme.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../services/nutrition/food_database_service.dart';
import 'animated/draggable_modal.dart';
import 'animated/animated_glass_text_field.dart';
import 'animated/animated_macro_input.dart';
import 'animated/animated_save_button.dart';

/// Animated glassmorphism modal for editing food items
/// Features: staggered animations, gesture dismissal, micro-interactions
class AnimatedFoodItemEditModal extends StatefulWidget {
  final FoodItem? foodItem;
  final Function(FoodItem) onSave;
  final VoidCallback? onSearchDatabase;
  final VoidCallback? onScanBarcode;
  final VoidCallback? onAIGenerate;

  const AnimatedFoodItemEditModal({
    super.key,
    this.foodItem,
    required this.onSave,
    this.onSearchDatabase,
    this.onScanBarcode,
    this.onAIGenerate,
  });

  @override
  State<AnimatedFoodItemEditModal> createState() => _AnimatedFoodItemEditModalState();
}

class _AnimatedFoodItemEditModalState extends State<AnimatedFoodItemEditModal>
    with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _sodiumController;
  late TextEditingController _potassiumController;

  double _calculatedCalories = 0;

  // Animation controllers
  late AnimationController _contentAnimationController;
  late Animation<double> _fadeAnimation;

  // Field keys for scroll-to functionality
  final GlobalKey _nameFieldKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  // Auto-calculation state
  final FoodDatabaseService _foodDb = FoodDatabaseService();
  Timer? _debounceTimer;
  bool _isSearching = false;
  FoodNutrition? _baseNutritionPer100g;
  String _selectedUnit = 'g';
  double _currentAmount = 100.0;

  @override
  void initState() {
    super.initState();

    final item = widget.foodItem;

    _nameController = TextEditingController(text: item?.name ?? '');
    _amountController = TextEditingController(
      text: item?.amount.toStringAsFixed(1) ?? '0',
    );
    _proteinController = TextEditingController(
      text: item?.protein.toStringAsFixed(1) ?? '0',
    );
    _carbsController = TextEditingController(
      text: item?.carbs.toStringAsFixed(1) ?? '0',
    );
    _fatController = TextEditingController(
      text: item?.fat.toStringAsFixed(1) ?? '0',
    );
    _sodiumController = TextEditingController(
      text: item?.sodium.toStringAsFixed(1) ?? '0',
    );
    _potassiumController = TextEditingController(
      text: item?.potassium.toStringAsFixed(1) ?? '0',
    );

    _calculateCalories();

    // Listen to macro changes to auto-update calories
    _proteinController.addListener(_calculateCalories);
    _carbsController.addListener(_calculateCalories);
    _fatController.addListener(_calculateCalories);

    // Content stagger animation
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    // Start animation after a brief delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _contentAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _sodiumController.dispose();
    _potassiumController.dispose();
    _contentAnimationController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _calculateCalories() {
    final protein = double.tryParse(_proteinController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fat = double.tryParse(_fatController.text) ?? 0;

    setState(() {
      _calculatedCalories = (protein * 4) + (carbs * 4) + (fat * 9);
    });
  }

  Future<void> _handleSave() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a food name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final protein = double.tryParse(_proteinController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fat = double.tryParse(_fatController.text) ?? 0;
    final kcal = (protein * 4) + (carbs * 4) + (fat * 9);

    final foodItem = FoodItem(
      name: _nameController.text.trim(),
      amount: double.tryParse(_amountController.text) ?? 0,
      protein: protein,
      carbs: carbs,
      fat: fat,
      kcal: kcal,
      sodium: double.tryParse(_sodiumController.text) ?? 0,
      potassium: double.tryParse(_potassiumController.text) ?? 0,
      recipeId: widget.foodItem?.recipeId,
      servings: widget.foodItem?.servings ?? 1.0,
      costPerUnit: widget.foodItem?.costPerUnit,
      currency: widget.foodItem?.currency,
      estimated: widget.foodItem?.estimated ?? false,
    );

    widget.onSave(foodItem);
  }

  /// Search food database when user enters food name
  Future<void> _searchFoodDatabase(String query) async {
    if (query.trim().isEmpty || query.length < 3) return;

    setState(() => _isSearching = true);

    try {
      // Try API first
      final results = await _foodDb.searchFoods(query);

      if (results.isNotEmpty && mounted) {
        // Get detailed nutrition for first result
        final nutrition = await _foodDb.getFoodNutrition(results.first.fdcId);

        if (nutrition != null && mounted) {
          setState(() {
            _baseNutritionPer100g = nutrition;
            _isSearching = false;
          });

          // Auto-fill macros for current portion
          _recalculateMacrosForPortion();

          // Show success feedback
          await HapticFeedback.lightImpact();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ Found: ${nutrition.name}'),
                backgroundColor: const Color(0xFF00D9A3),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      }

      // Fallback to local database
      final localResult = _foodDb.searchLocalDatabase(query);
      if (localResult != null && mounted) {
        setState(() {
          _baseNutritionPer100g = localResult;
          _isSearching = false;
        });

        _recalculateMacrosForPortion();

        await HapticFeedback.lightImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Found: ${localResult.name}'),
              backgroundColor: const Color(0xFF00D9A3),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => _isSearching = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
      print('Error searching food: $e');
    }
  }

  /// Recalculate macros when amount or unit changes
  void _recalculateMacrosForPortion() {
    if (_baseNutritionPer100g == null) return;

    final amount = double.tryParse(_amountController.text) ?? 100.0;
    setState(() => _currentAmount = amount);

    final macros = _baseNutritionPer100g!.calculateForPortion(
      amount,
      _selectedUnit,
    );

    // Update controllers with calculated values
    _proteinController.text = macros['protein']!.toStringAsFixed(1);
    _carbsController.text = macros['carbs']!.toStringAsFixed(1);
    _fatController.text = macros['fat']!.toStringAsFixed(1);

    // Trigger calorie recalculation
    _calculateCalories();
  }

  void _showUnitSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A3A3A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Unit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...['g', 'oz', 'serving', 'cup', 'tbsp', 'tsp'].map((unit) {
              return ListTile(
                title: Text(
                  unit,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: _selectedUnit == unit
                    ? const Icon(Icons.check, color: Color(0xFF00D9A3))
                    : null,
                onTap: () {
                  setState(() {
                    _selectedUnit = unit;
                  });
                  Navigator.pop(context);
                  _recalculateMacrosForPortion();
                },
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DraggableModal(
        onDismiss: () {},
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: MediaQuery.of(context).size.height * 0.85 - (keyboardHeight * 0.5),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF1A3A3A),
                        Color(0xFF0D2626),
                      ],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildAnimatedHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAnimatedSection(
                                delay: 0,
                                child: _buildFoodNameSection(),
                              ),
                              const SizedBox(height: 24),
                              _buildAnimatedSection(
                                delay: 100,
                                child: _buildMacronutrientsSection(),
                              ),
                              const SizedBox(height: 24),
                              _buildAnimatedSection(
                                delay: 200,
                                child: _buildQuickActionsSection(),
                              ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                      _buildAnimatedFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Drag handle
            Expanded(
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Close button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSection({
    required int delay,
    required Widget child,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildFoodNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Food Name',
          style: TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Hero(
          tag: 'food_name_${widget.foodItem?.name ?? "new"}',
          child: Material(
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                AnimatedGlassTextField(
                  fieldKey: _nameFieldKey,
                  controller: _nameController,
                  hint: 'Enter food name (e.g., chicken breast)',
                  icon: Icons.fastfood,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (value) {
                    // Debounced search
                    _debounceTimer?.cancel();
                    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
                      _searchFoodDatabase(value);
                    });
                  },
                ),
                // Loading indicator
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9A3)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Amount and unit row
        Row(
          children: [
            // Amount input
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Amount',
                    style: TextStyle(
                      color: AppTheme.neutralWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.transparent,
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: '100',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF00D9A3),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (_) => _recalculateMacrosForPortion(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Unit selector
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unit',
                    style: TextStyle(
                      color: AppTheme.neutralWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showUnitSelector,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedUnit,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Helper text when auto-calculated
        if (_baseNutritionPer100g != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '✓ Auto-calculated for $_currentAmount$_selectedUnit based on ${_baseNutritionPer100g!.name}',
              style: const TextStyle(
                color: Color(0xFF00D9A3),
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMacronutrientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Macronutrients',
          style: TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // 2x2 Grid
        Row(
          children: [
            Expanded(
              child: AnimatedMacroInput(
                controller: _proteinController,
                emoji: '💪',
                label: 'Protein',
                unit: 'g',
                color: const Color(0xFF00D9A3),
                onChanged: (_) => _calculateCalories(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedMacroInput(
                controller: _carbsController,
                emoji: '🍞',
                label: 'Carbs',
                unit: 'g',
                color: const Color(0xFFFF9A3C),
                onChanged: (_) => _calculateCalories(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AnimatedMacroInput(
                controller: _fatController,
                emoji: '🥑',
                label: 'Fat',
                unit: 'g',
                color: const Color(0xFFFFD93C),
                onChanged: (_) => _calculateCalories(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCaloriesDisplay(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCaloriesDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🔥', style: TextStyle(fontSize: 16)),
              SizedBox(width: 4),
              Text(
                'Calories',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: _calculatedCalories),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          Center(
            child: Text(
              'kcal',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (widget.onSearchDatabase != null)
              _buildQuickActionChip(
                icon: Icons.search,
                label: 'Search Database',
                onTap: widget.onSearchDatabase!,
              ),
            if (widget.onScanBarcode != null)
              _buildQuickActionChip(
                icon: Icons.qr_code_scanner,
                label: 'Scan Barcode',
                onTap: widget.onScanBarcode!,
              ),
            if (widget.onAIGenerate != null)
              _buildQuickActionChip(
                icon: Icons.auto_awesome,
                label: 'AI Generate',
                onTap: widget.onAIGenerate!,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentGreen.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppTheme.accentGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.accentGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedFooter() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Cancel button
              Expanded(
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Save button
              Expanded(
                flex: 2,
                child: AnimatedSaveButton(
                  onPressed: _handleSave,
                  text: 'Save Food',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}