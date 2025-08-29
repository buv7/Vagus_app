import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../services/share/share_card_service.dart';
import '../../theme/design_tokens.dart';


/// Screen for previewing and sharing generated cards
class SharePreviewScreen extends StatefulWidget {
  final ShareAsset asset;
  final ShareDataModel data;

  const SharePreviewScreen({
    super.key,
    required this.asset,
    required this.data,
  });

  @override
  State<SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends State<SharePreviewScreen> {
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview & Share'),
        backgroundColor: DesignTokens.ink50,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyCaption,
            tooltip: 'Copy Caption',
          ),
        ],
      ),
      body: Column(
        children: [
          // Preview Image
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(DesignTokens.space16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radius16),
                                   boxShadow: [
                     const BoxShadow(
                       color: DesignTokens.ink100,
                       blurRadius: 10,
                       offset: Offset(0, 4),
                     ),
                   ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radius16),
                child: Image.file(
                  File(widget.asset.path),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(DesignTokens.space16),
            decoration: const BoxDecoration(
              color: DesignTokens.ink50,
              border: Border(
                top: BorderSide(color: DesignTokens.ink100),
              ),
            ),
            child: Column(
              children: [
                // Caption Preview
                if (widget.asset.caption != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DesignTokens.space12),
                                         decoration: BoxDecoration(
                       color: DesignTokens.ink100,
                       borderRadius: BorderRadius.circular(DesignTokens.radius8),
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           'Caption Preview:',
                           style: DesignTokens.bodySmall.copyWith(
                             color: DesignTokens.ink500,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                         const SizedBox(height: DesignTokens.space8),
                         Text(
                           widget.asset.caption!,
                           style: DesignTokens.bodyMedium.copyWith(
                             color: DesignTokens.ink700,
                           ),
                         ),
                       ],
                     ),
                  ),
                  const SizedBox(height: DesignTokens.space16),
                ],
                
                // Share Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sharing ? null : _shareCard,
                    icon: _sharing 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share),
                    label: Text(_sharing ? 'Sharing...' : 'Share'),
                                       style: ElevatedButton.styleFrom(
                     backgroundColor: DesignTokens.blue600,
                     foregroundColor: DesignTokens.ink50,
                     padding: const EdgeInsets.symmetric(vertical: DesignTokens.space16),
                   ),
                  ),
                ),
                
                const SizedBox(height: DesignTokens.space12),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _saveToGallery,
                    icon: const Icon(Icons.save),
                    label: const Text('Save to Gallery'),
                                       style: OutlinedButton.styleFrom(
                     foregroundColor: DesignTokens.blue600,
                     side: const BorderSide(color: DesignTokens.blue600),
                     padding: const EdgeInsets.symmetric(vertical: DesignTokens.space16),
                   ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyCaption() {
    if (widget.asset.caption != null) {
      Clipboard.setData(ClipboardData(text: widget.asset.caption!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caption copied to clipboard'),
          backgroundColor: DesignTokens.success,
        ),
      );
    }
  }

  void _shareCard() async {
    setState(() => _sharing = true);
    
    try {
      // TODO: Implement native share functionality
      // For now, just show a success message
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(
           content: Text('Share functionality coming soon!'),
           backgroundColor: DesignTokens.blue600,
         ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  void _saveToGallery() async {
    try {
      // TODO: Implement save to gallery functionality
      // For now, just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save to gallery functionality coming soon!'),
          backgroundColor: DesignTokens.blue600,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: DesignTokens.danger,
        ),
      );
    }
  }
}
