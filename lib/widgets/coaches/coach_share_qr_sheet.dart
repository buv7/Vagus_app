import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vagus_app/theme/design_tokens.dart';
import 'package:vagus_app/services/coaches/qr_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoachShareQrSheet extends StatefulWidget {
  final String? username;

  const CoachShareQrSheet({super.key, this.username});

  @override
  State<CoachShareQrSheet> createState() => _CoachShareQrSheetState();
}

class _CoachShareQrSheetState extends State<CoachShareQrSheet> {
  final CoachQrService _qrService = CoachQrService();

  String? _qrToken;
  String? _staticDeepLink;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateQrData();
  }

  Future<void> _generateQrData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Not logged in';
          _isLoading = false;
        });
        return;
      }

      // Generate QR token
      final token = await _qrService.createToken(coachId: user.id);

      // Generate static deep link if username is available
      String? staticLink;
      if (widget.username != null && widget.username!.isNotEmpty) {
        staticLink = 'vagus://coach/${widget.username}';
      }

      setState(() {
        _qrToken = token;
        _staticDeepLink = staticLink;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to generate QR code: $e';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        backgroundColor: DesignTokens.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareLink(String link) {
    Share.share(
      'Connect with me on Vagus: $link',
      subject: 'Connect with me on Vagus',
    );
  }

  Widget _buildQrSection(String title, String data, IconData icon) {
    return Container(
      decoration: DesignTokens.glassmorphicDecoration(
        borderRadius: DesignTokens.radius20,
        backgroundColor: DesignTokens.cardBackground,
      ),
      child: DesignTokens.createBackdropFilter(
        sigmaX: DesignTokens.blurMd,
        sigmaY: DesignTokens.blurMd,
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space20),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: DesignTokens.accentGreen,
                    size: 24,
                  ),
                  const SizedBox(width: DesignTokens.space8),
                  Text(
                    title,
                    style: DesignTokens.titleSmall.copyWith(
                      color: DesignTokens.neutralWhite,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space16),
              Container(
                padding: const EdgeInsets.all(DesignTokens.space16),
                decoration: BoxDecoration(
                  color: DesignTokens.neutralWhite,
                  borderRadius: BorderRadius.circular(DesignTokens.radius16),
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 200.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: DesignTokens.primaryDark,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: DesignTokens.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.space16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _copyToClipboard(data, title),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Link'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.accentBlue,
                        foregroundColor: DesignTokens.neutralWhite,
                        padding: const EdgeInsets.symmetric(
                          vertical: DesignTokens.space12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radius12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _shareLink(data),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.accentPurple,
                        foregroundColor: DesignTokens.neutralWhite,
                        padding: const EdgeInsets.symmetric(
                          vertical: DesignTokens.space12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radius12),
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.primaryDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radius24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: DesignTokens.space8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: DesignTokens.textSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.qr_code,
                      color: DesignTokens.accentGreen,
                      size: 28,
                    ),
                    const SizedBox(width: DesignTokens.space12),
                    Text(
                      'Share Your Profile',
                      style: DesignTokens.titleLarge.copyWith(
                        color: DesignTokens.neutralWhite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space8),
                Text(
                  'Let clients scan your QR code or share your profile link',
                  style: DesignTokens.bodyMedium.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: DesignTokens.space24),
                if (_isLoading) ...[
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.accentGreen),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space20),
                ] else if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.space16),
                    decoration: BoxDecoration(
                      color: DesignTokens.dangerBg,
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                      border: Border.all(
                        color: DesignTokens.danger,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: DesignTokens.danger,
                        ),
                        const SizedBox(width: DesignTokens.space8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: DesignTokens.bodyMedium.copyWith(
                              color: DesignTokens.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space20),
                ] else ...[
                  if (_qrToken != null) ...[
                    _buildQrSection(
                      'Dynamic QR Code',
                      _qrToken!,
                      Icons.qr_code_2,
                    ),
                    const SizedBox(height: DesignTokens.space16),
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.space12),
                      decoration: BoxDecoration(
                        color: DesignTokens.infoBg,
                        borderRadius: BorderRadius.circular(DesignTokens.radius8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: DesignTokens.info,
                            size: 16,
                          ),
                          const SizedBox(width: DesignTokens.space8),
                          Expanded(
                            child: Text(
                              'Expires in 24 hours',
                              style: DesignTokens.bodySmall.copyWith(
                                color: DesignTokens.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space20),
                  ],
                  if (_staticDeepLink != null) ...[
                    _buildQrSection(
                      'Permanent Link',
                      _staticDeepLink!,
                      Icons.link,
                    ),
                    const SizedBox(height: DesignTokens.space20),
                  ],
                ],
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.lightGrey,
                    foregroundColor: DesignTokens.neutralWhite,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}