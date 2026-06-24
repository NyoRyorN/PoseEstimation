import 'package:flutter/material.dart';

import '../features/capture/capture_page.dart';
import 'theme.dart';

class PoseCaptureApp extends StatelessWidget {
  const PoseCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pose Capture',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const CapturePage(),
    );
  }
}
