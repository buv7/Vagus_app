import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_classifier.dart';

/// Squat: tracks knee angle (hip→knee→ankle) and back angle (shoulder→hip→knee).
/// Down threshold: knee angle < 110°. Up threshold: knee angle > 160°.
class SquatClassifier extends ExerciseClassifier {
  FormQuality _formQuality = FormQuality.good;
  double _lowestKneeAngle = 180;

  @override
  void process(List<Pose> poses) {
    if (poses.isEmpty) return;
    final pose = poses.first;

    final kneeAngle = avgAngle(
      pose,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.rightAnkle,
    );
    if (kneeAngle == null) return;

    if (phase == RepPhase.down && kneeAngle < _lowestKneeAngle) {
      _lowestKneeAngle = kneeAngle;
      _formQuality = _assessForm(pose, kneeAngle);
    }

    if (phase == RepPhase.up && kneeAngle < 110) {
      phase = RepPhase.down;
      _lowestKneeAngle = kneeAngle;
    } else if (phase == RepPhase.down && kneeAngle > 160) {
      phase = RepPhase.up;
      repCount = repCount + 1;
      _lowestKneeAngle = 180;
    }

    result = ClassificationResult(
      repCount: repCount,
      formQuality: _formQuality,
      feedback: _feedback(_formQuality, kneeAngle),
      isInDownPhase: phase == RepPhase.down,
    );
  }

  FormQuality _assessForm(Pose pose, double kneeAngle) {
    final backAngle = avgAngle(
      pose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
    );

    if (kneeAngle <= 90 && (backAngle == null || backAngle >= 160)) {
      return FormQuality.good;
    }
    if (kneeAngle <= 110 && (backAngle == null || backAngle >= 140)) {
      return FormQuality.fair;
    }
    return FormQuality.poor;
  }

  String _feedback(FormQuality q, double kneeAngle) {
    switch (q) {
      case FormQuality.good:
        return 'Good depth & neutral spine';
      case FormQuality.fair:
        return kneeAngle > 90 ? 'Go deeper' : 'Watch your back angle';
      case FormQuality.poor:
        return 'Shallow squat or rounding — reset';
    }
  }

  @override
  void reset() {
    super.reset();
    _formQuality = FormQuality.good;
    _lowestKneeAngle = 180;
  }
}
