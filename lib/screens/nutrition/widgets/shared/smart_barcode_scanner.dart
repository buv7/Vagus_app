import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../services/haptics.dart';
import '../../../../services/nutrition/barcode_service.dart';
import '../../../../models/nutrition/food_item.dart';
import '../../../../widgets/anim/vagus_loader.dart';

/// Smart barcode scanner with real-time food recognition
/// Features: Camera overlay, scan history, manual barcode entry, food suggestions
class SmartBarcodeScanner extends StatefulWidget {
  final Function(FoodItem) onFoodFound;
  final Function(String) onBarcodeScanned;
  final VoidCallback? onClose;

  const SmartBarcodeScanner({
    super.key,
    required this.onFoodFound,
    required this.onBarcodeScanned,
    this.onClose,
  });

  @override
  State<SmartBarcodeScanner> createState() => _SmartBarcodeScannerState();
}

class _SmartBarcodeScannerState extends State<SmartBarcodeScanner>
    with TickerProviderStateMixin {
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late AnimationController _overlayController;

  late Animation<double> _scanLineAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _overlayFadeAnimation;

  bool _isScanning = false;
  bool _hasPermission = false;
  bool _showManualEntry = false;
  FoodItem? _recognizedFood;
  final List<String> _scanHistory = [];

  final TextEditingController _manualBarcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkCameraPermission();
  }

  void _setupAnimations() {
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scanLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _overlayFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_overlayController);

    _scanLineController.repeat();
    _overlayController.forward();
  }

  Future<void> _checkCameraPermission() async {
    // TODO: Implement camera permission check
    // For now, simulate permission granted
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _hasPermission = true;
      _isScanning = true;
    });
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    _overlayController.dispose();
    _manualBarcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview (simulated)
          _buildCameraPreview(),

          // Overlay UI
          FadeTransition(
            opacity: _overlayFadeAnimation,
            child: _buildOverlay(),
          ),

          // Manual barcode entry
          if (_showManualEntry)
            _buildManualEntry(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_hasPermission) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: VagusLoader(size: 60),
        ),
      );
    }

    // Simulated camera preview
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a1a1a),
            Color(0xFF2a2a2a),
            Color(0xFF1a1a1a),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'Point camera at barcode',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(child: _buildScanningArea()),
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space20),
        child: Row(
          children: [
            // Close button
            GestureDetector(
              onTap: () {
                Haptics.tap();
                widget.onClose?.call();
                Navigator.of(context).pop();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),

            const Spacer(),

            // Title
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space16,
                vertical: DesignTokens.space8,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Scan Barcode',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const Spacer(),

            // Manual entry button
            GestureDetector(
              onTap: () {
                setState(() => _showManualEntry = true);
                Haptics.tap();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.keyboard,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningArea() {
    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          children: [
            // Scanning frame
            _buildScanningFrame(),

            // Scan line
            if (_isScanning)
              AnimatedBuilder(
                animation: _scanLineAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: _scanLineAnimation.value * 250,
                    left: 15,
                    right: 15,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppTheme.accentGreen,
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentGreen.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Recognition result
            if (_recognizedFood != null)
              _buildRecognitionResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningFrame() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _recognizedFood != null
            ? AppTheme.accentGreen
            : Colors.white.withValues(alpha: 0.8),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Corner indicators
          _buildCornerIndicator(Alignment.topLeft),
          _buildCornerIndicator(Alignment.topRight),
          _buildCornerIndicator(Alignment.bottomLeft),
          _buildCornerIndicator(Alignment.bottomRight),

          // Instructions
          if (_recognizedFood == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.space20),
                child: Text(
                  'Position barcode within the frame',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCornerIndicator(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 20,
        height: 20,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppTheme.accentGreen,
              width: alignment == Alignment.topLeft || alignment == Alignment.topRight ? 3 : 0,
            ),
            bottom: BorderSide(
              color: AppTheme.accentGreen,
              width: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? 3 : 0,
            ),
            left: BorderSide(
              color: AppTheme.accentGreen,
              width: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? 3 : 0,
            ),
            right: BorderSide(
              color: AppTheme.accentGreen,
              width: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? 3 : 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecognitionResult() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(DesignTokens.space20),
            padding: const EdgeInsets.all(DesignTokens.space16),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGreen.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: DesignTokens.space8),
                const Text(
                  'Food Found!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DesignTokens.space4),
                Text(
                  _recognizedFood!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space20),
        child: Column(
          children: [
            // Status text
            Text(
              _isScanning
                ? 'Scanning for barcodes...'
                : 'Camera not ready',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: DesignTokens.space16),

            // Action buttons
            Row(
              children: [
                // Flash toggle
                Expanded(
                  child: _buildControlButton(
                    icon: Icons.flash_on,
                    label: 'Flash',
                    onTap: _toggleFlash,
                  ),
                ),

                const SizedBox(width: DesignTokens.space12),

                // Scan history
                Expanded(
                  child: _buildControlButton(
                    icon: Icons.history,
                    label: 'History',
                    onTap: _showScanHistory,
                  ),
                ),

                const SizedBox(width: DesignTokens.space12),

                // Manual entry
                Expanded(
                  child: _buildControlButton(
                    icon: Icons.keyboard,
                    label: 'Manual',
                    onTap: () => setState(() => _showManualEntry = true),
                  ),
                ),
              ],
            ),

            const SizedBox(height: DesignTokens.space16),

            // Simulate scan button (for demo)
            ElevatedButton(
              onPressed: _simulateScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space24,
                  vertical: DesignTokens.space12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simulate Scan (Demo)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: DesignTokens.space12,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntry() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(DesignTokens.space20),
          padding: const EdgeInsets.all(DesignTokens.space24),
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter Barcode Manually',
                style: TextStyle(
                  color: AppTheme.neutralWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: DesignTokens.space16),

              TextField(
                controller: _manualBarcodeController,
                style: const TextStyle(color: AppTheme.neutralWhite),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter barcode number',
                  hintStyle: TextStyle(
                    color: AppTheme.lightGrey.withValues(alpha: 0.6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.mediumGrey.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.accentGreen,
                    ),
                  ),
                ),
                autofocus: true,
              ),

              const SizedBox(height: DesignTokens.space20),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() => _showManualEntry = false);
                        _manualBarcodeController.clear();
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppTheme.lightGrey),
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _processManualBarcode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Search'),
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

  void _toggleFlash() {
    Haptics.tap();
    // TODO: Implement flash toggle
  }

  void _showScanHistory() {
    Haptics.tap();
    // TODO: Show scan history modal
  }

  void _processManualBarcode() {
    final barcode = _manualBarcodeController.text.trim();
    if (barcode.isNotEmpty) {
      setState(() => _showManualEntry = false);
      _processBarcode(barcode);
      _manualBarcodeController.clear();
    }
  }

  void _simulateScan() {
    Haptics.tap();
    // Simulate finding a food item
    const simulatedBarcode = '1234567890123';
    _processBarcode(simulatedBarcode);
  }

  Future<void> _processBarcode(String barcode) async {
    setState(() {
      _isScanning = false;
    });

    try {
      // Lookup food by barcode
      final barcodeService = BarcodeService();
      final product = await barcodeService.lookup(barcode);

      if (product != null) {
        final food = barcodeService.toFoodItem(product);
        setState(() => _recognizedFood = food);
        unawaited(_pulseController.repeat(reverse: true));
        Haptics.success();

        // Add to scan history
        _scanHistory.insert(0, barcode);
        if (_scanHistory.length > 10) {
          _scanHistory.removeLast();
        }

        // Auto-proceed after 2 seconds
        unawaited(Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            widget.onFoodFound(food);
            Navigator.of(context).pop();
          }
        }));
      } else {
        // Food not found
        Haptics.warning();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Food not found for barcode: $barcode'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isScanning = true);
      }
    } catch (e) {
      Haptics.error();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error looking up barcode'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isScanning = true);
    }

    widget.onBarcodeScanned(barcode);
  }
}