import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../models/ads/ad_banner.dart';
import '../../services/admin/ad_banner_service.dart';

class AdBannerStrip extends StatefulWidget {
  final String audience;

  const AdBannerStrip({
    super.key,
    required this.audience,
  });

  @override
  State<AdBannerStrip> createState() => _AdBannerStripState();
}

class _AdBannerStripState extends State<AdBannerStrip> {
  final AdBannerService _adService = AdBannerService();
  List<AdBanner> _ads = [];
  bool _loading = true;
  final Set<String> _seenAdIds = {};

  bool _isValidHttpUrl(String? url) {
    if (url == null) return false;
    try {
      final uri = Uri.parse(url.trim());
      if (!(uri.scheme == 'http' || uri.scheme == 'https')) return false;
      if ((uri.host).isEmpty) return false;
      // Avoid known placeholder host that often fails on emulators/offline
      if (uri.host.contains('via.placeholder.com')) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    try {
      final ads = await _adService.fetchActive(audience: widget.audience);
      setState(() {
        _ads = ads;
        _loading = false;
      });

      // Track impressions for newly seen ads
      for (final ad in ads) {
        if (!_seenAdIds.contains(ad.id)) {
          _seenAdIds.add(ad.id);
          unawaited(_adService.trackImpression(ad.id));
        }
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _handleAdClick(AdBanner ad) async {
    // Track the click
    await _adService.trackClick(ad.id);

    // Open link if available
    if (ad.linkUrl != null && ad.linkUrl!.isNotEmpty) {
      try {
        final uri = Uri.parse(ad.linkUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Error launching URL: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox.shrink();
    }

    if (_ads.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 88,
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space16,
        vertical: DesignTokens.space8,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _ads.map((ad) => _buildAdCard(ad)).toList(),
        ),
      ),
    );
  }

  Widget _buildAdCard(AdBanner ad) {
    return Container(
      width: 200,
      height: 88,
      margin: const EdgeInsets.only(right: DesignTokens.space12),
      child: GestureDetector(
        onTap: () => _handleAdClick(ad),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            border: Border.all(
              color: AppTheme.mediumGrey.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            child: Stack(
              children: [
                // Ad Image
                Positioned.fill(
                  child: _isValidHttpUrl(ad.imageUrl)
                      ? Image.network(
                          ad.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.mediumGrey,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: AppTheme.lightGrey,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppTheme.mediumGrey,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppTheme.mediumGrey,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: AppTheme.lightGrey,
                              size: 32,
                            ),
                          ),
                        ),
                ),
                
                // Gradient overlay for better text readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Ad title
                Positioned(
                  bottom: DesignTokens.space8,
                  left: DesignTokens.space8,
                  right: DesignTokens.space8,
                  child: Text(
                    ad.title,
                    style: const TextStyle(
                      color: AppTheme.neutralWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Click indicator
                if (ad.linkUrl != null && ad.linkUrl!.isNotEmpty)
                  Positioned(
                    top: DesignTokens.space4,
                    right: DesignTokens.space4,
                    child: Container(
                      padding: const EdgeInsets.all(DesignTokens.space4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(DesignTokens.radius4),
                      ),
                      child: const Icon(
                        Icons.open_in_new,
                        color: AppTheme.primaryDark,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
