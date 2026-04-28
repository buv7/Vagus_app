import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/notifications/fcm_service.dart';
import '../../theme/design_tokens.dart';

/// Wraps a child widget and shows a slide-down in-app banner whenever a
/// foreground FCM message arrives. Prevents double-notification: FCM is
/// configured to suppress the system tray on foreground (alert: false).
///
/// Usage: wrap your root navigator widget with this:
///   InAppNotificationBanner(child: MaterialApp(...))
class InAppNotificationBanner extends StatefulWidget {
  final Widget child;

  const InAppNotificationBanner({super.key, required this.child});

  @override
  State<InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;

  StreamSubscription<FcmInAppNotification>? _sub;
  FcmInAppNotification? _current;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _sub = FcmService.instance.inAppNotifications.listen(_show);
  }

  void _show(FcmInAppNotification notification) {
    _dismissTimer?.cancel();
    setState(() => _current = notification);
    _controller.forward(from: 0);
    _dismissTimer = Timer(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) setState(() => _current = null);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_current != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: SlideTransition(
              position: _slideAnimation,
              child: _BannerCard(
                notification: _current!,
                onDismiss: _dismiss,
              ),
            ),
          ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final FcmInAppNotification notification;
  final VoidCallback onDismiss;

  const _BannerCard({
    required this.notification,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(DesignTokens.radius12),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        onTap: () {
          onDismiss();
          final route = notification.route;
          if (route != null) {
            Navigator.of(context, rootNavigator: true).pushNamed(route);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space16,
            vertical: DesignTokens.space12,
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications, size: 20),
              const SizedBox(width: DesignTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.body.isNotEmpty)
                      Text(
                        notification.body,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
