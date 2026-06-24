import '../pose/pose_frame.dart';

class CaptureState {
  final bool isInitializing;
  final bool isCameraReady;
  final bool isRecording;
  final bool isFrontCamera;
  final bool canSwitchCamera;
  final String statusMessage;
  final String? errorMessage;
  final int totalFrames;
  final int detectedPoseFrames;
  final int processedFrames;
  final double poseFps;
  final DateTime? recordingStartedAt;
  final PoseFrame? currentFrame;
  final String? lastCsvPath;
  final String? lastJsonPath;

  const CaptureState({
    this.isInitializing = false,
    this.isCameraReady = false,
    this.isRecording = false,
    this.isFrontCamera = false,
    this.canSwitchCamera = false,
    this.statusMessage = 'Initializing',
    this.errorMessage,
    this.totalFrames = 0,
    this.detectedPoseFrames = 0,
    this.processedFrames = 0,
    this.poseFps = 0,
    this.recordingStartedAt,
    this.currentFrame,
    this.lastCsvPath,
    this.lastJsonPath,
  });

  double get detectionRate {
    if (processedFrames == 0) {
      return 0;
    }
    return detectedPoseFrames / processedFrames;
  }

  CaptureState copyWith({
    bool? isInitializing,
    bool? isCameraReady,
    bool? isRecording,
    bool? isFrontCamera,
    bool? canSwitchCamera,
    String? statusMessage,
    String? errorMessage,
    bool clearError = false,
    int? totalFrames,
    int? detectedPoseFrames,
    int? processedFrames,
    double? poseFps,
    DateTime? recordingStartedAt,
    bool clearRecordingStartedAt = false,
    PoseFrame? currentFrame,
    String? lastCsvPath,
    String? lastJsonPath,
  }) {
    return CaptureState(
      isInitializing: isInitializing ?? this.isInitializing,
      isCameraReady: isCameraReady ?? this.isCameraReady,
      isRecording: isRecording ?? this.isRecording,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      canSwitchCamera: canSwitchCamera ?? this.canSwitchCamera,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      totalFrames: totalFrames ?? this.totalFrames,
      detectedPoseFrames: detectedPoseFrames ?? this.detectedPoseFrames,
      processedFrames: processedFrames ?? this.processedFrames,
      poseFps: poseFps ?? this.poseFps,
      recordingStartedAt: clearRecordingStartedAt
          ? null
          : recordingStartedAt ?? this.recordingStartedAt,
      currentFrame: currentFrame ?? this.currentFrame,
      lastCsvPath: lastCsvPath ?? this.lastCsvPath,
      lastJsonPath: lastJsonPath ?? this.lastJsonPath,
    );
  }
}
