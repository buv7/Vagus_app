import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_classifier.dart';

/// Deadlift: tracks hip hinge angle (shoulder→hip→knee).
/// Down = hip angle < 90° (loaded), Up = hip angle > 160° (lockout).
/// Bar-path proxy: wrist x deviation from ankle x (bar should track shin).
class DeadliftClassifier extends ExerciseClassifier {
  FormQuality _formQuality = FormQuality.good;
  double _lowestHipAngle = 180;

  @override
  void process(List<Pose> poses) {
    if (poses.isEmpty) return;
    final pose = poses.first;

    final hipAngle = avgAngle(
      pose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
    );
    if (hipAngle == null) return;

    if (phase == RepPhase.down && hipAngle < _lowestHipAngle) {
      _lowestHipAngle = hipAngle;
      _formQuality = _assessForm(pose, hipAngle);
    }

    if (phase == RepPhase.up && hipAngle < 90) {
      phase = RepPhase.down;
      _lowestHipAngle = hipAngle;
    } else if (phase == RepPhase.down && hipAngle > 160) {
      phase = RepPhase.up;
      repCount = repCount + 1;
      _lowestHipAngle = 180;
    }

    result = ClassificationResult(
      repCount: repCount,
      formQuality: _formQuality,
      feedback: _feedback(_formQuality, hipAngle),
      isInDownPhase: phase == RepPhase.down,
    );
  }

  FormQuality _assessForm(Pose pose, double hipAngle) {
    final lWrist = lm(pose, PoseLandmarkType.leftWrist);
    final lAnkle = lm(pose, PoseLandmarkType.leftAnkle);
    final rWrist = lm(pose, PoseLandmarkType.rightWrist);
    final rAnkle = lm(pose, PoseLandmarkType.rightAnkle);

    double? barDeviation;
    if (lWrist != null && lAnkle != null && rWrist != null && rAnkle != null) {
      final leftDev = (lWrist.x - lAnkle.x).abs();
      final rightDev = (rWrist.x - rAnkle.x).abs();
      barDeviation = (leftDev + rightDev) / 2;
    }

    // Excessive rounding proxy: shoulder y drops much lower than hip y
    final lShoulder = lm(pose, PoseLandmarkType.leftShoulder);
    final lHip = lm(pose, PoseLandmarkType.leftHip);
    bool spineOk = true;
    if (lShoulder != null && lHip != null) {
      if ((lShoulder.y - lHip.y) > lHip.y * 0.40) spineOk = false;
    }

    final barClose = barDeviation == null || barDeviation < 60;
    final barFair = barDeviation == null || barDeviation < 120;

    if (spineOk && barClose) return FormQuality.good;
    if (barFair) return FormQuality.fair;
    return FormQuality.poor;
  }

  String _feedback(FormQuality q, double hipAngle) {
    switch (q) {
      case FormQuality.good:
        return 'Good hip hinge, bar tracking close';
      case FormQuality.fair:
        return 'Keep the bar closer to your body';
      case FormQuality.poor:
        return 'Excessive rounding or bar flaring — reset';
    }
  }

  @override
  void reset() {
    super.reset();
    _formQuality = FormQuality.good;
    _lowestHipAngle = 180;
  }
}
