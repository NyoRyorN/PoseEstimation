import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pose_capture_app/features/pose/pose_frame.dart';
import 'package:pose_capture_app/features/pose/pose_joint.dart';
import 'package:pose_capture_app/features/recording/recording_controller.dart';
import 'package:pose_capture_app/features/recording/recording_paths.dart';

void main() {
  test('writes csv and metadata files', () async {
    final tempDir = await Directory.systemTemp.createTemp('pose_recording_test');
    addTearDown(() => tempDir.delete(recursive: true));

    final controller = RecordingController(
      createPaths: () async => RecordingPaths(tempDir),
      flushEveryRows: 1,
    );
    const camera = CameraDescription(
      name: '0',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    );

    final startedAt = DateTime(2026, 6, 24, 10, 30, 15);
    final session = await controller.start(
      camera: camera,
      imageWidth: 1280,
      imageHeight: 720,
      now: startedAt,
    );

    await controller.recordFrame(PoseFrame(
      sessionId: session.sessionId,
      frameIndex: 0,
      timestampMs: 1710000000000,
      imageWidth: 1280,
      imageHeight: 720,
      isFrontCamera: false,
      rotationDegrees: 90,
      joints: const [
        PoseJoint(
          name: 'leftShoulder',
          x: 252.4,
          y: 184.7,
          z: -32.1,
          confidence: 0.95,
        ),
      ],
    ));

    final result = await controller.stop(
      totalFrames: 1,
      detectedPoseFrames: 1,
      now: startedAt.add(const Duration(seconds: 2)),
    );

    expect(result, isNotNull);
    final csv = await result!.csvFile.readAsString();
    expect(csv, contains('session_id,timestamp_ms,frame_index,joint'));
    expect(csv, contains('leftShoulder'));

    final metadata = jsonDecode(await result.metadataFile.readAsString())
        as Map<String, Object?>;
    expect(metadata['session_id'], '20260624_103015');
    expect(metadata['saved_rows'], 1);
  });
}
