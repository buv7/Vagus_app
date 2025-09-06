import 'package:flutter/material.dart';
import '../../services/nutrition/locale_helper.dart';

/// Component for parsing nutrition labels from text input
class FoodLabelParser extends StatefulWidget {
  final Function(Map<String, dynamic>)? onNutritionParsed;
  final String? initialText;
  
  const FoodLabelParser({
    super.key,
    this.onNutritionParsed,
    this.initialText,
  });

  @override
  State<FoodLabelParser> createState() => _FoodLabelParserState();
}

class _FoodLabelParserState extends State<FoodLabelParser> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  Map<String, dynamic>? _parsedNutrition;
  bool _isParsing = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _textController.text = widget.initialText!;
      _parseNutritionLabel();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  LocaleHelper.t('parse_nutrition_label', language),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Text input
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: LocaleHelper.t('paste_nutrition_label', language),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: _isParsing ? null : _parseNutritionLabel,
                  icon: _isParsing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Parse button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isParsing ? null : _parseNutritionLabel,
                icon: const Icon(Icons.analytics),
                label: Text(LocaleHelper.t('parse_nutrition', language)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            
            // Error display
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Parsed nutrition display
            if (_parsedNutrition != null) ...[
              const SizedBox(height: 16),
              _buildParsedNutrition(language),
            ],
            
            // Instructions
            const SizedBox(height: 16),
            _buildInstructions(language),
          ],
        ),
      ),
    );
  }

  Widget _buildParsedNutrition(String language) {
    final nutrition = _parsedNutrition!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                LocaleHelper.t('parsed_nutrition', language),
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Nutrition values
          Row(
            children: [
              Expanded(
                child: _buildNutritionValue(
                  LocaleHelper.t('calories', language),
                  '${nutrition['kcal'] ?? 0}',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNutritionValue(
                  LocaleHelper.t('protein', language),
                  '${nutrition['protein'] ?? 0}g',
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildNutritionValue(
                  LocaleHelper.t('carbs', language),
                  '${nutrition['carbs'] ?? 0}g',
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNutritionValue(
                  LocaleHelper.t('fat', language),
                  '${nutrition['fat'] ?? 0}g',
                  Colors.yellow,
                ),
              ),
            ],
          ),
          
          if (nutrition['sodium'] != null || nutrition['potassium'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (nutrition['sodium'] != null)
                  Expanded(
                    child: _buildNutritionValue(
                      LocaleHelper.t('sodium', language),
                      '${nutrition['sodium']}mg',
                      Colors.blue,
                    ),
                  ),
                if (nutrition['sodium'] != null && nutrition['potassium'] != null)
                  const SizedBox(width: 8),
                if (nutrition['potassium'] != null)
                  Expanded(
                    child: _buildNutritionValue(
                      LocaleHelper.t('potassium', language),
                      '${nutrition['potassium']}mg',
                      Colors.teal,
                    ),
                  ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Use this data button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.onNutritionParsed != null) {
                  widget.onNutritionParsed!(_parsedNutrition!);
                }
              },
              icon: const Icon(Icons.check),
              label: Text(LocaleHelper.t('use_this_data', language)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionValue(String label, String value, Color color) {
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                LocaleHelper.t('parsing_tips', language),
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            LocaleHelper.t('parsing_tips_desc', language),
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _parseNutritionLabel() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _error = 'Please enter nutrition label text';
        _parsedNutrition = null;
      });
      return;
    }
    
    setState(() {
      _isParsing = true;
      _error = '';
      _parsedNutrition = null;
    });
    
    try {
      // Simple regex-based parsing
      final nutrition = _extractNutritionFromText(text);
      
      if (nutrition.isEmpty) {
        setState(() {
          _error = 'Could not find nutrition information in the text';
          _isParsing = false;
        });
        return;
      }
      
      setState(() {
        _parsedNutrition = nutrition;
        _isParsing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to parse nutrition label: $e';
        _isParsing = false;
      });
    }
  }

  Map<String, dynamic> _extractNutritionFromText(String text) {
    final nutrition = <String, dynamic>{};
    
    // Convert to lowercase for case-insensitive matching
    final lowerText = text.toLowerCase();
    
    // Extract calories
    final calorieMatch = RegExp(r'(\d+)\s*(?:kcal|calories?|cal)').firstMatch(lowerText);
    if (calorieMatch != null) {
      nutrition['kcal'] = int.tryParse(calorieMatch.group(1) ?? '0') ?? 0;
    }
    
    // Extract protein
    final proteinMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:g|grams?)\s*(?:protein|prot)').firstMatch(lowerText);
    if (proteinMatch != null) {
      nutrition['protein'] = double.tryParse(proteinMatch.group(1) ?? '0') ?? 0.0;
    }
    
    // Extract carbs
    final carbsMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:g|grams?)\s*(?:carbs?|carbohydrates?)').firstMatch(lowerText);
    if (carbsMatch != null) {
      nutrition['carbs'] = double.tryParse(carbsMatch.group(1) ?? '0') ?? 0.0;
    }
    
    // Extract fat
    final fatMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:g|grams?)\s*(?:fat|fats?)').firstMatch(lowerText);
    if (fatMatch != null) {
      nutrition['fat'] = double.tryParse(fatMatch.group(1) ?? '0') ?? 0.0;
    }
    
    // Extract sodium
    final sodiumMatch = RegExp(r'(\d+)\s*(?:mg|milligrams?)\s*(?:sodium|na)').firstMatch(lowerText);
    if (sodiumMatch != null) {
      nutrition['sodium'] = int.tryParse(sodiumMatch.group(1) ?? '0') ?? 0;
    }
    
    // Extract potassium
    final potassiumMatch = RegExp(r'(\d+)\s*(?:mg|milligrams?)\s*(?:potassium|k)').firstMatch(lowerText);
    if (potassiumMatch != null) {
      nutrition['potassium'] = int.tryParse(potassiumMatch.group(1) ?? '0') ?? 0;
    }
    
    return nutrition;
  }
}
