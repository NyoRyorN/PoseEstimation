import 'package:csv/csv.dart';

import '../pose/pose_frame.dart';

class PoseCsvWriter {
  static const header = <String>[
    'session_id',
    'timestamp_ms',
    'frame_index',
    'joint',
    'x',
    'y',
    'z',
    'confidence',
    'image_width',
    'image_height',
    'camera_lens',
    'rotation_deg',
  ];

  const PoseCsvWriter();

  List<List<Object?>> rowsForFrame(PoseFrame frame) {
    final cameraLens = frame.isFrontCamera ? 'front' : 'back';
    return [
      for (final joint in frame.joints)
        [
          frame.sessionId,
          frame.timestampMs,
          frame.frameIndex,
          joint.name,
          joint.x,
          joint.y,
          joint.z,
          joint.confidence,
          frame.imageWidth,
          frame.imageHeight,
          cameraLens,
          frame.rotationDegrees,
        ],
    ];
  }

  String convertRows(List<List<Object?>> rows) {
    return const ListToCsvConverter().convert(rows);
  }
}
