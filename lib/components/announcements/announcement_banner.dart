import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/announcements/announcement.dart';
import '../../services/announcements_service.dart';
import '../../services/navigation/app_navigator.dart';

class AnnouncementBanner extends StatefulWidget {
  final Announcement announcement;
  final VoidCallback? onDismiss;

  const AnnouncementBanner({
    super.key,
    required this.announcement,
    this.onDismiss,
  });

  @override
  State<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<AnnouncementBanner> {
  final AnnouncementsService _announcementsService = AnnouncementsService();
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    // Record impression when banner is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordImpression();
    });
  }

  Future<void> _recordImpression() async {
    try {
      await _announcementsService.recordImpression(widget.announcement.id);
    } catch (e) {
      // Silently handle errors - impressions are not critical
    }
  }

  Future<void> _handleCtaTap() async {
    try {
      await _announcementsService.recordClick(
        widget.announcement.id,
        target: widget.announcement.ctaValue,
      );

      if (widget.announcement.ctaType == 'url' && widget.announcement.ctaValue != null) {
        // Open URL
        final uri = Uri.parse(widget.announcement.ctaValue!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else if (widget.announcement.ctaType == 'coach' && widget.announcement.ctaValue != null) {
        // Navigate to coach profile
        if (mounted) {
          AppNavigator.coachProfile(context, widget.announcement.ctaValue!);
        }
      }
    } catch (e) {
      // Silently handle errors - clicks are not critical
    }
  }

  void _dismiss() {
    setState(() {
      _isDismissed = true;
    });
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with dismiss button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ANNOUNCEMENT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                IconButton(
                  onPressed: _dismiss,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image (if available)
                if (widget.announcement.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.announcement.imageUrl!,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.white54,
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Title
                const SizedBox(height: 12),
                Text(
                  widget.announcement.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                // Body (if available)
                if (widget.announcement.body != null && widget.announcement.body!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.announcement.body!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],

                // CTA Button (if available)
                if (widget.announcement.hasCta) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleCtaTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _getCtaButtonText(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCtaButtonText() {
    switch (widget.announcement.ctaType) {
      case 'url':
        return 'Learn More';
      case 'coach':
        return 'View Coach';
      default:
        return 'Learn More';
    }
  }
}
