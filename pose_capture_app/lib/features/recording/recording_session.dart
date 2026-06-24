import '../../shared/utils/timestamp_utils.dart';

class RecordingSession {
  final String sessionId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String cameraLensDirection;
  final int imageWidth;
  final int imageHeight;
  final int totalFrames;
  final int detectedPoseFrames;
  final int savedRows;

  const RecordingSession({
    required this.sessionId,
    required this.startedAt,
    required this.endedAt,
    required this.cameraLensDirection,
    required this.imageWidth,
    required this.imageHeight,
    required this.totalFrames,
    required this.detectedPoseFrames,
    required this.savedRows,
  });

  RecordingSession copyWith({
    DateTime? endedAt,
    int? totalFrames,
    int? detectedPoseFrames,
    int? savedRows,
  }) {
    return RecordingSession(
      sessionId: sessionId,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      cameraLensDirection: cameraLensDirection,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      totalFrames: totalFrames ?? this.totalFrames,
      detectedPoseFrames: detectedPoseFrames ?? this.detectedPoseFrames,
      savedRows: savedRows ?? this.savedRows,
    );
  }

  Map<String, Object?> toJson({
    String poseModel = 'base',
    double confidenceThreshold = 0.5,
    String appVersion = '0.1.0',
  }) {
    return {
      'session_id': sessionId,
      'started_at': isoTimestamp(startedAt),
      'ended_at': endedAt == null ? null : isoTimestamp(endedAt!),
      'camera_lens': cameraLensDirection,
      'image_width': imageWidth,
      'image_height': imageHeight,
      'pose_model': poseModel,
      'confidence_threshold': confidenceThreshold,
      'app_version': appVersion,
      'total_frames': totalFrames,
      'detected_pose_frames': detectedPoseFrames,
      'saved_rows': savedRows,
    };
  }
}
