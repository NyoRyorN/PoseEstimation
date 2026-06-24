import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../shared/widgets/capture_control_bar.dart';
import '../../shared/widgets/pose_overlay.dart';
import '../../shared/widgets/status_panel.dart';
import 'capture_controller.dart';

class CapturePage extends StatefulWidget {
  const CapturePage({super.key});

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  late final CaptureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CaptureController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final state = _controller.state;
          final cameraController = _controller.cameraController;

          return Stack(
            fit: StackFit.expand,
            children: [
              if (state.isCameraReady &&
                  cameraController != null &&
                  cameraController.value.isInitialized)
                _CameraPreview(controller: cameraController)
              else
                const ColoredBox(
                  color: Colors.black,
                  child: Center(child: CircularProgressIndicator()),
                ),
              PoseOverlay(frame: state.currentFrame),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: StatusPanel(state: state),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: CaptureControlBar(
                      isRecording: state.isRecording,
                      canSwitchCamera: state.canSwitchCamera,
                      hasShareTarget:
                          state.lastCsvPath != null && state.lastJsonPath != null,
                      onToggleRecording: state.isCameraReady
                          ? () {
                              if (state.isRecording) {
                                _controller.stopRecording();
                              } else {
                                _controller.startRecording();
                              }
                            }
                          : null,
                      onSwitchCamera: _controller.switchCamera,
                      onShare: _controller.shareLastRecording,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CameraPreview extends StatelessWidget {
  final CameraController controller;

  const _CameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(controller);
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}
