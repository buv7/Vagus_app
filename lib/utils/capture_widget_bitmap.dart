import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Utility for capturing widgets as PNG bitmaps
class CaptureWidgetBitmap {
  /// Captures a widget as PNG bitmap using RepaintBoundary
  /// 
  /// [key] - GlobalKey attached to a RepaintBoundary widget
  /// [pixelRatio] - Resolution multiplier (default 2.0 for high DPI)
  /// 
  /// Returns Uint8List of PNG bytes or null if capture fails
  static Future<Uint8List?> capturePng(GlobalKey key, {double pixelRatio = 2.0}) async {
    try {
      final RenderRepaintBoundary? boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        debugPrint('CaptureWidgetBitmap: RepaintBoundary not found');
        return null;
      }

      // Ensure the widget is painted
      if (!boundary.debugNeedsPaint) {
        // Force a repaint if needed
        boundary.markNeedsPaint();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Capture the image
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        debugPrint('CaptureWidgetBitmap: Failed to convert image to bytes');
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('CaptureWidgetBitmap: Error capturing widget - $e');
      return null;
    }
  }

  /// Captures multiple widgets as PNG bitmaps
  /// 
  /// [keys] - List of GlobalKeys attached to RepaintBoundary widgets
  /// [pixelRatio] - Resolution multiplier (default 2.0 for high DPI)
  /// 
  /// Returns Map of key index to PNG bytes (only successful captures)
  static Future<Map<int, Uint8List>> captureMultiple(
    List<GlobalKey> keys, {
    double pixelRatio = 2.0,
  }) async {
    final Map<int, Uint8List> results = {};
    
    for (int i = 0; i < keys.length; i++) {
      final bytes = await capturePng(keys[i], pixelRatio: pixelRatio);
      if (bytes != null) {
        results[i] = bytes;
      }
    }
    
    return results;
  }
}
