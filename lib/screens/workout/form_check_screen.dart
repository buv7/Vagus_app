import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/pose/pose_engine.dart';
import '../../services/pose/classifiers/exercise_classifier.dart';
import '../../services/pose/classifiers/squat_classifier.dart';
import '../../services/pose/classifiers/pushup_classifier.dart';
import '../../services/pose/classifiers/deadlift_classifier.dart';
import '../../services/subscription/tier_service.dart';

class FormCheckScreen extends StatefulWidget {
  const FormCheckScreen({super.key});

  @override
  State<FormCheckScreen> createState() => _FormCheckScreenState();
}

class _FormCheckScreenState extends State<FormCheckScreen>
    with WidgetsBindingObserver {
  // Tier / permissions
  bool _tierChecked = false;
  bool _hasAccess = false;
  bool _cameraGranted = false;

  // Camera / pose stream
  bool _engineStarted = false;
  StreamSubscription<PoseFrame>? _poseSub;
  List<Pose> _lastPoses = [];
  Size _imageSize = const Size(480, 640);

  // Exercise state
  ExerciseType _exercise = ExerciseType.squat;
  ExerciseClassifier _classifier = SquatClassifier();
  ClassificationResult _classResult = ClassificationResult.empty;

  // Clip saving — explicit opt-in, default OFF
  bool _saveClip = false;
  bool _isRecording = false;
  int _recordSecondsLeft = 0;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    final check = await TierService.instance.checkPoseDetection();
    if (!mounted) return;
    setState(() {
      _tierChecked = true;
      _hasAccess = check.allowed;
    });
    if (!check.allowed) return;

    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() => _cameraGranted = status.isGranted);
    if (!status.isGranted) return;

    await _startEngine();
  }

  Future<void> _startEngine() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    await PoseEngine.instance.start(camera);
    if (!mounted) return;

    _poseSub = PoseEngine.instance.poseStream.listen((frame) {
      _classifier.process(frame.poses);
      if (mounted) {
        setState(() {
          _lastPoses = frame.poses;
          _imageSize = frame.imageSize;
          _classResult = _classifier.result;
        });
      }
    });

    setState(() => _engineStarted = true);
  }

  void _selectExercise(ExerciseType type) {
    setState(() {
      _exercise = type;
      _classifier = switch (type) {
        ExerciseType.squat => SquatClassifier(),
        ExerciseType.pushUp => PushupClassifier(),
        ExerciseType.deadlift => DeadliftClassifier(),
      };
      _classResult = ClassificationResult.empty;
      _lastPoses = [];
    });
  }

  Future<void> _startClipRecording() async {
    if (_isRecording) return;
    await PoseEngine.instance.startRecording();
    setState(() {
      _isRecording = true;
      _recordSecondsLeft = 10;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }
      final left = _recordSecondsLeft - 1;
      setState(() => _recordSecondsLeft = left);
      if (left <= 0) {
        t.cancel();
        await _stopAndUploadClip();
      }
    });
  }

  Future<void> _stopAndUploadClip() async {
    final file = await PoseEngine.instance.stopRecording();
    if (!mounted) return;
    setState(() => _isRecording = false);
    if (file == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final ts = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'clips/${user.id}/${_exercise.name}_$ts.mp4';

    try {
      final bytes = await file.readAsBytes();
      await Supabase.instance.client.storage
          .from('pose-clips')
          .uploadBinary(storagePath, bytes);

      await Supabase.instance.client.from('pose_clips').insert({
        'user_id': user.id,
        'exercise': _exercise.name,
        'rep_count': _classResult.repCount,
        'form_quality': _classResult.formQuality.name,
        'storage_path': storagePath,
        'expires_at': DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Clip saved — visible to your coach, auto-deletes in 30 days')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_engineStarted) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _poseSub?.cancel();
      PoseEngine.instance.stop();
      if (mounted) setState(() => _engineStarted = false);
    } else if (state == AppLifecycleState.resumed && _cameraGranted) {
      _startEngine();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poseSub?.cancel();
    _recordTimer?.cancel();
    PoseEngine.instance.stop();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _body(),
    );
  }

  Widget _body() {
    if (!_tierChecked) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_hasAccess) return _upgradeWall();
    if (!_cameraGranted) return _permissionWall();
    if (!_engineStarted ||
        PoseEngine.instance.controller == null ||
        !PoseEngine.instance.controller!.value.isInitialized) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    return _cameraView();
  }

  Widget _cameraView() {
    final ctrl = PoseEngine.instance.controller!;
    final isFront =
        ctrl.description.lensDirection == CameraLensDirection.front;

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(ctrl),

        CustomPaint(
          painter: _PosePainter(
            poses: _lastPoses,
            imageSize: _imageSize,
            formQuality: _classResult.formQuality,
            isFrontCamera: isFront,
          ),
        ),

        // Top bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                _exercisePicker(),
              ],
            ),
          ),
        ),

        // Rep counter + form badge (right side)
        Positioned(
          right: 12,
          top: 0,
          bottom: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _repBadge(),
                const SizedBox(height: 12),
                _formBadge(),
              ],
            ),
          ),
        ),

        // Bottom bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_classResult.feedback.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _classResult.feedback,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _saveClipToggle(),
                      _recordButton(),
                      TextButton(
                        onPressed: () {
                          _classifier.reset();
                          setState(() {
                            _classResult = ClassificationResult.empty;
                            _lastPoses = [];
                          });
                        },
                        child: const Text('Reset',
                            style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _saveClipToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.videocam_outlined, color: Colors.white70, size: 18),
        const SizedBox(width: 4),
        const Text('Save clip',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        Switch(
          value: _saveClip,
          onChanged: (v) => setState(() => _saveClip = v),
          activeColor: Colors.greenAccent,
        ),
      ],
    );
  }

  Widget _recordButton() {
    if (!_saveClip) return const SizedBox.shrink();
    if (_isRecording) {
      return Text(
        '${_recordSecondsLeft}s',
        style: const TextStyle(
            color: Colors.redAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold),
      );
    }
    return TextButton.icon(
      onPressed: _startClipRecording,
      icon: const Icon(Icons.fiber_manual_record, color: Colors.redAccent),
      label: const Text('Record 10s',
          style: TextStyle(color: Colors.white)),
    );
  }

  Widget _exercisePicker() {
    return SegmentedButton<ExerciseType>(
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        selectedForegroundColor: Colors.black,
        selectedBackgroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 11),
      ),
      segments: const [
        ButtonSegment(value: ExerciseType.squat, label: Text('Squat')),
        ButtonSegment(value: ExerciseType.pushUp, label: Text('Push-up')),
        ButtonSegment(value: ExerciseType.deadlift, label: Text('Deadlift')),
      ],
      selected: {_exercise},
      onSelectionChanged: (s) => _selectExercise(s.first),
    );
  }

  Widget _repBadge() {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${_classResult.repCount}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold),
          ),
          const Text('reps',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _formBadge() {
    final (color, label) = switch (_classResult.formQuality) {
      FormQuality.good => (Colors.greenAccent, 'GOOD'),
      FormQuality.fair => (Colors.orangeAccent, 'FAIR'),
      FormQuality.poor => (Colors.redAccent, 'POOR'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _upgradeWall() {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Check')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Form Check is a Pro+ feature',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'On-device pose detection with rep counting and form feedback — no frames leave your device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('See upgrade options'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _permissionWall() {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Check')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Camera permission needed',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Pose detection runs entirely on-device — no video is sent to any server.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: openAppSettings,
                child: const Text('Open settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Landmark painter ─────────────────────────────────────────────────────

class _PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final FormQuality formQuality;
  final bool isFrontCamera;

  _PosePainter({
    required this.poses,
    required this.imageSize,
    required this.formQuality,
    required this.isFrontCamera,
  });

  static const _connections = [
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
    (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
    (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
    (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
    (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
    (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
    (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
    (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (poses.isEmpty || imageSize.isEmpty) return;

    final color = switch (formQuality) {
      FormQuality.good => Colors.greenAccent,
      FormQuality.fair => Colors.orangeAccent,
      FormQuality.poor => Colors.redAccent,
    };

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color.withOpacity(0.75);

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    for (final pose in poses) {
      for (final (a, b) in _connections) {
        final pa = _map(pose.landmarks[a], size);
        final pb = _map(pose.landmarks[b], size);
        if (pa != null && pb != null) canvas.drawLine(pa, pb, linePaint);
      }
      for (final lm in pose.landmarks.values) {
        final p = _map(lm, size);
        if (p != null) canvas.drawCircle(p, 5, dotPaint);
      }
    }
  }

  Offset? _map(PoseLandmark? lm, Size screen) {
    if (lm == null || lm.likelihood < 0.45) return null;
    final sx = screen.width / imageSize.width;
    final sy = screen.height / imageSize.height;
    double x = lm.x * sx;
    if (isFrontCamera) x = screen.width - x;
    return Offset(x, lm.y * sy);
  }

  @override
  bool shouldRepaint(_PosePainter old) =>
      old.poses != poses || old.formQuality != formQuality;
}
