import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'deep_link_service.dart';
import '../theme/design_tokens.dart';

class QRService {
  static final QRService _instance = QRService._internal();
  factory QRService() => _instance;
  QRService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final DeepLinkService _deepLinkService = DeepLinkService();

  /// Generate a temporary QR token for a coach
  Future<String> generateTemporaryToken(String coachId, {int expiryHours = 24}) async {
    try {
      final response = await _supabase.rpc('generate_qr_token', params: {
        'p_coach_id': coachId,
        'p_expires_hours': expiryHours,
      });
      
      return response as String;
    } catch (e) {
      throw Exception('Failed to generate QR token: $e');
    }
  }

  /// Generate a permanent deep link for a coach
  String generatePermanentLink(String username) {
    return _deepLinkService.generateCoachLink(username);
  }

  /// Create QR code widget
  Widget createQRWidget(String data, {double size = 200}) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        boxShadow: DesignTokens.cardShadow,
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ),
    );
  }

  /// Generate QR code as image data
  Future<Uint8List> generateQRImageData(String data, {double size = 300}) async {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );

    if (qrValidationResult.status != QrValidationStatus.valid) {
      throw Exception('Invalid QR data');
    }

    final qrCode = qrValidationResult.qrCode!;
    final painter = QrPainter.withQr(
      qr: qrCode,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
      gapless: true,
    );

    final image = await painter.toImage(size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) {
      throw Exception('Failed to generate QR image');
    }
    
    return byteData.buffer.asUint8List();
  }

  /// Share QR code with options
  Future<void> shareQRCode(BuildContext context, String data, String coachName) async {
    try {
      final imageData = await generateQRImageData(data);
      
      // Save to temporary file and share
      await Share.shareXFiles(
        [
          XFile.fromData(
            imageData,
            name: 'coach_qr_$coachName.png',
            mimeType: 'image/png',
          ),
        ],
        text: 'Connect with $coachName on VAGUS: $data',
        subject: 'VAGUS Coach Connection',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share QR code: $e'),
            backgroundColor: DesignTokens.accentPink,
          ),
        );
      }
    }
  }

  /// Show QR code in a dialog
  void showQRDialog(BuildContext context, String data, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius20),
        ),
        title: Text(
          title,
          style: DesignTokens.titleMedium.copyWith(
            color: DesignTokens.neutralWhite,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            createQRWidget(data),
            const SizedBox(height: DesignTokens.space16),
            Text(
              'Scan this QR code to connect',
              style: DesignTokens.bodySmall.copyWith(
                color: DesignTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: DesignTokens.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              shareQRCode(context, data, title);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.accentGreen,
              foregroundColor: DesignTokens.primaryDark,
            ),
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  /// Create a comprehensive QR sharing bottom sheet
  void showQRBottomSheet(BuildContext context, {
    required String coachId,
    required String coachName,
    required String username,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => QRBottomSheet(
        coachId: coachId,
        coachName: coachName,
        username: username,
      ),
    );
  }
}

class QRBottomSheet extends StatefulWidget {
  final String coachId;
  final String coachName;
  final String username;

  const QRBottomSheet({
    super.key,
    required this.coachId,
    required this.coachName,
    required this.username,
  });

  @override
  State<QRBottomSheet> createState() => _QRBottomSheetState();
}

class _QRBottomSheetState extends State<QRBottomSheet> {
  final QRService _qrService = QRService();
  
  bool _useTemporary = true;
  String? _temporaryToken;
  String? _permanentLink;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _loading = true);
    
    try {
      final token = await _qrService.generateTemporaryToken(widget.coachId);
      final permanent = _qrService.generatePermanentLink(widget.username);
      
      if (mounted) {
        setState(() {
          _temporaryToken = token;
          _permanentLink = permanent;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate QR codes: $e'),
            backgroundColor: DesignTokens.accentPink,
          ),
        );
      }
    }
  }

  String get _currentData {
    if (_useTemporary && _temporaryToken != null) {
      return DeepLinkService().generateQRLink(_temporaryToken!);
    } else if (_permanentLink != null) {
      return _permanentLink!;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radius24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: DesignTokens.space24),
            
            // Title
            Text(
              'Share Your Coach Profile',
              style: DesignTokens.titleLarge.copyWith(
                color: DesignTokens.neutralWhite,
              ),
            ),
            
            const SizedBox(height: DesignTokens.space24),
            
            if (_loading)
              const CircularProgressIndicator(color: DesignTokens.accentGreen)
            else if (_currentData.isNotEmpty) ...[
              // QR Type Toggle
              Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      'Temporary (24h)',
                      _useTemporary,
                      () => setState(() => _useTemporary = true),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space8),
                  Expanded(
                    child: _buildToggleButton(
                      'Permanent',
                      !_useTemporary,
                      () => setState(() => _useTemporary = false),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: DesignTokens.space24),
              
              // QR Code
              _qrService.createQRWidget(_currentData),
              
              const SizedBox(height: DesignTokens.space16),
              
              // Description
              Text(
                _useTemporary 
                    ? 'This QR code expires in 24 hours'
                    : 'This QR code works permanently',
                style: DesignTokens.bodySmall.copyWith(
                  color: DesignTokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: DesignTokens.space24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _qrService.shareQRCode(context, _currentData, widget.coachName);
                      },
                      child: const Text('Share'),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: DesignTokens.space24),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: DesignTokens.space12,
          horizontal: DesignTokens.space16,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? DesignTokens.accentGreen.withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected 
                ? DesignTokens.accentGreen
                : DesignTokens.glassBorder,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
        ),
        child: Text(
          text,
          style: DesignTokens.labelMedium.copyWith(
            color: isSelected 
                ? DesignTokens.accentGreen
                : DesignTokens.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
