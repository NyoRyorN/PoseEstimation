import 'package:flutter/material.dart';

class CaptureControlBar extends StatelessWidget {
  final bool isRecording;
  final bool canSwitchCamera;
  final bool hasShareTarget;
  final VoidCallback? onToggleRecording;
  final VoidCallback? onSwitchCamera;
  final VoidCallback? onShare;

  const CaptureControlBar({
    super.key,
    required this.isRecording,
    required this.canSwitchCamera,
    required this.hasShareTarget,
    this.onToggleRecording,
    this.onSwitchCamera,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filled(
              tooltip: isRecording ? 'Stop recording' : 'Start recording',
              onPressed: onToggleRecording,
              icon: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record),
              color: isRecording ? Colors.white : const Color(0xffffddd2),
              style: IconButton.styleFrom(
                backgroundColor:
                    isRecording ? const Color(0xffb3261e) : const Color(0xff006a60),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Switch camera',
              onPressed: canSwitchCamera && !isRecording ? onSwitchCamera : null,
              icon: const Icon(Icons.cameraswitch),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Share last recording',
              onPressed: hasShareTarget ? onShare : null,
              icon: const Icon(Icons.ios_share),
            ),
          ],
        ),
      ),
    );
  }
}
