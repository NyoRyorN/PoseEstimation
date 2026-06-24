import 'package:flutter_test/flutter_test.dart';
import 'package:pose_capture_app/shared/utils/timestamp_utils.dart';

void main() {
  test('isoTimestamp keeps UTC marker for UTC values', () {
    final value = DateTime.utc(2026, 6, 24, 1, 30, 15);

    expect(isoTimestamp(value), '2026-06-24T01:30:15.000Z');
  });
}
