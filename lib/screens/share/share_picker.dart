import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/share/share_card_service.dart';
import '../../theme/design_tokens.dart';
import '../../services/billing/plan_access_manager.dart';
import 'share_preview_screen.dart';

/// Screen for picking share card options
class SharePicker extends StatefulWidget {
  final ShareDataModel data;

  const SharePicker({
    super.key,
    required this.data,
  });

  @override
  State<SharePicker> createState() => _SharePickerState();
}

class _SharePickerState extends State<SharePicker> {
  ShareTemplate _selectedTemplate = ShareTemplate.minimal;
  bool _isStory = true;
  bool _minimalWatermark = false;
  bool _showHandle = true;
  bool _faceBlur = false;
  bool _isProUser = false;

  @override
  void initState() {
    super.initState();
    _checkProStatus();
  }

  Future<void> _checkProStatus() async {
    try {
      final isPro = await PlanAccessManager.instance.isProUser();
      setState(() => _isProUser = isPro);
    } catch (e) {
      // Ignore pro status errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Card'),
        backgroundColor: DesignTokens.ink50,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format Selection
            _buildSection(
              'Format',
              _buildFormatSelector(),
            ),
            
            const SizedBox(height: DesignTokens.space24),
            
            // Template Selection
            _buildSection(
              'Template',
              _buildTemplateSelector(),
            ),
            
            const SizedBox(height: DesignTokens.space24),
            
            // Privacy Settings
            _buildSection(
              'Privacy',
              _buildPrivacySettings(),
            ),
            
            const SizedBox(height: DesignTokens.space24),
            
            // Preview Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => unawaited(_showPreview()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.blue600,
                  foregroundColor: DesignTokens.ink50,
                  padding: const EdgeInsets.symmetric(vertical: DesignTokens.space16),
                ),
                child: const Text('Preview & Share'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DesignTokens.titleMedium.copyWith(
            color: DesignTokens.ink900,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: DesignTokens.space12),
        content,
      ],
    );
  }

  Widget _buildFormatSelector() {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.ink50,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: DesignTokens.ink100),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFormatOption(
              'Story',
              '9:16',
              Icons.phone_android,
              _isStory,
              () => setState(() => _isStory = true),
            ),
          ),
          Expanded(
            child: _buildFormatOption(
              'Feed',
              '1:1',
              Icons.crop_square,
              !_isStory,
              () => setState(() => _isStory = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption(
    String title,
    String ratio,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space16),
        decoration: BoxDecoration(
          color: isSelected ? DesignTokens.blue600.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
                           color: isSelected ? DesignTokens.blue600 : DesignTokens.ink500,
             size: 32,
           ),
           const SizedBox(height: DesignTokens.space8),
           Text(
             title,
             style: DesignTokens.bodyMedium.copyWith(
               color: isSelected ? DesignTokens.blue600 : DesignTokens.ink700,
                fontWeight: FontWeight.w500,
              ),
            ),
                         Text(
               ratio,
               style: DesignTokens.bodySmall.copyWith(
                 color: isSelected ? DesignTokens.blue600 : DesignTokens.ink500,
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSelector() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: DesignTokens.space12,
        mainAxisSpacing: DesignTokens.space12,
        childAspectRatio: 1.2,
      ),
      itemCount: ShareTemplate.values.length,
      itemBuilder: (context, index) {
        final template = ShareTemplate.values[index];
        final isSelected = template == _selectedTemplate;
        
        return GestureDetector(
          onTap: () => setState(() => _selectedTemplate = template),
          child: Container(
                         decoration: BoxDecoration(
               color: isSelected ? DesignTokens.blue600.withValues(alpha: 0.1) : DesignTokens.ink50,
               borderRadius: BorderRadius.circular(DesignTokens.radius12),
               border: Border.all(
                 color: isSelected ? DesignTokens.blue600 : DesignTokens.ink100,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                                 Icon(
                   _getTemplateIcon(template),
                   color: isSelected ? DesignTokens.blue600 : DesignTokens.ink500,
                   size: 32,
                 ),
                 const SizedBox(height: DesignTokens.space8),
                 Text(
                   _getTemplateName(template),
                   style: DesignTokens.bodyMedium.copyWith(
                     color: isSelected ? DesignTokens.blue600 : DesignTokens.ink700,
                    fontWeight: FontWeight.w500,
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

  IconData _getTemplateIcon(ShareTemplate template) {
    switch (template) {
      case ShareTemplate.minimal:
        return Icons.text_fields;
      case ShareTemplate.splitCompare:
        return Icons.compare_arrows;
      case ShareTemplate.gridStats:
        return Icons.grid_view;
      case ShareTemplate.ringFocus:
        return Icons.radio_button_checked;
      case ShareTemplate.badgeFlex:
        return Icons.emoji_events;
    }
  }

  String _getTemplateName(ShareTemplate template) {
    switch (template) {
      case ShareTemplate.minimal:
        return 'Minimal';
      case ShareTemplate.splitCompare:
        return 'Split Compare';
      case ShareTemplate.gridStats:
        return 'Grid Stats';
      case ShareTemplate.ringFocus:
        return 'Ring Focus';
      case ShareTemplate.badgeFlex:
        return 'Badge Flex';
    }
  }

  Widget _buildPrivacySettings() {
    return Column(
      children: [
        _buildPrivacyOption(
          'Show Handle',
          'Display your @handle on the card',
          _showHandle,
          (value) => setState(() => _showHandle = value),
        ),
        const SizedBox(height: DesignTokens.space12),
        _buildPrivacyOption(
          'Minimal Watermark',
          'Use smaller watermark (Pro only)',
          _minimalWatermark,
          (value) => setState(() => _minimalWatermark = value),
          enabled: _isProUser,
        ),
        if (widget.data.imagePaths?.isNotEmpty == true) ...[
          const SizedBox(height: DesignTokens.space12),
          _buildPrivacyOption(
            'Face Blur',
            'Blur faces in photos',
            _faceBlur,
            (value) => setState(() => _faceBlur = value),
          ),
        ],
      ],
    );
  }

  Widget _buildPrivacyOption(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged, {
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: DesignTokens.ink50,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: DesignTokens.ink100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                                 style: DesignTokens.bodyMedium.copyWith(
                 color: enabled ? DesignTokens.ink900 : DesignTokens.ink500,
                 fontWeight: FontWeight.w500,
               ),
             ),
             Text(
               subtitle,
               style: DesignTokens.bodySmall.copyWith(
                 color: enabled ? DesignTokens.ink500 : DesignTokens.ink500,
               ),
                ),
              ],
            ),
          ),
                     Switch(
             value: value,
             onChanged: enabled ? onChanged : null,
             activeColor: DesignTokens.blue600,
           ),
        ],
      ),
    );
  }

  Future<void> _showPreview() async {
    try {
      // Show loading
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Build share asset
      final shareService = ShareCardService();
      final ShareAsset asset;
      
      if (_isStory) {
        asset = await shareService.buildStory(
          _selectedTemplate,
          widget.data,
          minimalWatermark: _minimalWatermark,
        );
      } else {
        asset = await shareService.buildFeed(
          _selectedTemplate,
          widget.data,
          minimalWatermark: _minimalWatermark,
        );
      }

      // Hide loading
      if (!mounted || !context.mounted) return;
      Navigator.pop(context);

      // Show preview
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SharePreviewScreen(
            asset: asset,
            data: widget.data,
          ),
        ),
      );
    } catch (e) {
      // Hide loading
      if (!mounted || !context.mounted) return;
      Navigator.pop(context);
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create share card: $e'),
          backgroundColor: DesignTokens.danger,
        ),
      );
    }
  }
}
