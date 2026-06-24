import 'package:flutter/material.dart';

import 'pose_connections.dart';
import 'pose_coordinate_converter.dart';
import 'pose_frame.dart';
import 'pose_joint.dart';

class PoseOverlayPainter extends CustomPainter {
  final PoseFrame? frame;
  final PoseCoordinateConverter converter;
  final double minConfidence;

  const PoseOverlayPainter({
    required this.frame,
    this.converter = const PoseCoordinateConverter(),
    this.minConfidence = 0.35,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final currentFrame = frame;
    if (currentFrame == null || currentFrame.joints.isEmpty) {
      return;
    }

    final imageSize = Size(
      currentFrame.imageWidth.toDouble(),
      currentFrame.imageHeight.toDouble(),
    );
    final jointsByName = {
      for (final joint in currentFrame.joints)
        if (joint.confidence >= minConfidence) joint.name: joint,
    };

    final linePaint = Paint()
      ..color = const Color(0xff5eead4)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final pointPaint = Paint()..color = const Color(0xfffff7ed);
    final lowPointPaint = Paint()..color = const Color(0xffffb86b);

    for (final connection in poseConnections) {
      final from = jointsByName[connection.$1];
      final to = jointsByName[connection.$2];
      if (from == null || to == null) {
        continue;
      }
      canvas.drawLine(
        _toPreview(from, imageSize, size, currentFrame),
        _toPreview(to, imageSize, size, currentFrame),
        linePaint,
      );
    }

    for (final joint in currentFrame.joints) {
      final point = _toPreview(joint, imageSize, size, currentFrame);
      canvas.drawCircle(
        point,
        joint.confidence >= minConfidence ? 4.5 : 3,
        joint.confidence >= minConfidence ? pointPaint : lowPointPaint,
      );
    }
  }

  Offset _toPreview(
    PoseJoint joint,
    Size imageSize,
    Size previewSize,
    PoseFrame frame,
  ) {
    return converter.imageToPreview(
      imagePoint: Offset(joint.x, joint.y),
      imageSize: imageSize,
      previewSize: previewSize,
      rotationDegrees: frame.rotationDegrees,
      mirrorHorizontally: frame.isFrontCamera,
    );
  }

  @override
  bool shouldRepaint(covariant PoseOverlayPainter oldDelegate) {
    return oldDelegate.frame != frame ||
        oldDelegate.minConfidence != minConfidence;
  }
}
