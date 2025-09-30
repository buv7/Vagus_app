import 'package:flutter/material.dart';

/// Custom modal route with spring physics for premium feel
class FoodItemModalRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  FoodItemModalRoute({
    required this.builder,
    super.settings,
  });

  @override
  Color? get barrierColor => Colors.black54;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 350);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Spring animation curve
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Slide from bottom with slight overshoot
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(curvedAnimation);

    // Fade in backdrop
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    return Stack(
      children: [
        // Backdrop fade
        FadeTransition(
          opacity: fadeAnimation,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.black54,
            ),
          ),
        ),
        // Modal slide
        SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      ],
    );
  }
}

/// Helper function to show modal with custom route
void showFoodItemModal(
  BuildContext context, {
  required Widget modal,
}) {
  Navigator.of(context).push(
    FoodItemModalRoute(
      builder: (context) => modal,
    ),
  );
}