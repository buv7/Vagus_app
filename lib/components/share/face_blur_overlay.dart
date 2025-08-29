import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Lightweight face blur overlay for photo templates
class FaceBlurOverlay extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final List<Rect> faceRegions;

  const FaceBlurOverlay({
    super.key,
    required this.child,
    this.enabled = false,
    this.faceRegions = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled || faceRegions.isEmpty) {
      return child;
    }

    return Stack(
      children: [
        child,
        ...faceRegions.map((region) => Positioned(
          left: region.left,
          top: region.top,
          child: Container(
            width: region.width,
            height: region.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(region.width / 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(region.width / 2),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }
}

/// Helper class for face detection (stub for v1)
class FaceDetectionHelper {
  /// Detect faces in an image (stub implementation)
  static Future<List<Rect>> detectFaces(String imagePath) async {
    // TODO: Implement actual face detection
    // For v1, return empty list (no faces detected)
    return [];
  }
}
