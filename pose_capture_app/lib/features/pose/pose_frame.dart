import 'pose_joint.dart';

class PoseFrame {
  final String sessionId;
  final int frameIndex;
  final int timestampMs;
  final int imageWidth;
  final int imageHeight;
  final bool isFrontCamera;
  final int rotationDegrees;
  final List<PoseJoint> joints;

  const PoseFrame({
    required this.sessionId,
    required this.frameIndex,
    required this.timestampMs,
    required this.imageWidth,
    required this.imageHeight,
    required this.isFrontCamera,
    required this.rotationDegrees,
    required this.joints,
  });

  bool get hasPose => joints.isNotEmpty;
}
