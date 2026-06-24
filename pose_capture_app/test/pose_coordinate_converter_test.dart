import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pose_capture_app/features/pose/pose_coordinate_converter.dart';

void main() {
  const converter = PoseCoordinateConverter();

  test('maps image center to preview center', () {
    final point = converter.imageToPreview(
      imagePoint: const Offset(50, 25),
      imageSize: const Size(100, 50),
      previewSize: const Size(200, 100),
      rotationDegrees: 0,
      mirrorHorizontally: false,
    );

    expect(point.dx, closeTo(100, 0.001));
    expect(point.dy, closeTo(50, 0.001));
  });

  test('mirrors front camera only for display coordinates', () {
    final point = converter.imageToPreview(
      imagePoint: const Offset(20, 25),
      imageSize: const Size(100, 50),
      previewSize: const Size(200, 100),
      rotationDegrees: 0,
      mirrorHorizontally: true,
    );

    expect(point.dx, closeTo(160, 0.001));
    expect(point.dy, closeTo(50, 0.001));
  });
}
