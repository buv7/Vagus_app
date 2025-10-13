import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/branding/vagus_appbar.dart';
import '../coach_profile/coach_profile_screen.dart';
import '../../services/deep_link_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DeepLinkService _deepLinkService = DeepLinkService();
  
  MobileScannerController? _controller;
  bool _isProcessing = false;
  bool _torchEnabled = false;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code == _lastScannedCode) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
    });

    try {
      await _processQRCode(code);
    } catch (e) {
      _showError('Failed to process QR code: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processQRCode(String code) async {
    // Check if it's a Vagus deep link
    if (code.startsWith('vagus://')) {
      await _deepLinkService.handleDeepLink(code, context);
      if (mounted) Navigator.pop(context);
      return;
    }

    // Check if it's a URL containing our deep link
    if (code.contains('vagus://') || code.contains('/qr/') || code.contains('/coach/')) {
      await _deepLinkService.handleDeepLink(code, context);
      if (mounted) Navigator.pop(context);
      return;
    }

    // Try to resolve as QR token directly
    try {
      final response = await _supabase.rpc('resolve_qr_token', params: {
        'p_token': code,
      });

      if (response != null && response.isNotEmpty) {
        final coachData = response.first;
        if (mounted) {
          Navigator.pop(context);
          unawaited(Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoachProfileScreen(
                coachId: coachData['coach_id'],
                isPublicView: true,
              ),
            ),
          ));
        }
        return;
      }
    } catch (e) {
      debugPrint('Failed to resolve QR token: $e');
    }

    // If nothing worked, show error
    _showError('Invalid QR code. Please scan a valid coach QR code.');
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.accentPink,
      ),
    );
  }

  void _toggleTorch() {
    setState(() {
      _torchEnabled = !_torchEnabled;
    });
    _controller?.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: VagusAppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        foregroundColor: DesignTokens.neutralWhite,
        actions: [
          IconButton(
            icon: Icon(
              _torchEnabled ? Icons.flash_on : Icons.flash_off,
              color: _torchEnabled ? DesignTokens.accentOrange : DesignTokens.neutralWhite,
            ),
            onPressed: _toggleTorch,
            tooltip: 'Toggle Flash',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay with scanning frame
          _buildScannerOverlay(),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: DesignTokens.accentGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: const ShapeDecoration(
        shape: QRScannerOverlayShape(
          borderColor: DesignTokens.accentGreen,
          borderRadius: DesignTokens.radius12,
          borderLength: 30,
          borderWidth: 4,
          cutOutSize: 250,
        ),
      ),
      child: const Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.space24),
          child: Text(
            'Point your camera at a coach QR code',
            style: TextStyle(
              color: DesignTokens.neutralWhite,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class QRScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  const QRScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderRadius = 0,
    this.borderLength = 40,
    this.borderWidth = 7,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final Path path = Path()..addRect(rect);
    final Path cutout = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      );
    return Path.combine(PathOperation.difference, path, cutout);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Draw corner brackets
    _drawCornerBrackets(canvas, cutOutRect, paint);
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect, Paint paint) {
    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + borderLength)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.left + borderLength, rect.top),
      paint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - borderLength, rect.top)
        ..lineTo(rect.right - borderRadius, rect.top)
        ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + borderRadius)
        ..lineTo(rect.right, rect.top + borderLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - borderLength)
        ..lineTo(rect.left, rect.bottom - borderRadius)
        ..quadraticBezierTo(rect.left, rect.bottom, rect.left + borderRadius, rect.bottom)
        ..lineTo(rect.left + borderLength, rect.bottom),
      paint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - borderLength, rect.bottom)
        ..lineTo(rect.right - borderRadius, rect.bottom)
        ..quadraticBezierTo(rect.right, rect.bottom, rect.right, rect.bottom - borderRadius)
        ..lineTo(rect.right, rect.bottom - borderLength),
      paint,
    );
  }

  @override
  ShapeBorder scale(double t) => QRScannerOverlayShape(
        borderColor: borderColor,
        borderRadius: borderRadius,
        borderLength: borderLength,
        borderWidth: borderWidth,
        cutOutSize: cutOutSize,
      );
}
