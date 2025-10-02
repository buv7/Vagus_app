import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../theme/app_theme.dart';
import '../../models/nutrition/nutrition_plan.dart';

/// Glassmorphism modal for editing food items
/// Replaces cramped inline editing with spacious, beautiful modal design
class FoodItemEditModal extends StatefulWidget {
  final FoodItem? foodItem;
  final Function(FoodItem) onSave;
  final VoidCallback? onSearchDatabase;
  final VoidCallback? onScanBarcode;
  final VoidCallback? onAIGenerate;

  const FoodItemEditModal({
    super.key,
    this.foodItem,
    required this.onSave,
    this.onSearchDatabase,
    this.onScanBarcode,
    this.onAIGenerate,
  });

  @override
  State<FoodItemEditModal> createState() => _FoodItemEditModalState();
}

class _FoodItemEditModalState extends State<FoodItemEditModal> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _sodiumController;
  late TextEditingController _potassiumController;

  double _calculatedCalories = 0;

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

  void _handleSave() {
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

    HapticFeedback.mediumImpact();
    widget.onSave(foodItem);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A3A3A),
                    Color(0xFF0D2626),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Header: Drag handle + Close button
                  _buildHeader(),

                  // Scrollable content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Food Name Section
                        _buildFoodNameSection(),

                        const SizedBox(height: 24),

                        // Macronutrients Section (2x2 Grid)
                        _buildMacronutrientsSection(),

                        const SizedBox(height: 24),

                        // Quick Actions
                        _buildQuickActionsSection(),

                        const SizedBox(height: 100), // Space for footer
                      ],
                    ),
                  ),

                  // Footer: Cancel + Save buttons
                  _buildFooter(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
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
        _buildGlassTextField(
          controller: _nameController,
          hintText: 'Enter food name',
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.words,
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
            // Protein
            Expanded(
              child: _buildMacroInput(
                emoji: '💪',
                label: 'Protein',
                controller: _proteinController,
                color: const Color(0xFF00D9A3),
              ),
            ),
            const SizedBox(width: 12),
            // Carbs
            Expanded(
              child: _buildMacroInput(
                emoji: '🍞',
                label: 'Carbs',
                controller: _carbsController,
                color: const Color(0xFFFF9A3C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Fat
            Expanded(
              child: _buildMacroInput(
                emoji: '🥑',
                label: 'Fat',
                controller: _fatController,
                color: const Color(0xFFFFD93C),
              ),
            ),
            const SizedBox(width: 12),
            // Calories (disabled/auto-calculated)
            Expanded(
              child: _buildCaloriesDisplay(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroInput({
    required String emoji,
    required String label,
    required TextEditingController controller,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildGlassTextField(
          controller: controller,
          hintText: '0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          borderColor: color.withValues(alpha: 0.3),
          suffixText: 'g',
        ),
      ],
    );
  }

  Widget _buildCaloriesDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              'Calories',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.54),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            '${_calculatedCalories.toInt()} kcal',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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

  Widget _buildFooter() {
    return Container(
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
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9A3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Food',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Color? borderColor,
    String? suffixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 16,
        ),
        suffixText: suffixText,
        suffixStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: borderColor ?? Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: borderColor ?? Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: borderColor ?? AppTheme.accentGreen.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}