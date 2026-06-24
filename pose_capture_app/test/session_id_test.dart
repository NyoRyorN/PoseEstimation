import 'package:flutter_test/flutter_test.dart';
import 'package:pose_capture_app/shared/utils/session_id.dart';

void main() {
  test('createSessionId formats local timestamp', () {
    final id = createSessionId(DateTime(2026, 6, 24, 10, 30, 15));

    expect(id, '20260624_103015');
  });
}
