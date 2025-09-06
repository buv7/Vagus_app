import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class PdfCaptureHelper {
  /// Capture a widget to PNG bytes for PDF embedding
  static Future<Uint8List?> captureToPng(GlobalKey key, {double pixelRatio = 3.0}) async {
    try {
      final RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Failed to capture widget to PNG: $e');
      return null;
    }
  }

  /// Wrap a widget for capture with RepaintBoundary
  static Widget wrapForCapture({required GlobalKey key, required Widget child}) {
    return RepaintBoundary(
      key: key,
      child: child,
    );
  }
}
