String createSessionId([DateTime? now]) {
  final value = now ?? DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');

  return '${value.year}'
      '${two(value.month)}'
      '${two(value.day)}_'
      '${two(value.hour)}'
      '${two(value.minute)}'
      '${two(value.second)}';
}
