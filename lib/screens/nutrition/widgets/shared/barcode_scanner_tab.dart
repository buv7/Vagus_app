import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../services/haptics.dart';
import '../../../../services/nutrition/barcode_service.dart';
import '../../../../models/nutrition/food_item.dart';
import '../../../../widgets/anim/empty_state.dart';
import 'enhanced_food_card.dart';

/// Barcode scanner tab with full camera integration and scan history
/// Features: Integrated camera view, manual entry, scan history, quick actions
class BarcodeScannerTab extends StatefulWidget {
  final bool multiSelectMode;
  final List<FoodItem> selectedFoods;
  final Function(FoodItem) onFoodSelected;
  final Function(FoodItem) onFoodToggled;

  const BarcodeScannerTab({
    super.key,
    required this.multiSelectMode,
    required this.selectedFoods,
    required this.onFoodSelected,
    required this.onFoodToggled,
  });

  @override
  State<BarcodeScannerTab> createState() => _BarcodeScannerTabState();
}

class _BarcodeScannerTabState extends State<BarcodeScannerTab>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _pulseController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  bool _isCameraActive = false;
  bool _isScanning = false;
  bool _showHistory = false;
  List<ScannedItem> _scanHistory = [];
  FoodItem? _lastScannedFood;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadScanHistory();
  }

  void _setupAnimations() {
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadScanHistory() async {
    // TODO: Load scan history from storage
    setState(() {
      _scanHistory = [
        ScannedItem(
          barcode: '1234567890123',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          foodName: 'Chicken Breast',
        ),
        ScannedItem(
          barcode: '9876543210987',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          foodName: 'Greek Yogurt',
        ),
      ];
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildScannerControls(),
        Expanded(
          child: _showHistory ? _buildScanHistory() : _buildCameraView(),
        ),
      ],
    );
  }

  Widget _buildScannerControls() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space20),
      child: Column(
        children: [
          // Main action buttons
          Row(
            children: [
              // Start/Stop camera
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleCamera,
                  icon: Icon(
                    _isCameraActive ? Icons.camera_alt : Icons.camera_alt_outlined,
                    size: 20,
                  ),
                  label: Text(_isCameraActive ? 'Stop Camera' : 'Start Scanner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCameraActive
                      ? AppTheme.accentGreen
                      : AppTheme.mediumGrey.withOpacity(0.3),
                    foregroundColor: _isCameraActive
                      ? Colors.white
                      : AppTheme.lightGrey,
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.space12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(width: DesignTokens.space12),

              // Manual entry
              GestureDetector(
                onTap: _showManualEntry,
                child: Container(
                  padding: const EdgeInsets.all(DesignTokens.space12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.mediumGrey.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.keyboard,
                    color: AppTheme.lightGrey,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(width: DesignTokens.space8),

              // History toggle
              GestureDetector(
                onTap: () {
                  setState(() => _showHistory = !_showHistory);
                  Haptics.tap();
                },
                child: Container(
                  padding: const EdgeInsets.all(DesignTokens.space12),
                  decoration: BoxDecoration(
                    color: _showHistory
                      ? AppTheme.accentGreen.withOpacity(0.2)
                      : AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _showHistory
                        ? AppTheme.accentGreen.withOpacity(0.5)
                        : AppTheme.mediumGrey.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.history,
                    color: _showHistory ? AppTheme.accentGreen : AppTheme.lightGrey,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.space12),

          // Status and tips
          if (_isCameraActive) ...[
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isScanning ? AppTheme.accentGreen : AppTheme.lightOrange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: DesignTokens.space8),
                Text(
                  _isScanning ? 'Scanning for barcodes...' : 'Position barcode in view',
                  style: TextStyle(
                    color: AppTheme.lightGrey.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Scan barcodes to quickly find foods with accurate nutrition data',
              style: TextStyle(
                color: AppTheme.lightGrey.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (!_isCameraActive) {
      return EmptyState(
        icon: Icons.qr_code_scanner,
        title: 'Barcode Scanner',
        subtitle: 'Tap "Start Scanner" to begin scanning product barcodes',
        actionLabel: 'Start Scanner',
        onAction: _toggleCamera,
      );
    }

    return Container(
      margin: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.mediumGrey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Simulated camera preview
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2a2a2a),
                    Color(0xFF1a1a1a),
                    Color(0xFF2a2a2a),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white38,
                      size: 80,
                    ),
                    const SizedBox(height: DesignTokens.space16),
                    const Text(
                      'Camera Preview\n(Simulated)',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Scanning overlay
            _buildScanningOverlay(),

            // Bottom controls
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildCameraControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.accentGreen,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Corner indicators
            ...[
              Alignment.topLeft,
              Alignment.topRight,
              Alignment.bottomLeft,
              Alignment.bottomRight,
            ].map((alignment) => _buildCornerIndicator(alignment)),

            // Scanning line
            if (_isScanning)
              AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: _scanAnimation.value * 220 + 15,
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
                            color: AppTheme.accentGreen.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Instructions
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'Position barcode\nwithin this frame',
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
      ),
    );
  }

  Widget _buildCornerIndicator(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 25,
        height: 25,
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppTheme.accentGreen,
              width: alignment == Alignment.topLeft || alignment == Alignment.topRight ? 4 : 0,
            ),
            bottom: BorderSide(
              color: AppTheme.accentGreen,
              width: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? 4 : 0,
            ),
            left: BorderSide(
              color: AppTheme.accentGreen,
              width: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? 4 : 0,
            ),
            right: BorderSide(
              color: AppTheme.accentGreen,
              width: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? 4 : 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Flash toggle
        _buildCameraControlButton(
          icon: Icons.flash_on,
          label: 'Flash',
          onTap: _toggleFlash,
        ),

        // Demo scan button
        _buildCameraControlButton(
          icon: Icons.center_focus_strong,
          label: 'Demo Scan',
          onTap: _simulateScan,
          isPrimary: true,
        ),

        // Focus
        _buildCameraControlButton(
          icon: Icons.center_focus_weak,
          label: 'Focus',
          onTap: _focusCamera,
        ),
      ],
    );
  }

  Widget _buildCameraControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space12,
          vertical: DesignTokens.space8,
        ),
        decoration: BoxDecoration(
          color: isPrimary
            ? AppTheme.accentGreen
            : Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanHistory() {
    if (_scanHistory.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: 'No scan history',
        subtitle: 'Scanned barcodes will appear here for quick access',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(DesignTokens.space20),
      itemCount: _scanHistory.length,
      itemBuilder: (context, index) {
        final item = _scanHistory[index];
        return _buildHistoryItem(item);
      },
    );
  }

  Widget _buildHistoryItem(ScannedItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.mediumGrey.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Barcode icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.qr_code,
              color: AppTheme.accentGreen,
              size: 24,
            ),
          ),

          const SizedBox(width: DesignTokens.space12),

          // Item info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.foodName ?? 'Unknown Food',
                  style: const TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Barcode: ${item.barcode}',
                  style: TextStyle(
                    color: AppTheme.lightGrey.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatTimestamp(item.timestamp),
                  style: TextStyle(
                    color: AppTheme.lightGrey.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Rescan button
          GestureDetector(
            onTap: () => _rescanBarcode(item.barcode),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.refresh,
                color: AppTheme.accentGreen,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleCamera() {
    setState(() {
      _isCameraActive = !_isCameraActive;
      if (_isCameraActive) {
        _isScanning = true;
        _scanController.repeat();
      } else {
        _isScanning = false;
        _scanController.stop();
        _scanController.reset();
      }
    });
    Haptics.tap();
  }

  void _toggleFlash() {
    Haptics.tap();
    // TODO: Implement flash toggle
  }

  void _focusCamera() {
    Haptics.tap();
    // TODO: Implement camera focus
  }

  void _simulateScan() async {
    Haptics.tap();
    setState(() => _isScanning = true);

    // Simulate scanning delay
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      _processBarcode('1234567890123');
    }
  }

  void _showManualEntry() {
    Haptics.tap();
    showDialog(
      context: context,
      builder: (context) => _ManualBarcodeDialog(
        onBarcodeEntered: _processBarcode,
      ),
    );
  }

  void _processBarcode(String barcode) async {
    try {
      final barcodeService = BarcodeService();
      final product = await barcodeService.lookup(barcode);

      if (product != null) {
        final food = barcodeService.toFoodItem(product);
        setState(() => _lastScannedFood = food);

        // Add to history
        _scanHistory.insert(0, ScannedItem(
          barcode: barcode,
          timestamp: DateTime.now(),
          foodName: food.name,
        ));

        // Limit history to 20 items
        if (_scanHistory.length > 20) {
          _scanHistory.removeLast();
        }

        Haptics.success();
        widget.onFoodSelected(food);
      } else {
        Haptics.warning();
        _showFoodNotFoundDialog(barcode);
      }
    } catch (e) {
      Haptics.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error looking up barcode'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _rescanBarcode(String barcode) {
    _processBarcode(barcode);
  }

  void _showFoodNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text(
          'Food Not Found',
          style: TextStyle(color: AppTheme.neutralWhite),
        ),
        content: Text(
          'No food found for barcode: $barcode\nWould you like to create a custom food entry?',
          style: TextStyle(color: AppTheme.lightGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Open custom food creator with barcode
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
            ),
            child: const Text('Create Food'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class _ManualBarcodeDialog extends StatefulWidget {
  final Function(String) onBarcodeEntered;

  const _ManualBarcodeDialog({required this.onBarcodeEntered});

  @override
  State<_ManualBarcodeDialog> createState() => _ManualBarcodeDialogState();
}

class _ManualBarcodeDialogState extends State<_ManualBarcodeDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardDark,
      title: const Text(
        'Enter Barcode',
        style: TextStyle(color: AppTheme.neutralWhite),
      ),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: AppTheme.neutralWhite),
        decoration: InputDecoration(
          hintText: 'Enter barcode number',
          hintStyle: TextStyle(color: AppTheme.lightGrey.withOpacity(0.6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.accentGreen),
          ),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final barcode = _controller.text.trim();
            if (barcode.isNotEmpty) {
              Navigator.of(context).pop();
              widget.onBarcodeEntered(barcode);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentGreen,
          ),
          child: const Text('Lookup'),
        ),
      ],
    );
  }
}

class ScannedItem {
  final String barcode;
  final DateTime timestamp;
  final String? foodName;

  ScannedItem({
    required this.barcode,
    required this.timestamp,
    this.foodName,
  });
}