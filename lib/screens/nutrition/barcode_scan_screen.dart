import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/nutrition/barcode_service.dart';
import '../../services/ai/nutrition_ai.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../widgets/branding/vagus_appbar.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final BarcodeService _barcodeService = BarcodeService();
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _barcodeController = TextEditingController();
  
  bool _isScanning = true;
  bool _isProcessing = false;
  String _error = '';
  BarcodeProduct? _foundProduct;
  String? _scannedCode;

  @override
  void dispose() {
    _scannerController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;
    
    return Scaffold(
      appBar: VagusAppBar(
        title: Text(LocaleHelper.t('scan_barcode', language)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: ValueListenableBuilder(
              valueListenable: _scannerController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
          ),
          IconButton(
            onPressed: _switchCamera,
            icon: ValueListenableBuilder(
              valueListenable: _scannerController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner view
          Expanded(
            flex: 3,
            child: _buildScannerView(language),
          ),
          
          // Results section
          Expanded(
            flex: 2,
            child: _buildResultsSection(language),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView(String language) {
    if (!_isScanning) {
      return _buildManualEntryView(language);
    }
    
    return Stack(
      children: [
        // Scanner
        MobileScanner(
          controller: _scannerController,
          onDetect: _onBarcodeDetected,
        ),
        
        // Overlay
        _buildScannerOverlay(language),
        
        // Processing indicator
        if (_isProcessing)
          Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Processing...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScannerOverlay(String language) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
      ),
      child: Column(
        children: [
          const Spacer(),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              LocaleHelper.t('point_camera_at_barcode', language),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Scan frame
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Corner indicators
                ...List.generate(4, (index) {
                  final isTop = index < 2;
                  final isLeft = index % 2 == 0;
                  return Positioned(
                    top: isTop ? 0 : null,
                    bottom: isTop ? null : 0,
                    left: isLeft ? 0 : null,
                    right: isLeft ? null : 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          top: isTop ? const BorderSide(color: Colors.green, width: 3) : BorderSide.none,
                          bottom: isTop ? BorderSide.none : const BorderSide(color: Colors.green, width: 3),
                          left: isLeft ? const BorderSide(color: Colors.green, width: 3) : BorderSide.none,
                          right: isLeft ? BorderSide.none : const BorderSide(color: Colors.green, width: 3),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Manual entry button
          ElevatedButton.icon(
            onPressed: () => setState(() => _isScanning = false),
            icon: const Icon(Icons.keyboard),
            label: Text(LocaleHelper.t('enter_manually', language)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildManualEntryView(String language) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            LocaleHelper.t('enter_barcode_manually', language),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          TextField(
            decoration: InputDecoration(
              labelText: LocaleHelper.t('barcode_number', language),
              hintText: LocaleHelper.t('enter_barcode_hint', language),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.qr_code),
            ),
            keyboardType: TextInputType.number,
            onSubmitted: _lookupBarcode,
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _isScanning = true),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(LocaleHelper.t('scan_again', language)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () { _lookupBarcode(_barcodeController.text); },
                  icon: const Icon(Icons.search),
                  label: Text(LocaleHelper.t('lookup', language)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(String language) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error.isNotEmpty) _buildErrorDisplay(language),
          if (_foundProduct != null) _buildProductDisplay(language),
          if (_scannedCode != null && _foundProduct == null) _buildNotFoundDisplay(language),
          if (_error.isEmpty && _foundProduct == null && _scannedCode == null)
            _buildInstructions(language),
        ],
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

  Widget _buildProductDisplay(String language) {
    final product = _foundProduct!;
    
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
                  Icons.check_circle,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  LocaleHelper.t('product_found', language),
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              product.displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            if (product.brand != null) ...[
              const SizedBox(height: 4),
              Text(
                product.brand!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addToMeal,
                    icon: const Icon(Icons.add),
                    label: Text(LocaleHelper.t('add_to_meal', language)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _scanAgain,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(LocaleHelper.t('scan_another', language)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundDisplay(String language) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.search_off,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  LocaleHelper.t('product_not_found', language),
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              LocaleHelper.t('barcode_not_in_database', language),
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addManually,
                    icon: const Icon(Icons.add_box),
                    label: Text(LocaleHelper.t('add_manually', language)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _scanAgain,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(LocaleHelper.t('try_again', language)),
                  ),
                ),
              ],
            ),
          ],
        ),
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
              LocaleHelper.t('scanning_instructions', language),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInstructionItem(
              Icons.qr_code_scanner,
              LocaleHelper.t('hold_steady', language),
              LocaleHelper.t('hold_steady_desc', language),
            ),
            const SizedBox(height: 8),
            _buildInstructionItem(
              Icons.light_mode,
              LocaleHelper.t('good_lighting', language),
              LocaleHelper.t('good_lighting_desc', language),
            ),
            const SizedBox(height: 8),
            _buildInstructionItem(
              Icons.center_focus_strong,
              LocaleHelper.t('align_barcode', language),
              LocaleHelper.t('align_barcode_desc', language),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(IconData icon, String title, String description) {
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

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        _lookupBarcode(barcode.rawValue!);
      }
    }
  }

  Future<void> _lookupBarcode(String code) async {
    if (code.isEmpty) return;
    
    setState(() {
      _isProcessing = true;
      _error = '';
      _scannedCode = code;
      _foundProduct = null;
    });
    
    try {
      final product = await _barcodeService.lookup(code);
      
      setState(() {
        _foundProduct = product;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to lookup barcode: $e';
        _isProcessing = false;
      });
    }
  }

  void _addToMeal() {
    if (_foundProduct != null) {
      final foodItem = _barcodeService.toFoodItem(_foundProduct!);
      Navigator.of(context).pop(foodItem);
    }
  }

  void _addManually() {
    // TODO: Implement manual product entry
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manual product entry coming soon'),
      ),
    );
  }

  void _scanAgain() {
    setState(() {
      _isScanning = true;
      _error = '';
      _foundProduct = null;
      _scannedCode = null;
    });
  }

  void _toggleFlash() {
    _scannerController.toggleTorch();
  }

  void _switchCamera() {
    _scannerController.switchCamera();
  }
}
