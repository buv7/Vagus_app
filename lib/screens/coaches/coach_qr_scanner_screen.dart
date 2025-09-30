import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vagus_app/theme/design_tokens.dart';
import 'package:vagus_app/services/coaches/qr_service.dart';
import 'package:vagus_app/screens/coach/coach_profile_public_screen.dart';

class CoachQrScannerScreen extends StatefulWidget {
  const CoachQrScannerScreen({super.key});

  @override
  State<CoachQrScannerScreen> createState() => _CoachQrScannerScreenState();
}

class _CoachQrScannerScreenState extends State<CoachQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final CoachQrService _qrService = CoachQrService();

  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processQrCode(String value) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      Uri? uri;
      try {
        uri = Uri.parse(value);
      } catch (e) {
        _showError('Invalid QR code format');
        return;
      }

      if (uri.scheme == 'vagus') {
        if (uri.host == 'qr') {
          // Handle QR token: vagus://qr/<token>
          final token = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
          if (token != null) {
            await _resolveQrToken(token);
          } else {
            _showError('Invalid QR token');
          }
        } else if (uri.host == 'coach') {
          // Handle direct coach link: vagus://coach/<username>
          final username = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
          if (username != null) {
            await _openCoachProfile(username: username);
          } else {
            _showError('Invalid coach link');
          }
        } else {
          _showError('Unknown QR code type');
        }
      } else {
        _showError('This QR code is not a Vagus coach link');
      }
    } catch (e) {
      _showError('Error processing QR code: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _resolveQrToken(String token) async {
    try {
      final resolved = await _qrService.resolveToken(token);
      if (resolved != null) {
        if (resolved.username != null) {
          await _openCoachProfile(username: resolved.username!);
        } else {
          await _openCoachProfile(coachId: resolved.coachId);
        }
      } else {
        _showError('QR code has expired or is invalid');
      }
    } catch (e) {
      _showError('Failed to resolve QR code');
    }
  }

  Future<void> _openCoachProfile({String? username, String? coachId}) async {
    if (mounted) {
      unawaited(Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CoachProfilePublicScreen(
            coachId: coachId,
            username: username,
          ),
        ),
      ));
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: DesignTokens.danger,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _toggleTorch() {
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
    _controller.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.primaryDark,
      appBar: AppBar(
        title: Text(
          'Scan QR Code',
          style: DesignTokens.titleLarge.copyWith(
            color: DesignTokens.neutralWhite,
          ),
        ),
        backgroundColor: DesignTokens.primaryDark,
        foregroundColor: DesignTokens.neutralWhite,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (BarcodeCapture capture) {
              if (capture.barcodes.isNotEmpty && !_isProcessing) {
                final String? value = capture.barcodes.first.rawValue;
                if (value != null) {
                  _processQrCode(value);
                }
              }
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.accentGreen),
                    ),
                    SizedBox(height: DesignTokens.space16),
                    Text(
                      'Processing QR code...',
                      style: TextStyle(
                        color: DesignTokens.neutralWhite,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: DesignTokens.space32,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  Container(
                    decoration: DesignTokens.glassmorphicDecoration(
                      borderRadius: DesignTokens.radiusFull,
                      backgroundColor: DesignTokens.cardBackground,
                    ),
                    child: IconButton(
                      onPressed: _toggleTorch,
                      icon: Icon(
                        _isTorchOn ? Icons.flash_on : Icons.flash_off,
                        color: _isTorchOn ? DesignTokens.accentGreen : DesignTokens.neutralWhite,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space16),
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.space16),
                    decoration: DesignTokens.glassmorphicDecoration(
                      borderRadius: DesignTokens.radius16,
                      backgroundColor: DesignTokens.cardBackground,
                    ),
                    child: Text(
                      'Point your camera at a coach QR code',
                      style: DesignTokens.bodyMedium.copyWith(
                        color: DesignTokens.neutralWhite,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Scan area overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                border: Border.all(color: Colors.transparent),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: DesignTokens.accentGreen,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(DesignTokens.radius20),
                      ),
                    ),
                  ),
                  // Corner indicators
                  Center(
                    child: SizedBox(
                      width: 250,
                      height: 250,
                      child: Stack(
                        children: [
                          // Top-left corner
                          Positioned(
                            top: -3,
                            left: -3,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: DesignTokens.accentGreen, width: 4),
                                  left: BorderSide(color: DesignTokens.accentGreen, width: 4),
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(DesignTokens.radius20),
                                ),
                              ),
                            ),
                          ),
                          // Top-right corner
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: DesignTokens.accentGreen, width: 4),
                                  right: BorderSide(color: DesignTokens.accentGreen, width: 4),
                                ),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(DesignTokens.radius20),
                                ),
                              ),
                            ),
                          ),
                          // Bottom-left corner
                          Positioned(
                            bottom: -3,
                            left: -3,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: DesignTokens.accentGreen, width: 4),
                                  left: BorderSide(color: DesignTokens.accentGreen, width: 4),
                                ),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(DesignTokens.radius20),
                                ),
                              ),
                            ),
                          ),
                          // Bottom-right corner
                          Positioned(
                            bottom: -3,
                            right: -3,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: DesignTokens.accentGreen, width: 4),
                                  right: BorderSide(color: DesignTokens.accentGreen, width: 4),
                                ),
                                borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(DesignTokens.radius20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}