import 'package:flutter_test/flutter_test.dart';
import 'package:pose_capture_app/features/pose/pose_frame.dart';
import 'package:pose_capture_app/features/pose/pose_joint.dart';
import 'package:pose_capture_app/features/recording/csv_writer.dart';

void main() {
  test('rowsForFrame expands joints vertically', () {
    const writer = PoseCsvWriter();
    const frame = PoseFrame(
      sessionId: '20260624_103015',
      frameIndex: 7,
      timestampMs: 1710000000000,
      imageWidth: 1280,
      imageHeight: 720,
      isFrontCamera: false,
      rotationDegrees: 90,
      joints: [
        PoseJoint(
          name: 'leftShoulder',
          x: 252.4,
          y: 184.7,
          z: -32.1,
          confidence: 0.95,
        ),
      ],
    );

    final rows = writer.rowsForFrame(frame);

    expect(rows, hasLength(1));
    expect(rows.single, [
      '20260624_103015',
      1710000000000,
      7,
      'leftShoulder',
      252.4,
      184.7,
      -32.1,
      0.95,
      1280,
      720,
      'back',
      90,
    ]);
  });
}
