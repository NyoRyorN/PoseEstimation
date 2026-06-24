import 'dart:io';

import 'package:path_provider/path_provider.dart';

class RecordingPaths {
  final Directory directory;

  const RecordingPaths(this.directory);

  static Future<RecordingPaths> create() async {
    final directory = await getApplicationDocumentsDirectory();
    return RecordingPaths(directory);
  }

  File csvFile(String sessionId) {
    return File('${directory.path}/pose_$sessionId.csv');
  }

  File metadataFile(String sessionId) {
    return File('${directory.path}/pose_$sessionId.json');
  }
}
