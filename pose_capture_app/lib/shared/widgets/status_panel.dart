import 'package:flutter/material.dart';

import '../../features/capture/capture_state.dart';

class StatusPanel extends StatelessWidget {
  final CaptureState state;

  const StatusPanel({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final elapsed = state.recordingStartedAt == null
        ? Duration.zero
        : DateTime.now().difference(state.recordingStartedAt!);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DefaultTextStyle(
          style: theme.textTheme.bodySmall!.copyWith(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.statusMessage),
              Text('Pose FPS ${state.poseFps.toStringAsFixed(1)}'),
              Text('Frames ${state.processedFrames}/${state.totalFrames}'),
              Text('Detected ${(state.detectionRate * 100).toStringAsFixed(0)}%'),
              if (state.isRecording) Text('Recording ${_formatElapsed(elapsed)}'),
              if (state.errorMessage != null)
                Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Color(0xffffb4ab)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatElapsed(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
