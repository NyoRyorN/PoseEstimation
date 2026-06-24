import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../shared/constants/pose_landmark_names.dart';
import '../../shared/utils/logger.dart';
import '../../shared/utils/timestamp_utils.dart';
import '../camera/camera_service.dart';
import '../camera/input_image_converter.dart';
import '../pose/pose_detector_service.dart';
import '../pose/pose_frame.dart';
import '../pose/pose_joint.dart';
import '../recording/recording_controller.dart';
import 'capture_state.dart';

class CaptureController extends ChangeNotifier with WidgetsBindingObserver {
  final CameraService _cameraService;
  final PoseDetectorService _poseDetector;
  final InputImageConverter _inputImageConverter;
  final RecordingController _recordingController;

  CaptureState _state = const CaptureState();
  bool _isProcessing = false;
  bool _isDisposed = false;
  bool _isObservingLifecycle = false;
  int _cameraFrameIndex = 0;
  int _processedFrames = 0;
  int _detectedPoseFrames = 0;
  DateTime _fpsWindowStartedAt = DateTime.now();
  int _fpsWindowFrames = 0;

  CaptureController({
    CameraService? cameraService,
    PoseDetectorService? poseDetector,
    InputImageConverter inputImageConverter = const InputImageConverter(),
    RecordingController? recordingController,
  })  : _cameraService = cameraService ?? CameraService(),
        _poseDetector = poseDetector ?? PoseDetectorService(),
        _inputImageConverter = inputImageConverter,
        _recordingController = recordingController ?? RecordingController();

  CaptureState get state => _state;
  CameraController? get cameraController => _cameraService.controller;

  Future<void> initialize() async {
    if (!_isObservingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _isObservingLifecycle = true;
    }
    _setState(_state.copyWith(
      isInitializing: true,
      statusMessage: 'Requesting camera permission',
      clearError: true,
    ));

    try {
      final hasPermission = await _cameraService.ensurePermission();
      if (!hasPermission) {
        _setState(_state.copyWith(
          isInitializing: false,
          isCameraReady: false,
          statusMessage: 'Camera permission denied',
          errorMessage: 'カメラ権限が許可されていません。',
        ));
        return;
      }

      final controller = await _cameraService.initialize();
      await _startImageStream(controller);
      _setState(_state.copyWith(
        isInitializing: false,
        isCameraReady: true,
        isFrontCamera: _isFrontCamera,
        canSwitchCamera: _cameraService.hasMultipleCameras,
        statusMessage: 'Camera ready',
        clearError: true,
      ));
    } catch (error, stackTrace) {
      logInfo('Camera initialization failed', error: error, stackTrace: stackTrace);
      _setState(_state.copyWith(
        isInitializing: false,
        isCameraReady: false,
        statusMessage: 'Camera unavailable',
        errorMessage: 'カメラを初期化できませんでした。',
      ));
    }
  }

  Future<void> switchCamera() async {
    if (!_state.canSwitchCamera || _state.isRecording) {
      return;
    }

    _setState(_state.copyWith(statusMessage: 'Switching camera'));
    try {
      final controller = await _cameraService.switchCamera();
      await _startImageStream(controller);
      _setState(_state.copyWith(
        isCameraReady: true,
        isFrontCamera: _isFrontCamera,
        statusMessage: 'Camera ready',
        clearError: true,
      ));
    } catch (error, stackTrace) {
      logInfo('Camera switch failed', error: error, stackTrace: stackTrace);
      _setState(_state.copyWith(
        statusMessage: 'Camera switch failed',
        errorMessage: 'カメラ切替に失敗しました。',
      ));
    }
  }

  Future<void> startRecording() async {
    final controller = _cameraService.controller;
    final camera = _cameraService.activeCamera;
    if (controller == null || camera == null || !controller.value.isInitialized) {
      return;
    }

    final previewSize = controller.value.previewSize;
    final imageWidth = previewSize?.width.toInt() ?? 0;
    final imageHeight = previewSize?.height.toInt() ?? 0;

    try {
      final session = await _recordingController.start(
        camera: camera,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      );
      await WakelockPlus.enable();
      _setState(_state.copyWith(
        isRecording: true,
        recordingStartedAt: session.startedAt,
        statusMessage: 'Recording',
        clearError: true,
      ));
    } catch (error, stackTrace) {
      logInfo('Recording start failed', error: error, stackTrace: stackTrace);
      _setState(_state.copyWith(
        errorMessage: '記録を開始できませんでした。',
      ));
    }
  }

  Future<void> stopRecording() async {
    try {
      final result = await _recordingController.stop(
        totalFrames: _cameraFrameIndex,
        detectedPoseFrames: _detectedPoseFrames,
      );
      await WakelockPlus.disable();
      _setState(_state.copyWith(
        isRecording: false,
        clearRecordingStartedAt: true,
        statusMessage: result == null ? 'Ready' : 'Saved recording',
        lastCsvPath: result?.csvFile.path,
        lastJsonPath: result?.metadataFile.path,
        clearError: true,
      ));
    } catch (error, stackTrace) {
      logInfo('Recording stop failed', error: error, stackTrace: stackTrace);
      _setState(_state.copyWith(
        isRecording: false,
        clearRecordingStartedAt: true,
        errorMessage: '保存に失敗しました。',
      ));
    }
  }

  Future<void> shareLastRecording() async {
    final csvPath = _state.lastCsvPath;
    final jsonPath = _state.lastJsonPath;
    if (csvPath == null || jsonPath == null) {
      return;
    }
    await Share.shareXFiles([
      XFile(csvPath),
      XFile(jsonPath),
    ]);
  }

  Future<void> _startImageStream(CameraController controller) async {
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    await controller.startImageStream((image) {
      unawaited(_handleCameraImage(image));
    });
  }

  Future<void> _handleCameraImage(CameraImage image) async {
    final camera = _cameraService.activeCamera;
    if (camera == null || _isProcessing || _isDisposed) {
      return;
    }

    final frameIndex = _cameraFrameIndex++;
    _setState(_state.copyWith(totalFrames: _cameraFrameIndex));
    _isProcessing = true;

    try {
      final inputImage = _inputImageConverter.convert(
        image: image,
        camera: camera,
      );
      if (inputImage == null) {
        return;
      }

      final poses = await _poseDetector.processImage(inputImage);
      final frame = _toPoseFrame(
        poses: poses,
        camera: camera,
        image: image,
        frameIndex: frameIndex,
      );

      _processedFrames++;
      if (frame.hasPose) {
        _detectedPoseFrames++;
      }
      _updatePoseFps();

      if (_recordingController.isRecording) {
        await _recordingController.recordFrame(frame);
      }

      _setState(_state.copyWith(
        currentFrame: frame,
        processedFrames: _processedFrames,
        detectedPoseFrames: _detectedPoseFrames,
        isFrontCamera: _isFrontCamera,
        statusMessage: frame.hasPose ? 'Pose detected' : 'No person detected',
      ));
    } catch (error, stackTrace) {
      logInfo('Pose processing failed', error: error, stackTrace: stackTrace);
      _setState(_state.copyWith(errorMessage: '姿勢推定でエラーが発生しました。'));
    } finally {
      _isProcessing = false;
    }
  }

  PoseFrame _toPoseFrame({
    required List<Pose> poses,
    required CameraDescription camera,
    required CameraImage image,
    required int frameIndex,
  }) {
    final pose = poses.isEmpty ? null : poses.first;
    final joints = <PoseJoint>[
      if (pose != null)
        for (final entry in pose.landmarks.entries)
          PoseJoint(
            name: poseLandmarkNames[entry.key] ?? entry.key.name,
            x: entry.value.x,
            y: entry.value.y,
            z: entry.value.z,
            confidence: entry.value.likelihood,
          ),
    ];

    return PoseFrame(
      sessionId: _recordingController.session?.sessionId ?? 'preview',
      frameIndex: frameIndex,
      timestampMs: epochMilliseconds(),
      imageWidth: image.width,
      imageHeight: image.height,
      isFrontCamera: _isFrontCamera,
      rotationDegrees: camera.sensorOrientation,
      joints: joints,
    );
  }

  void _updatePoseFps() {
    _fpsWindowFrames++;
    final now = DateTime.now();
    final elapsed = now.difference(_fpsWindowStartedAt);
    if (elapsed.inMilliseconds < 700) {
      return;
    }
    final fps = _fpsWindowFrames * 1000 / elapsed.inMilliseconds;
    _fpsWindowFrames = 0;
    _fpsWindowStartedAt = now;
    _setState(_state.copyWith(poseFps: fps));
  }

  bool get _isFrontCamera {
    return _cameraService.activeCamera?.lensDirection ==
        CameraLensDirection.front;
  }

  void _setState(CaptureState next) {
    if (_isDisposed) {
      return;
    }
    _state = next;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(initialize());
      return;
    }

    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_recordingController.flush());
      unawaited(_cameraService.disposeController());
      _setState(_state.copyWith(
        isCameraReady: false,
        statusMessage: 'Camera paused',
      ));
      return;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_isObservingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _isObservingLifecycle = false;
    }
    unawaited(WakelockPlus.disable());
    unawaited(_recordingController.flush());
    unawaited(_poseDetector.close());
    unawaited(_cameraService.disposeController());
    super.dispose();
  }
}
