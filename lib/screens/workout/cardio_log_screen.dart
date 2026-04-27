import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../services/ocr/ocr_cardio_service.dart';
import '../../services/cardio/manual_cardio_service.dart';
import '../../widgets/workout/manual_cardio_entry_dialog.dart';
import '../../widgets/ocr/ocr_cardio_preview_dialog.dart';

/// Image source type for OCR capture
enum CardioImageSource { camera, gallery }

class CardioLogScreen extends StatefulWidget {
  const CardioLogScreen({super.key});

  @override
  State<CardioLogScreen> createState() => _CardioLogScreenState();
}

class _CardioLogScreenState extends State<CardioLogScreen> {
  final OCRCardioService _ocrService = OCRCardioService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? DesignTokens.darkBackground : DesignTokens.scaffoldBg(context),
      appBar: AppBar(
        backgroundColor: isDark ? DesignTokens.darkBackground : Colors.white,
        foregroundColor: isDark ? Colors.white : DesignTokens.textColor(context),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignTokens.accentOrange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.directions_run,
                color: DesignTokens.accentOrange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Cardio Log',
              style: TextStyle(
                color: isDark ? Colors.white : DesignTokens.textColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with glassmorphism
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark 
                  ? DesignTokens.accentBlue.withValues(alpha: 0.1)
                  : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark 
                    ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                    : DesignTokens.borderColor(context),
                  width: isDark ? 2 : 1,
                ),
                boxShadow: isDark ? [
                  BoxShadow(
                    color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ] : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.directions_run,
                          color: DesignTokens.accentBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Quick Cardio Log',
                        style: TextStyle(
                          color: isDark ? Colors.white : DesignTokens.textColor(context),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Capture your cardio workout data using OCR technology',
                    style: TextStyle(
                      color: isDark ? Colors.white.withValues(alpha: 0.7) : DesignTokens.textColorSecondary(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // OCR Cardio Button with glassmorphism
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark 
                  ? DesignTokens.accentBlue.withValues(alpha: 0.1)
                  : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark 
                    ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                    : DesignTokens.borderColor(context),
                  width: isDark ? 2 : 1,
                ),
                boxShadow: isDark ? [
                  BoxShadow(
                    color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ] : null,
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: DesignTokens.accentBlue,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'OCR Cardio Capture',
                    style: TextStyle(
                      color: isDark ? Colors.white : DesignTokens.textColor(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a photo of your cardio machine display to automatically log your workout',
                    style: TextStyle(
                      color: isDark ? Colors.white.withValues(alpha: 0.7) : DesignTokens.textColorSecondary(context),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        color: DesignTokens.accentBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : _captureCardioImage,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _isLoading 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  _isLoading ? 'Processing...' : 'Capture Cardio',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Manual Entry Option with glassmorphism
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark 
                  ? DesignTokens.accentBlue.withValues(alpha: 0.05)
                  : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark 
                    ? DesignTokens.accentBlue.withValues(alpha: 0.2)
                    : DesignTokens.borderColor(context),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit,
                      color: isDark ? Colors.white.withValues(alpha: 0.8) : DesignTokens.iconColor(context),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Manual Entry',
                    style: TextStyle(
                      color: isDark ? Colors.white : DesignTokens.textColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your cardio workout details manually',
                    style: TextStyle(
                      color: isDark ? Colors.white.withValues(alpha: 0.7) : DesignTokens.textColorSecondary(context),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.2) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark 
                            ? DesignTokens.accentBlue.withValues(alpha: 0.4)
                            : DesignTokens.accentBlue,
                          width: isDark ? 2 : 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showManualEntryDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit, color: isDark ? Colors.white : DesignTokens.accentBlue),
                                const SizedBox(width: 8),
                                Text(
                                  'Enter Manually',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : DesignTokens.accentBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showManualEntryDialog() async {
    final result = await showDialog<ManualCardioEntry>(
      context: context,
      builder: (context) => const ManualCardioEntryDialog(),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${ManualCardioService.getSportDisplayName(result.sport)} workout logged successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate back after successful logging
      Navigator.pop(context);
    }
  }

  Future<void> _captureCardioImage() async {
    // Show source selection dialog
    final source = await _showImageSourceDialog();
    if (source == null || !mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Use the OCR service to capture and process the image
      final result = await _ocrService.captureAndProcess(
        fromCamera: source == CardioImageSource.camera,
      );
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      if (result != null) {
        // Show preview dialog for user to verify/edit data
        final savedData = await showOCRCardioPreviewDialog(
          context: context,
          data: result,
          onRetake: () => _captureCardioImage(), // Recursive call to retake
        );
        
        if (savedData != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ ${savedData.sport ?? 'Cardio'} workout logged! '
                '${savedData.distance?.toStringAsFixed(1) ?? ''} ${savedData.distanceUnit ?? ''} '
                '${savedData.durationMinutes ?? 0}min',
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back after successful logging
          if (mounted) Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Capture cancelled or failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<CardioImageSource?> _showImageSourceDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return showDialog<CardioImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? DesignTokens.secondaryDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Capture Cardio Display',
          style: TextStyle(
            color: isDark ? Colors.white : DesignTokens.textColor(context),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Take a photo of your cardio machine display or select from gallery.',
              style: TextStyle(
                color: isDark ? Colors.white70 : DesignTokens.textColorSecondary(context),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSourceButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => Navigator.pop(context, CardioImageSource.camera),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => Navigator.pop(context, CardioImageSource.gallery),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: DesignTokens.accentBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: DesignTokens.accentBlue.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: DesignTokens.accentBlue),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : DesignTokens.textColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
