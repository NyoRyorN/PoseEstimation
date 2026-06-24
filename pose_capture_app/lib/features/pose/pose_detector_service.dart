import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseDetectorService {
  final PoseDetector _detector;

  PoseDetectorService({
    PoseDetector? detector,
  }) : _detector = detector ??
            PoseDetector(
              options: PoseDetectorOptions(
                model: PoseDetectionModel.base,
                mode: PoseDetectionMode.stream,
              ),
            );

  Future<List<Pose>> processImage(InputImage inputImage) {
    return _detector.processImage(inputImage);
  }

  Future<void> close() => _detector.close();
}
