import 'dart:developer' as developer;

void logInfo(String message, {Object? error, StackTrace? stackTrace}) {
  developer.log(
    message,
    name: 'pose_capture',
    error: error,
    stackTrace: stackTrace,
  );
}
