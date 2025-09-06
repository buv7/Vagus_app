import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ai/nutrition_ai.dart';
import '../../models/nutrition/food_item.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../widgets/branding/vagus_appbar.dart';

class FoodSnapScreen extends StatefulWidget {
  final Function(FoodItem)? onFoodItemCreated;
  
  const FoodSnapScreen({
    super.key,
    this.onFoodItemCreated,
  });

  @override
  State<FoodSnapScreen> createState() => _FoodSnapScreenState();
}

class _FoodSnapScreenState extends State<FoodSnapScreen> {
  final NutritionAI _nutritionAI = NutritionAI();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _selectedImage;
  FoodItem? _estimatedFoodItem;
  bool _isProcessing = false;
  String _error = '';
  
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;
    
    return Scaffold(
      appBar: VagusAppBar(
        title: Text(LocaleHelper.t('add_via_photo', language)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (_estimatedFoodItem != null)
            TextButton(
              onPressed: _saveFoodItem,
              child: Text(
                LocaleHelper.t('save', language),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image selection section
            _buildImageSelectionSection(language),
            
            const SizedBox(height: 24),
            
            // Processing indicator
            if (_isProcessing) _buildProcessingIndicator(language),
            
            // Error display
            if (_error.isNotEmpty) _buildErrorDisplay(language),
            
            // Estimated food item display
            if (_estimatedFoodItem != null) _buildEstimatedFoodItem(language),
            
            const SizedBox(height: 24),
            
            // Instructions
            _buildInstructions(language),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelectionSection(String language) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleHelper.t('select_photo', language),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Image preview or placeholder
            if (_selectedImage != null)
              _buildImagePreview()
            else
              _buildImagePlaceholder(language),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(LocaleHelper.t('take_photo', language)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: Text(LocaleHelper.t('choose_from_gallery', language)),
                  ),
                ),
              ],
            ),
            
            if (_selectedImage != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _processImage,
                  icon: _isProcessing 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                  label: Text(LocaleHelper.t('analyze_photo', language)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(String language) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            LocaleHelper.t('no_image_selected', language),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator(String language) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                LocaleHelper.t('analyzing_photo', language),
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDisplay(String language) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade700,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error,
                style: TextStyle(
                  color: Colors.red.shade700,
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _error = ''),
              icon: Icon(
                Icons.close,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimatedFoodItem(String language) {
    final item = _estimatedFoodItem!;
    
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  LocaleHelper.t('estimated_food_item', language),
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    LocaleHelper.t('estimated', language),
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Food name
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Nutrition info
            Row(
              children: [
                Expanded(
                  child: _buildNutritionChip(
                    LocaleHelper.t('amount', language),
                    '${item.amount.toStringAsFixed(0)}g',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNutritionChip(
                    LocaleHelper.t('calories', language),
                    '${item.kcal.toStringAsFixed(0)}',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildNutritionChip(
                    LocaleHelper.t('protein', language),
                    '${item.protein.toStringAsFixed(1)}g',
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNutritionChip(
                    LocaleHelper.t('carbs', language),
                    '${item.carbs.toStringAsFixed(1)}g',
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNutritionChip(
                    LocaleHelper.t('fat', language),
                    '${item.fat.toStringAsFixed(1)}g',
                    Colors.yellow,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Edit button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _editFoodItem,
                icon: const Icon(Icons.edit),
                label: Text(LocaleHelper.t('edit_details', language)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(String language) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleHelper.t('photo_tips', language),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              Icons.light_mode,
              LocaleHelper.t('good_lighting', language),
              LocaleHelper.t('good_lighting_desc', language),
            ),
            const SizedBox(height: 8),
            _buildTipItem(
              Icons.center_focus_strong,
              LocaleHelper.t('clear_focus', language),
              LocaleHelper.t('clear_focus_desc', language),
            ),
            const SizedBox(height: 8),
            _buildTipItem(
              Icons.crop_free,
              LocaleHelper.t('fill_frame', language),
              LocaleHelper.t('fill_frame_desc', language),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _estimatedFoodItem = null;
          _error = '';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to take photo: $e';
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _estimatedFoodItem = null;
          _error = '';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to select image: $e';
      });
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _isProcessing = true;
      _error = '';
    });
    
    try {
      final bytes = await _selectedImage!.readAsBytes();
      final user = Supabase.instance.client.auth.currentUser;
      final locale = Localizations.localeOf(context).languageCode;
      
      final foodItem = await _nutritionAI.estimateFromPhoto(
        bytes,
        locale: locale,
      );
      
      setState(() {
        _estimatedFoodItem = foodItem;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to analyze photo: $e';
        _isProcessing = false;
      });
    }
  }

  void _editFoodItem() {
    // TODO: Implement food item editing dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Food item editing coming soon'),
      ),
    );
  }

  void _saveFoodItem() {
    if (_estimatedFoodItem != null && widget.onFoodItemCreated != null) {
      widget.onFoodItemCreated!(_estimatedFoodItem!);
      Navigator.of(context).pop();
    }
  }
}
