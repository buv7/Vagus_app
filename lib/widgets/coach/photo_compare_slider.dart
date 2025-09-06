import 'package:flutter/material.dart';

/// Simple no-deps before/after slider: two images stacked, draggable divider.
class PhotoCompareSlider extends StatefulWidget {
  final String beforeUrl;
  final String afterUrl;
  const PhotoCompareSlider({super.key, required this.beforeUrl, required this.afterUrl});

  @override
  State<PhotoCompareSlider> createState() => _PhotoCompareSliderState();
}

class _PhotoCompareSliderState extends State<PhotoCompareSlider> {
  double _pos = 0.5;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (ctx, b) {
        final w = b.maxWidth;
        final cut = w * _pos.clamp(0.0, 1.0);
        return GestureDetector(
          onHorizontalDragUpdate: (d) {
            setState(() => _pos = (d.localPosition.dx / w).clamp(0.0, 1.0));
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned.fill(child: Image.network(widget.afterUrl, fit: BoxFit.cover)),
                Positioned.fill(
                  child: ClipPath(
                    clipper: _LeftClip(cut),
                    child: Image.network(widget.beforeUrl, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  left: cut - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: (isDark ? Colors.white : Colors.black).withOpacity(0.8)),
                ),
                Positioned(
                  left: cut - 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.75),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.drag_handle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LeftClip extends CustomClipper<Path> {
  final double x;
  _LeftClip(this.x);
  @override
  Path getClip(Size size) {
    return Path()..addRect(Rect.fromLTWH(0, 0, x, size.height));
  }
  @override
  bool shouldReclip(covariant _LeftClip oldClip) => oldClip.x != x;
}
