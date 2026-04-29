import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseFrame {
  final List<Pose> poses;
  final Size imageSize;
  final InputImageRotation rotation;
  final bool isFrontCamera;

  const PoseFrame({
    required this.poses,
    required this.imageSize,
    required this.rotation,
    required this.isFrontCamera,
  });
}

class PoseEngine {
  PoseEngine._();
  static final PoseEngine instance = PoseEngine._();

  late final PoseDetector _detector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.accurate,
      mode: PoseDetectionMode.stream,
    ),
  );

  CameraController? _controller;
  final StreamController<PoseFrame> _stream =
      StreamController<PoseFrame>.broadcast();

  bool _busy = false;
  CameraDescription? _camera;

  Stream<PoseFrame> get poseStream => _stream.stream;
  CameraController? get controller => _controller;
  bool get isRunning => _controller != null && _controller!.value.isInitialized;

  Future<void> start(CameraDescription camera) async {
    _camera = camera;
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    await _controller!.initialize();
    await _controller!.startImageStream(_onImage);
  }

  Future<void> stop() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
    _busy = false;
  }

  Future<void> dispose() async {
    await stop();
    await _detector.close();
    await _stream.close();
  }

  // Start video recording — returns null if camera not ready.
  Future<void> startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isRecordingVideo) return;
    await _controller!.startVideoRecording();
  }

  Future<XFile?> stopRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return null;
    return _controller!.stopVideoRecording();
  }

  void _onImage(CameraImage image) async {
    if (_busy || _camera == null) return;
    _busy = true;
    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) return;
      final poses = await _detector.processImage(inputImage);
      if (!_stream.isClosed) {
        _stream.add(PoseFrame(
          poses: poses,
          imageSize: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: inputImage.metadata!.rotation,
          isFrontCamera:
              _camera!.lensDirection == CameraLensDirection.front,
        ));
      }
    } catch (e) {
      debugPrint('PoseEngine._onImage error: $e');
    } finally {
      _busy = false;
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final camera = _camera!;
    final rotation = _rotationFor(camera);
    if (rotation == null) return null;

    if (Platform.isAndroid) {
      // ImageFormatGroup.nv21 → single concatenated plane on newer camera pkg,
      // or 3-plane YUV_420_888 on older. Handle both.
      Uint8List bytes;
      if (image.planes.length == 1) {
        bytes = image.planes.first.bytes;
      } else {
        bytes = _yuv420ToNv21(image);
      }
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width,
        ),
      );
    } else {
      // iOS: BGRA8888, single plane
      if (image.planes.isEmpty) return null;
      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    }
  }

  static const _orientationAngles = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImageRotation? _rotationFor(CameraDescription camera) {
    final deviceAngle = _orientationAngles[
            _controller?.value.deviceOrientation ??
                DeviceOrientation.portraitUp] ??
        0;
    final sensor = camera.sensorOrientation;
    int compensation;
    if (camera.lensDirection == CameraLensDirection.front) {
      compensation = (sensor + deviceAngle) % 360;
    } else {
      compensation = (sensor - deviceAngle + 360) % 360;
    }
    return InputImageRotationValue.fromRawValue(compensation);
  }

  /// Convert YUV_420_888 (3 planes) to NV21 (Y + VU interleaved).
  static Uint8List _yuv420ToNv21(CameraImage img) {
    final w = img.width;
    final h = img.height;
    final yPlane = img.planes[0];
    final uPlane = img.planes[1];
    final vPlane = img.planes[2];
    final nv21 = Uint8List(w * h + w * h ~/ 2);
    var idx = 0;

    for (var row = 0; row < h; row++) {
      final rowOffset = row * yPlane.bytesPerRow;
      for (var col = 0; col < w; col++) {
        nv21[idx++] = yPlane.bytes[rowOffset + col];
      }
    }

    final uvPixelStride = uPlane.bytesPerPixel ?? 1;
    for (var row = 0; row < h ~/ 2; row++) {
      final rowOffset = row * uPlane.bytesPerRow;
      for (var col = 0; col < w ~/ 2; col++) {
        final uvIdx = rowOffset + col * uvPixelStride;
        nv21[idx++] = vPlane.bytes[uvIdx];
        nv21[idx++] = uPlane.bytes[uvIdx];
      }
    }
    return nv21;
  }
}
