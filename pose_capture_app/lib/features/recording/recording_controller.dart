import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';

import '../../shared/utils/session_id.dart';
import '../pose/pose_frame.dart';
import 'csv_writer.dart';
import 'recording_paths.dart';
import 'recording_session.dart';

class RecordingResult {
  final File csvFile;
  final File metadataFile;
  final RecordingSession session;

  const RecordingResult({
    required this.csvFile,
    required this.metadataFile,
    required this.session,
  });
}

class RecordingController {
  final PoseCsvWriter csvWriter;
  final Future<RecordingPaths> Function() createPaths;
  final int flushEveryRows;

  RecordingSession? _session;
  File? _csvFile;
  File? _metadataFile;
  final List<List<Object?>> _buffer = [];
  int _savedRows = 0;
  DateTime _lastFlush = DateTime.fromMillisecondsSinceEpoch(0);

  RecordingController({
    this.csvWriter = const PoseCsvWriter(),
    this.createPaths = RecordingPaths.create,
    this.flushEveryRows = 120,
  });

  bool get isRecording => _session != null;
  RecordingSession? get session => _session;

  Future<RecordingSession> start({
    required CameraDescription camera,
    required int imageWidth,
    required int imageHeight,
    DateTime? now,
  }) async {
    await stop(totalFrames: 0, detectedPoseFrames: 0);

    final startedAt = now ?? DateTime.now();
    final sessionId = createSessionId(startedAt);
    final paths = await createPaths();
    _csvFile = paths.csvFile(sessionId);
    _metadataFile = paths.metadataFile(sessionId);
    _buffer.clear();
    _savedRows = 0;
    _lastFlush = startedAt;

    _session = RecordingSession(
      sessionId: sessionId,
      startedAt: startedAt,
      endedAt: null,
      cameraLensDirection: camera.lensDirection.name,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      totalFrames: 0,
      detectedPoseFrames: 0,
      savedRows: 0,
    );

    await _csvFile!.writeAsString(
      '${csvWriter.convertRows([PoseCsvWriter.header])}\n',
      flush: true,
    );
    return _session!;
  }

  Future<void> recordFrame(PoseFrame frame) async {
    if (_session == null || frame.joints.isEmpty) {
      return;
    }

    _buffer.addAll(csvWriter.rowsForFrame(frame));
    final elapsed = DateTime.now().difference(_lastFlush);
    if (_buffer.length >= flushEveryRows || elapsed.inSeconds >= 1) {
      await flush();
    }
  }

  Future<void> flush() async {
    final csvFile = _csvFile;
    if (csvFile == null || _buffer.isEmpty) {
      return;
    }

    final rows = List<List<Object?>>.from(_buffer);
    _buffer.clear();
    await csvFile.writeAsString(
      '${csvWriter.convertRows(rows)}\n',
      mode: FileMode.append,
      flush: true,
    );
    _savedRows += rows.length;
    _lastFlush = DateTime.now();
  }

  Future<RecordingResult?> stop({
    required int totalFrames,
    required int detectedPoseFrames,
    DateTime? now,
  }) async {
    final current = _session;
    final csvFile = _csvFile;
    final metadataFile = _metadataFile;
    if (current == null || csvFile == null || metadataFile == null) {
      return null;
    }

    await flush();
    final closed = current.copyWith(
      endedAt: now ?? DateTime.now(),
      totalFrames: totalFrames,
      detectedPoseFrames: detectedPoseFrames,
      savedRows: _savedRows,
    );
    await metadataFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(closed.toJson()),
      flush: true,
    );

    _session = null;
    _csvFile = null;
    _metadataFile = null;
    _buffer.clear();

    return RecordingResult(
      csvFile: csvFile,
      metadataFile: metadataFile,
      session: closed,
    );
  }
}
