import 'package:flutter/material.dart';

class PoseCoordinateConverter {
  const PoseCoordinateConverter();

  Offset imageToPreview({
    required Offset imagePoint,
    required Size imageSize,
    required Size previewSize,
    required int rotationDegrees,
    required bool mirrorHorizontally,
  }) {
    final rotated = _rotatePoint(
      imagePoint,
      imageSize,
      rotationDegrees,
    );
    final rotatedSize = _rotatedSize(imageSize, rotationDegrees);
    final displayPoint = mirrorHorizontally
        ? Offset(rotatedSize.width - rotated.dx, rotated.dy)
        : rotated;

    final fitted = applyBoxFit(BoxFit.cover, rotatedSize, previewSize);
    final sourceRect = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & rotatedSize,
    );
    final destinationRect = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & previewSize,
    );

    final scaleX = destinationRect.width / sourceRect.width;
    final scaleY = destinationRect.height / sourceRect.height;

    return Offset(
      destinationRect.left + (displayPoint.dx - sourceRect.left) * scaleX,
      destinationRect.top + (displayPoint.dy - sourceRect.top) * scaleY,
    );
  }

  Offset _rotatePoint(Offset point, Size imageSize, int rotationDegrees) {
    switch (rotationDegrees % 360) {
      case 90:
        return Offset(imageSize.height - point.dy, point.dx);
      case 180:
        return Offset(imageSize.width - point.dx, imageSize.height - point.dy);
      case 270:
        return Offset(point.dy, imageSize.width - point.dx);
      default:
        return point;
    }
  }

  Size _rotatedSize(Size imageSize, int rotationDegrees) {
    final normalized = rotationDegrees % 360;
    if (normalized == 90 || normalized == 270) {
      return Size(imageSize.height, imageSize.width);
    }
    return imageSize;
  }
}
