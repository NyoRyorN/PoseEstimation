int epochMilliseconds([DateTime? value]) {
  return (value ?? DateTime.now()).millisecondsSinceEpoch;
}

String isoTimestamp(DateTime value) {
  if (value.isUtc) {
    return value.toIso8601String();
  }

  final offset = value.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final absolute = offset.abs();
  final hours = absolute.inHours.toString().padLeft(2, '0');
  final minutes = absolute.inMinutes.remainder(60).toString().padLeft(2, '0');
  return '${value.toIso8601String()}$sign$hours:$minutes';
}
