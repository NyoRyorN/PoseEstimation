import 'dart:io';

import 'package:camera/camera.dart';

ImageFormatGroup get defaultImageFormatGroup {
  if (Platform.isAndroid) {
    return ImageFormatGroup.nv21;
  }
  if (Platform.isIOS) {
    return ImageFormatGroup.bgra8888;
  }
  return ImageFormatGroup.unknown;
}

ResolutionPreset get defaultResolutionPreset => ResolutionPreset.medium;
