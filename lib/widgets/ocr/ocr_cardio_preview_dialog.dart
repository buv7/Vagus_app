import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/ocr/ocr_cardio_service.dart';
import '../../theme/design_tokens.dart';

/// Dialog to preview and edit OCR-captured cardio workout data before saving
class OCRCardioPreviewDialog extends StatefulWidget {
  final CardioWorkoutData initialData;
  final VoidCallback? onSaved;
  final VoidCallback? onRetake;

  const OCRCardioPreviewDialog({
    super.key,
    required this.initialData,
    this.onSaved,
    this.onRetake,
  });

  @override
  State<OCRCardioPreviewDialog> createState() => _OCRCardioPreviewDialogState();
}

class _OCRCardioPreviewDialogState extends State<OCRCardioPreviewDialog> {
  late CardioWorkoutData _data;
  bool _isSaving = false;

  // Form controllers
  late TextEditingController _distanceController;
  late TextEditingController _durationMinController;
  late TextEditingController _durationSecController;
  late TextEditingController _caloriesController;
  late TextEditingController _avgHrController;
  late TextEditingController _maxHrController;

  String _selectedSport = 'running';
  String _selectedDistanceUnit = 'km';

  static const List<String> _sports = [
    'running',
    'cycling',
    'walking',
    'elliptical',
    'rowing',
    'swimming',
    'stairmaster',
    'other',
  ];

  static const List<String> _distanceUnits = ['km', 'mi', 'm'];

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    _selectedSport = _data.sport ?? 'running';
    _selectedDistanceUnit = _data.distanceUnit ?? 'km';

    _distanceController = TextEditingController(
      text: _data.distance?.toStringAsFixed(2) ?? '',
    );
    _durationMinController = TextEditingController(
      text: _data.durationMinutes?.toString() ?? '',
    );
    _durationSecController = TextEditingController(
      text: _data.durationSeconds?.toString() ?? '0',
    );
    _caloriesController = TextEditingController(
      text: _data.calories?.toStringAsFixed(0) ?? '',
    );
    _avgHrController = TextEditingController(
      text: _data.avgHeartRate?.toStringAsFixed(0) ?? '',
    );
    _maxHrController = TextEditingController(
      text: _data.maxHeartRate?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _durationMinController.dispose();
    _durationSecController.dispose();
    _caloriesController.dispose();
    _avgHrController.dispose();
    _maxHrController.dispose();
    super.dispose();
  }

  CardioWorkoutData _getUpdatedData() {
    return _data.copyWith(
      sport: _selectedSport,
      distance: double.tryParse(_distanceController.text),
      distanceUnit: _selectedDistanceUnit,
      durationMinutes: int.tryParse(_durationMinController.text),
      durationSeconds: int.tryParse(_durationSecController.text),
      calories: double.tryParse(_caloriesController.text),
      avgHeartRate: double.tryParse(_avgHrController.text),
      maxHeartRate: double.tryParse(_maxHrController.text),
      confidence: 1.0, // User verified
    );
  }

  Future<void> _saveWorkout() async {
    setState(() => _isSaving = true);

    try {
      final updatedData = _getUpdatedData();
      final ocrService = OCRCardioService();

      final saved = await ocrService.saveWorkoutData(
        imagePath: _data.imagePath ?? '',
        ocrText: _data.rawOcrText ?? '',
        parsedData: updatedData,
      );

      if (saved && mounted) {
        widget.onSaved?.call();
        Navigator.of(context).pop(updatedData);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save workout. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confidenceColor = _data.confidence > 0.7
        ? Colors.green
        : _data.confidence > 0.4
            ? Colors.orange
            : Colors.red;

    return Dialog(
      backgroundColor: isDark ? DesignTokens.secondaryDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: DesignTokens.accentBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OCR Cardio Capture',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : DesignTokens.textColor(context),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: confidenceColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Confidence: ${(_data.confidence * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: confidenceColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Image preview
              if (_data.imagePath != null && _data.imagePath!.isNotEmpty)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_data.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.grey),
                              const SizedBox(height: 4),
                              Text(
                                'Image not available',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Sport selection
              Text(
                'Sport',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : DesignTokens.textColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSport,
                    isExpanded: true,
                    dropdownColor: isDark ? DesignTokens.secondaryDark : Colors.white,
                    items: _sports.map((sport) {
                      return DropdownMenuItem(
                        value: sport,
                        child: Text(
                          sport[0].toUpperCase() + sport.substring(1),
                          style: TextStyle(
                            color: isDark ? Colors.white : DesignTokens.textColor(context),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSport = value);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Distance row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      label: 'Distance',
                      controller: _distanceController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDistanceUnit,
                          isExpanded: true,
                          dropdownColor: isDark ? DesignTokens.secondaryDark : Colors.white,
                          items: _distanceUnits.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(
                                unit,
                                style: TextStyle(
                                  color: isDark ? Colors.white : DesignTokens.textColor(context),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedDistanceUnit = value);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Duration row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Minutes',
                      controller: _durationMinController,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: 'Seconds',
                      controller: _durationSecController,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Calories
              _buildTextField(
                label: 'Calories',
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                isDark: isDark,
                suffix: 'kcal',
              ),

              const SizedBox(height: 16),

              // Heart rate row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Avg HR',
                      controller: _avgHrController,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                      suffix: 'bpm',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: 'Max HR',
                      controller: _maxHrController,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                      suffix: 'bpm',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  if (widget.onRetake != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                widget.onRetake?.call();
                              },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Retake'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : DesignTokens.accentBlue,
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.3)
                                : DesignTokens.accentBlue,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (widget.onRetake != null) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveWorkout,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isSaving ? 'Saving...' : 'Save Workout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    TextInputType? keyboardType,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isDark ? Colors.white : DesignTokens.textColor(context),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            color: isDark ? Colors.white : DesignTokens.textColor(context),
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixText: suffix,
            suffixStyle: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: DesignTokens.accentBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Show the OCR preview dialog
Future<CardioWorkoutData?> showOCRCardioPreviewDialog({
  required BuildContext context,
  required CardioWorkoutData data,
  VoidCallback? onSaved,
  VoidCallback? onRetake,
}) {
  return showDialog<CardioWorkoutData>(
    context: context,
    barrierDismissible: false,
    builder: (context) => OCRCardioPreviewDialog(
      initialData: data,
      onSaved: onSaved,
      onRetake: onRetake,
    ),
  );
}
