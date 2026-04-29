import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum ExerciseType { squat, pushUp, deadlift }

enum FormQuality { good, fair, poor }

// Public so subclasses in other files can reference it
enum RepPhase { up, down }

class ClassificationResult {
  final int repCount;
  final FormQuality formQuality;
  final String feedback;
  final bool isInDownPhase;

  const ClassificationResult({
    required this.repCount,
    required this.formQuality,
    required this.feedback,
    required this.isInDownPhase,
  });

  static const empty = ClassificationResult(
    repCount: 0,
    formQuality: FormQuality.good,
    feedback: '',
    isInDownPhase: false,
  );
}

abstract class ExerciseClassifier {
  int _repCount = 0;
  RepPhase _phase = RepPhase.up;
  ClassificationResult _result = ClassificationResult.empty;

  int get repCount => _repCount;
  ClassificationResult get result => _result;

  void process(List<Pose> poses);

  void reset() {
    _repCount = 0;
    _phase = RepPhase.up;
    _result = ClassificationResult.empty;
  }

  /// Angle at vertex b formed by points a-b-c (in degrees).
  double angle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final bax = a.x - b.x;
    final bay = a.y - b.y;
    final bcx = c.x - b.x;
    final bcy = c.y - b.y;
    final dot = bax * bcx + bay * bcy;
    final mag = math.sqrt(bax * bax + bay * bay) *
        math.sqrt(bcx * bcx + bcy * bcy);
    if (mag == 0) return 0;
    return math.acos((dot / mag).clamp(-1.0, 1.0)) * 180 / math.pi;
  }

  PoseLandmark? lm(Pose pose, PoseLandmarkType type) =>
      pose.landmarks[type];

  /// Average angle from left and right sides for robustness.
  double? avgAngle(
    Pose pose,
    PoseLandmarkType aLeft,
    PoseLandmarkType bLeft,
    PoseLandmarkType cLeft,
    PoseLandmarkType aRight,
    PoseLandmarkType bRight,
    PoseLandmarkType cRight,
  ) {
    final ll = lm(pose, aLeft);
    final lb = lm(pose, bLeft);
    final lc = lm(pose, cLeft);
    final rl = lm(pose, aRight);
    final rb = lm(pose, bRight);
    final rc = lm(pose, cRight);

    double? left, right;
    if (ll != null && lb != null && lc != null) left = angle(ll, lb, lc);
    if (rl != null && rb != null && rc != null) right = angle(rl, rb, rc);

    if (left != null && right != null) return (left + right) / 2;
    return left ?? right;
  }

  // Protected-style accessors for subclasses
  RepPhase get phase => _phase;
  set phase(RepPhase v) => _phase = v;
  set result(ClassificationResult v) => _result = v;
  set repCount(int v) => _repCount = v;
}
