import 'package:flutter/widgets.dart';

import '../../features/pose/pose_frame.dart';
import '../../features/pose/pose_overlay_painter.dart';

class PoseOverlay extends StatelessWidget {
  final PoseFrame? frame;

  const PoseOverlay({
    super.key,
    required this.frame,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PoseOverlayPainter(frame: frame),
      size: Size.infinite,
    );
  }
}
