import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import 'camera_config.dart';

class CameraService {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  CameraDescription? _activeCamera;

  CameraController? get controller => _controller;
  CameraDescription? get activeCamera => _activeCamera;
  bool get hasMultipleCameras => _cameras.length > 1;

  Future<bool> ensurePermission() async {
    final status = await Permission.camera.request();
    return status.isGranted || status.isLimited;
  }

  Future<CameraController> initialize({
    CameraLensDirection preferredDirection = CameraLensDirection.back,
  }) async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw CameraException('no_camera', 'No cameras are available.');
    }

    final camera = _findCamera(preferredDirection) ?? _cameras.first;
    return _initializeCamera(camera);
  }

  Future<CameraController> switchCamera() async {
    final current = _activeCamera;
    if (current == null || _cameras.length < 2) {
      throw CameraException('no_alternate_camera', 'No alternate camera.');
    }

    final nextDirection = current.lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    final next = _findCamera(nextDirection) ??
        _cameras.firstWhere((camera) => camera.name != current.name);
    return _initializeCamera(next);
  }

  Future<void> disposeController() async {
    final controller = _controller;
    _controller = null;
    _activeCamera = null;
    if (controller == null) {
      return;
    }
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    await controller.dispose();
  }

  CameraDescription? _findCamera(CameraLensDirection direction) {
    for (final camera in _cameras) {
      if (camera.lensDirection == direction) {
        return camera;
      }
    }
    return null;
  }

  Future<CameraController> _initializeCamera(CameraDescription camera) async {
    await disposeController();
    final controller = CameraController(
      camera,
      defaultResolutionPreset,
      enableAudio: false,
      imageFormatGroup: defaultImageFormatGroup,
    );
    await controller.initialize();
    _controller = controller;
    _activeCamera = camera;
    return controller;
  }
}
