import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_classifier.dart';

/// Push-up: tracks elbow angle (shoulder→elbow→wrist) and body alignment
/// (shoulder→hip→ankle). Down = elbow < 90°. Up = elbow > 160°.
class PushupClassifier extends ExerciseClassifier {
  FormQuality _formQuality = FormQuality.good;
  double _lowestElbowAngle = 180;

  @override
  void process(List<Pose> poses) {
    if (poses.isEmpty) return;
    final pose = poses.first;

    final elbowAngle = avgAngle(
      pose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
    );
    if (elbowAngle == null) return;

    if (phase == RepPhase.down && elbowAngle < _lowestElbowAngle) {
      _lowestElbowAngle = elbowAngle;
      _formQuality = _assessForm(pose, elbowAngle);
    }

    if (phase == RepPhase.up && elbowAngle < 90) {
      phase = RepPhase.down;
      _lowestElbowAngle = elbowAngle;
    } else if (phase == RepPhase.down && elbowAngle > 160) {
      phase = RepPhase.up;
      repCount = repCount + 1;
      _lowestElbowAngle = 180;
    }

    result = ClassificationResult(
      repCount: repCount,
      formQuality: _formQuality,
      feedback: _feedback(_formQuality, elbowAngle),
      isInDownPhase: phase == RepPhase.down,
    );
  }

  FormQuality _assessForm(Pose pose, double elbowAngle) {
    final alignment = avgAngle(
      pose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightAnkle,
    );

    final bodyOk = alignment == null || alignment >= 160;
    final bodyFair = alignment != null && alignment >= 145;

    if (elbowAngle <= 90 && bodyOk) return FormQuality.good;
    if (elbowAngle <= 110 && (bodyOk || bodyFair)) return FormQuality.fair;
    return FormQuality.poor;
  }

  String _feedback(FormQuality q, double elbowAngle) {
    switch (q) {
      case FormQuality.good:
        return 'Full range, body straight';
      case FormQuality.fair:
        return elbowAngle > 90
            ? 'Lower your chest to the floor'
            : 'Engage your core — hips sagging';
      case FormQuality.poor:
        return 'Half rep or body misaligned — reset';
    }
  }

  @override
  void reset() {
    super.reset();
    _formQuality = FormQuality.good;
    _lowestElbowAngle = 180;
  }
}
